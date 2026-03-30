import sys
from sqlalchemy import text
from app.database import engine

def main():
    if not engine:
        print("Database engine not initialized.")
        sys.exit(1)
        
    try:
        with engine.connect() as conn:
            # Check existing columns in lawyers
            result = conn.execute(text("SHOW COLUMNS FROM lawyers"))
            columns = [row[0] for row in result]
            
            # Prepare ADD COLUMN statements
            alter_sqls = []
            if 'hourly_rate' not in columns:
                alter_sqls.append("ADD COLUMN hourly_rate INT DEFAULT 20000")
            if 'rating' not in columns:
                alter_sqls.append("ADD COLUMN rating FLOAT DEFAULT 4.8")
            if 'reviews_count' not in columns:
                alter_sqls.append("ADD COLUMN reviews_count INT DEFAULT 50")
            
            if alter_sqls:
                alter_query = f"ALTER TABLE lawyers {', '.join(alter_sqls)};"
                print(f"Executing: {alter_query}")
                conn.execute(text(alter_query))
                conn.commit()
                print("Successfully added columns to lawyers table!")
            else:
                print("Columns already exist.")
                
    except Exception as e:
        print(f"Error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
