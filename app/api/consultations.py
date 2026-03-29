from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import Consultation, User, Lawyer
from ..schemas import ConsultationCreate, ConsultationResponse
from ..core.security import get_current_user

router = APIRouter(prefix="/consultations", tags=["consultations"])

@router.post("/", response_model=ConsultationResponse)
def create_consultation(consultation: ConsultationCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.user_type != "user":
        raise HTTPException(status_code=403, detail="Only standard users can book consultations")

    # Check if lawyer exists
    lawyer = db.query(Lawyer).filter(Lawyer.id == consultation.lawyer_id).first()
    if not lawyer:
        raise HTTPException(status_code=404, detail="Lawyer not found")

    new_consultation = Consultation(
        user_id=current_user.id,
        lawyer_id=consultation.lawyer_id,
        consultation_date=consultation.consultation_date,
        consultation_time=consultation.consultation_time,
        description=consultation.description,
        status="pending"
    )
    db.add(new_consultation)
    db.commit()
    db.refresh(new_consultation)
    return new_consultation

@router.get("/my-consultations", response_model=List[ConsultationResponse])
def get_my_consultations(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if current_user.user_type == "user":
        return db.query(Consultation).filter(Consultation.user_id == current_user.id).all()
    elif current_user.user_type == "lawyer":
        lawyer_profile = db.query(Lawyer).filter(Lawyer.user_id == current_user.id).first()
        if not lawyer_profile:
            return []
        return db.query(Consultation).filter(Consultation.lawyer_id == lawyer_profile.id).all()
    else:
        return db.query(Consultation).all() # Admins see all

@router.put("/{consultation_id}/status", response_model=ConsultationResponse)
def update_consultation_status(consultation_id: int, status: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    consultation = db.query(Consultation).filter(Consultation.id == consultation_id).first()
    if not consultation:
        raise HTTPException(status_code=404, detail="Consultation not found")

    if current_user.user_type == "lawyer":
        lawyer_profile = db.query(Lawyer).filter(Lawyer.user_id == current_user.id).first()
        if not lawyer_profile or consultation.lawyer_id != lawyer_profile.id:
            raise HTTPException(status_code=403, detail="Not authorized to update this consultation")
    elif current_user.user_type == "user":
        if consultation.user_id != current_user.id or status not in ["cancelled"]:
            raise HTTPException(status_code=403, detail="Users can only cancel their own consultations")
            
    consultation.status = status
    db.commit()
    db.refresh(consultation)
    return consultation
