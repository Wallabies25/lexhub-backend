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

# Aiven REQUIRES SSL. We use ssl_disabled=False + ssl_verify_cert=False
# so we get encrypted connection without needing a .pem CA file.
# ssl_verify_identity=False skips hostname verification (safe for Render).
if IS_AIVEN:
    connect_args = {
        "ssl_disabled": False,
        "ssl_verify_cert": False,
        "ssl_verify_identity": False,
    }
    print(f"[DB] Aiven SSL mode (no CA file needed). {DB_HOST}:{DB_PORT}/{DB_NAME}")
else:
    connect_args = {}
    print(f"[DB] Local MySQL. {DB_HOST}:{DB_PORT}/{DB_NAME}")

try:
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        connect_args=connect_args,
        pool_pre_ping=True,     # ping before using pooled connection
        pool_recycle=280,       # recycle before Aiven's 5-min idle timeout
        pool_size=5,
        max_overflow=10,
    )
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    print("[DB] Engine created OK.")
except Exception as e:
    print(f"[DB] FATAL engine creation failed: {e}")
    engine = None
    SessionLocal = None

Base = declarative_base()

def get_db():
    if SessionLocal is None:
        raise RuntimeError("DB unavailable — check Render environment variables.")
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
