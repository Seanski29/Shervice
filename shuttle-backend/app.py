import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv
from supabase import create_client, Client

# 1. Load Environmental Variables Safely
load_dotenv()

app = Flask(__name__)

# 2. Configure Dynamic Cross-Origin Resource Sharing (CORS)
CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:3000", "http://localhost:8080", "http://127.0.0.1:8080"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})

# 3. Initialize Unified Supabase Client Connection
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("Missing critical configuration parameters inside your backend .env file!")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


# ─────────── API ENDPOINT: CENTRALIZED AUTH INTEGRATION ───────────
@app.route('/api/auth/login', methods=['POST', 'OPTIONS'])
def handle_api_login():
    """
    Validates user credentials against the Supabase 'user_account' table.
    Handles CORS preflight headers automatically.
    """
    if request.method == 'OPTIONS':
        return jsonify({"success": True}), 200
        
    try:
        body = request.get_json() or {}
        email = body.get('email')
        password = body.get('password')

        if not email or not password:
            return jsonify({"success": False, "message": "Missing authentication parameters"}), 400

        user_query = supabase.table('user_account').select('*').eq('username', email).execute()
        
        if not user_query.data:
            return jsonify({"success": False, "message": "Account record does not exist."}), 401
            
        # Force Pylance to safely evaluate this line as a key-value dictionary mapping
        account: dict = user_query.data[0] # type: ignore

        if account.get('password_hash') != password:
            return jsonify({"success": False, "message": "Incorrect password credentials."}), 401

        role = account.get('role', '').lower()
        user_id = account.get('user_id')
        display_name = "System User"

        if role == 'driver':
            driver_profile = supabase.table('driver_profile').select('full_name').eq('user_id', user_id).execute()
            if driver_profile.data:
                # Add type ignore here to silence the dictionary method warning
                display_name = driver_profile.data[0].get('full_name') # type: ignore
        elif role == 'oic':
            oic_profile = supabase.table('oic_profile').select('company_name').eq('user_id', user_id).execute()
            if oic_profile.data:
                # Add type ignore here to safely extract the string property
                display_name = f"OIC ({oic_profile.data[0].get('company_name')})" # type: ignore
        else:
            display_name = "Admin Management"

        return jsonify({
            "success": True,
            "user": {
                "id": user_id,
                "role": role,
                "name": display_name
            }
        }), 200

    except Exception as e:
        print(f"❌ Core Auth Pipeline Exception Tracker: {e}")
        return jsonify({"success": False, "error": str(e)}), 500


# ─────────── API ENDPOINT: FLUTTER ADMIN DASHBOARD METRICS ───────────
@app.route('/api/dashboard/metrics', methods=['GET'])
def get_dashboard_metrics():
    """
    Aggregates operational metrics using your active table structures.
    """
    try:
        # 1. Fetch Total Drivers Count from 'driver_profile' table
        drivers_res = supabase.table('driver_profile').select('driver_id').execute()
        total_drivers = len(drivers_res.data) if drivers_res.data else 0

        # 2. Fetch Total Active Vehicles where status is 'Good Condition'
        active_res = supabase.table('vehicle').select('vehicle_id').eq('health_status', 'Good Condition').execute()
        active_vehicles = len(active_res.data) if active_res.data else 0

        # 3. Fetch Maintenance Flags where status is 'Maintenance Required'
        maint_res = supabase.table('vehicle').select('vehicle_id').eq('health_status', 'Maintenance Required').execute() 
        maint_alerts = len(maint_res.data) if maint_res.data else 0

        # 4. FIXED: Dynamically compute the rolling average from real database entries
        eval_res = supabase.table('passenger_evaluation').select('punctuality_score').execute()
        
        # Set a default baseline rating if the table is completely empty
        avg_punctuality = 5.0 
        
        if eval_res.data:
            # Safely extract all valid integer ratings
            scores = [row['punctuality_score'] for row in eval_res.data if row['punctuality_score'] is not None] # type: ignore
            
           # Calculate the true rolling arithmetic mean
            if scores:
                # Force Pylance to treat this list as numbers for the sum() function
                avg_punctuality = round(sum(scores), 1) / len(scores) # type: ignore
       
        # 5. FIXED: Single, safe loop that handles your vehicle columns cleanly
        recent_maint_res = supabase.table('vehicle').select('plate_number, health_status').eq('health_status', 'Maintenance Required').execute()
        raw_shuttles = recent_maint_res.data if recent_maint_res.data else []
        
        formatted_alerts = []
        for shuttle in raw_shuttles:
            # Added type ignore here to silence the final dict attribute warning
            formatted_alerts.append({
                "plate_number": shuttle.get('plate_number', 'Unknown Plate'), # type: ignore
                "description": "Vehicle flagged for maintenance. System diagnostics overhaul required."
            })

        return jsonify({
            "success": True,
            "metrics": {
                "totalDrivers": total_drivers,
                "activeVehicles": active_vehicles,
                "averagePunctuality": avg_punctuality,
                "maintenanceAlerts": maint_alerts
            },
            "alerts": formatted_alerts
        }), 200

    except Exception as e:
        print(f"❌ Core Metrics Stream Processing Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500


# ─────────── API ENDPOINT: REACT OIC / TRIP SCHEDULING ───────────
@app.route('/api/trips', methods=['GET', 'POST'])
def handle_trips_pipeline():
    """
    GET: Fetches upcoming trip logs.
    POST: Injects a scheduling payload that aligns with your ERD definitions.
    """
    if request.method == 'GET':
        try:
            trips_res = supabase.table('trip_schedule').select('*').order('schedule_date', desc=False).execute()
            return jsonify({"success": True, "trips": trips_res.data or []}), 200
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 500

    elif request.method == 'POST':
        try:
            body = request.get_json() or {}
            
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

    # FALLBACK: Explicit return statement at function root scope to guarantee no 'None' exits
    return jsonify({"success": False, "message": "Method request disallowed."}), 405

# ─────────── DIAGNOSTIC ENDPOINT: PROVE DATABASE CONNECTION ───────────
@app.route('/api/test-db', methods=['GET'])
def diagnostic_database_check():
    """
    Directly queries the driver_profile table to prove connection viability.
    """
    try:
        # Perform a direct select query
        test_query = supabase.table('driver_profile').select('*').execute()
        
        raw_data = test_query.data
        row_count = len(raw_data) if raw_data else 0
        
        return jsonify({
            "connection_status": "SUCCESS",
            "message": "Flask successfully authenticated and communicated with Supabase!",
            "table_queried": "driver_profile",
            "total_rows_found": row_count,
            "sample_data_payload": raw_data[:2] # Returns first two rows as proof
        }), 200
        
    except Exception as e:
        print(f"❌ Diagnostic database connection failed: {e}")
        return jsonify({
            "connection_status": "FAILED",
            "message": "Could not fetch data from Supabase.",
            "error_details": str(e)
        }), 500
        
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)