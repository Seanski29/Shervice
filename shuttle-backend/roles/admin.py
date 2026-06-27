import os
from typing import Any, Dict, List, cast
from flask import Blueprint, jsonify, request
from supabase import create_client

admin_bp = Blueprint('admin', __name__)

# Dynamically assigned by app.py upon initialization
supabase = None

def get_admin_client():
    """Helper to create a dedicated Admin Client for secure Auth modifications"""
    return create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))

@admin_bp.route('/api/dashboard/metrics', methods=['GET'])
def get_dashboard_metrics():
    try:
        drivers_res = supabase.table('driver_profile').select('driver_id').execute()
        total_drivers = len(drivers_res.data) if drivers_res.data else 0

        active_res = supabase.table('vehicle').select('vehicle_id').eq('health_status', 'Good Condition').execute()
        active_vehicles = len(active_res.data) if active_res.data else 0

        maint_res = supabase.table('vehicle').select('vehicle_id').eq('health_status', 'Maintenance Required').execute() 
        maint_alerts = len(maint_res.data) if maint_res.data else 0

        eval_res = supabase.table('passenger_evaluation').select('punctuality_score').execute()
        avg_punctuality = 5.0 
        
        if eval_res.data:
            scores = [row['punctuality_score'] for row in eval_res.data if row.get('punctuality_score') is not None] # type: ignore
            if scores:
                avg_punctuality = round(sum(scores), 1) / len(scores) # type: ignore
       
        recent_maint_res = supabase.table('vehicle').select('plate_number, health_status').eq('health_status', 'Maintenance Required').execute()
        raw_shuttles = cast(List[Dict[str, Any]], recent_maint_res.data if recent_maint_res.data else [])
        
        formatted_alerts = []
        for shuttle in raw_shuttles:
            formatted_alerts.append({
                "plate_number": shuttle.get('plate_number', 'Unknown Plate'),
                "description": "Vehicle flagged for maintenance. System diagnostics overhaul required."
            })

        return jsonify({
            "success": True,
            "metrics": {
                "totalDrivers": total_drivers,
                "activeVehicles": active_vehicles,
                "averagePunctuality": avg_punctuality,
                "maintenanceAlerts": maint_alerts
            },
            "alerts": formatted_alerts
        }), 200

    except Exception as e:
        print(f"❌ Core Metrics Stream Processing Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500


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


@admin_bp.route('/api/trips', methods=['GET'])
def get_admin_schedules():
    try:
        trips_res = supabase.table('trip_schedule').select('*').order('schedule_date', desc=False).execute()
        return jsonify({
            "success": True, 
            "trips": trips_res.data or []
        }), 200
    except Exception as e:
        print(f"❌ Admin Schedule Fetch Exception: {e}")
        return jsonify({"success": False, "error": str(e)}), 500


# ─────────── VEHICLE ENDPOINTS (PUT & DELETE) ───────────

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
        supabase.table('vehicle').delete().eq("vehicle_id", vehicle_id).execute()
        return jsonify({"success": True, "message": "Vehicle removed successfully."}), 200
    except Exception as e:
        print(f"❌ Vehicle Deletion DB Crash: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


# ─────────── USER MANAGEMENT ENDPOINTS (PUT & DELETE) ───────────

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
            admin_supabase = get_admin_client()
            admin_supabase.auth.admin.update_user_by_id(
                user_id,
                attributes={"email": new_email, "email_confirm": True}
            )

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

        admin_supabase = get_admin_client()
        admin_supabase.auth.admin.delete_user(user_id)

        return jsonify({"success": True, "message": "User accounts entirely removed from records."}), 200
    except Exception as e:
        print(f"❌ System User Deletion Crash: {e}")
        return jsonify({"success": False, "message": str(e)}), 500