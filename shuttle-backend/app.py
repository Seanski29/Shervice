import os
from flask import Flask, make_response, request
from flask_cors import CORS
from dotenv import load_dotenv
from supabase import create_client, Client

# Import your blueprint role modules from the folder structures
import roles.auth as auth_module
import roles.admin as admin_module
import roles.oic as oic_module
import roles.drivers as drivers_module
import roles.staff as staff_module
import roles.passenger as passenger_module

class TransportBackendApp:
    def __init__(self):
        # 1. Initialize safe environment profile keys
        load_dotenv()
        self.app = Flask(__name__)
        
        # 2. ENHANCED GLOBAL CORS HANDLER: Overrides incoming pipeline preflights
        CORS(self.app, resources={
            r"/api/*": {
                "origins": "*",
                "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
                "allow_headers": ["Content-Type", "Authorization", "Accept"],
                "expose_headers": ["Content-Type", "Authorization"]
            }
        })
        
        # 3. Setup core unified database engine connection parameters
        self.supabase_url = os.getenv("SUPABASE_URL")
        self.supabase_key = os.getenv("SUPABASE_KEY")
        
        if not self.supabase_url or not self.supabase_key:
            raise ValueError("Missing critical configuration parameters inside your backend .env file!")
            
        self.supabase: Client = create_client(self.supabase_url, self.supabase_key)
        
        # 4. Bind hooks and structural modular router blueprints
        self._register_hooks()
        self._inject_dependencies_and_register_blueprints()

    def _register_hooks(self):
        # GLOBAL OPTIONS HANDSHAKE CATCHER: Intercepts preflight checks cleanly
        @self.app.before_request
        def handle_preflight():
            if request.method == "OPTIONS":
                response = make_response()
                response.headers.add("Access-Control-Allow-Origin", "*")
                response.headers.add("Access-Control-Allow-Headers", "Content-Type,Authorization,Accept")
                response.headers.add("Access-Control-Allow-Methods", "GET,PUT,POST,DELETE,OPTIONS")
                return response, 200

    def _inject_dependencies_and_register_blueprints(self):
        """
        Injects the initialized single client connection into each role module 
        variable space before mounting blueprints into the unified server schema.
        """
        auth_module.supabase = self.supabase
        admin_module.supabase = self.supabase
        oic_module.supabase = self.supabase
        drivers_module.supabase = self.supabase
        staff_module.supabase = self.supabase
        passenger_module.supabase = self.supabase

        # Register functional application blueprints cleanly
        self.app.register_blueprint(auth_module.auth_bp)
        self.app.register_blueprint(admin_module.admin_bp)
        self.app.register_blueprint(oic_module.oic_bp)
        self.app.register_blueprint(drivers_module.drivers_bp)
        self.app.register_blueprint(staff_module.staff_bp)
        self.app.register_blueprint(passenger_module.passenger_bp)

    def run(self):
        # Force alignment to explicit loopback addresses
        self.app.run(host='127.0.0.1', port=5000, debug=True)

if __name__ == '__main__':
    server = TransportBackendApp()
    server.run()