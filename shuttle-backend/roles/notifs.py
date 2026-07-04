import os
import time
import socket
import traceback
from dotenv import load_dotenv
from flask import Blueprint, request, jsonify
from supabase import create_client

# Create the blueprint
notifs_bp = Blueprint('notifs', __name__)

# This will be dynamically assigned in app.py
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
# 1. FETCH NOTIFICATIONS (WITH ROLE/COMPANY FILTERING)
# ==========================================
@notifs_bp.route('/api/notifications', methods=['GET'])
def get_notifications():
    try:
        # Get parameters passed from Flutter and normalize whitespace/case
        user_id = request.args.get('user_id')
        role = (request.args.get('role') or '').strip().lower()
        company = (request.args.get('company') or '').strip()
        if company.lower() in ('internal', 'gt lantin internal', 'unknown'):
            company = ''

        print(f"🔔 get_notifications called with user_id={user_id!r}, role={role!r}, company={company!r}")

        if not user_id:
            return jsonify({"success": False, "message": "Missing user_id parameter"}), 400

        # Admin sees everything.
        supabase_client = _create_supabase_client()
        try:
            response = _execute_supabase(
                lambda: supabase_client.table('app_notification')
                .select('*')
                .order('created_at', desc=True)
                .execute()
            )
        finally:
            try:
                supabase_client.postgrest.session.close()
            except Exception:
                pass

        if role.lower() == 'admin':
            filtered_notifications = response.data or []
        else:
            filtered_notifications = []
            for notification in response.data or []:
                target_user_id = notification.get('target_user_id')
                target_role = (notification.get('target_role') or '').strip().lower()
                target_company = (notification.get('target_company') or '').strip()

                # Directly addressed to the current user.
                if str(target_user_id) == str(user_id):
                    filtered_notifications.append(notification)
                    continue

                # Global notification for everyone.
                if not target_role and not target_company:
                    filtered_notifications.append(notification)
                    continue

                # Company-wide notification for all roles.
                if not target_role and company and target_company.lower() == company.lower():
                    filtered_notifications.append(notification)
                    continue

                # Role-wide notification for all companies.
                if target_role == role and not target_company:
                    filtered_notifications.append(notification)
                    continue

                # If the user has no valid company mapping, show same-role notifications anyway.
                if target_role == role and not company:
                    filtered_notifications.append(notification)
                    continue

                # Role + company scoped notification.
                if target_role == role and company and target_company.lower() == company.lower():
                    filtered_notifications.append(notification)

            print(f"🔔 returning {len(filtered_notifications)} notifications (raw fetched: {len(response.data or [])}) for user_id={user_id}")

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
        supabase_client = _create_supabase_client()
        try:
            response = _execute_supabase(
                lambda: supabase_client.table('app_notification')
                .update({'is_read': True})
                .eq('notification_id', notif_id)
                .execute()
            )
        finally:
            try:
                supabase_client.postgrest.session.close()
            except Exception:
                pass

        if response.data:
            return jsonify({"success": True, "message": "Notification marked as read."}), 200
        else:
            return jsonify({"success": False, "message": "Notification not found."}), 404

    except Exception as e:
        print(f"❌ Notification Update Error: {e}")
        return jsonify({"success": False, "message": "Internal server error."}), 500