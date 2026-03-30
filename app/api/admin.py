from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Dict, Any

from ..database import get_db
from ..models import User, Lawyer, Consultation, UserType
from ..core.security import get_current_user, get_password_hash
from ..schemas import UserProfileResponse, UserCreate

router = APIRouter(prefix="/admin", tags=["admin"])

def require_admin(current_user: User = Depends(get_current_user)):
    if current_user.user_type.value != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions. Admin only."
        )
    return current_user

@router.get("/stats", response_model=Dict[str, Any])
def get_platform_stats(admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    total_users = db.query(User).filter(User.user_type == "user").count()
    total_lawyers = db.query(User).filter(User.user_type == "lawyer").count()
    total_consultations = db.query(Consultation).count()
    
    # Extra stats
    pending_consultations = db.query(Consultation).filter(Consultation.status == "pending").count()
    
    return {
        "total_users": total_users,
        "total_lawyers": total_lawyers,
        "total_consultations": total_consultations,
        "pending_consultations": pending_consultations
    }

@router.get("/users", response_model=List[UserProfileResponse])
def get_all_users(admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    # Returns all standard users
    return db.query(User).filter(User.user_type == "user").all()

@router.get("/lawyers", response_model=List[UserProfileResponse])
def get_all_lawyers(admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    # Returns all lawyers (User models with lawyer_details populated)
    return db.query(User).filter(User.user_type == "lawyer").all()

@router.get("/admins", response_model=List[UserProfileResponse])
def get_all_admins(admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    return db.query(User).filter(User.user_type == "admin").all()

@router.post("/users", response_model=UserProfileResponse)
def create_user_as_admin(user: UserCreate, admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    hashed_pass = get_password_hash(user.password)
    new_user = User(
        name=user.name,
        email=user.email,
        hashed_password=hashed_pass,
        user_type=user.user_type
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    if new_user.user_type == UserType.lawyer.value:
        lawyer_profile = Lawyer(
            user_id=new_user.id,
            phone=user.phone,
            license_number=user.licenseNumber,
            specialty=user.specialty
        )
        db.add(lawyer_profile)
        db.commit()
        
    return new_user

@router.delete("/users/{user_id}")
def delete_user(user_id: int, admin: User = Depends(require_admin), db: Session = Depends(get_db)):
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Cannot delete your own admin account")
        
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Delete related records
    if user.user_type.value == "lawyer":
        lawyer = db.query(Lawyer).filter(Lawyer.user_id == user.id).first()
        if lawyer:
            # Delete their consultations first
            db.query(Consultation).filter(Consultation.lawyer_id == lawyer.id).delete()
            db.delete(lawyer)
    else:
        # Delete user's consultations
        db.query(Consultation).filter(Consultation.user_id == user.id).delete()
        
    db.delete(user)
    db.commit()
    return {"message": "User deleted successfully"}
