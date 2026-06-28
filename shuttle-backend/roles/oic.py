from typing import Any, Dict, cast
from flask import Blueprint, jsonify, request

oic_bp = Blueprint('oic', __name__)

# Dynamically assigned by app.py upon initialization
supabase = None

@oic_bp.route('/api/trips', methods=['GET', 'POST'])
def handle_trips_pipeline():
    if request.method == 'GET':
        try:
            # Explicitly select the driver relation via foreign key constraint referencing user_id
            trips_res = supabase.table('trip_schedule').select(
                '*, driver_profile:user_id(full_name)'
            ).order('schedule_date', desc=False).execute()
            
            raw_trips = trips_res.data or []
            formatted_trips = _format_trip_data(raw_trips)

            # Return both root dictionary mapping structures to satisfy both frontend layout files simultaneously
            return jsonify({
                "success": True, 
                "trips": formatted_trips, 
                "data": formatted_trips
            }), 200
        except Exception as e:
            print(f"❌ Backend Trip Retrieval Error: {e}")
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

@oic_bp.route('/api/schedules/oic/<oic_id>', methods=['GET'])
def get_trips_by_oic(oic_id):
    try:
        # Step 1: Resolve the text UUID to the OIC's integer primary key
        # We query the 'oic_profile' table where the account ID matches the incoming UUID
        oic_profile_res = supabase.table('oic_profile')\
            .select('oic_id')\
            .eq('user_id', oic_id)\
            .maybe_single()\
            .execute()
            
        oic_profile_data = oic_profile_res.data
        
        if not oic_profile_data:
            print(f"⚠️ No OIC Profile row found for user UUID: {oic_id}")
            return jsonify({"success": True, "trips": [], "data": []}), 200
            
        # Extract the true integer identifier (e.g., 1, 2, 3...)
        resolved_int_id = oic_profile_data.get('oic_id')

        # Step 2: Query trip schedules using the resolved integer identifier
        trips_res = supabase.table('trip_schedule').select(
            '*, driver_profile:user_id(full_name)'
        ).eq('oic_id', resolved_int_id).order('schedule_date', desc=False).execute()
        
        raw_trips = trips_res.data or []
        formatted_trips = _format_trip_data(raw_trips)

        return jsonify({
            "success": True, 
            "trips": formatted_trips, 
            "data": formatted_trips
        }), 200
        
    except Exception as e:
        print(f"❌ OIC Filtered Fetch Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500


def _format_trip_data(raw_trips: list) -> list:
    """Helper method to format raw database rows into unified payload profiles."""
    formatted_trips = []
    
    for trip in raw_trips:
        # 1. SAFELY RESOLVE THE DRIVER FULL NAME WITH FALLBACKS
        driver_info = trip.get('driver_profile')
        if isinstance(driver_info, list) and len(driver_info) > 0:
            driver_name = driver_info[0].get('full_name', 'Driver Assigned')
        elif isinstance(driver_info, dict):
            driver_name = driver_info.get('full_name', 'Driver Assigned')
        else:
            raw_uid = trip.get('user_id')
            driver_name = f"ID: {raw_uid[:4]}..." if raw_uid else "Unassigned"

        # 2. SAFELY RESOLVE THE DEPARTURE TIME FORMATTING
        raw_time = trip.get('departure_time') or trip.get('time')
        display_time = str(raw_time)[:5] if raw_time else "--:--"

        # Build a robust response map structure containing all key combinations required by frontend views
        formatted_trips.append({
            'trip_id': trip.get('trip_id'),
            'id': trip.get('trip_id'),
            'status': trip.get('trip_status') or trip.get('status', 'Scheduled'),
            'trip_status': trip.get('trip_status') or trip.get('status', 'Scheduled'),
            
            # Time properties mapping variations
            'departure_time': display_time, 
            'schedule_time': display_time,  
            'time': display_time,
            
            # Driver identity properties mapping variations
            'driver_name': driver_name,
            'driver': driver_name,
            
            'route_name': trip.get('route_name') or trip.get('route', 'Route Unassigned'),
            'plate_number': trip.get('plate_number', 'No Plate Assigned'),
            'schedule_date': str(trip.get('schedule_date')),
            'passenger_count': trip.get('passenger_count', 0),
            'route_distance': trip.get('route_distance', 0.0),
            'vehicle_id': trip.get('vehicle_id'),
        })
        
    return formatted_trips