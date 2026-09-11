import os
from io import BytesIO
from datetime import datetime
from typing import Any, Dict, List, cast
from flask import Blueprint, jsonify, request
from supabase import create_client
import xlrd
from openpyxl import Workbook
from roles.schedules import _sweep_expired_trips

# Blueprint must be defined first so decorators can use it down the line
admin_bp = Blueprint('admin', __name__)

# Dynamically assigned by app.py upon initialization
supabase = None

def get_admin_client():
    """Helper to create a dedicated Admin Client for secure Auth modifications"""
    return create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))


def _normalize_xls_cell(value: Any) -> Any:
    """Normalizes raw .xls cell values to strings and plain Python values."""
    if value is None:
        return ""
    if isinstance(value, float):
        if value.is_integer():
            return str(int(value))
        return str(value)
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d %H:%M:%S")
    return str(value).strip()


def parse_legacy_xls_bytes(file_bytes: bytes) -> Dict[str, Any]:
    """Reads a legacy .xls workbook, normalizes rows, and converts it to XLSX in memory."""
    try:
        workbook = xlrd.open_workbook(file_contents=file_bytes)
        sheet = workbook.sheet_by_index(0)

        rows: List[List[Any]] = []
        for row_idx in range(sheet.nrows):
            values = []
            for col_idx in range(sheet.ncols):
                values.append(sheet.cell_value(row_idx, col_idx))
            rows.append(values)

        if not rows:
            return {"success": False, "error": "Uploaded file has no rows."}

        headers = []
        for index, header in enumerate(rows[0]):
            normalized = _normalize_xls_cell(header)
            headers.append(normalized or f"Column {index + 1}")

        data_rows = []
        for row in rows[1:]:
            record = {}
            for index, header in enumerate(headers):
                value = row[index] if index < len(row) else ""
                record[header] = _normalize_xls_cell(value)
            if any(str(value).strip() for value in record.values()):
                data_rows.append(record)

        workbook_out = Workbook()
        ws = workbook_out.active
        ws.title = 'Attendance'
        ws.append(headers)

        for row in rows[1:]:
            converted_row = []
            for index in range(len(headers)):
                value = row[index] if index < len(row) else ""
                converted_row.append(_normalize_xls_cell(value))
            ws.append(converted_row)

        buffer = BytesIO()
        workbook_out.save(buffer)
        xlsx_bytes = buffer.getvalue()

        return {
            "success": True,
            "sheet_name": sheet.name,
            "headers": headers,
            "rows": data_rows,
            "xlsx_bytes": xlsx_bytes,
            "row_count": len(data_rows),
            "xlsx_size": len(xlsx_bytes),
        }
    except Exception as exc:
        return {"success": False, "error": f"Unable to convert legacy .xls file: {exc}"}


# ─────────── DIAGNOSTIC DATABASE CHECKS (DRIVERS USE THIS) ───────────
@admin_bp.route('/api/test-db', methods=['GET'])
def diagnostic_database_check():
    """Fetches all driver profiles, calculates ratings, and links them to the Flutter UI"""
    try:
        test_query = supabase.table('driver_profile').select(
            '*, user_account(username)'
        ).execute()
        raw_data = test_query.data or []

        trips_res = supabase.table('trip_schedule').select('trip_id, user_id').execute()
        trip_to_driver = {t['trip_id']: t['user_id'] for t in trips_res.data if t.get('user_id')}

        evals_res = supabase.table('passenger_evaluation').select('trip_id, safety_score, punctuality_score, professionalism_score').execute()
        
        driver_scores = {}
        for ev in evals_res.data or []:
            t_id = ev.get('trip_id')
            driver_id = trip_to_driver.get(t_id)
            if driver_id:
                s = float(ev.get('safety_score') or 0)
                p = float(ev.get('punctuality_score') or 0)
                pr = float(ev.get('professionalism_score') or 0)
                eval_avg = (s + p + pr) / 3.0
                
                if driver_id not in driver_scores:
                    driver_scores[driver_id] = []
                driver_scores[driver_id].append(eval_avg)

        flattened_drivers = []
        for row in raw_data:
            linked_account = row.get('user_account') or {}
            row['username'] = linked_account.get('username', '')
            
            d_uuid = row.get('user_id')
            scores = driver_scores.get(d_uuid, [])
            row['rating'] = sum(scores) / len(scores) if scores else 0.0
            
            flattened_drivers.append(row)

        return jsonify({
            "connection_status": "SUCCESS",
            "message": "Driver profiles and ratings successfully aggregated!",
            "total_rows_found": len(flattened_drivers),
            "sample_data_payload": flattened_drivers
        }), 200
    except Exception as e:
        print(f"❌ Diagnostic database connection failed: {e}")
        return jsonify({"connection_status": "FAILED", "error_details": str(e)}), 500

