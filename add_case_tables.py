import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# Load environment variables if any
load_dotenv()

# MySQL Connection String (Matches the user's setup)
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "root")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = os.getenv("DB_NAME", "lexhub")

SQLALCHEMY_DATABASE_URL = f"mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

def migrate():
    print(f"Connecting to database: {DB_NAME} on {DB_HOST}...")
    try:
        engine = create_engine(SQLALCHEMY_DATABASE_URL)
        
        # Ensure the connection works
        with engine.connect() as conn:
            print("Successfully connected to database.")
            
            # Use SQLAlchemy's metadata to create tables automatically
            # This will create 'cases', 'case_documents', and 'case_notes' 
            # if they don't already exist.
            print("Creating Case management tables...")
            from app.models import Base
            # This will detect the new models Case, CaseDocument, CaseNote 
            # because they were added to app.models.
            Base.metadata.create_all(bind=engine)
            
            print("Tables created successfully.")
            
    except Exception as e:
        print(f"Error during migration: {e}")

if __name__ == "__main__":
    migrate()
