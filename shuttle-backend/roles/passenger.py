from flask import Blueprint

passenger_bp = Blueprint('passenger', __name__)

# Dynamically assigned by app.py upon initialization
supabase = None

# 💡 Ready for your future passenger custom updates! Add your new routes underneath this comment block.