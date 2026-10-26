from flask import Blueprint, request, jsonify, session, render_template
from werkzeug.security import generate_password_hash, check_password_hash

from app import db
from app.models import User


auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "GET":
        return render_template("register.html")
    
    data = request.get_json()

    username = data.get("username")
    password = data.get("password")
    email = data.get("email")
    phone = data.get("phone")

    if not username or not password:
        return jsonify({
            "error": "Username и password обязательны"
        }), 400

    if len(username) < 3:
        return jsonify({
            "error": "Username должен содержать минимум 3 символа"
        }), 400

    if len(password) < 6:
        return jsonify({
            "error": "Пароль должен содержать минимум 6 символов"
        }), 400

    existing_user = User.query.filter_by(username=username).first()

    if existing_user:
        return jsonify({
            "error": "Такой username уже существует"
        }), 409

    if email:
        existing_email = User.query.filter_by(email=email).first()

        if existing_email:
            return jsonify({
                "error": "Такой email уже зарегистрирован"
            }), 409

        email = email.strip()

    user = User(
        username=username.strip(),
        email=email,
        phone=phone,
        password_hash=generate_password_hash(password)
    )

    db.session.add(user)
    db.session.commit()

    return jsonify({
        "message": "Пользователь успешно зарегистрирован",
        "user": {
            "id": user.id,
            "username": user.username,
            "role": user.role,
            "balance": float(user.balance)
        }
    }), 201
    
@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "GET":
        return render_template("login.html")
    
    data = request.get_json()
    
    username = data.get("username")
    password = data.get("password")
    
    if not username or not password:
        return jsonify({
            "error": "Данные не должны быть пустыми"    
        }), 400
        
    user = User.query.filter_by(username=username.strip()).first()
    
    if not user:
        return jsonify({
            "error": "Неверный логин или пароль"
        }), 401
    
    if not check_password_hash(user.password_hash, password):
        return jsonify({
            "error": "Неверный логин или пароль"
        }), 401
        
    if user.status != "ACTIVE":
        return jsonify({
            "error": "Пользователь заблокирован"
        }), 403
        
    session["user_id"] = user.id
    
    return jsonify({
        "message": "Успешный вход",
        "user": {
            "id": user.id,
            "username": user.username,
            "role": user.role
        }
    }), 200
    
@auth_bp.route("/me", methods=["GET"])
def me():
    user_id = session.get("user_id")
    
    if not user_id:
        return jsonify({
            "error": "не авторизован"
        }), 401
        
    user = db.session.get(User, user_id)
    
    if not user:
        session.clear()
        
        return jsonify({
            "error": "Пользователь не найден"
        }), 401
    
    return jsonify({
        "id": user.id,
        "username": user.username,
        "role": user.role,
        "balance": float(user.balance)
    }), 200
    
@auth_bp.route("/logout", methods=["POST"])
def logout():
    session.clear()
    
    return jsonify({
        "message": "Вы вышли из аккаунта"
    }), 200