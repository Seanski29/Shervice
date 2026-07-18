from flask import Blueprint, request, jsonify

schedules_bp = Blueprint('schedules', __name__)
supabase = None  # Injected in app.py


def _create_notification(payload):
    try:
        supabase.table('app_notification').insert(payload).execute()
    except Exception as e:
        print(f"❌ Notification Create Error: {e}")


@schedules_bp.route('/api/schedules/request', methods=['POST'])
def create_trip_request():
    """OIC submits a new trip request"""
    try:
        data = request.get_json() or {}
        
        # ─── SAFE CONVERSIONS ───
        try:
            p_count = int(data.get('passenger_count', 0))
        except (ValueError, TypeError):
            p_count = 0 
            
        try:
            r_distance = float(data.get('route_distance', 0.0)) 
        except (ValueError, TypeError):
            r_distance = 0.0

        oic_uuid = data.get('oic_id')
        
        # 1. Lookup the integer ID and company name from the oic_profile table
        # 🛡️ THE PGRST116 FIX: Removed .single() to handle duplicate user_ids safely
        oic_lookup = (
            supabase.table('oic_profile')
            .select('oic_id, company_name')
            .eq('user_id', oic_uuid)
            .execute()
        )
        
        if not oic_lookup.data:
            return jsonify({"success": False, "message": "OIC Profile not found."}), 404
            
        # Safely grab the first integer ID from the list
        oic_int_id = oic_lookup.data[0].get('oic_id')
        company_name = oic_lookup.data[0].get('company_name')
        final_route = data.get('destination', 'Unspecified Route')
        final_date = data.get('departure_date')

        # 2. Insert using the correct integer ID
        response = (
            supabase.table('trip_schedule')
            .insert({
                "oic_id": oic_int_id, 
                "staff_id": data.get('staff_id'),
                "route_name": final_route,
                "route_distance": r_distance, 
                "passenger_count": p_count, 
                "schedule_date": final_date, 
                "departure_time": data.get('departure_time'),
                "estimated_arrival_time": data.get('estimated_arrival_time'), 
                "trip_status": "Pending Staff Assignment" 
            })
            .execute()
        )

        if response.data and len(response.data) > 0:
            trip_id = response.data[0].get('trip_id')
            notification_payload = {
                "title": "New trip request",
                "message": f"{final_route} requested for {final_date}",
                "target_role": "staff",
                "related_trip_id": trip_id,
            }
            if company_name:
                notification_payload["target_company"] = company_name
            _create_notification(notification_payload)

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


