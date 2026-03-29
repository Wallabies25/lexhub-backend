from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from .database import engine, Base
from .api import auth, users, lawyers, consultations

# Initialize database schemas
Base.metadata.create_all(bind=engine)

app = FastAPI(title="LexHub API", description="Python backend for LexHub frontend")

# Allow CORS for the frontend (React Vite default port is 5173)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(lawyers.router)
app.include_router(consultations.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to LexHub Python API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8080, reload=True)
