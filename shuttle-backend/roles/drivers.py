from flask import Blueprint

drivers_bp = Blueprint('drivers', __name__)

# Dynamically assigned by app.py upon initialization
supabase = None

# 💡 Ready for your future driver custom updates! Add your new routes underneath this comment block.