from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime, date

class LawyerDetails(BaseModel):
    phone: Optional[str] = None
    license_number: Optional[str] = None
    specialty: Optional[str] = None
    cases_handled: Optional[int] = 0
    success_rate: Optional[str] = None
    education: Optional[str] = None

class UserBase(BaseModel):
    name: str
    email: EmailStr
    user_type: str = "user"
    bio: Optional[str] = None

class UserCreate(UserBase):
    password: str
    # Lawyer specific optional fields during registration
    phone: Optional[str] = None
    licenseNumber: Optional[str] = None
    specialty: Optional[str] = None

class UserProfileResponse(UserBase):
    id: int
    joined_date: datetime
    profile_picture: Optional[str] = None
    lawyer_details: Optional[LawyerDetails] = None

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: str
    user_type: str
    id: int

class ConsultationBase(BaseModel):
    lawyer_id: int
    consultation_date: date
    consultation_time: str
    description: Optional[str] = None

class ConsultationCreate(ConsultationBase):
    pass

class ConsultationResponse(ConsultationBase):
    id: int
    user_id: int
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True
