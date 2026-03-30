from sqlalchemy import text
from app.database import engine

def show_users():
    print("\n--- LexHub User Management ---\n")
    try:
        with engine.connect() as conn:
            # Query users table
            query = text("SELECT id, name, email, user_type, joined_date FROM users")
            result = conn.execute(query)
            
            users = result.fetchall()
            
            if not users:
                print("No users found in the database.")
                return

            print(f"{'ID':<5} | {'Name':<20} | {'Email':<30} | {'Type':<10} | {'Joined Date'}")
            print("-" * 85)
            for user in users:
                # user[0] is id, user[1] is name, etc.
                print(f"{user[0]:<5} | {user[1]:<20} | {user[2]:<30} | {user[3]:<10} | {user[4]}")
            
            print(f"\nTotal Users: {len(users)}")
            
    except Exception as e:
        print(f"Error fetching users: {e}")
        print("\nMake sure your MySQL server is running and the database 'lexhub' exists.")

if __name__ == "__main__":
    show_users()