@schedules_bp.route('/api/schedules/oic/<string:oic_uuid>', methods=['GET'])
def get_oic_trips(oic_uuid):
    """Fetches all trips requested by ANY OIC within the same company"""
    try:
        # 1. Find out which company this specific OIC belongs to
        # 🛡️ THE PGRST116 FIX: Removed .single() here as well
        user_profile = (
            supabase.table('oic_profile')
            .select('company_name')
            .eq('user_id', oic_uuid)
            .execute()
        )
        
        if not user_profile.data:
            return jsonify({"success": True, "data": []}), 200
            
        company_name = user_profile.data[0].get('company_name')

        # 2. Find ALL OIC integer IDs that belong to this same company
        company_colleagues = (
            supabase.table('oic_profile')
            .select('oic_id')
            .eq('company_name', company_name)
            .execute()
        )
        
        # Create a list of allowed integer IDs (e.g., [1, 4, 7])
        allowed_oic_ids = [colleague['oic_id'] for colleague in company_colleagues.data]

        # 3. Fetch all trips where the requested oic_id is in our allowed list
        trips = (
            supabase.table('trip_schedule')
            .select('*')
            .in_('oic_id', allowed_oic_ids)
            .order('schedule_date', desc=True)
            .execute()
        )
        
        # 4. Fetch reference data to match IDs to names
        vehicles = supabase.table('vehicle').select('vehicle_id, plate_number').execute()
        drivers = supabase.table('driver_profile').select('user_id, full_name').execute()

        v_map = {v['vehicle_id']: v['plate_number'] for v in vehicles.data}
        d_map = {d['user_id']: d['full_name'] for d in drivers.data}

        # 5. Attach the names to the trips
        formatted_trips = []
        for t in trips.data:
            t['plate_number'] = v_map.get(t.get('vehicle_id'), 'No Plate Assigned')
            t['driver_name'] = d_map.get(t.get('user_id'), 'Unassigned')
            formatted_trips.append(t)

        return jsonify({"success": True, "data": formatted_trips}), 200
        
    except Exception as e:
        print(f"❌ OIC Company Fetch Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
    
@schedules_bp.route('/api/schedules/pending', methods=['GET'])
def get_pending_schedules():
    """Staff views all requests waiting for driver/vehicle allocation"""
    try:
        query = (
            supabase.table('trip_schedule')
            .select('*')
            .eq('trip_status', 'Pending Staff Assignment') # Cleaned up to match your DB schema strictly
            .execute()
        )
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@schedules_bp.route('/api/schedules/dispatch-options', methods=['GET'])
def get_dispatch_options():
    """Fetches drivers and vehicles. If 'date' is provided, filters out busy assets."""
    try:
        all_vehicles = supabase.table('vehicle').select('vehicle_id, plate_number, bus_type').eq('health_status', 'Excellent').execute()
        all_drivers = supabase.table('driver_profile').select('user_id, full_name').execute()

        target_date = request.args.get('date')
        ignore_trip_id = request.args.get('ignore_trip_id') # NEW: Ignore the trip we are currently editing
        
        if not target_date:
            return jsonify({"success": True, "vehicles": all_vehicles.data, "drivers": all_drivers.data}), 200

        # Find busy assets
        busy_query = supabase.table('trip_schedule').select('vehicle_id, user_id, trip_id').eq('schedule_date', target_date).in_('trip_status', ['Scheduled', 'In Progress', 'Ongoing'])
        
        # If we are editing a trip, don't count its currently assigned driver/vehicle as "busy"
        if ignore_trip_id:
            busy_query = busy_query.neq('trip_id', ignore_trip_id)
            
        busy_data = busy_query.execute()
            
        busy_vehicle_ids = [t['vehicle_id'] for t in busy_data.data if t.get('vehicle_id')]
        busy_driver_uuids = [t['user_id'] for t in busy_data.data if t.get('user_id')]

        available_vehicles = [v for v in all_vehicles.data if v['vehicle_id'] not in busy_vehicle_ids]
        available_drivers = [d for d in all_drivers.data if d['user_id'] not in busy_driver_uuids]

        return jsonify({"success": True, "vehicles": available_vehicles, "drivers": available_drivers}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@schedules_bp.route('/api/schedules/staff-edit', methods=['PUT'])
def staff_edit_trip():
    """Staff edits a trip, including route details and asset assignments"""
    try:
        data = request.get_json() or {}
        trip_id = data.get('trip_id')

        update_data = {
            "route_name": data.get('destination'),
            "passenger_count": int(data.get('passenger_count', 0)),
            "route_distance": float(data.get('route_distance', 0.0)),
            "schedule_date": data.get('departure_date'),
            "departure_time": data.get('departure_time'),
            "estimated_arrival_time": data.get('estimated_arrival_time')
        }

        # If staff assigned a driver/vehicle during the edit
        driver_uuid = data.get('driver_uuid')
        vehicle_id = data.get('vehicle_id')
        
        if driver_uuid and vehicle_id:
            update_data['user_id'] = driver_uuid
            update_data['vehicle_id'] = vehicle_id
            
            # Automatically upgrade status if it was pending
            check = supabase.table('trip_schedule').select('trip_status').eq('trip_id', trip_id).execute()
            if check.data and check.data[0].get('trip_status') == 'Pending Staff Assignment':
                update_data['trip_status'] = 'Scheduled'

        supabase.table('trip_schedule').update(update_data).eq('trip_id', trip_id).execute()

        return jsonify({"success": True, "message": "Trip updated successfully."}), 200
    except Exception as e:
        print(f"❌ Staff Edit Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


@schedules_bp.route('/api/schedules/assign', methods=['POST'])
def assign_trip_assets():
    """Staff binds a driver and vehicle to the OIC's trip request"""
    try:
        data = request.get_json() or {}
        trip_id = data.get('trip_id')
        driver_uuid = data.get('driver_uuid')
        
        response = (
            supabase.table('trip_schedule')
            .update({
                "user_id": driver_uuid,  
                "vehicle_id": data.get('vehicle_id'), 
                "trip_status": "Scheduled"
            })
            .eq('trip_id', trip_id)
            .execute()
        )

        # Send a notification to the assigned OIC and optionally the assigned driver
        trip_info = (
            supabase.table('trip_schedule')
            .select('route_name, schedule_date, oic_id')
            .eq('trip_id', trip_id)
            .execute()
        )

        if trip_info.data:
            route_name = trip_info.data[0].get('route_name')
            schedule_date = trip_info.data[0].get('schedule_date')
            oic_id = trip_info.data[0].get('oic_id')

            oic_profile = (
                supabase.table('oic_profile')
                .select('user_id, company_name')
                .eq('oic_id', oic_id)
                .execute()
            )

            company_name = None
            if oic_profile.data:
                oic_user_id = oic_profile.data[0].get('user_id')
                company_name = oic_profile.data[0].get('company_name')
                _create_notification({
                    "title": "Trip assigned",
                    "message": f"{route_name} is scheduled for {schedule_date}",
                    "target_user_id": oic_user_id,
                    "target_role": "oic",
                    "target_company": company_name,
                    "related_trip_id": trip_id,
                })

            if driver_uuid:
                _create_notification({
                    "title": "You were assigned a trip",
                    "message": f"{route_name} is scheduled for {schedule_date}",
                    "target_user_id": driver_uuid,
                    "target_role": "driver",
                    "target_company": company_name,
                    "related_trip_id": trip_id,
                })

        return jsonify({"success": True, "message": "Trip successfully dispatched!"}), 200
    except Exception as e:
        print(f"❌ Dispatch Error: {e}")
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
    
@schedules_bp.route('/api/schedules/staff/<string:staff_uuid>', methods=['GET'])
def get_staff_assigned_trips(staff_uuid):
    """Fetches all trips handled specifically by this Staff member"""
    try:
        # 1. Fetch only trips where this staff member is assigned
        trips = (
            supabase.table('trip_schedule')
            .select('*')
            .eq('staff_id', staff_uuid)
            .order('schedule_date', desc=True)
            .execute()
        )
        
        # 2. Fetch reference data to attach names
        vehicles = supabase.table('vehicle').select('vehicle_id, plate_number').execute()
        drivers = supabase.table('driver_profile').select('user_id, full_name').execute()
        oics = supabase.table('oic_profile').select('oic_id, company_name').execute()

        v_map = {v['vehicle_id']: v['plate_number'] for v in vehicles.data}
        d_map = {d['user_id']: d['full_name'] for d in drivers.data}
        o_map = {o['oic_id']: o['company_name'] for o in oics.data}

        # 3. Attach the readable data to the trips
        formatted_trips = []
        for t in trips.data:
            t['plate_number'] = v_map.get(t.get('vehicle_id'), 'Pending Assignment')
            t['driver_name'] = d_map.get(t.get('user_id'), 'Pending Assignment')
            t['client_company'] = o_map.get(t.get('oic_id'), 'Unknown Client')
            formatted_trips.append(t)

        return jsonify({"success": True, "data": formatted_trips}), 200
    except Exception as e:
        print(f"❌ Staff Fetch Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500

@schedules_bp.route('/api/schedules/reject', methods=['POST'])
def reject_trip_request():
    """Staff rejects a pending trip request"""
    try:
        data = request.get_json() or {}
        trip_id = data.get('trip_id')

        # 1. Update status to Rejected
        response = (
            supabase.table('trip_schedule')
            .update({"trip_status": "Rejected"})
            .eq('trip_id', trip_id)
            .execute()
        )

        # 2. Trigger Notification to the OIC
        trip_info = supabase.table('trip_schedule').select('route_name, oic_id').eq('trip_id', trip_id).execute()
        if trip_info.data:
            route_name = trip_info.data[0].get('route_name')
            oic_id = trip_info.data[0].get('oic_id')
            
            oic_profile = supabase.table('oic_profile').select('user_id, company_name').eq('oic_id', oic_id).execute()
            if oic_profile.data:
                _create_notification({
                    "title": "Trip Request Rejected",
                    "message": f"Your request for {route_name} was rejected by staff.",
                    "target_user_id": oic_profile.data[0].get('user_id'),
                    "target_role": "oic",
                    "target_company": oic_profile.data[0].get('company_name'),
                    "related_trip_id": trip_id
                })

        return jsonify({"success": True, "message": "Trip request rejected."}), 200
    except Exception as e:
        print(f"❌ Trip Reject Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


@schedules_bp.route('/api/schedules/edit', methods=['PUT'])
def edit_trip_request():
    """OIC edits an existing pending or rejected trip"""
    try:
        data = request.get_json() or {}
        trip_id = data.get('trip_id')

        # 1. Verify trip is still editable (Pending or Rejected)
        check = supabase.table('trip_schedule').select('trip_status, staff_id').eq('trip_id', trip_id).execute()
        if not check.data:
            return jsonify({"success": False, "message": "Trip not found."}), 404
        
        current_status = check.data[0].get('trip_status')
        if current_status not in ['Pending Staff Assignment', 'Rejected']:
            return jsonify({"success": False, "message": "Cannot edit a trip that has already been scheduled or completed."}), 400

        # 2. Update the record (Reset to Pending, wipe previous assignments)
        update_data = {
            "route_name": data.get('destination'),
            "passenger_count": int(data.get('passenger_count', 0)),
            "route_distance": float(data.get('route_distance', 0.0)),
            "schedule_date": data.get('departure_date'),
            "departure_time": data.get('departure_time'),
            "estimated_arrival_time": data.get('estimated_arrival_time'),
            "trip_status": "Pending Staff Assignment", # Force re-approval
            "user_id": None,    # Clear driver
            "vehicle_id": None  # Clear vehicle
        }

        supabase.table('trip_schedule').update(update_data).eq('trip_id', trip_id).execute()

        # 3. Trigger Notification to the Assigned Staff
        staff_id = check.data[0].get('staff_id')
        if staff_id:
            _create_notification({
                "title": "Trip Request Updated & Requires Re-approval",
                "message": f"An OIC updated {update_data['route_name']}. Please review and assign assets.",
                "target_user_id": staff_id,
                "target_role": "staff",
                "related_trip_id": trip_id
            })

        return jsonify({"success": True, "message": "Trip updated and sent for re-approval."}), 200
    except Exception as e:
        print(f"❌ Trip Edit Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500