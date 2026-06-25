import uuid
import os
from typing import Any, Dict, cast
from flask import Blueprint, jsonify, request
from supabase import create_client

auth_bp = Blueprint('auth', __name__)

# Dynamically assigned by app.py upon initialization
supabase = None 

@auth_bp.route('/api/auth/login', methods=['POST'])
def handle_api_login():
    try:
        body = cast(Dict[str, Any], request.get_json() or {})
        email = str(body.get('email', '')).strip().lower()
        password = body.get('password')

        if not email or not password:
            return jsonify({"success": False, "message": "Missing authentication parameters"}), 400

        # ─── STRICT SECURITY CHECK: NO MORE BYPASS ───
        try:
            # This line FORCES the password to be correct for EVERYONE. 
            # If they type the wrong password, it immediately throws an error and rejects them.
            auth_response = supabase.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
            
            user_uuid = auth_response.user.id
            token = auth_response.session.access_token
            
        except Exception as auth_err:
            print(f"❌ Login Rejected (Wrong Password or Email): {auth_err}")
            return jsonify({"success": False, "status": "error", "message": "Invalid email or password credentials."}), 401

        # ─── IF THE PASSWORD WAS CORRECT, GET THEIR ROLE ───
        role = "admin" 
        display_name = "System User"

        user_query = supabase.table('user_account').select('*').eq('user_id', user_uuid).execute()
        
        if user_query.data:
            account: dict = user_query.data[0]
            role = account.get('role', '').lower()
            
            if role == 'driver':
                driver_profile = supabase.table('driver_profile').select('full_name').eq('user_id', user_uuid).execute()
                if driver_profile.data:
                    display_name = driver_profile.data[0].get('full_name')
            elif role == 'oic':
                oic_profile = supabase.table('oic_profile').select('company_name').eq('user_id', user_uuid).execute()
                if oic_profile.data:
                    display_name = f"OIC ({oic_profile.data[0].get('company_name')})"
            elif role == 'staff':
                display_name = "Dispatch Staff"
            else:
                display_name = "Admin Management"
                
        print(f"✅ Secure Login Success: {email} ({role})")

        return jsonify({
            "success": True,
            "status": "success",
            "data": {
                "id": user_uuid,
                "role": role,
                "name": display_name,
                "token": token
            },
            "user": { 
                "id": user_uuid,
                "role": role,
                "name": display_name
            }
        }), 200

    except Exception as e:
        print(f"❌ Core Auth Pipeline Exception Tracker: {e}")
        return jsonify({"success": False, "status": "error", "message": "Invalid email or password credentials."}), 401

@auth_bp.route('/api/auth/register-driver', methods=['POST'])
def register_driver():
    """
    Fallback registration engine creating structural user assets 
    directly inside your public schemas to bypass dashboard security blocks.
    """
    try:
        data = cast(Dict[str, Any], request.get_json() or {})
        email = data.get('email')
        password = data.get('password') # Captured securely for system profiles
        full_name = data.get('full_name')
        license_no = data.get('license_no')
        birthday = data.get('birthday', '1995-05-15')
        license_expiry = data.get('license_expiry', '2031-12-31')
        date_hired = data.get('date_hired')
        
        if not email or not password or not full_name or not license_no:
            return jsonify({"success": False, "message": "Missing required field configurations."}), 400

        # 1. Register the driver officially in the Supabase Vault (Saves the real password!)
        auth_response = supabase.auth.sign_up({
            "email": email,
            "password": password
        })
        driver_uuid = auth_response.user.id

        # 2. Sync baseline login directory record straight into user_account table
        supabase.table('user_account').insert({
            "user_id": driver_uuid,
            "role": "driver",
            "username": email
        }).execute()

        # 3. Inject operational metrics context inside public.driver_profile matching your SQL constraints
        supabase.table('driver_profile').insert({
            "user_id": driver_uuid,
            "full_name": full_name,
            "birthday": birthday,
            "license_no": license_no,
            "license_expiry": license_expiry,
            "date_hired": date_hired,
            "employment_status": "Active",
            "is_backup": "No"
        }).execute()

        print(f"✅ Driver registered manually under local system bypass UUID: {driver_uuid}")
        return jsonify({"success": True, "message": "Driver account recorded successfully!"}), 201

    except Exception as e:
        print(f"❌ Driver Creation Intercept Failure: {e}")
        return jsonify({"success": False, "message": str(e)}), 500
    
@auth_bp.route('/api/auth/update-password', methods=['POST'])
def update_user_password():
    """
    Foolproof Password Reset:
    Creates a localized, temporary Admin client to bypass any global public key restrictions.
    """
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')
        new_password = data.get('new_password')

        if not user_id or not new_password:
            return jsonify({"success": False, "message": "Missing user ID or new password."}), 400

        ADMIN_URL = os.getenv("SUPABASE_URL")
        ADMIN_KEY = os.getenv("SUPABASE_KEY")
        
        if not ADMIN_URL or not ADMIN_KEY:
             return jsonify({"success": False, "message": "Server configuration missing keys."}), 500
        
        # Creates a localized master-admin connection just for this specific password task
        admin_supabase = create_client(ADMIN_URL, ADMIN_KEY)

        print(f"🔄 Admin attempting to update password for UUID: {user_id}")

        # Use the dedicated admin client to force the update
        update_response = admin_supabase.auth.admin.update_user_by_id(
            user_id, 
            attributes={"password": new_password}
        )

        print(f"✅ Supabase Vault Confirmed: Password changed successfully.")
        
        return jsonify({"success": True, "message": "Password updated successfully!"}), 200

    except Exception as e:
        print(f"❌ EXACT Password Update Error: {str(e)}")
        return jsonify({"success": False, "message": f"Server failed: {str(e)}"}), 500