from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from .database import engine, Base
from .api import auth, users, lawyers, consultations, chat, admin, blogs, forum, statutes, cases, reports, notifications
from fastapi.staticfiles import StaticFiles
import os

# Initialize database schemas
Base.metadata.create_all(bind=engine)

app = FastAPI(title="LexHub API", description="Python backend for LexHub frontend")

# Mount static files for document downloads
static_dir = os.path.join(os.path.dirname(__file__), "static")
if not os.path.exists(static_dir):
    os.makedirs(static_dir, exist_ok=True)
app.mount("/static", StaticFiles(directory=static_dir), name="static")

# Allow CORS for the frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173", 
        "http://localhost:3000", 
        "https://lexhub-frontdemo.vercel.app", # මෙන්න මේක අනිවාර්යයෙන්ම තියෙන්න ඕනේ
        "https://lexhub-frontdemo-nimhanrds22-2012s-projects.vercel.app" # ඔයාගේ අර දිග Vercel ලින්ක් එකත් දාන්න
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

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
    return {"message": "Welcome to LexHub Python API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8080, reload=True)