# ─────────── TRIP SCHEDULES (NOW USING CLIENT_COMPANY JOIN) ───────────

@admin_bp.route('/trips', methods=['GET'])
def get_admin_schedules():
    """Fetches all trip schedules, fetches actual company, and attaches passenger CSAT ratings."""
    try:
        _sweep_expired_trips()
        # 1. Direct join with client_company using the new company_id
        trips_res = supabase.table('trip_schedule').select(
            'trip_id, schedule_date, departure_time, route_name, route_distance, '
            'trip_status, passenger_count, estimated_arrival_time, '
            'actual_start_time, actual_end_time, '
            'vehicle_id, vehicle(plate_number, bus_type), '
            'user_id, user_account(full_name), '
            'client_company(company_name)'
        ).order('schedule_date', desc=False).execute()
        
        raw_trips = trips_res.data or []

        # 2. Fetch Passenger Evaluations to calculate CSAT per trip
        evals_res = supabase.table('passenger_evaluation').select('trip_id, safety_score, punctuality_score, professionalism_score').execute()
        
        trip_evals = {}
        for ev in (evals_res.data or []):
            t_id = ev.get('trip_id')
            if t_id is not None:
                s = float(ev.get('safety_score') or 0.0)
                p = float(ev.get('punctuality_score') or 0.0)
                pr = float(ev.get('professionalism_score') or 0.0)
                eval_avg = (s + p + pr) / 3.0
                
                t_id_str = str(t_id)
                if t_id_str not in trip_evals:
                    trip_evals[t_id_str] = []
                trip_evals[t_id_str].append(eval_avg)

        # 3. Inject scores
        for trip in raw_trips:
            t_id_str = str(trip.get('trip_id'))
            if t_id_str in trip_evals and trip_evals[t_id_str]:
                scores = trip_evals[t_id_str]
                trip['evaluation_score'] = sum(scores) / len(scores)
            else:
                trip['evaluation_score'] = None

        return jsonify({"success": True, "trips": raw_trips}), 200
    except Exception as e:
        print(f"❌ Admin Schedule Fetch Exception: {e}")
        return jsonify({"success": False, "error": str(e)}), 500

# ─────────── UNIFIED MUTUAL EVALUATIONS SINGLE-TABLE ENDPOINT ───────────
@admin_bp.route('/api/admin/attendance/upload-legacy-xls', methods=['POST'])
def upload_legacy_xls_attendance():
    """Reads legacy .xls uploads, converts them in memory to xlsx, and returns the normalized rows."""
    try:
        if 'file' not in request.files:
            return jsonify({"success": False, "error": "No file uploaded."}), 400

        uploaded = request.files['file']
        if uploaded.filename == '':
            return jsonify({"success": False, "error": "No selected file."}), 400

        file_bytes = uploaded.read()
        if not file_bytes:
            return jsonify({"success": False, "error": "Uploaded file is empty."}), 400

        result = parse_legacy_xls_bytes(file_bytes)
        if not result.get('success'):
            return jsonify({"success": False, "error": result.get('error', 'Unable to convert legacy .xls file.')}), 400

        return jsonify({
            "success": True,
            "sheet_name": result.get('sheet_name'),
            "headers": result.get('headers', []),
            "rows": result.get('rows', []),
            "xlsx_size": result.get('xlsx_size', 0),
            "row_count": result.get('row_count', 0),
        }), 200
    except Exception as exc:
        return jsonify({"success": False, "error": f"Unable to convert legacy .xls file: {exc}"}), 500


