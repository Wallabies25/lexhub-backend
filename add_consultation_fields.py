from sqlalchemy import text
from app.database import engine

def migrate():
    print("Checking for new columns in 'consultations' table using SQLAlchemy...")
    
    with engine.connect() as conn:
        # Add contact_phone
        try:
            conn.execute(text("ALTER TABLE consultations ADD COLUMN contact_phone VARCHAR(50) NULL"))
            print("Successfully added 'contact_phone' column.")
        except Exception as e:
            if "Duplicate column name" in str(e) or "1060" in str(e):
                print("'contact_phone' already exists.")
            else:
                print(f"Error adding 'contact_phone': {e}")

        # Add contact_email
        try:
            conn.execute(text("ALTER TABLE consultations ADD COLUMN contact_email VARCHAR(100) NULL"))
            print("Successfully added 'contact_email' column.")
        except Exception as e:
            if "Duplicate column name" in str(e) or "1060" in str(e):
                print("'contact_email' already exists.")
            else:
                print(f"Error adding 'contact_email': {e}")

        # Add is_paid
        try:
            conn.execute(text("ALTER TABLE consultations ADD COLUMN is_paid BOOLEAN DEFAULT FALSE"))
            print("Successfully added 'is_paid' column.")
        except Exception as e:
            if "Duplicate column name" in str(e) or "1060" in str(e):
                print("'is_paid' already exists.")
            else:
                print(f"Error adding 'is_paid': {e}")

        conn.commit()
    print("Migration completed successfully!")

if __name__ == "__main__":
    migrate()
