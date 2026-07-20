import os
import time
import socket
import traceback
from datetime import datetime
from typing import Any, Dict, List, cast
from dotenv import load_dotenv
from flask import Blueprint, jsonify, request
from supabase import create_client

# Blueprint must be defined first so decorators can use it down the line
admin_bp = Blueprint('admin', __name__)


def _create_supabase_client():
    load_dotenv()
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_KEY')
    if not url or not key:
        raise RuntimeError('Missing SUPABASE_URL or SUPABASE_KEY environment variables.')
    return create_client(url, key)


def _execute_supabase(action, retries=3, backoff=0.25):
    last_exc = None
    for attempt in range(1, retries + 1):
        try:
            return action()
        except Exception as e:
            last_exc = e
            message = str(e).lower()
            retryable = (
                isinstance(e, OSError)
                or '10035' in message
                or 'non-blocking socket operation' in message
                or 'temporarily unavailable' in message
                or 'timeout' in message
            )
            print(f'⚠️ Supabase retry attempt {attempt}/{retries}: {e}')
            traceback.print_exc()
            if not retryable or attempt >= retries:
                break
            time.sleep(backoff * attempt)
    raise last_exc


# Dynamically assigned by app.py upon initialization
supabase = None

def get_admin_client():
    """Helper to create a dedicated Admin Client for secure Auth modifications"""
    return create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))


# ─────────── DIAGNOSTIC DATABASE CHECKS ───────────

@admin_bp.route('/api/test-db', methods=['GET'])
def diagnostic_database_check():
    try:
        test_query = supabase.table('driver_profile').select(
            '*, user_account(username)'
        ).execute()
        
        raw_data = test_query.data or []
        flattened_drivers = []

        for row in raw_data:
            linked_account = row.get('user_account') or {}
            driver_email = linked_account.get('username', '')
            
            row['username'] = driver_email
            flattened_drivers.append(row)

        return jsonify({
            "connection_status": "SUCCESS",
            "message": "Flask successfully linked driver profiles and unified user account email blocks!",
            "table_queried": "driver_profile join user_account",
            "total_rows_found": len(flattened_drivers),
            "sample_data_payload": flattened_drivers[:100]
        }), 200
    except Exception as e:
        print(f"❌ Diagnostic database connection or table join failed: {e}")
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

@app.route('/api/dashboard/metrics', methods=['GET'])
def get_dashboard_metrics():
    try:
        # 1. Active Drivers (Ensure 'Active' matches your DB string exactly)
        drivers_res = supabase.table('driver_profile').select('*', count='exact').eq('employment_status', 'Active').execute()
        total_drivers = drivers_res.count if drivers_res else 0

        # 2. Active Vehicles
        vehicles_res = supabase.table('vehicle').select('*', count='exact').eq('is_available', True).execute()
        active_vehicles = vehicles_res.count if vehicles_res else 0

        # 3. Ongoing Trips (Ensure 'Ongoing' matches your trip_status in the DB)
        ongoing_res = supabase.table('trip_schedule').select('*', count='exact').eq('trip_status', 'Ongoing').execute()
        ongoing_trips = ongoing_res.count if ongoing_res else 0

        # 4. Unassigned Trips (Strict PostgREST syntax for OR conditions)
        unassigned_res = supabase.table('trip_schedule').select('*', count='exact').or_("trip_status.eq.Pending Staff Assignment").execute()
        unassigned_trips = unassigned_res.count if unassigned_res else 0

        # 5. Maintenance Alerts
        maintenance_res = supabase.table('maintenance_log').select('*', count='exact').eq('is_resolved', False).execute()
        maintenance_alerts = maintenance_res.count if maintenance_res else 0

        return jsonify({
            "success": True,
            "metrics": {
                "totalDrivers": total_drivers,
                "activeVehicles": active_vehicles,
                "ongoingTrips": ongoing_trips,
                "unassignedTrips": unassigned_trips,
                "maintenanceAlerts": maintenance_alerts
            },
            # Fetch your alerts and company metrics here as you were previously
            "alerts": [], 
            "company_weekly_metrics": [] 
        }), 200

    except Exception as e:
        # Print the error to your terminal so you can see if a DB query is crashing
        print(f"DASHBOARD ERROR: {e}")
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