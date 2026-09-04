"""
/v1/auth/* — Authentication endpoints.
"""

import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import User, InviteCode, AuditLog
from ..auth import (
    UserLogin, UserCreate, Token, TokenData, InviteCodeCreate,
    get_password_hash, verify_password,
    create_access_token, create_refresh_token,
    get_current_user, decode_token, require_role,
    generate_invite_code, TRUSTED_PLATFORM_DOMAINS,
    log_audit_event
)

router = APIRouter(prefix="/auth", tags=["Authentication"])

class RefreshRequest(BaseModel):
    refresh_token: str

# ── Role-Friendly Display Names ─────────────────────────────────────────────

_ROLE_MESSAGES: dict[str, str] = {
    "CITIZEN": "Registered as Citizen Reporter. Contact your department for officer access.",
    "ECOM_LEAD": "Registered as E-Commerce Platform Lead based on your verified email domain.",
    "INSPECTOR": "Registered as Legal Metrology Inspector via invite code.",
    "QA_MANAGER": "Registered as QA Manager via invite code.",
    "ADMIN": "Registered as System Administrator via invite code.",
}

@router.post("/login", response_model=Token, summary="Login")
async def login(creds: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == creds.username).first()
    if not user or not verify_password(creds.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account deactivated — contact your administrator",
        )

    log_audit_event(db, "LOGIN", actor_user_id=user.user_id, actor_username=user.username)

    token_data = {"sub": user.user_id, "role": user.role}
    return Token(
        access_token=create_access_token(token_data),
        refresh_token=create_refresh_token(token_data),
    )

@router.post("/refresh", response_model=Token, summary="Refresh tokens")
async def refresh_tokens(body: RefreshRequest):
    token_data = decode_token(body.refresh_token)
    new_token_data = {"sub": token_data.user_id, "role": token_data.role}
    return Token(
        access_token=create_access_token(new_token_data),
        refresh_token=create_refresh_token(new_token_data),
    )

@router.post("/register", summary="Register new user")
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == user_data.username).first():
        raise HTTPException(status_code=400, detail="Username already exists")
    
    if db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(status_code=400, detail="Email already exists")

    user_id = str(uuid.uuid4())
    assigned_role = "CITIZEN"
    assigned_district = None

    if user_data.invite_code:
        invite = db.query(InviteCode).filter(InviteCode.code == user_data.invite_code).first()
        if not invite:
            raise HTTPException(status_code=400, detail="Invalid invite code")
        if invite.used:
            raise HTTPException(status_code=400, detail="Invite code has already been used")
        
        import datetime as dt
        if invite.expires_at.replace(tzinfo=None) < dt.datetime.utcnow():
            raise HTTPException(status_code=400, detail="Invite code has expired")

        assigned_role = invite.role
        assigned_district = invite.district
    else:
        email_domain = user_data.email.split("@")[-1].lower() if "@" in user_data.email else ""
        if email_domain in TRUSTED_PLATFORM_DOMAINS:
            assigned_role = "ECOM_LEAD"

    new_user = User(
        user_id=user_id,
        username=user_data.username,
        full_name=user_data.full_name,
        email=user_data.email,
        password_hash=get_password_hash(user_data.password),
        role=assigned_role,
        district=assigned_district,
        is_active=True
    )
    db.add(new_user)
    db.flush()

    if user_data.invite_code:
        invite.used = True
        invite.used_by = user_id

    db.commit()

    log_audit_event(db, "REGISTER", actor_user_id=user_id, actor_username=user_data.username, target=user_id, details=f"Assigned role: {assigned_role}")

    token_data = {"sub": user_id, "role": assigned_role}
    return {
        "user_id": user_id,
        "username": user_data.username,
        "role": assigned_role,
        "district": assigned_district,
        "message": _ROLE_MESSAGES.get(assigned_role, f"Registered as {assigned_role}."),
        "access_token": create_access_token(token_data),
        "refresh_token": create_refresh_token(token_data),
        "token_type": "bearer",
    }

@router.post("/invite-codes", summary="Generate invite code (ADMIN only)", dependencies=[Depends(require_role("ADMIN"))])
async def create_invite_code(body: InviteCodeCreate, current_user: TokenData = Depends(get_current_user), db: Session = Depends(get_db)):
    valid_roles = {"INSPECTOR", "QA_MANAGER", "ADMIN"}
    if body.role not in valid_roles:
        raise HTTPException(status_code=400, detail=f"Invalid role. Must be one of: {', '.join(sorted(valid_roles))}")

    code = generate_invite_code(db, role=body.role, district=body.district, issued_by=current_user.user_id)
    
    admin_user = db.query(User).filter(User.user_id == current_user.user_id).first()
    admin_username = admin_user.username if admin_user else "admin"
    log_audit_event(db, "INVITE_CODE_ISSUED", actor_user_id=current_user.user_id, actor_username=admin_username, target=code)

    invite = db.query(InviteCode).filter(InviteCode.code == code).first()
    return {
        "invite_code": code,
        "role": invite.role,
        "district": invite.district,
        "issued_at": invite.issued_at,
        "expires_at": invite.expires_at,
    }

