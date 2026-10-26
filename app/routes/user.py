from flask import Blueprint, render_template, session, redirect

from app import db
from app.models import User

user_bp = Blueprint("user", __name__)

@user_bp.route("/dashboard")
def dashboard():
    user_id = session.get("user_id")
    
    if not user_id:
        return redirect("/login")
    
    user = db.session.get(User, user_id)
    
    if not user:
        session.clear()
        return redirect("/login")
    
    return render_template(
        "dashboard.html",
        user = user 
    )