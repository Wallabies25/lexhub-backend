"""
LexHub Database Seeder
Run this script ONCE after resetting the database to populate it with initial data.
Usage: python seed_db.py
"""
import os
import sys
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
from datetime import date

load_dotenv()

DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "root")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = os.getenv("DB_NAME", "lexhub")

DATABASE_URL = f"mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

# Import models AFTER engine is created
from app.models import Base, User, Lawyer, Blog, ForumPost
from app.core.security import get_password_hash

def seed():
    print("🌱 Starting LexHub database seed...")

    # Create all tables first
    Base.metadata.create_all(bind=engine)
    print("✅ Tables created/verified.")

    db = SessionLocal()

    try:
        # -----------------------------------------------
        # 1. Create Admin User
        # -----------------------------------------------
        admin = db.query(User).filter(User.email == "admin@lexhub.com").first()
        if not admin:
            admin = User(
                name="LexHub Admin",
                email="admin@lexhub.com",
                hashed_password=get_password_hash("Admin@123"),
                user_type="admin",
                bio="System Administrator",
                occupation="Administrator",
            )
            db.add(admin)
            db.flush()
            print("✅ Admin created: admin@lexhub.com / Admin@123")
        else:
            print("⏭️  Admin already exists, skipping.")

        # -----------------------------------------------
        # 2. Create Lawyer Users
        # -----------------------------------------------
        lawyers_data = [
            {
                "name": "Amal Perera",
                "email": "amal.perera@lexhub.com",
                "password": "Lawyer@123",
                "bio": "Senior Intellectual Property lawyer with 15 years of experience.",
                "occupation": "Lawyer",
                "phone": "+94 77 123 4567",
                "specialty": "Intellectual Property",
                "license_number": "LK-IP-2010-001",
                "cases_handled": 145,
                "success_rate": "94%",
                "hourly_rate": 25000,
                "rating": 4.9,
            },
            {
                "name": "Nimal Sirisena",
                "email": "nimal.sirisena@lexhub.com",
                "password": "Lawyer@123",
                "bio": "Expert in Copyright and Trademark law.",
                "occupation": "Lawyer",
                "phone": "+94 71 987 6543",
                "specialty": "Copyright & Trademark",
                "license_number": "LK-CT-2012-042",
                "cases_handled": 98,
                "success_rate": "91%",
                "hourly_rate": 20000,
                "rating": 4.7,
            },
            {
                "name": "Dilini Jayawardena",
                "email": "dilini.jayawardena@lexhub.com",
                "password": "Lawyer@123",
                "bio": "Specializes in Patent law and Technology IP.",
                "occupation": "Lawyer",
                "phone": "+94 76 555 0099",
                "specialty": "Patent Law",
                "license_number": "LK-PT-2015-018",
                "cases_handled": 67,
                "success_rate": "89%",
                "hourly_rate": 18000,
                "rating": 4.8,
            },
        ]

        created_lawyers = []
        for ld in lawyers_data:
            user = db.query(User).filter(User.email == ld["email"]).first()
            if not user:
                user = User(
                    name=ld["name"],
                    email=ld["email"],
                    hashed_password=get_password_hash(ld["password"]),
                    user_type="lawyer",
                    bio=ld["bio"],
                    occupation=ld["occupation"],
                    phone=ld["phone"],
                )
                db.add(user)
                db.flush()

                lawyer = Lawyer(
                    user_id=user.id,
                    specialty=ld["specialty"],
                    license_number=ld["license_number"],
                    cases_handled=ld["cases_handled"],
                    success_rate=ld["success_rate"],
                    hourly_rate=ld["hourly_rate"],
                    rating=ld["rating"],
                    reviews_count=50,
                    phone=ld["phone"],
                )
                db.add(lawyer)
                db.flush()
                created_lawyers.append((user, lawyer))
                print(f"✅ Lawyer created: {ld['email']} / {ld['password']}")
            else:
                print(f"⏭️  Lawyer {ld['email']} already exists, skipping.")

        # -----------------------------------------------
        # 3. Create Regular Users
        # -----------------------------------------------
        users_data = [
            {
                "name": "Kasun Fernando",
                "email": "kasun.fernando@gmail.com",
                "password": "User@123",
                "bio": "Entrepreneur looking for IP protection for my business.",
                "occupation": "Entrepreneur",
                "phone": "+94 72 111 2233",
            },
            {
                "name": "Sachini Rathnayake",
                "email": "sachini.r@gmail.com",
                "password": "User@123",
                "bio": "Graphic designer needing copyright advice.",
                "occupation": "Graphic Designer",
                "phone": "+94 75 444 5566",
            },
        ]

        for ud in users_data:
            user = db.query(User).filter(User.email == ud["email"]).first()
            if not user:
                user = User(
                    name=ud["name"],
                    email=ud["email"],
                    hashed_password=get_password_hash(ud["password"]),
                    user_type="user",
                    bio=ud["bio"],
                    occupation=ud["occupation"],
                    phone=ud["phone"],
                )
                db.add(user)
                print(f"✅ User created: {ud['email']} / {ud['password']}")
            else:
                print(f"⏭️  User {ud['email']} already exists, skipping.")

        db.flush()

        # -----------------------------------------------
        # 4. Create Sample Blog Posts (by lawyers)
        # -----------------------------------------------
        if created_lawyers:
            lawyer_obj = created_lawyers[0][1]  # First lawyer

            blog = db.query(Blog).filter(Blog.lawyer_id == lawyer_obj.id).first()
            if not blog:
                blog = Blog(
                    lawyer_id=lawyer_obj.id,
                    title="Understanding Intellectual Property Rights in Sri Lanka",
                    content="""Intellectual Property (IP) refers to creations of the mind — inventions, literary and artistic works, designs, symbols, names, and images used in commerce.

In Sri Lanka, IP is governed by the Intellectual Property Act No. 36 of 2003. This comprehensive law covers:

**1. Patents** — Protect inventions that are new, involve an inventive step, and are industrially applicable.

**2. Trademarks** — Protect distinctive signs (words, logos, colors) that identify your goods or services.

**3. Copyright** — Automatically protects original literary, artistic, and scientific works.

**4. Industrial Designs** — Protect the visual features (shape, pattern, color) of a product.

Understanding your rights is the first step to protecting them. If you need legal advice, feel free to contact our team at LexHub.""",
                    excerpt="A comprehensive guide to understanding how IP rights work in Sri Lanka under the IP Act No. 36 of 2003.",
                    tags="IP Law, Patent, Trademark, Copyright, Sri Lanka",
                )
                db.add(blog)
                print("✅ Sample blog post created.")

        # -----------------------------------------------
        # 5. Create Sample Forum Post
        # -----------------------------------------------
        all_users = db.query(User).filter(User.user_type == "user").all()
        if all_users:
            post_user = all_users[0]
            existing_post = db.query(ForumPost).filter(ForumPost.user_id == post_user.id).first()
            if not existing_post:
                forum_post = ForumPost(
                    user_id=post_user.id,
                    title="How do I register a trademark for my small business?",
                    content="I recently started a small business selling handmade products. I want to protect my brand name and logo. What is the process for registering a trademark in Sri Lanka? How long does it take and how much does it cost?",
                    category="Trademark",
                )
                db.add(forum_post)
                print("✅ Sample forum post created.")

        db.commit()
        print("\n🎉 Database seeding complete!")
        print("\n📋 Login Credentials:")
        print("  Admin:  admin@lexhub.com      / Admin@123")
        print("  Lawyer: amal.perera@lexhub.com / Lawyer@123")
        print("  Lawyer: nimal.sirisena@lexhub.com / Lawyer@123")
        print("  Lawyer: dilini.jayawardena@lexhub.com / Lawyer@123")
        print("  User:   kasun.fernando@gmail.com / User@123")
        print("  User:   sachini.r@gmail.com / User@123")

    except Exception as e:
        db.rollback()
        print(f"❌ Error during seeding: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    seed()
