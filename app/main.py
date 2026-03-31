from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session

from .database import engine, Base
from .api import auth, users, lawyers, consultations, chat, admin, blogs, forum, statutes, cases, reports, notifications
from fastapi.staticfiles import StaticFiles
import os

app = FastAPI(title="LexHub API", description="Python backend for LexHub frontend")

# ============================================================
# STEP 1: CORS MIDDLEWARE MUST BE FIRST - before everything else
# Using allow_origins=["*"] to nuke CORS entirely for now.
# NOTE: When allow_origins=["*"], allow_credentials MUST be False.
# We handle auth via Bearer token in Authorization header, not cookies,
# so this is safe.
# ============================================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# ============================================================
# STEP 2: Mount static files AFTER middleware
# ============================================================
static_dir = os.path.join(os.path.dirname(__file__), "static")
if not os.path.exists(static_dir):
    os.makedirs(static_dir, exist_ok=True)
app.mount("/static", StaticFiles(directory=static_dir), name="static")

# ============================================================
# STEP 3: Create DB tables on startup (safe - won't drop existing data)
# Wrapped in try/except so a DB error doesn't kill CORS headers
# ============================================================
@app.on_event("startup")
async def startup_event():
    try:
        Base.metadata.create_all(bind=engine)
        print("Database tables verified/created successfully.")
    except Exception as e:
        print(f"WARNING: DB table creation failed: {e}")
        print("App will still run - tables may already exist.")

# ============================================================
# STEP 4: Register all routers
# ============================================================
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(lawyers.router)
app.include_router(consultations.router)
app.include_router(chat.router)
app.include_router(admin.router)
app.include_router(blogs.router)
app.include_router(forum.router)
app.include_router(statutes.router)
app.include_router(cases.router)
app.include_router(reports.router)
app.include_router(notifications.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to LexHub Python API", "status": "running"}

@app.get("/health")
def health_check():
    """Health check endpoint - use this to verify backend is live"""
    return {"status": "healthy", "cors": "open"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8080, reload=True)
