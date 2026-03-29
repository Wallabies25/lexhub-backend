from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import Lawyer, User
from ..schemas import UserProfileResponse, LawyerDetails

router = APIRouter(prefix="/lawyers", tags=["lawyers"])

@router.get("/", response_model=List[UserProfileResponse])
def get_all_lawyers(db: Session = Depends(get_db)):
    lawyers = db.query(User).filter(User.user_type == "lawyer").all()
    return lawyers

@router.get("/{lawyer_id}", response_model=UserProfileResponse)
def get_lawyer_by_id(lawyer_id: int, db: Session = Depends(get_db)):
    lawyer = db.query(User).join(Lawyer).filter(Lawyer.id == lawyer_id).first()
    if not lawyer:
        raise HTTPException(status_code=404, detail="Lawyer not found")
    return lawyer
