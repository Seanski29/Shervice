from flask import Blueprint, request, jsonify

schedules_bp = Blueprint('schedules', __name__)
supabase = None  # Injected in app.py

@schedules_bp.route('/api/schedules/request', methods=['POST'])
def create_trip_request():
    """OIC submits a new trip request"""
    try:
        data = request.get_json() or {}
        
        # ─── BULLETPROOF INTEGER CONVERSION ───
        try:
            p_count = int(data.get('passenger_count', 0))
        except (ValueError, TypeError):
            p_count = 0 # Fallback to 0 if they send letters like "adsdasda"
        
        response = supabase.table('trip_schedule').insert({
            "oic_id": data.get('oic_id'), 
            "staff_id": data.get('staff_id'),
            "route_name": data.get('destination', 'Unspecified Route'),
            "route_distance": 0.0, 
            "passenger_count": p_count, # 👈 Use our safe variable here
            "schedule_date": data.get('departure_date'), 
            "departure_time": data.get('departure_time'),
            "estimated_arrival_time": data.get('departure_time'), 
            "trip_status": "Pending Staff Assignment" 
        }).execute()

        return jsonify({"success": True, "message": "Trip request submitted to staff!"}), 201
    except Exception as e:
        print(f"❌ Trip Request Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
@schedules_bp.route('/api/schedules/staff-options', methods=['GET'])
def get_staff_options():
    """Fetches list of Dispatch Staff for the OIC dropdown"""
    try:
        query = supabase.table('user_account').select('user_id, full_name').eq('role', 'staff').execute()
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@schedules_bp.route('/api/schedules/oic/<int:oic_id>', methods=['GET'])
def get_oic_trips(oic_id):
    """Fetches all trips requested by this specific OIC to display on their dashboard"""
    try:
        query = supabase.table('trip_schedule').select('*').eq('oic_id', oic_id).order('trip_id', desc=True).execute()
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
    
@schedules_bp.route('/api/schedules/pending', methods=['GET'])
def get_pending_schedules():
    """Staff views all requests waiting for driver/vehicle allocation"""
    try:
        # Fetch trips that are waiting for staff assignment
        query = supabase.table('trip_schedule')\
            .select('*')\
            .eq('trip_status', 'Pending Assignment')\
            .execute()
            
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@schedules_bp.route('/api/schedules/dispatch-options', methods=['GET'])
def get_dispatch_options():
    """Fetches drivers and vehicles available specifically for the requested date"""
    try:
        # 1. Grab the date we are checking from the request URL
        target_date = request.args.get('date')
        
        if not target_date:
            return jsonify({"success": False, "message": "Date is required to check availability."}), 400

        # 2. Find vehicles and drivers already scheduled for this specific date
        busy_query = supabase.table('trip_schedule')\
            .select('vehicle_id, user_id')\
            .eq('schedule_date', target_date)\
            .in_('trip_status', ['Scheduled', 'In Progress'])\
            .execute()
            
        # Extract their IDs into lists
        busy_vehicle_ids = [t['vehicle_id'] for t in busy_query.data if t.get('vehicle_id')]
        busy_driver_uuids = [t['user_id'] for t in busy_query.data if t.get('user_id')]

        # 3. Fetch ALL active assets
        all_vehicles = supabase.table('vehicle').select('vehicle_id, plate_number, bus_type').eq('health_status', 'Excellent').execute()
        all_drivers = supabase.table('driver_profile').select('user_id, full_name').execute()

        # 4. Filter out the busy ones in Python
        available_vehicles = [v for v in all_vehicles.data if v['vehicle_id'] not in busy_vehicle_ids]
        available_drivers = [d for d in all_drivers.data if d['user_id'] not in busy_driver_uuids]

        return jsonify({
            "success": True,
            "vehicles": available_vehicles,
            "drivers": available_drivers
        }), 200
    except Exception as e:
        print(f"❌ Dispatch Options Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500

@schedules_bp.route('/api/schedules/assign', methods=['POST'])
def assign_trip_assets():
    """Staff binds a driver and vehicle to the OIC's trip request"""
    try:
        data = request.get_json() or {}
        trip_id = data.get('trip_id')
        
        # Update the existing record with the Driver (user_id) and Vehicle
        response = supabase.table('trip_schedule').update({
            "user_id": data.get('driver_uuid'),  # The UUID from driver_profile
            "vehicle_id": data.get('vehicle_id'), # The Int ID from vehicle table
            "trip_status": "Scheduled"
        }).eq('trip_id', trip_id).execute()

        return jsonify({"success": True, "message": "Trip successfully dispatched!"}), 200
    except Exception as e:
        print(f"❌ Dispatch Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
    
@schedules_bp.route('/api/schedules/staff/<string:staff_id>', methods=['GET'])
def get_staff_assigned_trips(staff_id):
    """Fetches all trips routed specifically to this Staff member"""
    try:
        query = supabase.table('trip_schedule')\
            .select('*')\
            .eq('staff_id', staff_id)\
            .order('trip_id', desc=True)\
            .execute()
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500