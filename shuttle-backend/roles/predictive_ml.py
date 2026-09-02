import os
import numpy as np
from flask import Blueprint, request, jsonify
from sklearn.linear_model import LinearRegression # 👈 Changed to Linear Regression
from sklearn.preprocessing import StandardScaler

predictive_bp = Blueprint('predictive_ml', __name__)
supabase = None  

model = LinearRegression()
scaler = StandardScaler()
is_trained = False

def train_baseline_model():
    """
    Trains a Multiple Linear Regression model to forecast maintenance cycles.
    Features: [Total Mileage (km), Vehicle Age (Years), Trip Count, Past Repair Count]
    Target (y): Estimated Days Until Next Maintenance Required
    """
    global is_trained, model, scaler
    try:
        # X: Independent Variables (Telemetry)
        X_train = np.array([
            [85000, 8, 120, 14],  # Heavily used, old
            [12000, 1, 15,  1],   # New vehicle
            [62000, 5, 95,  8],   # Moderate/Heavy wear
            [22000, 2, 40,  2],   # Lightly used
            [110000, 9, 180, 22], # Critical structural wear
            [5000,  1, 8,   0],   # Pristine baseline
            [71000, 6, 110, 11],  # High repair history
            [35000, 3, 55,  3]    # Standard nominal tier
        ])
        
        # y: Dependent Variable (Days Remaining)
        y_train = np.array([12.0, 310.0, 45.0, 240.0, 2.0, 350.0, 25.0, 180.0])
        
        X_scaled = scaler.fit_transform(X_train)
        model.fit(X_scaled, y_train)
        is_trained = True
        print("🧠 Multiple Linear Regression Engine compiled successfully!")
    except Exception as e:
        print(f"❌ ML Engine Compiler Exception: {e}")

@predictive_bp.route('/api/vehicles/predict/<int:vehicle_id>', methods=['GET'])
def predict_maintenance_risk(vehicle_id):
    global is_trained, model, scaler
    
    if not is_trained:
        train_baseline_model()
        
    try:
        vehicle_res = supabase.table('vehicle').select('*').eq('vehicle_id', vehicle_id).execute()
        if not vehicle_res.data:
            return jsonify({"success": False, "message": "Vehicle asset not found."}), 404
        vehicle = vehicle_res.data[0]

        current_year = 2026
        try: age = float(current_year - int(vehicle.get('model_year', current_year)))
        except ValueError: age = 2.0

        trips_res = supabase.table('trip_schedule').select('route_distance').eq('vehicle_id', vehicle_id).eq('trip_status', 'Completed').execute()
        trip_count = len(trips_res.data) if trips_res.data else 0
        total_mileage = sum(float(t.get('route_distance', 0.0)) for t in trips_res.data) if trips_res.data else 0.0

        logs_res = supabase.table('maintenance_log').select('source: maintenance_id').eq('vehicle_id', vehicle_id).execute()
        past_repairs = len(logs_res.data) if logs_res.data else 0

        # Execute Multiple Linear Regression Inference
        live_features = np.array([[total_mileage, age, trip_count, past_repairs]])
        scaled_features = scaler.transform(live_features)
        
        # Predict continuous days remaining
        predicted_days = float(model.predict(scaled_features)[0])
        predicted_days = max(0.0, round(predicted_days, 1)) # Prevent negative days
        
        # Re-using the risk_score column in DB to store the forecasted days
        update_payload = {"risk_score": predicted_days}
        
        # 🚨 Lockout Strategy: If predicted days is 7 or less, trigger automated lockout
        if predicted_days <= 7.0 and vehicle.get('is_available') == True:
            update_payload["health_status"] = "Needs Maintenance"
            update_payload["is_available"] = False
            update_payload["last_maintenance_description"] = f"⚠️ ML FORECAST: Structural maintenance required within {predicted_days} days."

        supabase.table('vehicle').update(update_payload).eq('vehicle_id', vehicle_id).execute()

        return jsonify({
            "success": True,
            "vehicle_id": vehicle_id,
            "plate_number": vehicle.get('plate_number'),
            "risk_index": predicted_days, # This now sends DAYS instead of PERCENTAGE
            "telemetry_metrics": {
                "total_mileage_km": total_mileage,
                "age_years": age,
                "total_trips": trip_count,
                "past_repairs_count": past_repairs
            }
        }), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

@predictive_bp.route('/api/vehicles/predict/fleet-sweep', methods=['POST', 'GET'])
def evaluate_entire_fleet():
    global is_trained, model, scaler
    
    if not is_trained:
        train_baseline_model()
        
    try:
        vehicles_res = supabase.table('vehicle').select('*').execute()
        if not vehicles_res.data:
            return jsonify({"success": True, "message": "No vehicles found."}), 200
            
        flagged_assets = []
        
        for vehicle in vehicles_res.data:
            vehicle_id = vehicle['vehicle_id']
            
            current_year = 2026
            try: age = float(current_year - int(vehicle.get('model_year', current_year)))
            except ValueError: age = 2.0
                
            trips_res = supabase.table('trip_schedule').select('route_distance').eq('vehicle_id', vehicle_id).eq('trip_status', 'Completed').execute()
            trip_count = len(trips_res.data) if trips_res.data else 0
            total_mileage = sum(float(t.get('route_distance', 0.0)) for t in trips_res.data) if trips_res.data else 0.0
            
            logs_res = supabase.table('maintenance_log').select('source: maintenance_id').eq('vehicle_id', vehicle_id).execute()
            past_repairs = len(logs_res.data) if logs_res.data else 0
            
            live_features = np.array([[total_mileage, age, trip_count, past_repairs]])
            scaled_features = scaler.transform(live_features)
            
            predicted_days = float(model.predict(scaled_features)[0])
            predicted_days = max(0.0, round(predicted_days, 1))

            update_payload = {"risk_score": predicted_days}
            
            if predicted_days <= 7.0 and vehicle.get('is_available') == True:
                update_payload["health_status"] = "Needs Maintenance"
                update_payload["is_available"] = False
                update_payload["last_maintenance_description"] = f"⚠️ ML FORECAST: Background sweep triggered lockout. Maintenance due in {predicted_days} days."
                
                flagged_assets.append({
                    "plate": vehicle.get('plate_number'),
                    "forecast_days": predicted_days
                })

            supabase.table('vehicle').update(update_payload).eq('vehicle_id', vehicle_id).execute()
                
        return jsonify({
            "success": True,
            "message": "Fleet ML sweep complete.",
            "total_evaluated": len(vehicles_res.data),
            "newly_flagged_count": len(flagged_assets),
            "flagged_assets": flagged_assets
        }), 200

    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500