@admin_bp.route('/api/dashboard/metrics', methods=['GET'])
def get_dashboard_metrics():
    """Calculates unified fleet parameters, active counts, and monthly completed trip metrics live"""
    try:
        # 1. Count all registered drivers
        drivers_query = supabase.table('driver_profile').select(
            '*, user_account(username)'
        ).execute()
        all_drivers = drivers_query.data or []
        total_drivers = len(all_drivers)
        driver_details = [
            {
                "label": driver.get('full_name') or f"Driver {driver.get('user_id', 'Unknown')}",
                "driver_id": driver.get('driver_id'),
                "user_id": driver.get('user_id'),
                "username": (driver.get('user_account') or {}).get('username'),
                "license_no": driver.get('license_no'),
                "license_expiry": driver.get('license_expiry'),
                "employment_status": driver.get('employment_status', 'Active'),
                "date_hired": driver.get('date_hired'),
                "birthday": driver.get('birthday')
            }
            for driver in all_drivers
        ]

        # 2. Count Active Vehicles
        vehicles_query = supabase.table('vehicle').select('vehicle_id, plate_number').eq('is_available', True).execute()
        active_vehicles = len(vehicles_query.data) if vehicles_query.data else 0
        vehicle_details = [
            {"label": vehicle.get('plate_number') or f"Vehicle {vehicle.get('vehicle_id', 'Unknown')}"}
            for vehicle in (vehicles_query.data or [])
        ]

        # 3. Count Active Maintenance Alerts
        alerts_count_query = supabase.table('vehicle').select('vehicle_id').eq('is_available', False).execute()
        maintenance_alerts_count = len(alerts_count_query.data) if alerts_count_query.data else 0

        # 4. Fetch recent maintenance log entries stream details
        alerts_log_query = supabase.table('maintenance_log')\
            .select('maintenance_id, description, vehicle_id')\
            .order('repair_date', desc=True)\
            .execute()

        all_vehicles = supabase.table('vehicle').select('vehicle_id, plate_number').execute()
        vehicle_map = {}
        if all_vehicles.data:
            for v in all_vehicles.data:
                v_id = v.get('vehicle_id')
                if v_id is not None:
                    vehicle_map[str(v_id)] = v.get('plate_number', 'Unknown Plate')
                    vehicle_map[int(v_id)] = v.get('plate_number', 'Unknown Plate')

        formatted_alerts = []
        if alerts_log_query.data:
            for log in alerts_log_query.data:
                raw_v_id = log.get('vehicle_id')
                resolved_plate = vehicle_map.get(raw_v_id, vehicle_map.get(str(raw_v_id), f"Asset {raw_v_id}"))
                formatted_alerts.append({
                    "id": str(log.get('maintenance_id')),
                    "vehicle_id": resolved_plate,
                    "plate_number": resolved_plate,
                    "description": log.get('description', 'No details provided.')
                })

        # 5. Count Ongoing Trips
        ongoing_query = supabase.table('trip_schedule').select('trip_id, trip_status')\
            .in_('trip_status', ['Ongoing', 'ongoing', 'ONGOING', 'In Progress', 'in progress', 'IN PROGRESS'])\
            .execute()
        ongoing_trips_count = len(ongoing_query.data) if ongoing_query.data else 0
        ongoing_trip_details = [
            {"label": f"Trip {trip.get('trip_id', 'Unknown')}", "status": trip.get('trip_status', 'Ongoing')}
            for trip in (ongoing_query.data or [])
        ]

        # 6. Count Unassigned Schedules
        pending_query = supabase.table('trip_schedule').select('trip_id, user_id, vehicle_id')\
            .in_('trip_status', ['Pending Staff Assignment', 'pending staff assignment', 'Pending', 'pending', 'Scheduled', 'scheduled'])\
            .execute()
        
        unassigned_count = 0
        if pending_query.data:
            unassigned_count = sum(1 for t in pending_query.data if t.get('user_id') is None or t.get('vehicle_id') is None)
        unassigned_details = [
            {"label": f"Trip {trip.get('trip_id', 'Unknown')}", "status": "Needs assignment"}
            for trip in (pending_query.data or [])
            if trip.get('user_id') is None or trip.get('vehicle_id') is None
        ]

        # 7. Fetch Company Monthly Utilization Metrics Live
        company_monthly_metrics = []
        try:
            selected_month = int(request.args.get('month', datetime.now().month))
            selected_year = int(request.args.get('year', datetime.now().year))
            if selected_month < 1 or selected_month > 12:
                raise ValueError('month must be between 1 and 12')
            
            period_start = datetime(selected_year, selected_month, 1).date().isoformat()
            if selected_month == 12:
                next_month = datetime(selected_year + 1, 1, 1)
            else:
                next_month = datetime(selected_year, selected_month + 1, 1)
            period_end = next_month.date().isoformat()
            
            # Fetch valid companies directly
            companies_fetch = supabase.table('client_company').select('company_name').execute()
            if companies_fetch.data:
                company_list = [
                    c['company_name'] for c in companies_fetch.data 
                    if c.get('company_name') and 'INTERNAL' not in c['company_name'].upper() and 'GT LANTIN' not in c['company_name'].upper()
                ]
            else:
                company_list = ["Bandai", "NX Logistics", "EPSON"]

            # Fetch trips with joined company name
            trips_fetch = supabase.table('trip_schedule')\
                .select('trip_id, client_company(company_name)')\
                .eq('trip_status', 'Completed')\
                .gte('schedule_date', period_start)\
                .lt('schedule_date', period_end)\
                .execute()
            
            counts = {name: 0 for name in company_list}
            
            if trips_fetch.data:
                for trip in trips_fetch.data:
                    # Cleanly extract the joined company name
                    client_comp = trip.get('client_company') or {}
                    assigned_company = client_comp.get('company_name')
                    
                    if assigned_company and assigned_company in counts:
                        counts[assigned_company] += 1
            
            max_trips = max(counts.values()) if counts and max(counts.values()) > 0 else 1
            for idx, (comp, count) in enumerate(counts.items()):
                company_monthly_metrics.append({
                    "id": idx,
                    "company_name": comp,
                    "trip_count": count,
                    "utilization": float(count / max_trips)
                })
        except Exception as table_err:
            print(f"⚠️ Monthly trips completed filter failed: {table_err}")

        return jsonify({
            "success": True,
            "metrics": {
                "totalDrivers": total_drivers,
                "activeVehicles": active_vehicles,
                "ongoingTrips": ongoing_trips_count,
                "unassignedSchedules": unassigned_count,
                "maintenanceAlerts": maintenance_alerts_count
            },
            "details": {
                "All Drivers": driver_details,
                "Active Vehicles": vehicle_details,
                "Ongoing Trips": ongoing_trip_details,
                "Unscheduled": unassigned_details,
                "Maintenance Alerts": formatted_alerts
            },
            "alerts": formatted_alerts,
            "company_monthly_metrics": company_monthly_metrics
        }), 200
    except Exception as e:
        print(f"❌ Dashboard Metrics Engine Failure: {e}")
        return jsonify({"success": False, "message": str(e)}), 500

