import os
import json
from flask import Blueprint, request, jsonify
from google import genai
from google.genai import types

# 1. Import your clean rules and schema from the new file
from ai_rules import get_shervice_system_prompt, get_ai_schema

ai_bp = Blueprint('ai', __name__)

# SECURITY: Load from .env so your key isn't hardcoded in the file
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
client = genai.Client(api_key=GEMINI_API_KEY)

@ai_bp.route('/api/ai/chat', methods=['POST'])
def ai_chat():
    try:
        # 1. Receiving data from the Flutter app
        data = request.get_json()
        user_message = data.get('message', '')
        user_role = data.get('role', 'User')
        user_name = data.get('name', 'User')

        # 2. Get the dynamically generated system prompt
        system_prompt = get_shervice_system_prompt(user_name, user_role)
        schema = get_ai_schema()

        # 3. Requesting JSON output using the correct config
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                response_mime_type="application/json",
                response_schema=schema,
                temperature=0.0 # Lock this to 0.0 for strict rule adherence
            )
        )
        
        # 4. Parse the AI's JSON response
        ai_data = json.loads(response.text)
        action_type = ai_data.get('action', 'normal')
        ai_reply = ai_data.get('reply', 'I received your message.')

        # 5. HANDLE SYSTEM ACTIONS (Backend Triggers)
        if action_type == 'emergency':
            print(f"🚨 EMERGENCY TRIGGERED BY {user_name} ({user_role}): {user_message}")
            # TODO: Add your Socket.io emit code later
            
        elif action_type == 'bug':
            print(f"🐛 BUG REPORT LOGGED BY {user_name}: {user_message}")
            # TODO: Save bug report to your database here.

        # 6. Send the reply back to Flutter
        return jsonify({
            "success": True,
            "response": ai_reply,
            "action": action_type
        }), 200

    except Exception as e:
        print(f"❌ AI Chat Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500