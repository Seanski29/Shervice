from flask import Blueprint, jsonify, request

# Update the blueprint variable or name string to plural if desired
drivers_bp = Blueprint('drivers', __name__)
supabase = None

# Update your route decorators below to use the new variable name:
@drivers_bp.route('/api/driver/active-trip/<driver_name>', methods=['GET'])
def get_driver_active_trip(driver_name):
    try:
        # 1. Resolve driver_name to locate the driver's user_id reference row
        driver_res = supabase.table('driver_profile')\
            .select('user_id')\
            .ilike('full_name', driver_name)\
            .maybe_single()\
            .execute()
            
        driver_data = driver_res.data
        if not driver_data:
            return jsonify({"success": True, "active_trip": None}), 200
            
        user_uuid = driver_data.get('user_id')

        # 2. Query the trip schedule table for the active/ongoing trip assigned to this user_id
        # We also join the vehicle details relationship map
        trip_res = supabase.table('trip_schedule').select(
            '*, vehicle(*)'
        ).eq('user_id', user_uuid)\
         .in_('trip_status', ['Ongoing', 'Scheduled'])\
         .order('schedule_date', desc=False)\
         .limit(1)\
         .maybe_single()\
         .execute()
         
        trip = trip_res.data
        if not trip:
            return jsonify({"success": True, "active_trip": None}), 200

        # Safely capture joined vehicle profile specs
        vehicle_info = trip.get('vehicle') or {}
        
        # Format metrics cleanly for Flutter consumption
        formatted_trip = {
            'trip_id': trip.get('trip_id'),
            'status': trip.get('trip_status', 'Scheduled').upper(),
            'route_name': trip.get('route_name', 'Route Unassigned'),
            'departure_time': str(trip.get('departure_time'))[:5] if trip.get('departure_time') else '--:--',
            'estimated_arrival_time': str(trip.get('estimated_arrival_time'))[:5] if trip.get('estimated_arrival_time') else '--:--',
            'passenger_count': trip.get('passenger_count', 0),
            'route_distance': trip.get('route_distance', 0.0),
            # Vehicle Mappings
            'plate_number': vehicle_info.get('plate_number', 'No Plate Assigned'),
            'model': vehicle_info.get('model', 'Unknown Vehicle model')
        }

        return jsonify({"success": True, "active_trip": formatted_trip}), 200
        
    except Exception as e:
        print(f"❌ Driver Active Trip Sync Exception: {e}")
        return jsonify({"success": False, "error": str(e)}), 500