import numpy as np
from flask import Blueprint, jsonify
from sklearn.neighbors import KNeighborsClassifier
from sklearn.preprocessing import StandardScaler

driver_ml_bp = Blueprint('driver_ml', __name__)
supabase = None  # Injected via app.py

# Initialize KNN model (using 3 nearest neighbors)
model = KNeighborsClassifier(n_neighbors=3)
scaler = StandardScaler()
is_trained = False

def train_driver_classification_model():
    """
    Trains a KNN model to classify driver behavior.
    Features: [Avg Safety, Avg Punctuality, Avg Professionalism, Total Trips]
    Target (y): Behavioral Category
    """
    global is_trained, model, scaler
    try:
        # X: Independent Variables (Evaluation Averages & Experience)
        X_train = np.array([
            [4.8, 4.9, 4.8, 50],  # Excellent across board, highly experienced
            [4.5, 4.7, 4.9, 15],  # Excellent across board, moderate experience
            [2.1, 4.8, 3.5, 30],  # Poor safety, but on time (Fast/Aggressive Driver)
            [1.5, 4.5, 4.0, 10],  # Very poor safety
            [4.6, 2.0, 4.5, 25],  # Safe and polite, but constantly late
            [4.2, 1.5, 4.0, 40],  # Safe, but severe delays
            [4.5, 4.5, 1.8, 20],  # Safe and on time, but rude to passengers
            [4.0, 4.2, 2.1, 15],  # Unprofessional attitude
            [2.5, 2.5, 2.5, 35],  # Poor performance across the board
            [2.0, 2.0, 2.0, 10],  # Consistently bad
        ])
        
        # y: Dependent Variable (Behavioral Class)
        y_train = np.array([
            "Consistent Performer", "Consistent Performer",
            "Aggressive Driving Risk", "Aggressive Driving Risk",
            "Tardiness Risk", "Tardiness Risk",
            "Unprofessional Conduct", "Unprofessional Conduct",
            "Needs Review", "Needs Review"
        ])
        
        # Scale the features so the large 'Total Trips' number doesn't overpower the 1-5 ratings
        X_scaled = scaler.fit_transform(X_train)
        model.fit(X_scaled, y_train)
        is_trained = True
        print("🧠 KNN Driver Classification Engine compiled successfully!")
    except Exception as e:
        print(f"❌ Driver ML Compiler Exception: {e}")
@driver_ml_bp.route('/api/drivers/classify/<string:driver_uuid>', methods=['GET'])
def classify_driver(driver_uuid):
    global is_trained, model, scaler
    
    if not is_trained:
        train_driver_classification_model()
        
    try:
        # 1. Catch invalid/empty IDs from Flutter
        if not driver_uuid or driver_uuid == 'null' or driver_uuid == 'None':
             return jsonify({
                 "success": True, 
                 "classification": "Insufficient Data",
                 "message": "Invalid Driver ID."
             }), 200

        # 2. Get all trips completed by this driver
        trips_res = supabase.table('trip_schedule').select('trip_id').eq('user_id', driver_uuid).execute()
        
        if not trips_res.data:
             return jsonify({
                 "success": True, 
                 "classification": "Insufficient Data",
                 "message": "Driver has no completed trips."
             }), 200
             
        # Extract valid trip IDs, ignoring any nulls
        trip_ids = [t['trip_id'] for t in trips_res.data if t.get('trip_id')]
        
        if not trip_ids:
             return jsonify({"success": True, "classification": "Insufficient Data"}), 200
        
        # 3. Fetch all passenger evaluations linked to those trips
        evals_res = supabase.table('passenger_evaluation').select('safety_score, punctuality_score, professionalism_score').in_('trip_id', trip_ids).execute()
        
        total_evals = len(evals_res.data) if evals_res.data else 0
        
        # Rule: A driver needs at least 3 evaluations for the AI to make a fair classification
        if total_evals < 3:
             return jsonify({
                 "success": True, 
                 "classification": "Insufficient Data",
                 "evaluations_count": total_evals
             }), 200

        # 4. Calculate Aggregates (The 'or 5.0' prevents Python from crashing if a DB cell is NULL)
        total_safety = sum(float(e.get('safety_score') or 5.0) for e in evals_res.data)
        total_punct = sum(float(e.get('punctuality_score') or 5.0) for e in evals_res.data)
        total_prof = sum(float(e.get('professionalism_score') or 5.0) for e in evals_res.data)
        
        avg_safety = total_safety / total_evals
        avg_punct = total_punct / total_evals
        avg_prof = total_prof / total_evals
        
        # 5. Execute KNN Inference
        live_features = np.array([[avg_safety, avg_punct, avg_prof, total_evals]])
        scaled_features = scaler.transform(live_features)
        
        # Convert Scikit-Learn's Numpy String into a standard Python string
        predicted_class = str(model.predict(scaled_features)[0])
        
        return jsonify({
            "success": True,
            "classification": predicted_class,
            "metrics": {
                "avg_safety": round(avg_safety, 2),
                "avg_punctuality": round(avg_punct, 2),
                "avg_professionalism": round(avg_prof, 2),
                "total_evaluations": total_evals
            }
        }), 200

    except Exception as e:
        print(f"🚨 CLASSIFICATION ERROR FOR {driver_uuid}: {e}")
        return jsonify({"success": False, "message": str(e)}), 500