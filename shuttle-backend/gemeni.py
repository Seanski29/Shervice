import os
import json
from flask import Blueprint, request, jsonify
from google import genai
from google.genai import types

ai_bp = Blueprint('ai', __name__)

# Load your Gemini API key from environment variables
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
client = genai.Client(api_key=GEMINI_API_KEY)

def load_company_knowledge():
    """Reads the local text file to act as the AI's knowledge base."""
    try:
        # Looks for knowledge_base.txt in the root of your Flask project
        with open('knowledge_base.txt', 'r', encoding='utf-8') as file:
            return file.read()
    except FileNotFoundError:
        print("⚠️ Warning: knowledge_base.txt not found!")
        return "No specific company knowledge available."

@ai_bp.route('/api/ai/chat', methods=['POST'])
def ai_chat():
    try:
        # 1. Receive parameters from the Flutter mobile app
        data = request.get_json()
        user_message = data.get('message', '')
        user_role = data.get('role', 'User')
        user_name = data.get('name', 'User')

        # 2. Read the local knowledge base file
        company_knowledge = load_company_knowledge()

        # 3. Formulate the strict system behavior guidelines
        system_prompt = f"""
        You are the 'Shervice Copilot', an in-app support assistant for the GT LANTIN Shuttle Service System.
        You are assisting {user_name}, whose role is {user_role}.
        
        ========== COMPANY KNOWLEDGE BASE ==========
        {company_knowledge}
        ============================================
        
        STRICT RULES:
        1. Answer the user's question using ONLY the information provided in the 'COMPANY KNOWLEDGE BASE' above. 
        2. If the user asks a question and the answer is NOT explicitly stated in the knowledge base, you MUST reply: "I do not have that specific information in my system. Please contact an Admin." Do NOT guess, improvise, or extrapolate.
        3. Keep answers concise, clear, and professional.
        4. Categorize bugs as 'bug' and emergencies as 'emergency'.
        """

        # 4. Enforce structural integrity via a JSON schema
        schema = {
            "type": "OBJECT",
            "properties": {
                "reply": {
                    "type": "STRING", 
                    "description": "Your factual response to the user based strictly on the knowledge base."
                },
                "action": {
                    "type": "STRING", 
                    "enum": ["normal", "bug", "emergency"],
                    "description": "Categorize the user's intent."
                }
            },
            "required": ["reply", "action"]
        }

        # 5. Query the Gemini model with a deterministic temperature setting
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                response_mime_type="application/json",
                response_schema=schema,
                temperature=0.0  # Eliminates random variations in answers
            )
        )
        
        # 6. Parse the forced JSON response structure
        ai_data = json.loads(response.text)
        action_type = ai_data.get('action', 'normal')
        ai_reply = ai_data.get('reply', 'I received your message.')

        # Backend triggers based on parsed actions
        if action_type == 'emergency':
            print(f"🚨 EMERGENCY TRIGGERED BY {user_name}: {user_message}")
        elif action_type == 'bug':
            print(f"🐛 BUG REPORTED BY {user_name}: {user_message}")

        return jsonify({
            "success": True,
            "response": ai_reply,
            "action": action_type
        }), 200

    except Exception as e:
        print(f"❌ AI Chat Error: {e}")
        return jsonify({"success": False, "error": str(e)}), 500