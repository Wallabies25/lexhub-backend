"""
Quick Migration: Add missing columns to Aiven LIVE database.
Credentials are read ONLY from .env file - never hardcoded.

Usage:
  1. Create a .env file in this folder with your Aiven credentials:
       DB_USER=avnadmin
       DB_PASSWORD=your_aiven_password
       DB_HOST=mysql-xxx.aivencloud.com
       DB_PORT=3306
       DB_NAME=defaultdb
  2. python migrate_add_columns.py
"""
import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

# Read ONLY from environment variables or .env file
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = os.getenv("DB_NAME", "defaultdb")

if not all([DB_USER, DB_PASSWORD, DB_HOST]):
    print("ERROR: Missing DB credentials!")
    print("Create a .env file with DB_USER, DB_PASSWORD, DB_HOST and run again.")
    exit(1)

DATABASE_URL = f"mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

print(f"Connecting to: {DB_HOST}:{DB_PORT}/{DB_NAME}")

engine = create_engine(DATABASE_URL)

# Columns to add safely (won't crash if already exists)
migrations = [
    ("users", "occupation",    "VARCHAR(255) NULL"),
    ("users", "linkedin_url",  "VARCHAR(500) NULL"),
    ("users", "phone",         "VARCHAR(50) NULL"),
    ("users", "bio",           "TEXT NULL"),
    ("users", "profile_picture", "VARCHAR(500) NULL"),
    ("lawyers", "rating",      "FLOAT DEFAULT 0.0"),
    ("lawyers", "reviews_count", "INT DEFAULT 0"),
    ("lawyers", "hourly_rate", "INT DEFAULT 0"),
    ("lawyers", "cases_handled", "INT DEFAULT 0"),
    ("lawyers", "success_rate", "VARCHAR(20) NULL"),
    ("lawyers", "phone",       "VARCHAR(50) NULL"),
]

def safe_add_column(conn, table, column, definition):
    try:
        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {column} {definition}"))
        print(f"  Added: {table}.{column}")
    except Exception as e:
        err = str(e)
        if "Duplicate column" in err or "1060" in err:
            print(f"  Already exists: {table}.{column}")
        else:
            print(f"  Error on {table}.{column}: {err}")

def run_migrations():
    with engine.connect() as conn:
        print("\nRunning migrations...\n")
        for table, column, definition in migrations:
            safe_add_column(conn, table, column, definition)
        conn.commit()
        print("\nAll migrations complete!")

if __name__ == "__main__":
    run_migrations()
