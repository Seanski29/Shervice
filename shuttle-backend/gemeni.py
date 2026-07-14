import json
from flask import Blueprint, request, jsonify
from google import genai
from google.genai import types

ai_bp = Blueprint('ai', __name__)

# IMPORTANT: Your Google AI Studio API Key
GEMINI_API_KEY = "AQ.Ab8RN6KiaatA4WjsytI_lvdm3ErtqqkazyzTrvzCNQHq3vhJfA"

# Initialize the new official SDK client
client = genai.Client(api_key=GEMINI_API_KEY)

@ai_bp.route('/api/ai/chat', methods=['POST'])
def ai_chat():
    try:
        # 1. Receiving data from the Flutter app
        data = request.get_json()
        user_message = data.get('message', '')
        user_role = data.get('role', 'User')
        user_name = data.get('name', 'User')

        # 2. Strict System Prompt defining Shervice's exact AI rules
        system_prompt = f"""
        You are the 'Shervice Copilot', an in-app support assistant for the GT LANTIN Shuttle Service System.
        You are talking to {user_name}, whose role is {user_role}.
        
        YOUR RULES:
        1. NO ROUTING/LOGISTICS: Do NOT give routing advice, ETA predictions, or logistics calculations.
        2. APP NAVIGATION: Answer questions on how to use the app (e.g., "How do I add a schedule?", "How do I delete a user?"). Be concise and provide step-by-step instructions based on standard web/app dashboards.
        3. BUG REPORTING: If the user reports a bug, acknowledge it and assure them IT staff has been notified.
        4. EMERGENCY PROTOCOL: provide immediate instructions for emergencies (e.g., "Call 911", "Contact the shuttle service manager") and do NOT provide any other information.make it short.
    
        OUTPUT FORMAT:
        You must answer using the systems actual names and roles used in the GT LANTIN Shuttle Service System. Do NOT make up names or roles.
        You MUST respond ONLY with a valid  JSON object matching this exact structure:
        {{
            "reply": "Your conversational response to the user.",
            "action": "normal" | "bug" | "emergency"
        }}
        """

        # 3. Requesting JSON output using the correct GenerateContentConfig object
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                response_mime_type="application/json"
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
