from typing import Any, Dict, cast
from flask import Blueprint, jsonify, request
from datetime import datetime

oic_bp = Blueprint('oic', __name__)

# Dynamically assigned by app.py upon initialization
supabase = None


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
            
    return jsonify({"success": False, "message": "Method request disallowed."}), 405


@oic_bp.route('/api/schedules/oic/<oic_id>', methods=['GET'])
def get_trips_by_oic(oic_id):
    try:
        # Step 1: Resolve the text UUID to the OIC's integer primary key
        oic_profile_res = supabase.table('oic_profile')\
            .select('oic_id')\
            .eq('user_id', oic_id)\
            .maybe_single()\
            .execute()
            
        oic_profile_data = oic_profile_res.data
        
        if not oic_profile_data:
            print(f"⚠️ No OIC Profile row found for user UUID: {oic_id}")
            return jsonify({"success": True, "trips": [], "data": []}), 200
            
        resolved_int_id = oic_profile_data.get('oic_id')

        # Step 2: Query trip schedules along with relational joins matching resolved key
        trips_res = supabase.table('trip_schedule').select(
            '*, user_account(full_name), vehicle(plate_number, bus_type)'
        ).eq('oic_id', resolved_int_id).order('schedule_date', desc=False).execute()
        
        raw_trips = trips_res.data or []
        formatted_trips = _format_trip_data(raw_trips)

        return jsonify({
            "success": True, 
            "trips": formatted_trips, 
            "data": formatted_trips
        }), 200
        
    except Exception as e:
        print(f"❌ OIC Filtered Fetch Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500


# ─────────── MUTUAL EVALUATIONS PIPELINE (GET & POST) ───────────

@oic_bp.route('/api/evaluations/mutual', methods=['GET', 'POST'])
def handle_mutual_evaluations_pipeline():
    """Handles both saving and retrieving OIC Client feedback ratings securely"""
    try:
        if request.method == 'POST':
            data = request.get_json() or {}
            
            new_evaluation = {
                "trip_id": int(data.get("trip_id")),
                "oic_id": int(data.get("oic_id")),
                "overall_rating": int(data.get("overall_rating", 5)),
                "comments": data.get("comments", "").strip(),
                "evaluator_type": data.get("evaluator_type", "OIC"),
                "submit_date": datetime.utcnow().strftime('%Y-%m-%d')
            }
            
            if not new_evaluation["comments"]:
                return jsonify({"success": False, "message": "Comments cannot be empty."}), 400
                
            supabase.table('oic_evaluation').insert(new_evaluation).execute()
            return jsonify({"success": True, "message": "Client feedback rating stored successfully!"}), 201

        elif request.method == 'GET':
            query_res = supabase.table('oic_evaluation').select('*').execute()
            return jsonify({
                "success": True,
                "evaluations": query_res.data or []
            }), 200

    except Exception as e:
        print(f"❌ OIC Mutual Evaluation API Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500


def _format_trip_data(raw_trips: list) -> list:
    """Helper method to format raw database rows into unified payload profiles."""
    formatted_trips = []
    
    for trip in raw_trips:
        user_info = trip.get('user_account')
        if isinstance(user_info, dict):
            driver_name = user_info.get('full_name', 'Driver Assigned')
        else:
            raw_uid = trip.get('user_id')
            driver_name = f"ID: {str(raw_uid)[:4]}..." if raw_uid else "Unassigned"

        vehicle_info = trip.get('vehicle') or {}
        plate_number = vehicle_info.get('plate_number', 'No Plate Assigned')

        raw_time = trip.get('departure_time') or trip.get('time')
        display_time = str(raw_time)[:5] if raw_time else "--:--"

        formatted_trips.append({
            'trip_id': trip.get('trip_id'),
            'id': trip.get('trip_id'),
            'status': trip.get('trip_status') or trip.get('status', 'Scheduled'),
            'trip_status': trip.get('trip_status') or trip.get('status', 'Scheduled'),
            'departure_time': display_time, 
            'schedule_time': display_time,  
            'time': display_time,
            'driver_name': driver_name,
            'driver': driver_name,
            'plate_number': plate_number,
            'vehicle': vehicle_info,
            'route_name': trip.get('route_name') or trip.get('route', 'Route Unassigned'),
            'schedule_date': str(trip.get('schedule_date')),
            'passenger_count': trip.get('passenger_count', 0),
            'route_distance': trip.get('route_distance', 0.0),
            'vehicle_id': trip.get('vehicle_id'),
            'oic_id': trip.get('oic_id'),
        })
        
    return formatted_trips

@oic_bp.route('/api/evaluations/summary', methods=['GET'])
def get_evaluation_summary():
    try:
        # Fetch all evaluations with their company names
        res = supabase.table('oic_evaluation').select(
            'overall_rating, oic_profile(company_name)'
        ).execute()
        
        data = res.data or []
        summary = {}

        for entry in data:
            profile = entry.get('oic_profile') or {}
            comp = profile.get('company_name', 'Unknown')
            if comp not in summary:
                summary[comp] = {'total': 0, 'sum': 0}
            summary[comp]['total'] += 1
            summary[comp]['sum'] += entry['overall_rating']
            
        result = []
        for comp, val in summary.items():
            result.append({
                "name": comp,
                "avg": round(val['sum'] / val['total'], 1),
                "count": val['total']
            })
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500