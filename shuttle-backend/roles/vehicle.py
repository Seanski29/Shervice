import os
from flask import Blueprint, request, jsonify

# Create the Blueprint for vehicle routes
vehicles_bp = Blueprint('vehicles', __name__)

# This will be assigned dynamically in app.py
supabase = None 

@vehicles_bp.route('/api/vehicles', methods=['GET', 'POST'])
def handle_vehicles():
    """Handles fetching all vehicles (GET) and registering a new vehicle (POST)"""
    try:
        # ─── REGISTER NEW VEHICLE (POST) ───
        if request.method == 'POST':
            data = request.get_json() or {}
            
            # Helper to strip spaces and convert empty inputs to clean database nulls
            def clean_field(val):
                if val is None:
                    return None
                cleaned = str(val).strip()
                return cleaned if cleaned != "" and cleaned.lower() != "n/a" else None

            # Helper to safely parse numbers without crashing the operational cycle
            def to_int(val):
                cleaned = clean_field(val)
                if not cleaned:
                    return None
                try:
                    return int(cleaned)
                except ValueError:
                    return None

            # Enforce sanitation rules across the dataset model boundary
            new_vehicle = {
                "plate_number": clean_field(data.get('plate_number')),
                "bus_type": clean_field(data.get('bus_type')) or 'Standard Shuttle',
                "model_year": to_int(data.get('model_year')),  # Safely converted to Int for numeric constraints
                "engine_no": clean_field(data.get('engine_no')),
                "insurance_policy_no": clean_field(data.get('insurance_policy_no')),
                "insurance_expiry": clean_field(data.get('insurance_expiry')),  # Expects strict YYYY-MM-DD
                "franchise_no": clean_field(data.get('franchise_no')),
                "franchise_expiry": clean_field(data.get('franchise_expiry')),
                "cr_no": clean_field(data.get('cr_no')),
                "cr_date": clean_field(data.get('cr_date')),
                "or_no": clean_field(data.get('or_no')),
                "or_expiry": clean_field(data.get('or_expiry')),
                "health_status": "Excellent",
                "is_available": True,
                "last_maintenance_description": "No recent service entries registered."
            }

            # Enforce validation on identity matrix parameters
            if not new_vehicle["plate_number"]:
                return jsonify({"success": False, "message": "Plate number parameter is required."}), 400

            # Insert clean record directly into your Supabase data table layout context
            query = supabase.table('vehicle').insert(new_vehicle).execute()
            
            return jsonify({
                "success": True, 
                "message": "Vehicle registered securely in the fleet vault!", 
                "data": query.data
            }), 201

        # ─── FETCH ALL VEHICLES (GET) ───
        query = supabase.table('vehicle').select('*').order('plate_number').execute()
        return jsonify({"success": True, "data": query.data}), 200

    except Exception as e:
        print(f"❌ Vehicles Endpoint Exception Payload Error Context: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


@vehicles_bp.route('/api/vehicles/<string:vehicle_identifier>', methods=['DELETE'])
def delete_vehicle(vehicle_identifier):
    """Deletes a fleet unit from the asset database supporting both integer IDs or Plate strings"""
    try:
        print(f"🔄 Starting cascading teardown sequence for identifier: {vehicle_identifier}")

        # Check if the identifier sent is a numeric ID or a raw plate number string
        is_numeric = vehicle_identifier.isdigit()
        
        # 1. Clear linked maintenance log history tracking entries
        try:
            if is_numeric:
                supabase.table('maintenance_log').delete().eq('vehicle_id', int(vehicle_identifier)).execute()
            else:
                vehicle_data = supabase.table('vehicle').select('vehicle_id').eq('plate_number', vehicle_identifier).execute()
                if vehicle_data.data:
                    v_id = vehicle_data.data[0]['vehicle_id']
                    supabase.table('maintenance_log').delete().eq('vehicle_id', v_id).execute()
            print("✅ Dependent maintenance logs cleared successfully.")
        except Exception as log_err:
            print(f"⚠️ Maintenance log cleanup warning: {log_err}")
        
        # 2. Unlink vehicle references from schedule tracking structures
        for table_name in ['schedules', 'schedule']:
            try:
                if is_numeric:
                    supabase.table(table_name).update({"vehicle_id": None}).eq('vehicle_id', int(vehicle_identifier)).execute()
                else:
                    vehicle_data = supabase.table('vehicle').select('vehicle_id').eq('plate_number', vehicle_identifier).execute()
                    if vehicle_data.data:
                        v_id = vehicle_data.data[0]['vehicle_id']
                        supabase.table(table_name).update({"vehicle_id": None}).eq('vehicle_id', v_id).execute()
                print(f"✅ Unlinked references inside table: '{table_name}'")
            except Exception:
                pass

        # 3. Purge the core vehicle profile item configuration row entry
        if is_numeric:
            query = supabase.table('vehicle').delete().eq('vehicle_id', int(vehicle_identifier)).execute()
        else:
            query = supabase.table('vehicle').delete().eq('plate_number', vehicle_identifier).execute()
            
        print(f"🎉 Fleet asset profile permanently removed: {query.data}")
        
        return jsonify({
            "success": True, 
            "message": "Fleet asset entry erased successfully from history systems registry!"
        }), 200
        
    except Exception as e:
        print(f"❌ Vehicle Deletion Transaction Error Code Context: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


@vehicles_bp.route('/api/vehicles/maintenance', methods=['GET'])
def get_maintenance_logs():
    """Fetches historical maintenance log entries joined with the logging user's name"""
    try:
        query = supabase.table('maintenance_log')\
            .select('maintenance_id, repair_date, description, vehicle_id, user_id, vehicle(plate_number), user_account(full_name)')\
            .order('repair_date', desc=True)\
            .execute()
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        print(f"❌ Fetch Maintenance Logs Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


@vehicles_bp.route('/api/vehicles/maintenance', methods=['POST'])
def add_maintenance_log():
    try:
        data = request.get_json() or {}
        
        new_log = {
            "repair_date": data.get('repair_date'),       # Format: YYYY-MM-DD
            "description": data.get('description', ''),
            "vehicle_id": int(data.get('vehicle_id')),    # Native table link
            "user_id": data.get('user_id')                # Staff user account UUID
        }

        if not new_log["repair_date"] or not new_log["description"] or not new_log["vehicle_id"]:
            return jsonify({"success": False, "message": "Missing required log entries fields."}), 400

        supabase.table('maintenance_log').insert(new_log).execute()
        
        # Determine availability state based on health status choice
        updated_health = data.get('health_status', 'Excellent')
        
        # 🔒 LOCKOUT LOGIC: If vehicle matches maintenance or duty keywords, remove availability flag
        is_available = True
        health_lower = updated_health.lower()
        if "need" in health_lower or "maintenance" in health_lower or "poor" in health_lower or "bad" in health_lower or "duty" in health_lower:
            is_available = False

        supabase.table('vehicle')\
            .update({
                "health_status": updated_health,
                "is_available": is_available, 
                "last_maintenance_description": new_log["description"] 
            })\
            .eq('vehicle_id', new_log["vehicle_id"])\
            .execute()

        return jsonify({"success": True, "message": "Maintenance log securely saved and availability status updated!"}), 201

    except Exception as e:
        print(f"❌ Maintenance Logging Exception: {e}")
        return jsonify({"success": False, "message": str(e)}), 500