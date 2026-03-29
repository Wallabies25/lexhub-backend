from sqlalchemy import Column, Integer, String, Enum, ForeignKey, Date, DateTime, Text, Boolean
from sqlalchemy.orm import relationship
from datetime import datetime, date, time
from .database import Base
from .database import Base
import enum

class UserType(str, enum.Enum):
    user = "user"
    lawyer = "lawyer"
    admin = "admin"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    user_type = Column(Enum(UserType), default=UserType.user)
    joined_date = Column(DateTime, default=datetime.utcnow)
    profile_picture = Column(String(500), nullable=True)
    bio = Column(Text, nullable=True)

    lawyer_details = relationship("Lawyer", back_populates="user", uselist=False)

class Lawyer(Base):
    __tablename__ = "lawyers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    phone = Column(String(50), nullable=True)
    license_number = Column(String(100), nullable=True)
    specialty = Column(String(255), nullable=True)
    cases_handled = Column(Integer, default=0)
    success_rate = Column(String(10), nullable=True)
    education = Column(String(255), nullable=True)
    
    user = relationship("User", back_populates="lawyer_details")
    consultations = relationship("Consultation", back_populates="lawyer")

class Consultation(Base):
    __tablename__ = "consultations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    lawyer_id = Column(Integer, ForeignKey("lawyers.id"))
    status = Column(String(50), default="pending")  # pending, confirmed, completed, cancelled
    consultation_date = Column(Date, nullable=False)
    consultation_time = Column(String(20), nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", backref="consultations")
    lawyer = relationship("Lawyer", back_populates="consultations")
