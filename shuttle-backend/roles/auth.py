import uuid
import os
from typing import Any, Dict, cast
from flask import Blueprint, jsonify, request
from supabase import create_client

auth_bp = Blueprint('auth', __name__)

# Dynamically assigned by app.py upon initialization
supabase = None 

def get_admin_client():
    """Helper to create a dedicated Admin Client for secure tasks"""
    return create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_KEY"))

@auth_bp.route('/api/auth/login', methods=['POST'])
def handle_api_login():
    try:
        body = cast(Dict[str, Any], request.get_json() or {})
        email = str(body.get('email', '')).strip().lower()
        password = body.get('password')

        if not email or not password:
            return jsonify({"success": False, "message": "Missing authentication parameters"}), 400

        # Strict Security Verification
        auth_response = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })
        user_uuid = auth_response.user.id
        token = auth_response.session.access_token
        
        # 1. Initialize variables before the 'if' checks
        role = "admin" 
        display_name = "System User"
        company_str = "GT Lantin Internal" # Default value

        user_query = supabase.table('user_account').select('*').eq('user_id', user_uuid).execute()
        
        if user_query.data:
            account = user_query.data[0]
            role = account.get('role', '').lower()
            display_name = account.get('full_name') or "System User"
            
            # 2. Add specific formatting for OICs
            if role == 'oic':
                oic_profile = supabase.table('oic_profile').select('company_name').eq('user_id', user_uuid).execute()
                if oic_profile.data:
                    company_str = oic_profile.data[0].get('company_name', 'Unknown')
            
            # 3. Fallback for old Drivers registered before the SQL update
            elif role == 'driver' and display_name == "System User":
                driver_profile = supabase.table('driver_profile').select('full_name').eq('user_id', user_uuid).execute()
                if driver_profile.data:
                    display_name = driver_profile.data[0].get('full_name', 'Driver')

        # Now company_str is guaranteed to be defined
        return jsonify({
            "success": True,
            "data": {
                "id": user_uuid,
                "role": role,
                "name": display_name,
                "company": company_str, 
                "token": token
            }
        }), 200

    except Exception as e:
        print(f"❌ Login Rejected: {e}")
        return jsonify({"success": False, "message": "Invalid email or password credentials."}), 401


