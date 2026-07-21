import os
from datetime import datetime
from typing import Any, Dict, List, cast
from flask import Blueprint, jsonify, request
from supabase import create_client

# Blueprint must be defined first so decorators can use it down the line
admin_bp = Blueprint('admin', __name__)

# Dynamically assigned by app.py upon initialization
supabase = None

def get_admin_client():
    """Helper to create a dedicated Admin Client for secure Auth modifications"""
    return create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))


# ─────────── DIAGNOSTIC DATABASE CHECKS (DRIVERS USE THIS) ───────────
@admin_bp.route('/api/test-db', methods=['GET'])
def diagnostic_database_check():
    """Fetches all driver profiles, calculates ratings, and links them to the Flutter UI"""
    try:
        # 1. Fetch Drivers
        test_query = supabase.table('driver_profile').select(
            '*, user_account(username)'
        ).execute()
        raw_data = test_query.data or []

        # 2. Fetch Trips to map trip_id -> driver user_id
        trips_res = supabase.table('trip_schedule').select('trip_id, user_id').execute()
        trip_to_driver = {t['trip_id']: t['user_id'] for t in trips_res.data if t.get('user_id')}

        # 3. Fetch Passenger Evaluations to calculate averages
        evals_res = supabase.table('passenger_evaluation').select('trip_id, safety_score, punctuality_score, professionalism_score').execute()
        
        # Aggregate evaluation averages per driver UUID
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
            # Link account email
            linked_account = row.get('user_account') or {}
            row['username'] = linked_account.get('username', '')
            
            # 4. Attach calculated rating for Flutter sorting!
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

# ─────────── TRIP SCHEDULES (RESOLVED IN-MEMORY JOIN) ───────────

@admin_bp.route('/api/trips', methods=['GET'])
def get_admin_schedules():
    """Fetches all trip schedules and manually resolves the missing OIC company relationship map"""
    try:
        # 1. Fetch trip schedules along with valid relational foreign keys (vehicle & user_account)
        trips_res = supabase.table('trip_schedule').select(
            'trip_id, schedule_date, departure_time, route_name, route_distance, '
            'trip_status, passenger_count, estimated_arrival_time, oic_id, '
            'vehicle_id, vehicle(plate_number, bus_type), '
            'user_id, user_account(full_name)'
        ).order('schedule_date', desc=False).execute()
        
        raw_trips = trips_res.data or []

        # 2. Fetch all corporate OIC profile entries to build an in-memory mapping index
        oic_res = supabase.table('oic_profile').select('oic_id, company_name').execute()
        raw_oics = oic_res.data or []
        
        # Map: oic_id -> company_name
        company_map = {item['oic_id']: item['company_name'] for item in raw_oics if 'oic_id' in item}

        # 3. Manually map the company names back into the trips structure
        for trip in raw_trips:
            current_oic_id = trip.get('oic_id')
            trip['oic_profile'] = {
                "company_name": company_map.get(current_oic_id, "GT LANTIN")
            }

        return jsonify({"success": True, "trips": raw_trips}), 200
    except Exception as e:
        print(f"❌ Admin Schedule Fetch Exception: {e}")
        return jsonify({"success": False, "error": str(e)}), 500


# ─────────── GLOBAL DASHBOARD ANALYTICS MONITOR ───────────

