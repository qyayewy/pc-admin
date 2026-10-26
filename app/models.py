from app import db


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(
        db.BigInteger,
        primary_key=True,
        autoincrement=True
    )

    username = db.Column(
        db.String(50),
        nullable=False,
        unique=True
    )

    email = db.Column(
        db.String(255),
        unique=True
    )

    phone = db.Column(
        db.String(30)
    )

    password_hash = db.Column(
        db.Text,
        nullable=False
    )

    role = db.Column(
        db.String(20),
        nullable=False,
        default="USER"
    )

    balance = db.Column(
        db.Numeric(10, 2),
        nullable=False,
        default=0.00
    )

    status = db.Column(
        db.String(20),
        nullable=False,
        default="ACTIVE"
    )

    created_at = db.Column(
        db.DateTime(timezone=True),
        nullable=False,
        server_default=db.func.now()
    )

    updated_at = db.Column(
        db.DateTime(timezone=True),
        nullable=False,
        server_default=db.func.now(),
        onupdate=db.func.now()
    )