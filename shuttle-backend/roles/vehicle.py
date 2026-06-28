import os
from flask import Blueprint, request, jsonify

# Create the Blueprint for vehicle routes
vehicles_bp = Blueprint('vehicles', __name__)

# This will be assigned dynamically in app.py
supabase = None 

@vehicles_bp.route('/api/vehicles', methods=['GET'])
def get_vehicles():
    """Fetches all vehicles alongside their availability status to display on the dashboard"""
    try:
        query = supabase.table('vehicle').select('*').order('plate_number').execute()
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        print(f"❌ Fetch Vehicles Error: {e}")
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