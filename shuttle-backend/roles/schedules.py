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
        
        # Wrapped in () to prevent IndentationErrors
        response = (
            supabase.table('trip_schedule')
            .insert({
                "oic_id": data.get('oic_id'), 
                "staff_id": data.get('staff_id'),
                "route_name": data.get('destination', 'Unspecified Route'),
                "route_distance": 0.0, 
                "passenger_count": p_count,
                "schedule_date": data.get('departure_date'), 
                "departure_time": data.get('departure_time'),
                "estimated_arrival_time": data.get('departure_time'), 
                "trip_status": "Pending Staff Assignment" 
            })
            .execute()
        )

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


@schedules_bp.route('/api/schedules/oic/<string:oic_id>', methods=['GET'])
def get_oic_trips(oic_id):
    """Fetches all trips requested by this specific OIC, with names attached"""
    try:
        # 1. Fetch ONLY the trips belonging to this OIC
        trips = (
            supabase.table('trip_schedule')
            .select('*')
            .eq('oic_id', oic_id)
            .order('schedule_date', desc=True)
            .execute()
        )
        
        # 2. Fetch reference data to match IDs to names
        vehicles = supabase.table('vehicle').select('vehicle_id, plate_number').execute()
        drivers = supabase.table('driver_profile').select('user_id, full_name').execute()

        v_map = {v['vehicle_id']: v['plate_number'] for v in vehicles.data}
        d_map = {d['user_id']: d['full_name'] for d in drivers.data}

        # 3. Attach the names to the trips
        formatted_trips = []
        for t in trips.data:
            t['plate_number'] = v_map.get(t.get('vehicle_id'), 'No Plate Assigned')
            t['driver_name'] = d_map.get(t.get('user_id'), 'Unassigned')
            formatted_trips.append(t)

        return jsonify({"success": True, "data": formatted_trips}), 200
    except Exception as e:
        print(f"❌ OIC Fetch Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500

@schedules_bp.route('/api/schedules/pending', methods=['GET'])
def get_pending_schedules():
    """Staff views all requests waiting for driver/vehicle allocation"""
    try:
        query = (
            supabase.table('trip_schedule')
            .select('*')
            .eq('trip_status', 'Pending Assignment')
            .execute()
        )
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@schedules_bp.route('/api/schedules/dispatch-options', methods=['GET'])
def get_dispatch_options():
    """Fetches drivers and vehicles. If 'date' is provided, filters out busy assets."""
    try:
        # 1. Fetch ALL active assets first
        all_vehicles = supabase.table('vehicle').select('vehicle_id, plate_number, bus_type').eq('health_status', 'Excellent').execute()
        all_drivers = supabase.table('driver_profile').select('user_id, full_name').execute()

        # 2. Grab the date we are checking from the request URL
        target_date = request.args.get('date')
        
        # If no date is provided, just return the full lists (Fixes the 400 error!)
        if not target_date:
            return jsonify({
                "success": True,
                "vehicles": all_vehicles.data,
                "drivers": all_drivers.data
            }), 200

        # 3. Find vehicles and drivers already scheduled for this specific date
        busy_query = (
            supabase.table('trip_schedule')
            .select('vehicle_id, user_id')
            .eq('schedule_date', target_date)
            .in_('trip_status', ['Scheduled', 'In Progress', 'Ongoing'])
            .execute()
        )
            
        busy_vehicle_ids = [t['vehicle_id'] for t in busy_query.data if t.get('vehicle_id')]
        busy_driver_uuids = [t['user_id'] for t in busy_query.data if t.get('user_id')]

        # 4. Filter out the busy ones
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
        
        response = (
            supabase.table('trip_schedule')
            .update({
                "user_id": data.get('driver_uuid'),  
                "vehicle_id": data.get('vehicle_id'), 
                "trip_status": "Scheduled"
            })
            .eq('trip_id', trip_id)
            .execute()
        )

        return jsonify({"success": True, "message": "Trip successfully dispatched!"}), 200
    except Exception as e:
        print(f"❌ Dispatch Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
    

@schedules_bp.route('/api/schedules/staff/<string:staff_id>', methods=['GET'])
def get_staff_assigned_trips(staff_id):
    """Fetches all trips routed specifically to this Staff member"""
    try:
        query = (
            supabase.table('trip_schedule')
            .select('*')
            .eq('staff_id', staff_id)
            .order('trip_id', desc=True)
            .execute()
        )
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
    

@schedules_bp.route('/api/schedules/complete', methods=['POST'])
def complete_trip():
    """Driver marks their trip as finished"""
    try:
        data = request.get_json() or {}
        trip_id = data.get('trip_id')
        
        response = (
            supabase.table('trip_schedule')
            .update({"trip_status": "Completed"})
            .eq('trip_id', trip_id)
            .execute()
        )

        return jsonify({"success": True, "message": "Trip marked as finished!"}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
    

@schedules_bp.route('/api/schedules/driver/<string:driver_uuid>', methods=['GET'])
def get_driver_trips(driver_uuid):
    """Fetches all trips assigned to a specific driver"""
    try:
        query = (
            supabase.table('trip_schedule')
            .select('*')
            .eq('user_id', driver_uuid)
            .order('schedule_date', desc=True)
            .execute()
        )
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500
    
@schedules_bp.route('/api/schedules/update-status', methods=['POST'])
def update_trip_status():
    """Updates a trip to any status (Ongoing, Completed, etc.)"""
    try:
        data = request.get_json() or {}
        trip_id = data.get('trip_id')
        new_status = data.get('status')
        
        response = (
            supabase.table('trip_schedule')
            .update({"trip_status": new_status})
            .eq('trip_id', trip_id)
            .execute()
        )

        return jsonify({"success": True, "message": f"Trip updated to {new_status}"}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@schedules_bp.route('/api/schedules/all', methods=['GET'])
def get_all_trips():
    """Fetches all historical and active trips for the OIC Deployment Log"""
    try:
        # 1. Fetch the raw trips
        trips = (
            supabase.table('trip_schedule')
            .select('*')
            .order('schedule_date', desc=True)
            .execute()
        )
        
        # 2. Fetch reference data to match IDs to names
        vehicles = supabase.table('vehicle').select('vehicle_id, plate_number').execute()
        drivers = supabase.table('driver_profile').select('user_id, full_name').execute()

        # Create quick lookup dictionaries
        v_map = {v['vehicle_id']: v['plate_number'] for v in vehicles.data}
        d_map = {d['user_id']: d['full_name'] for d in drivers.data}

        # 3. Attach the names to the trips
        formatted_trips = []
        for t in trips.data:
            t['plate_number'] = v_map.get(t.get('vehicle_id'), 'No Plate Assigned')
            t['driver_name'] = d_map.get(t.get('user_id'), 'Unassigned')
            formatted_trips.append(t)

        # 4. Send back as 'data'
        return jsonify({"success": True, "data": formatted_trips}), 200
    except Exception as e:
        print(f"❌ Fetch All Trips Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500