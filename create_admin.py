import argparse
from sqlalchemy.orm import Session
from app.database import SessionLocal, engine
from app.models import User, UserType
from app.core.security import get_password_hash

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def promote_user(email: str):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            print(f"User with email {email} not found.")
            return

        user.user_type = UserType.admin
        db.commit()
        print(f"Successfully promoted {user.name} ({email}) to Admin!")
    finally:
        db.close()

def create_admin(name: str, email: str, password: str):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if user:
            print(f"User with email {email} already exists. Promoting instead...")
            user.user_type = UserType.admin
        else:
            user = User(
                name=name,
                email=email,
                hashed_password=get_password_hash(password),
                user_type=UserType.admin
            )
            db.add(user)
        db.commit()
        print(f"Admin {name} ({email}) created successfully!")
    finally:
        db.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Manage Admins")
    parser.add_argument("--promote", type=str, help="Email of user to promote to admin")
    parser.add_argument("--create", type=str, nargs=3, metavar=("NAME", "EMAIL", "PASSWORD"), help="Create a brand new admin user")
    
    args = parser.parse_args()
    
    if args.promote:
        promote_user(args.promote)
    elif args.create:
        create_admin(args.create[0], args.create[1], args.create[2])
    else:
        parser.print_help()
