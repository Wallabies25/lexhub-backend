import os
import sys

# Add the current directory to sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from sqlalchemy import create_engine, text
from app.models import Base
from app.database import SQLALCHEMY_DATABASE_URL

def reset_db():
    try:
        engine = create_engine(SQLALCHEMY_DATABASE_URL)
        
        # Drop tables in specific order to avoid constraint issues
        with engine.connect() as conn:
            conn.execute(text("SET FOREIGN_KEY_CHECKS = 0;"))
            
            # Get table names from metadata
            for table in reversed(Base.metadata.sorted_tables):
                conn.execute(text(f"DROP TABLE IF EXISTS {table.name};"))
            
            conn.execute(text("SET FOREIGN_KEY_CHECKS = 1;"))
            conn.commit()
            
        print("Dropped existing tables.")
        
        # Create all tables according to new models
        Base.metadata.create_all(bind=engine)
        print("Database schema recreated successfully.")
    except Exception as e:
        print(f"Error resetting database: {e}")

if __name__ == "__main__":
    reset_db()