@auth_bp.route('/api/auth/register-driver', methods=['POST'])
def register_driver():
    try:
        data = request.get_json() or {}
        email = str(data.get('email', '')).strip().lower()
        full_name = data.get('full_name')
        
        auth_res = supabase.auth.sign_up({
            "email": email,
            "password": data.get('password')
        })
        uid = auth_res.user.id

        # SAVE NAME TO USER ACCOUNT
        supabase.table('user_account').insert({
            "user_id": uid, 
            "role": "driver", 
            "username": email,
            "full_name": full_name
        }).execute()

        supabase.table('driver_profile').insert({
            "user_id": uid, 
            "full_name": full_name, 
            "birthday": data.get('birthday', '1995-05-15'),
            "license_no": data.get('license_no'),
            "license_expiry": data.get('license_expiry', '2031-12-31'),
            "date_hired": data.get('date_hired'),
            "employment_status": "Active", 
            "is_backup": "No"
        }).execute()

        return jsonify({"success": True, "message": "Driver registered!"}), 201
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@auth_bp.route('/api/auth/register-staff-oic', methods=['POST'])
def register_staff_oic():
    try:
        data = request.get_json() or {}
        email = str(data.get('email', '')).strip().lower()
        full_name = data.get('full_name')
        role_raw = data.get('role')
        company_name = data.get('company_name')

        role_map = {'Administrator': 'admin', 'Dispatch Staff': 'staff', 'Officer-in-Charge': 'oic'}
        normalized_role = role_map.get(role_raw, 'staff')

        admin_supabase = get_admin_client()
        auth_res = admin_supabase.auth.admin.create_user({
            "email": email,
            "password": data.get('password'),
            "email_confirm": True
        })
        uid = auth_res.user.id

        # SAVE NAME TO USER ACCOUNT
        supabase.table('user_account').insert({
            "user_id": uid,
            "role": normalized_role,
            "username": email,
            "full_name": full_name
        }).execute()

        if normalized_role == 'oic':
            supabase.table('oic_profile').insert({
                "user_id": uid,
                "company_name": company_name
            }).execute()

        return jsonify({"success": True, "message": "User registered!"}), 201
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@auth_bp.route('/api/auth/update-password', methods=['POST'])
def update_user_password():
    try:
        data = request.get_json() or {}
        admin_client = get_admin_client()
        admin_client.auth.admin.update_user_by_id(
            data['user_id'], 
            attributes={"password": data['new_password']}
        )
        return jsonify({"success": True, "message": "Password updated!"}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


@auth_bp.route('/api/auth/system-users', methods=['GET'])
def get_system_users():
    try:
        users_query = supabase.table('user_account').select('*').neq('role', 'driver').execute()
        oic_query = supabase.table('oic_profile').select('*').execute()
        
        oic_map = {oic['user_id']: oic['company_name'] for oic in oic_query.data}
        formatted_users = []

        for u in users_query.data:
            role = str(u.get('role', 'staff')).lower()
            actual_name = u.get('full_name') or 'System User'
            
            company = "GT Lantin Internal"
            permission = "Logistics Only"
            display_role = "Dispatch Staff"
            status_color = "green"

            if role == 'admin':
                display_role = "Administrator"
                permission = "Full Access"
            elif role == 'oic':
                display_role = "Officer-in-Charge"
                company = oic_map.get(u['user_id'], 'Unknown Client')
                permission = "Schedules & Feedback"
                status_color = "blue"

            formatted_users.append({
                "id": u['user_id'],
                "name": actual_name,
                "email": u.get('username', ''),
                "role": display_role,
                "company": company,
                "permission": permission,
                "status": "Active",
                "color": status_color
            })

        return jsonify({"success": True, "data": formatted_users}), 200
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500


# ─────────── ENDPOINT: UPDATE DRIVER DATA ───────────
@auth_bp.route('/api/auth/update-driver/<driver_id>', methods=['PUT'])
def update_driver(driver_id):
    try:
        data = request.get_json() or {}
        new_email = data.get("email", "").strip().lower()
        
        # 1. Update the email directly inside the core Supabase Auth Vault
        if new_email:
            admin_supabase = get_admin_client()
            admin_supabase.auth.admin.update_user_by_id(
                driver_id,
                attributes={"email": new_email, "email_confirm": True}
            )
        
        # 2. Sync full name and email inside your public user_account tracking folder
        supabase.table("user_account").update({
            "full_name": data.get("full_name"),
            "username": new_email # Syncing login identifier
        }).eq("user_id", driver_id).execute()
        
        # 3. Sync profile operational descriptors
        supabase.table("driver_profile").update({
            "full_name": data.get("full_name"),
            "birthday": data.get("birthday"),
            "license_no": data.get("license_no"),
            "employment_status": data.get("employment_status")
        }).eq("user_id", driver_id).execute()
        
        return jsonify({"success": True, "message": "Driver fields and login credentials updated safely."}), 200
    except Exception as e:
        print(f"❌ Driver Update Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500

# ─────────── ENDPOINT: PURGE DRIVER FROM SYSTEM ───────────
@auth_bp.route('/api/auth/delete-driver/<driver_id>', methods=['DELETE'])
def delete_driver(driver_id):
    try:
        # Step 1: Wipe profile relations first to free foreign key constraints
        supabase.table("driver_profile").delete().eq("user_id", driver_id).execute()
        
        # Step 2: Wipe custom user account metadata tracking row
        supabase.table("user_account").delete().eq("user_id", driver_id).execute()
        
        # Step 3: Now it is safe to completely clear the user out of Supabase GoTrue Auth
        admin_supabase = get_admin_client()
        admin_supabase.auth.admin.delete_user(driver_id)
        
        return jsonify({"success": True, "message": "Driver completely expunged from system."}), 200
    except Exception as e:
        print(f"❌ Driver Delete Error: {e}")
        return jsonify({"success": False, "message": f"Server processing error: {str(e)}"}), 500
    
@auth_bp.route('/api/auth/facebook', methods=['POST'])
def facebook_auth():
    data = request.get_json()
    email = data.get('email')
    full_name = data.get('full_name')
    
    if not email:
        return jsonify({"success": False, "message": "Facebook account has no email attached."}), 400

    try:
        # 1. Check if the user exists
        existing_user = supabase.table('user_account').select('*').eq('username', email).execute()
        
        if existing_user.data:
            # Login successful
            account = existing_user.data[0]
            role = account.get('role', 'driver')
            
            return jsonify({
                "success": True, 
                "message": "Logged in via Facebook", 
                "data": {
                    "id": account['user_id'],
                    "role": role,
                    "name": account.get('full_name', full_name),
                    "company": "GT Lantin Internal", 
                    "token": "facebook-oauth-token-bypass" # Bypass standard token
                }
            }), 200
            
        else:
            # 2. Driver doesn't exist. Create them dynamically.
            # Create in auth vault with a random secure password
            import secrets
            import string
            random_password = ''.join(secrets.choice(string.ascii_letters + string.digits) for i in range(16))
            
            admin_client = get_admin_client()
            auth_res = admin_client.auth.admin.create_user({
                "email": email,
                "password": random_password,
                "email_confirm": True
            })
            uid = auth_res.user.id

            # Save to user_account
            supabase.table('user_account').insert({
                "user_id": uid, 
                "role": "driver", 
                "username": email,
                "full_name": full_name
            }).execute()

            # Save to driver_profile
            supabase.table('driver_profile').insert({
                "user_id": uid, 
                "full_name": full_name, 
                "employment_status": "Active"
            }).execute()

            return jsonify({
                "success": True, 
                "message": "Driver account created via Facebook", 
                "data": {
                    "id": uid,
                    "role": "driver",
                    "name": full_name,
                    "company": "GT Lantin Internal",
                    "token": "facebook-oauth-token-bypass"
                }
            }), 201

    except Exception as e:
        print(f"❌ Facebook Auth Error: {e}")
        return jsonify({"success": False, "message": str(e)}), 500