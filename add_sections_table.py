from sqlalchemy import create_engine, Column, Integer, String, Text, ForeignKey, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import datetime
import os
from dotenv import load_dotenv

load_dotenv()

# Use the same DB URL as the app
SQLALCHEMY_DATABASE_URL = "mysql+mysqlconnector://root:root@localhost/lexhub"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
Base = declarative_base()

class StatuteSection(Base):
    __tablename__ = "statute_sections"

    id = Column(Integer, primary_key=True, index=True)
    document_id = Column(Integer, ForeignKey("statute_documents.id", ondelete="CASCADE"))
    section_number = Column(String(50), nullable=True)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    summary = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

def migrate():
    print("Creating statute_sections table...")
    Base.metadata.create_all(bind=engine)
    print("Done!")

if __name__ == "__main__":
    migrate()
