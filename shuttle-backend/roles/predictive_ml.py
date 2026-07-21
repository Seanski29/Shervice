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
    """
    Extracts dynamic live telemetry parameters from your Supabase schema
    to calculate a real-time structural breakdown probability score.
    """
    global is_trained, model, scaler
    
    # Lazy train model on the first incoming request if it isn't running yet
    if not is_trained:
        train_baseline_model()
        
    try:
        # 1. Fetch Target Vehicle Data
        vehicle_res = supabase.table('vehicle').select('*').eq('vehicle_id', vehicle_id).execute()
        if not vehicle_res.data:
            return jsonify({"success": False, "message": "Vehicle asset not found in database."}), 404
        vehicle = vehicle_res.data[0]

        # 2. Extract Feature 1: Vehicle Age
        current_year = 2026
        try:
            age = float(current_year - int(vehicle.get('model_year', current_year)))
        except ValueError:
            age = 2.0

        # 3. Calculate Feature 2 & 3: Total Mileage & Total Trip Count from completed dispatches
        trips_res = supabase.table('trip_schedule').select('route_distance')\
            .eq('vehicle_id', vehicle_id).eq('trip_status', 'Completed').execute()
        
        trip_count = len(trips_res.data) if trips_res.data else 0
        total_mileage = sum(float(t.get('route_distance', 0.0)) for t in trips_res.data) if trips_res.data else 0.0

        # 4. Calculate Feature 4: Past Repair Counts from historical logs
        logs_res = supabase.table('maintenance_log').select('source: maintenance_id').eq('vehicle_id', vehicle_id).execute()
        past_repairs = len(logs_res.data) if logs_res.data else 0

        # 5. Execute Machine Learning Inference Pipeline
        live_features = np.array([[total_mileage, age, trip_count, past_repairs]])
        scaled_features = scaler.transform(live_features)
        
        prediction = int(model.predict(scaled_features)[0])
        probabilities = model.predict_proba(scaled_features)[0]
        failure_probability = float(probabilities[1])  # Class 1 Probability index

        # 6. Safety Trigger Strategy: Automated Hazard Lockout
        # If failure index is > 85%, automatically restrict scheduling dispatch configurations
        if failure_probability > 0.85 and vehicle.get('is_available') == True:
            supabase.table('vehicle').update({
                "health_status": "Needs Maintenance",
                "is_available": False,
                "last_maintenance_description": f"⚠️ ML CRITICAL LOCKOUT: Automated structural break probability high ({round(failure_probability * 100, 1)}%)."
            }).eq('vehicle_id', vehicle_id).execute()

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