import os
from flask import Blueprint, request, jsonify

# Create the Blueprint for vehicle routes
vehicles_bp = Blueprint('vehicles', __name__)

# This will be assigned dynamically in app.py
supabase = None 

@vehicles_bp.route('/api/vehicles', methods=['GET'])
def get_vehicles():
    """Fetches all vehicles to display on the dashboard"""
    try:
        query = supabase.table('vehicle').select('*').execute()
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        print(f"❌ Fetch Vehicles Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500

@vehicles_bp.route('/api/vehicles/maintenance', methods=['POST'])
def add_maintenance_log():
    try:
        data = request.get_json() or {}
        
        # Pull parameters safely matching your production schema types
        new_log = {
            "repair_date": data.get('repair_date'),       # Format: YYYY-MM-DD
            "description": data.get('description', ''),
            "vehicle_id": int(data.get('vehicle_id')),    # Native table link
            "user_id": data.get('user_id')                # Staff user account UUID
        }

        # Operational validations
        if not new_log["repair_date"] or not new_log["description"] or not new_log["vehicle_id"]:
            return jsonify({"success": False, "message": "Missing required log entries fields."}), 400

        supabase.table('maintenance_log').insert(new_log).execute()
        
        # Optional extension optimization: Update vehicle health status concurrently
        updated_health = data.get('health_status')
        if updated_health:
            supabase.table('vehicle')\
                .update({"health_status": updated_health})\
                .eq('vehicle_id', new_log["vehicle_id"])\
                .execute()

        return jsonify({"success": True, "message": "Maintenance log securely saved!"}), 201

    except Exception as e:
        print(f"❌ Maintenance Logging Exception: {e}")
        return jsonify({"success": False, "message": str(e)}), 500