# ─────────── NEW: MONTHLY DRIVER LEADERBOARD & OVERALL AVERAGE ───────────

@admin_bp.route('/api/dashboard/driver-leaderboard', methods=['GET'])
def get_driver_leaderboard():
    """Fetches top drivers and calculates overall metrics specifically for a given month and year."""
    try:
        selected_month = int(request.args.get('month', datetime.now().month))
        selected_year = int(request.args.get('year', datetime.now().year))
        
        period_start = datetime(selected_year, selected_month, 1).date().isoformat()
        if selected_month == 12:
            next_month = datetime(selected_year + 1, 1, 1)
        else:
            next_month = datetime(selected_year, selected_month + 1, 1)
        period_end = next_month.date().isoformat()

        evals_res = supabase.table('passenger_evaluation')\
            .select('trip_id, safety_score, punctuality_score, professionalism_score')\
            .gte('submit_date', period_start)\
            .lt('submit_date', period_end)\
            .execute()
        
        raw_evals = evals_res.data or []

        if not raw_evals:
            return jsonify({
                "success": True, 
                "top_drivers": [],
                "overall_average": 0.0,
                "total_rated_drivers": 0
            }), 200

        trip_ids = list(set([str(e['trip_id']) for e in raw_evals if e.get('trip_id')]))
        
        if not trip_ids:
            return jsonify({
                "success": True, 
                "top_drivers": [],
                "overall_average": 0.0,
                "total_rated_drivers": 0
            }), 200

        trips_res = supabase.table('trip_schedule')\
            .select('trip_id, user_id')\
            .in_('trip_id', trip_ids)\
            .execute()
        
        trip_to_driver = {t['trip_id']: t['user_id'] for t in trips_res.data if t.get('user_id')}

        driver_ids = list(set(trip_to_driver.values()))
        if not driver_ids:
            return jsonify({
                "success": True, 
                "top_drivers": [],
                "overall_average": 0.0,
                "total_rated_drivers": 0
            }), 200
            
        drivers_res = supabase.table('driver_profile')\
            .select('user_id, full_name')\
            .in_('user_id', driver_ids)\
            .execute()
        
        driver_names = {d['user_id']: d['full_name'] for d in drivers_res.data}

        driver_scores = {}
        all_trip_scores = []

        for ev in raw_evals:
            t_id = ev.get('trip_id')
            driver_id = trip_to_driver.get(t_id)
            
            s = float(ev.get('safety_score') or 0)
            p = float(ev.get('punctuality_score') or 0)
            pr = float(ev.get('professionalism_score') or 0)
            eval_avg = (s + p + pr) / 3.0
            
            if eval_avg > 0:
                all_trip_scores.append(eval_avg)
                if driver_id:
                    if driver_id not in driver_scores:
                        driver_scores[driver_id] = []
                    driver_scores[driver_id].append(eval_avg)

        top_drivers = []
        for d_id, scores in driver_scores.items():
            avg_rating = sum(scores) / len(scores)
            top_drivers.append({
                "user_id": d_id,
                "full_name": driver_names.get(d_id, "Unknown Driver"),
                "rating": round(avg_rating, 2),
                "eval_count": len(scores)
            })

        top_drivers.sort(key=lambda x: (x['rating'], x['eval_count']), reverse=True)
        overall_monthly_average = sum(all_trip_scores) / len(all_trip_scores) if all_trip_scores else 0.0

        return jsonify({
            "success": True,
            "top_drivers": top_drivers[:5],
            "overall_average": round(overall_monthly_average, 2),
            "total_rated_drivers": len(driver_scores)
        }), 200

    except Exception as e:
        print(f"❌ Driver Leaderboard Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500


# ─────────── VEHICLE SPECIFICATIONS MANAGEMENT ───────────

@admin_bp.route('/api/vehicles/update/<vehicle_id>', methods=['PUT'])
def update_vehicle_details(vehicle_id):
    try:
        data = request.get_json() or {}
        
        supabase.table('vehicle').update({
            "plate_number": data.get("plate_number"),
            "bus_type": data.get("bus_type"),
            "model_year": data.get("model_year"),
            "engine_no": data.get("engine_no"),
            "insurance_policy_no": data.get("insurance_policy_no"),
            "insurance_expiry": data.get("insurance_expiry"),
            "franchise_no": data.get("franchise_no"),
            "franchise_expiry": data.get("franchise_expiry"),
            "cr_no": data.get("cr_no"),
            "cr_date": data.get("cr_date"),
            "or_no": data.get("or_no"),
            "or_expiry": data.get("or_expiry")
        }).eq("vehicle_id", vehicle_id).execute()

        return jsonify({"success": True, "message": "Vehicle specifications updated!"}), 200
    except Exception as e:
        print(f"❌ Vehicle Update DB Crash: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


@admin_bp.route('/api/vehicles/delete/<vehicle_id>', methods=['DELETE'])
def delete_vehicle_record(vehicle_id):
    try:
        supabase.table('maintenance_log').delete().eq("vehicle_id", int(vehicle_id)).execute()
        supabase.table('vehicle').delete().eq("vehicle_id", int(vehicle_id)).execute()
        return jsonify({"success": True, "message": "Vehicle and associated logs removed successfully."}), 200
    except Exception as e:
        print(f"❌ Vehicle Deletion DB Crash: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


# ─────────── DRIVER PROFILE LEDGER SYSTEM ───────────

@admin_bp.route('/api/auth/update-driver/<user_id>', methods=['PUT'])
def update_driver_profile(user_id):
    try:
        data = request.get_json() or {}
        new_email = data.get("email", "").strip().lower()
        full_name = data.get("full_name")

        if new_email:
            try:
                admin_supabase = get_admin_client()
                admin_supabase.auth.admin.update_user_by_id(
                    user_id,
                    attributes={"email": new_email, "email_confirm": True}
                )
            except Exception as auth_err:
                print(f"⚠️ Auth Vault Sync bypassed: {auth_err}")

            supabase.table("user_account").update({
                "username": new_email,
                "full_name": full_name
            }).eq("user_id", user_id).execute()

        supabase.table("driver_profile").update({
            "full_name": full_name,
            "license_no": data.get("license_no"),
            "birthday": data.get("birthday"),
            "employment_status": data.get("employment_status", "Active")
        }).eq("user_id", user_id).execute()

        if hasattr(supabase, 'postgrest'):
            supabase.postgrest.session.close()

        return jsonify({"success": True, "message": "Live driver profile tables committed successfully."}), 200
        
    except Exception as e:
        print(f"❌ Core Driver Profile Update Crash: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


# ─────────── USER INTERFACE ACCOUNT MASTER KEYS ───────────

@admin_bp.route('/api/auth/update-user/<user_id>', methods=['PUT'])
def update_system_user(user_id):
    try:
        data = request.get_json() or {}
        new_email = data.get("email", "").strip().lower()
        raw_role = data.get("role")
        company_name = data.get("company_name")

        role_map = {'Administrator': 'admin', 'Dispatch Staff': 'staff', 'Officer-in-Charge': 'oic'}
        normalized_role = role_map.get(raw_role, 'staff')

        if new_email:
            try:
                admin_supabase = get_admin_client()
                admin_supabase.auth.admin.update_user_by_id(
                    user_id,
                    attributes={"email": new_email, "email_confirm": True}
                )
            except Exception as auth_err:
                print(f"⚠️ Auth Vault Sync bypassed: {auth_err}")

        supabase.table("user_account").update({
            "full_name": data.get("full_name"),
            "username": new_email,
            "role": normalized_role
        }).eq("user_id", user_id).execute()

        if normalized_role == 'oic':
            supabase.table("oic_profile").upsert({
                "user_id": user_id,
                "company_name": company_name
            }).execute()
        else:
            supabase.table("oic_profile").delete().eq("user_id", user_id).execute()

        return jsonify({"success": True, "message": "User profiles synchronized successfully."}), 200
    except Exception as e:
        print(f"❌ System User Update Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


@admin_bp.route('/api/auth/delete-user/<user_id>', methods=['DELETE'])
def delete_system_user(user_id):
    try:
        supabase.table("oic_profile").delete().eq("user_id", user_id).execute()
        supabase.table("user_account").delete().eq("user_id", user_id).execute()

        try:
            admin_supabase = get_admin_client()
            admin_supabase.auth.admin.delete_user(user_id)
        except Exception as auth_err:
            print(f"⚠️ Auth microservice reference absent or skipped: {auth_err}")

        return jsonify({"success": True, "message": "User accounts entirely removed from records."}), 200
    except Exception as e:
        print(f"❌ System User Deletion Crash: {e}")
        return jsonify({"success": False, "message": str(e)}), 500

# ─────────── CLIENT COMPANY MANAGEMENT ───────────

@admin_bp.route('/api/companies', methods=['GET'])
def get_client_companies():
    """Fetch all registered client companies."""
    try:
        res = supabase.table('client_company').select('*').order('company_name', desc=False).execute()
        return jsonify({"success": True, "data": res.data or []}), 200
    except Exception as e:
        print(f"❌ Fetch Companies Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


@admin_bp.route('/api/companies', methods=['POST'])
def add_client_company():
    """Add a new client company."""
    try:
        data = request.get_json() or {}
        name = (data.get('company_name') or '').strip()
        if not name:
            return jsonify({"success": False, "message": "Company name is required."}), 400

        res = supabase.table('client_company').insert({"company_name": name}).execute()
        return jsonify({"success": True, "message": "Company added successfully!", "data": res.data}), 201
    except Exception as e:
        print(f"❌ Add Company Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


@admin_bp.route('/api/companies/<int:company_id>', methods=['DELETE'])
def delete_client_company(company_id):
    """Delete a company and prevent deletion if referenced."""
    try:
        # 1. Fetch company name
        comp_res = supabase.table('client_company').select('company_name').eq('company_id', company_id).execute()
        if not comp_res.data:
            return jsonify({"success": False, "message": "Company not found."}), 404

        comp_name = comp_res.data[0]['company_name']

        # 2. Check if active OIC accounts are assigned to this company
        oic_check = supabase.table('oic_profile').select('oic_id').eq('company_name', comp_name).execute()
        if oic_check.data and len(oic_check.data) > 0:
            return jsonify({
                "success": False, 
                "message": f"Cannot delete '{comp_name}' because active Officer-in-Charge profiles are assigned to it."
            }), 400

        # 3. Delete from table
        supabase.table('client_company').delete().eq('company_id', company_id).execute()
        return jsonify({"success": True, "message": f"'{comp_name}' deleted successfully."}), 200
    except Exception as e:
        print(f"❌ Delete Company Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500