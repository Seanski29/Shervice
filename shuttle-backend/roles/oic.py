from typing import Any, Dict, cast
from flask import Blueprint, jsonify, request
from datetime import datetime

oic_bp = Blueprint('oic', __name__)
supabase = None # Assigned by app.py

# ─────────── 1. CORE TRIPS & SCHEDULES PIPELINE ───────────

@oic_bp.route('/api/trips', methods=['GET', 'POST'])
def handle_trips_pipeline():
    if request.method == 'GET':
        try:
            # Resolves user_account names and vehicle plates simultaneously
            trips_res = supabase.table('trip_schedule').select(
                '*, user_account(full_name), vehicle(plate_number, bus_type)'
            ).execute()
            
            raw_trips = trips_res.data or []
            return jsonify({"success": True, "trips": raw_trips}), 200
        except Exception as e:
            print(f"❌ Admin Schedule Fetch Exception: {e}")
            return jsonify({"success": False, "error": str(e)}), 500

    elif request.method == 'POST':
        try:
            body = cast(Dict[str, Any], request.get_json() or {})
            new_trip = {
                "schedule_date": body.get("schedule_date"),
                "departure_time": body.get("departure_time"),
                "route_name": body.get("route_name"),
                "trip_status": body.get("trip_status", "Pending Staff Assignment"), 
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
            
    return jsonify({"success": False, "message": "Method request disallowed."}), 405


# ─────────── 2. MUTUAL EVALUATIONS PIPELINE ───────────

@oic_bp.route('/api/evaluations/mutual', methods=['GET', 'POST'])
def handle_evaluations():
    try:
        if request.method == 'POST':
            data = request.get_json() or {}
            
            # Safe parsing to prevent type errors on missing elements
            trip_id_raw = data.get("trip_id")
            oic_id_raw = data.get("oic_id")
            
            if trip_id_raw is None or oic_id_raw is None:
                return jsonify({"success": False, "message": "Missing trip_id or oic_id"}), 400

            new_eval = {
                "trip_id": int(trip_id_raw),
                "oic_id": int(oic_id_raw),
                "overall_rating": int(data.get("overall_rating", 5)),
                "comments": str(data.get("comments", "")).strip(),
                "evaluator_type": "OIC",
                "submit_date": datetime.utcnow().strftime('%Y-%m-%d')
            }
            supabase.table('oic_evaluation').insert(new_eval).execute()
            return jsonify({"success": True}), 201
        
        # GET: Includes the join for company_name
        res = supabase.table('oic_evaluation').select('*, oic_profile(company_name)').execute()
        return jsonify({"success": True, "evaluations": res.data or []}), 200
    except Exception as e:
        print(f"❌ Evaluation Handler Exception: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


@oic_bp.route('/api/evaluations/summary', methods=['GET'])
def get_evaluation_summary():
    try:
        res = supabase.table('oic_evaluation').select('overall_rating, oic_profile(company_name)').execute()
        summary = {}
        for entry in (res.data or []):
            oic_prof = entry.get('oic_profile', {})
            if isinstance(oic_prof, list) and len(oic_prof) > 0:
                oic_prof = oic_prof[0]
                
            comp = oic_prof.get('company_name', 'Unknown') if isinstance(oic_prof, dict) else 'Unknown'
            
            if comp not in summary: 
                summary[comp] = {'total': 0, 'sum': 0}
            summary[comp]['total'] += 1
            summary[comp]['sum'] += entry.get('overall_rating', 5)
        
        return jsonify([
            {
                "name": k, 
                "avg": round(v['sum'] / v['total'], 1) if v['total'] > 0 else 0.0, 
                "count": v['total']
            } for k, v in summary.items()
        ]), 200
    except Exception as e:
        print(f"❌ Summary Calculation Exception: {e}")
        return jsonify({"success": False, "message": str(e)}), 500