import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "root")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = os.getenv("DB_NAME", "lexhub")

# Detect if we're connecting to Aiven (cloud) or local MySQL
IS_CLOUD_DB = "aivencloud.com" in DB_HOST or os.getenv("DB_SSL", "false").lower() == "true"

if IS_CLOUD_DB:
    # Aiven requires SSL - use ssl_disabled=False
    SQLALCHEMY_DATABASE_URL = (
        f"mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
        f"?ssl_disabled=False"
    )
    print(f"Connecting to CLOUD database (SSL enabled): {DB_HOST}:{DB_PORT}/{DB_NAME}")
else:
    SQLALCHEMY_DATABASE_URL = (
        f"mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    print(f"Connecting to LOCAL database: {DB_HOST}:{DB_PORT}/{DB_NAME}")

try:
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        pool_pre_ping=True,        # Test connection before using from pool
        pool_recycle=300,          # Recycle connections every 5 min (avoids timeout)
        connect_args={"connection_timeout": 30}
    )
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    print("Database engine created successfully.")
except Exception as e:
    print(f"Error creating database engine: {e}")
    engine = None
    SessionLocal = None

Base = declarative_base()

def get_db():
    if SessionLocal is None:
        raise Exception("Database not configured")
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
