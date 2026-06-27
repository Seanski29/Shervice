from typing import Any, Dict, List, cast
from flask import Blueprint, jsonify

admin_bp = Blueprint('admin', __name__)

# Dynamically assigned by app.py upon initialization
supabase = None

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
        test_query = supabase.table('driver_profile').select('*').execute()
        raw_data = test_query.data
        row_count = len(raw_data) if raw_data else 0
        return jsonify({
            "connection_status": "SUCCESS",
            "message": "Flask successfully authenticated and communicated with Supabase!",
            "table_queried": "driver_profile",
            "total_rows_found": row_count,
            "sample_data_payload": raw_data[:100]
        }), 200
    except Exception as e:
        print(f"❌ Diagnostic database connection failed: {e}")
        return jsonify({"connection_status": "FAILED", "error_details": str(e)}), 500

@admin_bp.route('/api/trips', methods=['GET'])
def get_admin_schedules():
    """
    Dedicated Schedule Pipeline:
    Fetches all live rows inside trip_schedule sorted chronologically.
    """
    try:
        trips_res = supabase.table('trip_schedule').select('*').order('schedule_date', desc=False).execute()
        print(f"📊 [Admin Pipeline] Dispatched {len(trips_res.data or [])} trip records to dashboard.")
        return jsonify({
            "success": True, 
            "trips": trips_res.data or []
        }), 200
    except Exception as e:
        print(f"❌ Admin Schedule Fetch Exception: {e}")
        return jsonify({
            "success": False, 
            "error": "Failed to sync system schedule streams."
        }), 500