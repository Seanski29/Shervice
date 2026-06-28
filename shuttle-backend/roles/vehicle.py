import os
from flask import Blueprint, request, jsonify

# Create the Blueprint for vehicle routes
vehicles_bp = Blueprint('vehicles', __name__)

# This will be assigned dynamically in app.py
supabase = None 

@vehicles_bp.route('/api/vehicles/register', methods=['POST'])
def register_vehicle():
    try:
        data = request.get_json() or {}
        
        role = str(data.get('role', '')).lower()
        if role != 'admin':
            return jsonify({"success": False, "message": "Unauthorized. Only Administrators can register fleet vehicles."}), 403
        
        # Now dynamically accepting ALL data from the Flutter app
        supabase.table('vehicle').insert({
            "plate_number": data.get('plate_number', '').upper(),
            "bus_type": data.get('bus_type', ''),
            "model_year": data.get('model_year', ''),
            "engine_no": data.get('engine_no', ''),
            "insurance_policy_no": data.get('insurance_policy_no', ''),
            "insurance_expiry": data.get('insurance_expiry', None),
            "franchise_no": data.get('franchise_no', ''),
            "franchise_expiry": data.get('franchise_expiry', None),
            "cr_no": data.get('cr_no', ''),
            "cr_date": data.get('cr_date', None),
            "or_no": data.get('or_no', ''),
            "or_expiry": data.get('or_expiry', None),
            "health_status": "Excellent"
        }).execute()

        return jsonify({"success": True, "message": "Vehicle securely registered!"}), 201

    except Exception as e:
        print(f"❌ Vehicle Registration Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500

@vehicles_bp.route('/api/vehicles', methods=['GET'])
def get_vehicles():
    """Fetches all vehicles to display on the dashboard"""
    try:
        query = supabase.table('vehicle').select('*').execute()
        return jsonify({"success": True, "data": query.data}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500