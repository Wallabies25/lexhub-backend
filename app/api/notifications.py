from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from ..database import get_db
from ..models import Notification, User
from ..schemas import NotificationResponse
from ..core.security import get_current_user

router = APIRouter(prefix="/notifications", tags=["notifications"])

@router.get("/", response_model=List[NotificationResponse])
def get_user_notifications(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Get all notifications for the current user, ordered by newest first."""
    notifications = db.query(Notification)\
        .filter(Notification.user_id == current_user.id)\
        .order_by(Notification.created_at.desc())\
        .limit(20)\
        .all()
    return notifications

@router.put("/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_as_read(
    notification_id: int, 
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """Mark a specific notification as read."""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()

    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return notification

def create_notification(db: Session, user_id: int, title: str, message: str, notif_type: str, reference_id: int = None):
    """Utility function to create a notification."""
    notif = Notification(
        user_id=user_id,
        title=title,
        message=message,
        type=notif_type,
        reference_id=reference_id
    )
    db.add(notif)
    db.commit()
    return notif