@router.get("/invite-codes", summary="List all invite codes (ADMIN only)", dependencies=[Depends(require_role("ADMIN"))])
async def list_invite_codes(db: Session = Depends(get_db)):
    return db.query(InviteCode).all()

@router.delete("/invite-codes/{code}", summary="Revoke an unused invite code (ADMIN only)", dependencies=[Depends(require_role("ADMIN"))])
async def delete_invite_code(code: str, current_user: TokenData = Depends(get_current_user), db: Session = Depends(get_db)):
    invite = db.query(InviteCode).filter(InviteCode.code == code).first()
    if not invite:
        raise HTTPException(status_code=404, detail="Invite code not found")
    if invite.used:
        raise HTTPException(status_code=400, detail="Cannot revoke an already used code")
    
    db.delete(invite)
    db.commit()

    admin_user = db.query(User).filter(User.user_id == current_user.user_id).first()
    admin_username = admin_user.username if admin_user else "admin"
    log_audit_event(db, "INVITE_CODE_REVOKED", actor_user_id=current_user.user_id, actor_username=admin_username, target=code)
    return {"message": "Invite code revoked successfully"}

@router.get("/me", summary="Get current user profile")
async def get_me(current_user: TokenData = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == current_user.user_id).first()
    if user:
        return {
            "user_id": user.user_id,
            "username": user.username,
            "full_name": user.full_name,
            "role": user.role,
        }
    return {"user_id": current_user.user_id, "role": current_user.role, "username": "", "full_name": ""}

@router.get("/users", summary="List all users (ADMIN only)", dependencies=[Depends(require_role("ADMIN"))])
async def list_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    users_list = []
    for u in users:
        users_list.append({
            "user_id": u.user_id,
            "username": u.username,
            "full_name": u.full_name,
            "email": u.email,
            "role": u.role,
            "district": u.district,
            "is_active": u.is_active,
            "created_at": u.created_at
        })
    return users_list

class StatusUpdate(BaseModel):
    is_active: bool

class RoleUpdate(BaseModel):
    role: str
    district: str | None = None

@router.patch("/users/{user_id}/status", summary="Toggle user active status (ADMIN only)", dependencies=[Depends(require_role("ADMIN"))])
async def update_user_status(user_id: str, body: StatusUpdate, current_user: TokenData = Depends(get_current_user), db: Session = Depends(get_db)):
    if user_id == current_user.user_id:
        raise HTTPException(status_code=400, detail="Cannot deactivate your own account")
        
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.is_active = body.is_active
    db.commit()

    admin_user = db.query(User).filter(User.user_id == current_user.user_id).first()
    admin_username = admin_user.username if admin_user else "admin"

    action = "USER_REACTIVATED" if body.is_active else "USER_DEACTIVATED"
    log_audit_event(db, action, actor_user_id=current_user.user_id, actor_username=admin_username, target=user_id)
    return {"message": f"User status updated to {body.is_active}"}

@router.patch("/users/{user_id}/role", summary="Update user role (ADMIN only)", dependencies=[Depends(require_role("ADMIN"))])
async def update_user_role(user_id: str, body: RoleUpdate, current_user: TokenData = Depends(get_current_user), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    old_role = user.role
    user.role = body.role
    user.district = body.district
    db.commit()

    admin_user = db.query(User).filter(User.user_id == current_user.user_id).first()
    admin_username = admin_user.username if admin_user else "admin"

    log_audit_event(db, "ROLE_CHANGED", actor_user_id=current_user.user_id, actor_username=admin_username, target=user_id, details=f"{old_role} -> {body.role}")
    return {"message": "User role updated successfully"}

from typing import Optional

@router.get("/audit-log", summary="Get audit log (ADMIN only)", dependencies=[Depends(require_role("ADMIN"))])
async def get_audit_log(
    action: Optional[str] = None,
    actor_user_id: Optional[str] = None,
    since: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(AuditLog)
    if action:
        query = query.filter(AuditLog.action == action)
    if actor_user_id:
        query = query.filter(AuditLog.actor_user_id == actor_user_id)
    if since:
        try:
            since_dt = datetime.fromisoformat(since.replace("Z", "+00:00"))
            query = query.filter(AuditLog.timestamp >= since_dt)
        except ValueError:
            pass
    
    results = query.order_by(AuditLog.timestamp.desc()).all()
    return results
