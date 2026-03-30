from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..models import User, ForumPost, ForumReply, ForumLike
from ..schemas import ForumPostCreate, ForumPostResponse, ForumReplyCreate, ForumReplyResponse
from ..core.security import get_current_user
from .notifications import create_notification

router = APIRouter(prefix="/forum", tags=["forum"])

@router.get("/", response_model=List[ForumPostResponse])
def get_posts(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    posts = db.query(ForumPost).order_by(ForumPost.created_at.desc()).all()
    
    result = []
    for post in posts:
        has_liked = db.query(ForumLike).filter(
            ForumLike.post_id == post.id,
            ForumLike.user_id == current_user.id
        ).first() is not None
        
        replies = [
            ForumReplyResponse(
                id=r.id,
                content=r.content,
                post_id=r.post_id,
                user_id=r.user_id,
                created_at=r.created_at,
                author_name=r.user.name,
                author_photo=r.user.profile_picture
            ) for r in post.replies
        ]
        
        result.append(ForumPostResponse(
            id=post.id,
            user_id=post.user_id,
            title=post.title,
            content=post.content,
            category=post.category,
            created_at=post.created_at,
            author_name=post.user.name,
            author_photo=post.user.profile_picture,
            replies_count=len(post.replies),
            likes_count=len(post.likes),
            has_liked=has_liked,
            replies=replies
        ))
    return result

@router.post("/", response_model=ForumPostResponse)
def create_post(post: ForumPostCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_post = ForumPost(
        user_id=current_user.id,
        title=post.title,
        content=post.content,
        category=post.category
    )
    db.add(db_post)
    db.commit()
    db.refresh(db_post)
    
    return ForumPostResponse(
        id=db_post.id,
        user_id=db_post.user_id,
        title=db_post.title,
        content=db_post.content,
        category=db_post.category,
        created_at=db_post.created_at,
        author_name=current_user.name,
        author_photo=current_user.profile_picture,
        replies_count=0,
        likes_count=0,
        has_liked=False,
        replies=[]
    )

@router.post("/{post_id}/reply", response_model=ForumReplyResponse)
def add_reply(post_id: int, reply: ForumReplyCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_post = db.query(ForumPost).filter(ForumPost.id == post_id).first()
    if not db_post:
        raise HTTPException(status_code=404, detail="Post not found")
        
    db_reply = ForumReply(
        post_id=post_id,
        user_id=current_user.id,
        content=reply.content
    )
    db.add(db_reply)
    db.commit()
    db.refresh(db_reply)
    
    # Notify post author BEFORE returning (if not replying to own post)
    if db_post.user_id != current_user.id:
        create_notification(
            db=db,
            user_id=db_post.user_id,
            title="New Reply on Your Post",
            message=f"{current_user.name} replied to your post: '{db_post.title}'",
            notif_type="forum_reply",
            reference_id=post_id
        )

    return ForumReplyResponse(
        id=db_reply.id,
        content=db_reply.content,
        post_id=db_reply.post_id,
        user_id=db_reply.user_id,
        created_at=db_reply.created_at,
        author_name=current_user.name,
        author_photo=current_user.profile_picture
    )

@router.post("/{post_id}/like")
def toggle_like(post_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    db_post = db.query(ForumPost).filter(ForumPost.id == post_id).first()
    if not db_post:
        raise HTTPException(status_code=404, detail="Post not found")
        
    existing_like = db.query(ForumLike).filter(
        ForumLike.post_id == post_id,
        ForumLike.user_id == current_user.id
    ).first()
    
    if existing_like:
        db.delete(existing_like)
        db.commit()
        return {"liked": False}
    else:
        new_like = ForumLike(post_id=post_id, user_id=current_user.id)
        db.add(new_like)
        db.commit()
        # Notify post author
        if db_post.user_id != current_user.id:
            create_notification(
                db=db,
                user_id=db_post.user_id,
                title="New Reaction on Your Post",
                message=f"{current_user.name} liked your forum post: '{db_post.title}'",
                notif_type="forum_reaction",
                reference_id=post_id
            )
        return {"liked": True}
        
@router.get("/user-stats")
def get_user_forum_stats(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Total likes received on all posts by this user
    user_posts = db.query(ForumPost).filter(ForumPost.user_id == current_user.id).all()
    post_ids = [p.id for p in user_posts]
    
    likes_received = db.query(ForumLike).filter(ForumLike.post_id.in_(post_ids)).count() if post_ids else 0
    replies_received = db.query(ForumReply).filter(ForumReply.post_id.in_(post_ids)).count() if post_ids else 0
    
    return {
        "posts_count": len(user_posts),
        "likes_received": likes_received,
        "replies_received": replies_received
    }
