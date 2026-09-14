import os
import time
import traceback
from dotenv import load_dotenv
from flask import Blueprint, request, jsonify
from supabase import create_client

notifs_bp = Blueprint('notifs', __name__)
supabase = None

def _create_supabase_client():
    load_dotenv()
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_KEY')
    if not url or not key:
        raise RuntimeError('Missing SUPABASE_URL or SUPABASE_KEY environment variables.')
    return create_client(url, key)

def _execute_supabase(action, retries=3, backoff=0.25):
    last_exc = None
    for attempt in range(1, retries + 1):
        try:
            return action()
        except Exception as e:
            last_exc = e
            message = str(e).lower()
            retryable = (
                isinstance(e, OSError)
                or '10035' in message
                or 'non-blocking socket operation' in message
                or 'temporarily unavailable' in message
                or 'timeout' in message
            )
            print(f'⚠️ Supabase retry attempt {attempt}/{retries}: {e}')
            traceback.print_exc()
            if not retryable or attempt >= retries:
                break
            time.sleep(backoff * attempt)
    raise last_exc

# ==========================================
# 1. FETCH NOTIFICATIONS (WITH STRICT DRIVER ISOLATION)
# ==========================================
@notifs_bp.route('/api/notifications', methods=['GET'])
def get_notifications():
    try:
        user_id = request.args.get('user_id')
        role = (request.args.get('role') or '').strip().lower()
        company = (request.args.get('company') or '').strip()
        if company.lower() in ('internal', 'gt lantin internal', 'unknown'):
            company = ''

        if not user_id:
            return jsonify({"success": False, "message": "Missing user_id parameter"}), 400

        # PERF: Reuse app.py's process-scoped client to avoid constructing and
        # tearing down an HTTP session for every notification request.
        supabase_client = supabase or _create_supabase_client()
        response = _execute_supabase(
            lambda: supabase_client.table('app_notification')
            .select('*')
            .order('created_at', desc=True)
            .execute()
        )

        raw_notifs = response.data or []
        filtered_notifications = []

        # --------------------------------------------------
        # THE STRICT FILTERS
        # --------------------------------------------------
        if role == 'admin':
            # Admins see everything
            filtered_notifications = raw_notifs
            
        elif role == 'driver':
            # RUTHLESS DRIVER FILTER: 
            # Drivers ONLY see notifications explicitly linked to their exact UUID.
            for notification in raw_notifs:
                target_user_id = notification.get('target_user_id')
                if str(target_user_id) == str(user_id):
                    filtered_notifications.append(notification)
                    
        else:
            # STAFF AND OIC FILTER:
            # They get the flexible rules (Global broadcasts, company broadcasts, etc.)
            for notification in raw_notifs:
                target_user_id = notification.get('target_user_id')
                target_role = (notification.get('target_role') or '').strip().lower()
                target_company = (notification.get('target_company') or '').strip()

                if str(target_user_id) == str(user_id):
                    filtered_notifications.append(notification)
                    continue
                if not target_role and not target_company:
                    filtered_notifications.append(notification)
                    continue
                if not target_role and company and target_company.lower() == company.lower():
                    filtered_notifications.append(notification)
                    continue
                if target_role == role and not target_company:
                    filtered_notifications.append(notification)
                    continue
                if target_role == role and not company:
                    filtered_notifications.append(notification)
                    continue
                if target_role == role and company and target_company.lower() == company.lower():
                    filtered_notifications.append(notification)

        return jsonify({
            "success": True,
            "data": filtered_notifications
        }), 200

    except Exception as e:
        print(f"❌ Notification Fetch Error: {e}")
        return jsonify({"success": False, "message": "Internal server error."}), 500


# ==========================================
# 2. MARK NOTIFICATION AS READ
# ==========================================
@notifs_bp.route('/api/notifications/<int:notif_id>/read', methods=['PUT'])
def mark_as_read(notif_id):
    try:
        # PERF: Reuse the shared HTTP session instead of allocating one per update.
        supabase_client = supabase or _create_supabase_client()
        response = _execute_supabase(
            lambda: supabase_client.table('app_notification')
            .update({'is_read': True})
            .eq('notification_id', notif_id)
            .execute()
        )

        if response.data:
            return jsonify({"success": True, "message": "Notification marked as read."}), 200
        else:
            return jsonify({"success": False, "message": "Notification not found."}), 404

    except Exception as e:
        print(f"❌ Notification Update Error: {e}")
        return jsonify({"success": False, "message": "Internal server error."}), 500


# ==========================================
# 3. UNIVERSAL TRIGGER HELPER
# ==========================================
def trigger_notification(title, message, target_user_id=None, target_role=None, target_company=None, related_trip_id=None, source_tag='system'):
    """
    Call this function from anywhere in your backend to generate a notification.
    """
    try:
        # PERF: Keep inserts on the shared connection pool for lower latency under burst load.
        supabase_client = supabase or _create_supabase_client()
        payload = {
            'title': title,
            'message': message,
            'source_tag': source_tag
        }
        if target_user_id: payload['target_user_id'] = target_user_id
        if target_role: payload['target_role'] = target_role
        if target_company: payload['target_company'] = target_company
        if related_trip_id: payload['related_trip_id'] = related_trip_id

        _execute_supabase(
            lambda: supabase_client.table('app_notification').insert(payload).execute()
        )
        print(f'✅ Notification triggered successfully: {title}')
        return True
    except Exception as e:
        print(f"❌ Failed to trigger notification: {e}")
        return False