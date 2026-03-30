from sqlalchemy import create_engine, Column, Integer, String, Enum, ForeignKey, Date, DateTime, Text, Boolean, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import enum
from datetime import datetime
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "mysql+mysqlconnector://root:root@localhost/lexhub")

engine = create_engine(DATABASE_URL)
Base = declarative_base()

class StatuteDocument(Base):
    __tablename__ = "statute_documents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    title = Column(String(255), nullable=False)
    category = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    file_url = Column(String(500), nullable=False)
    file_name = Column(String(255), nullable=False)
    file_size = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

def migrate():
    print("Checking for 'statute_documents' table...")
    Base.metadata.create_all(bind=engine)
    print("Table 'statute_documents' created or already exists.")

if __name__ == "__main__":
    migrate()
