import os
import numpy as np
from flask import Blueprint, request, jsonify
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

predictive_bp = Blueprint('predictive_ml', __name__)
supabase = None  # Injected dynamically by app.py upon initialization

# Global model structures so they persist in-memory on localhost
model = LogisticRegression()
scaler = StandardScaler()
is_trained = False

def train_baseline_model():
    """
    Trains a classification model using historical operational baselines.
    Features: [Total Mileage (km), Vehicle Age (Years), Trip Count, Past Repair Count]
    """
    global is_trained, model, scaler
    try:
        # Labeled Training Dataset: 
        # 1 = High Risk / Breakdown imminent, 0 = Operating Safely
        X_train = np.array([
            [85000, 8, 120, 14],  # 1 (High breakdown profile)
            [12000, 1, 15,  1],   # 0 (New vehicle baseline)
            [62000, 5, 95,  8],   # 1 (Heavy duty wear)
            [22000, 2, 40,  2],   # 0 (Stable baseline)
            [110000, 9, 180, 22], # 1 (Critical structural wear)
            [5000,  1, 8,   0],   # 0 (Pristine baseline)
            [71000, 6, 110, 11],  # 1 (High repair history)
            [35000, 3, 55,  3]    # 0 (Standard nominal tier)
        ])
        
        y_train = np.array([1, 0, 1, 0, 1, 0, 1, 0])
        
        # Fit our pipeline tools
        X_scaled = scaler.fit_transform(X_train)
        model.fit(X_scaled, y_train)
        is_trained = True
        print("🧠 Predictive Maintenance ML Engine compiled and trained successfully!")
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
        try:
            age = float(current_year - int(vehicle.get('model_year', current_year)))
        except ValueError:
            age = 2.0

        trips_res = supabase.table('trip_schedule').select('route_distance').eq('vehicle_id', vehicle_id).eq('trip_status', 'Completed').execute()
        trip_count = len(trips_res.data) if trips_res.data else 0
        total_mileage = sum(float(t.get('route_distance', 0.0)) for t in trips_res.data) if trips_res.data else 0.0

        logs_res = supabase.table('maintenance_log').select('source: maintenance_id').eq('vehicle_id', vehicle_id).execute()
        past_repairs = len(logs_res.data) if logs_res.data else 0

        live_features = np.array([[total_mileage, age, trip_count, past_repairs]])
        scaled_features = scaler.transform(live_features)
        
        prediction = int(model.predict(scaled_features)[0])
        probabilities = model.predict_proba(scaled_features)[0]
        failure_probability = float(probabilities[1])  

        # Always save the risk_score when the modal is clicked
        update_payload = {"risk_score": failure_probability}
        
        if failure_probability >= 0.80 and vehicle.get('is_available') == True:
            update_payload["health_status"] = "Needs Maintenance"
            update_payload["is_available"] = False
            update_payload["last_maintenance_description"] = f"⚠️ ML CRITICAL LOCKOUT: Automated structural break probability high ({round(failure_probability * 100, 1)}%)."

        # Push the update to Supabase instantly
        supabase.table('vehicle').update(update_payload).eq('vehicle_id', vehicle_id).execute()

        return jsonify({
            "success": True,
            "vehicle_id": vehicle_id,
            "plate_number": vehicle.get('plate_number'),
            "needs_maintenance_prediction": prediction == 1,
            "risk_index": failure_probability,
            "telemetry_metrics": {
                "total_mileage_km": total_mileage,
                "age_years": age,
                "total_trips": trip_count,
                "past_repairs_count": past_repairs
            }
        }), 200

    except Exception as e:
        print(f"❌ ML Diagnostic Inference Engine Error: {e}")
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
            try:
                age = float(current_year - int(vehicle.get('model_year', current_year)))
            except ValueError:
                age = 2.0
                
            trips_res = supabase.table('trip_schedule').select('route_distance').eq('vehicle_id', vehicle_id).eq('trip_status', 'Completed').execute()
            trip_count = len(trips_res.data) if trips_res.data else 0
            total_mileage = sum(float(t.get('route_distance', 0.0)) for t in trips_res.data) if trips_res.data else 0.0
            
            logs_res = supabase.table('maintenance_log').select('source: maintenance_id').eq('vehicle_id', vehicle_id).execute()
            past_repairs = len(logs_res.data) if logs_res.data else 0
            
            live_features = np.array([[total_mileage, age, trip_count, past_repairs]])
            scaled_features = scaler.transform(live_features)
            
            probabilities = model.predict_proba(scaled_features)[0]
            failure_probability = float(probabilities[1])

            # Formulate the payload for the background sweep
            update_payload = {"risk_score": failure_probability}
            
            if failure_probability >= 0.80 and vehicle.get('is_available') == True:
                update_payload["health_status"] = "Needs Maintenance"
                update_payload["is_available"] = False
                update_payload["last_maintenance_description"] = f"⚠️ ML CRITICAL LOCKOUT: Automated background sweep detected imminent breakdown probability ({round(failure_probability * 100, 1)}%)."
                
                flagged_assets.append({
                    "plate": vehicle.get('plate_number'),
                    "risk": round(failure_probability * 100, 1)
                })

            # Update the database silently in the background
            supabase.table('vehicle').update(update_payload).eq('vehicle_id', vehicle_id).execute()
                
        return jsonify({
            "success": True,
            "message": "Fleet ML sweep complete.",
            "total_evaluated": len(vehicles_res.data),
            "newly_flagged_count": len(flagged_assets),
            "flagged_assets": flagged_assets
        }), 200

    except Exception as e:
        print(f"❌ Fleet Sweep ML Engine Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500