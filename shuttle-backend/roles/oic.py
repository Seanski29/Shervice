from typing import Any, Dict, cast
from flask import Blueprint, jsonify, request

oic_bp = Blueprint('oic', __name__)

# Dynamically assigned by app.py upon initialization
supabase = None

@oic_bp.route('/api/trips', methods=['GET', 'POST'])
def handle_trips_pipeline():
    if request.method == 'GET':
        try:
            trips_res = supabase.table('trip_schedule').select('*').order('schedule_date', desc=False).execute()
            return jsonify({"success": True, "trips": trips_res.data or []}), 200
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 500

    elif request.method == 'POST':
        try:
            body = cast(Dict[str, Any], request.get_json() or {})
            new_trip = {
                "schedule_date": body.get("schedule_date"),
                "departure_time": body.get("departure_time"),
                "route_name": body.get("route_name"),
                "trip_status": body.get("trip_status", "Scheduled"),
                "user_id": body.get("user_id"), 
                "vehicle_id": body.get("vehicle_id"), 
                "oic_id": body.get("oic_id"),
                "passenger_count": body.get("passenger_count", 0),
                "estimated_arrival_time": body.get("estimated_arrival_time"),
                "route_distance": body.get("route_distance", 0.0)
            }
            insert_res = supabase.table('trip_schedule').insert(new_trip).execute()
            return jsonify({"success": True, "inserted": insert_res.data}), 201
        except Exception as e:
            print(f"❌ Backend Trip Injection Error: {e}")
            return jsonify({"success": False, "error": str(e)}), 500
    return jsonify({"success": False, "message": "Method request disallowed."}), 405