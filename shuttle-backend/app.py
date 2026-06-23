import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv
from supabase import create_client, Client

# 1. Load Environmental Variables Safely
load_dotenv()

app = Flask(__name__)

# 2. Configure Dynamic Cross-Origin Resource Sharing (CORS)
# This allows both your React app (3000) and Flutter app (8080) to securely pull data
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


# ─────────── API ENDPOINT: FLUTTER ADMIN DASHBOARD ───────────
@app.route('/api/dashboard/metrics', methods=['GET'])
def get_dashboard_metrics():
    """
    Aggregates operational metrics for the Flutter Admin Dashboard UI.
    Calculates drivers, active vehicles, maintenance alerts, and evaluation scores.
    """
    try:
        # Fetch Total Active Drivers Magnitude
        drivers_res = supabase.table('driver_profile').select('driver_id').execute()
        total_drivers = len(drivers_res.data) if drivers_res.data else 0

        # Fetch Total Good Status Vehicles
        active_res = supabase.table('vehicle').select('vehicle_id').ilike('health_status', 'Good').execute()
        active_vehicles = len(active_res.data) if active_res.data else 0

        # Fetch Total Maintenance Critical Status Vehicles
        maint_res = supabase.table('vehicle').select('vehicle_id').ilike('health_status', 'Maintenance').execute()
        maint_alerts = len(maint_res.data) if maint_res.data else 0

        # Dynamically Compute Average Passenger Punctuality Score
        eval_res = supabase.table('passenger_evaluation').select('punctuality_score').execute()
        avg_punctuality = 4.8  # Default baseline
        if eval_res.data:
            scores = [row['punctuality_score'] for row in eval_res.data if row['punctuality_score'] is not None]
            if scores:
                avg_punctuality = round(sum(scores) / len(scores), 1)

        # Fetch Live Maintenance Logs Linked to Vehicles via Foreign Key
        logs_res = supabase.table('maintenance_log').select(
            'description, vehicle:vehicle_id(plate_number)'
        ).order('repair_date', desc=True).limit(5).execute()
        
        raw_logs = logs_res.data if logs_res.data else []
        formatted_alerts = []
        for log in raw_logs:
            v_info = log.get('vehicle', {}) or {}
            formatted_alerts.append({
                "plate_number": v_info.get('plate_number', 'Unknown Plate'),
                "description": log.get('description', 'Routine Diagnostic Overhaul Required')
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
        print(f"❌ Backend Dashboard Engine Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500


# ─────────── API ENDPOINT: REACT OIC / TRIP SCHEDULING ───────────
@app.route('/api/trips', methods=['GET', 'POST'])
def handle_trips_pipeline():
    """
    GET: Fetches all upcoming trip schedules for React OIC Views.
    POST: Injects a new scheduled transit loop created by the OIC Officer.
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
            
            # Prepare payload matching your ERD trip_schedule configuration parameters exactly
            new_trip = {
                "schedule_date": body.get("schedule_date"),
                "departure_time": body.get("departure_time"),
                "route_name": body.get("route_name"),
                "trip_status": "Scheduled",
                "user_id": body.get("user_id"),         # Linked OIC/Staff Account
                "vehicle_id": body.get("vehicle_id"),   # Allocated Vehicle Asset
                "passenger_count": body.get("passenger_count", 0)
            }

            insert_res = supabase.table('trip_schedule').insert(new_trip).execute()
            return jsonify({"success": True, "inserted": insert_res.data}), 201
            
        except Exception as e:
            print(f"❌ Backend Trip Injection Error: {e}")
            return jsonify({"success": False, "error": str(e)}), 500


if __name__ == '__main__':
    # Runs backend processing service on host address port 5000 in debug developer execution mode
    app.run(host='0.0.0.0', port=5000, debug=True)