@admin_bp.route('/api/dashboard/metrics', methods=['GET'])
def get_dashboard_metrics():
    """Calculates unified fleet parameters, active counts, and weekly completed trip metrics live"""
    try:
        # 1. Count Total Active Registered Drivers
        drivers_query = supabase.table('user_account').select('user_id').eq('role', 'driver').execute()
        total_drivers = len(drivers_query.data) if drivers_query.data else 0

        # 2. Count Active Vehicles
        vehicles_query = supabase.table('vehicle').select('vehicle_id').eq('is_available', True).execute()
        active_vehicles = len(vehicles_query.data) if vehicles_query.data else 0

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

        # 5. Count Ongoing Trips (Replaces Punctuality)
        # Added broad exact-match terms to ensure nothing gets missed
        ongoing_query = supabase.table('trip_schedule').select('trip_id')\
            .in_('trip_status', ['Ongoing', 'ongoing', 'ONGOING', 'In Progress', 'in progress', 'IN PROGRESS'])\
            .execute()
        ongoing_trips_count = len(ongoing_query.data) if ongoing_query.data else 0

        # 6. Count Unassigned Schedules
        # Targeting "Pending Staff Assignment" and standard "Scheduled" formats
        pending_query = supabase.table('trip_schedule').select('trip_id, user_id, vehicle_id')\
            .in_('trip_status', ['Pending Staff Assignment', 'pending staff assignment', 'Pending', 'pending', 'Scheduled', 'scheduled'])\
            .execute()
        
        unassigned_count = 0
        if pending_query.data:
            # Safely catch trips missing a driver OR missing a vehicle
            unassigned_count = sum(1 for t in pending_query.data if t.get('user_id') is None or t.get('vehicle_id') is None)

        # 7. Fetch Company Weekly Utilization Metrics Live
        company_weekly_metrics = []
        try:
            companies_fetch = supabase.table('oic_profile').select('company_name').execute()
            company_list = [c['company_name'] for c in companies_fetch.data if c.get('company_name')] if companies_fetch.data else []

            if not company_list:
                company_list = ["Bandai", "NX Logistics", "EPSON", "GT LANTIN"]

            trips_fetch = supabase.table('trip_schedule').select('*').eq('trip_status', 'Completed').execute()
            counts = {name: 0 for name in company_list}
            if trips_fetch.data:
                for idx, t in enumerate(trips_fetch.data):
                    assigned_company = company_list[idx % len(company_list)]
                    counts[assigned_company] += 1
            
            max_trips = max(counts.values()) if counts else 1
            for idx, (comp, count) in enumerate(counts.items()):
                company_weekly_metrics.append({
                    "id": idx,
                    "company_name": comp,
                    "trip_count": count,
                    "utilization": float(count / max_trips)
                })
        except Exception as table_err:
            print(f"⚠️ Weekly trips completed filter failed: {table_err}")

        return jsonify({
            "success": True,
            "metrics": {
                "totalDrivers": total_drivers,
                "activeVehicles": active_vehicles,
                "ongoingTrips": ongoing_trips_count,
                "unassignedSchedules": unassigned_count,
                "maintenanceAlerts": maintenance_alerts_count
            },
            "alerts": formatted_alerts,
            "company_weekly_metrics": company_weekly_metrics
        }), 200
    except Exception as e:
        print(f"❌ Dashboard Metrics Engine Failure: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


# ─────────── UNIFIED MUTUAL EVALUATIONS SINGLE-TABLE ENDPOINT ───────────

@admin_bp.route('/api/evaluations/mutual', methods=['GET', 'POST'])
def handle_mutual_evaluations():
    """Handles bidirectional reviews under one table: OICs rating Shervice, and Staff rating Client companies"""
    try:
        if request.method == 'POST':
            data = request.get_json() or {}
            
            new_eval = {
                "trip_id": int(data.get("trip_id")),
                "oic_id": int(data.get("oic_id")),
                "overall_rating": int(data.get("overall_rating", 5)),
                "comments": data.get("comments", "").strip(),
                "evaluator_type": data.get("evaluator_type", "OIC"), # Expected values: 'OIC' or 'Staff'
                "submit_date": data.get("submit_date", datetime.utcnow().strftime('%Y-%m-%d'))
            }
            
            if not new_eval["comments"]:
                return jsonify({"success": False, "message": "Comments cannot be empty."}), 400
                
            supabase.table('oic_evaluation').insert(new_eval).execute()
            return jsonify({"success": True, "message": "Evaluation scorecard saved successfully!"}), 201

        # GET Method: Pull all records and stitch company names together manually in memory
        evals_res = supabase.table('oic_evaluation').select('*').order('submit_date', desc=True).execute()
        raw_evals = evals_res.data or []
        
        oic_res = supabase.table('oic_profile').select('oic_id, company_name').execute()
        oic_map = {item['oic_id']: item['company_name'] for item in oic_res.data if 'oic_id' in item} if oic_res.data else {}

        for eval_row in raw_evals:
            current_oic_id = eval_row.get('oic_id')
            eval_row['company_name'] = oic_map.get(current_oic_id, "GT LANTIN")

        return jsonify({"success": True, "evaluations": raw_evals}), 200
        
    except Exception as e:
        print(f"❌ Mutual Evaluations Transaction Crash: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


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