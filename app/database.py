import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DB_USER     = os.getenv("DB_USER",     "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "root")
DB_HOST     = os.getenv("DB_HOST",     "localhost")
DB_PORT     = os.getenv("DB_PORT",     "3306")
DB_NAME     = os.getenv("DB_NAME",     "lexhub")

IS_AIVEN = "aivencloud.com" in DB_HOST

SQLALCHEMY_DATABASE_URL = (
    f"mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# SSL connect args for Aiven - passed as connect_args NOT url params
connect_args = {}
if IS_AIVEN:
    connect_args = {
        "ssl_disabled": False,
        "connection_timeout": 30,
    }
    print(f"[DB] Aiven cloud mode - SSL enabled. Host: {DB_HOST}:{DB_PORT}")
else:
    print(f"[DB] Local mode. Host: {DB_HOST}:{DB_PORT}/{DB_NAME}")

try:
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        connect_args=connect_args,
        pool_pre_ping=True,
        pool_recycle=280,
        pool_size=5,
        max_overflow=10,
    )
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    print("[DB] Engine created successfully.")
except Exception as e:
    print(f"[DB] FATAL: Could not create engine: {e}")
    engine = None
    SessionLocal = None

Base = declarative_base()

def get_db():
    if SessionLocal is None:
        raise RuntimeError("Database is not available. Check DB environment variables.")
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
