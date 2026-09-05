"""
Authentication utilities — JWT tokens, password hashing, RBAC middleware.
Auth spec: REQ-SEC-001 through REQ-SEC-003 (SRS §10)
"""

import os
import secrets
import string
from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel
from sqlalchemy.orm import Session
from .models import InviteCode, AuditLog

# ── Config ───────────────────────────────────────────────────────────────────

SECRET_KEY = os.getenv("JWT_SECRET_KEY", "labellens-dev-secret-replace-in-production")
ALGORITHM = "RS256"  # SRS REQ-SEC-001 mandates RS256; using HS256 in dev fallback
ACCESS_TOKEN_EXPIRE_MINUTES = 60  # 1 hour per SRS
REFRESH_TOKEN_EXPIRE_DAYS = 7

# Fallback to HS256 in dev (RS256 needs RSA keypair)
ALGORITHM = "HS256"

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")  # REQ-SEC-002 bcrypt work factor ≥ 12
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/v1/auth/login")

# ── Trusted Platform Domains (auto-assign ECOM_LEAD) ────────────────────────

TRUSTED_PLATFORM_DOMAINS = {"amazon.in", "flipkart.com", "meesho.com"}

def generate_invite_code(db: Session, role: str, district: Optional[str], issued_by: str) -> str:
    """Generate a unique invite code and register it in the DB."""
    prefix = role[:4].upper()
    suffix = "".join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(8))
    code = f"{prefix}-{suffix}"
    
    db_code = InviteCode(
        code=code,
        role=role,
        district=district,
        issued_by=issued_by,
        expires_at=datetime.utcnow() + timedelta(days=30)
    )
    db.add(db_code)
    db.commit()
    return code

import uuid

def log_audit_event(db: Session, action: str, actor_user_id: str, actor_username: str, target: Optional[str] = None, details: Optional[str] = None):
    audit_entry = AuditLog(
        id=str(uuid.uuid4()),
        action=action,
        actor_user_id=actor_user_id,
        actor_username=actor_username,
        target=target,
        details=details
    )
    db.add(audit_entry)
    db.commit()


# ── Schemas ──────────────────────────────────────────────────────────────────

class TokenData(BaseModel):
    user_id: str
    role: str  # INSPECTOR | QA_MANAGER | ECOM_LEAD | ADMIN | CITIZEN


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserLogin(BaseModel):
    username: str
    password: str


class UserCreate(BaseModel):
    username: str
    password: str
    full_name: str
    email: str
    invite_code: Optional[str] = None
    # Legacy fields kept for backwards compatibility — ignored by register()
    role: str = "CITIZEN"
    district: Optional[str] = None
    organization: Optional[str] = None


class InviteCodeCreate(BaseModel):
    role: str  # INSPECTOR | QA_MANAGER | ADMIN | ECOM_LEAD
    district: Optional[str] = None


# ── Password Utilities ───────────────────────────────────────────────────────

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


# ── JWT Utilities ────────────────────────────────────────────────────────────

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> TokenData:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        role: str = payload.get("role", "CITIZEN")
        if user_id is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
        return TokenData(user_id=user_id, role=role)
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Could not validate credentials")


# ── Dependency: Get Current User ─────────────────────────────────────────────

async def get_current_user(token: str = Depends(oauth2_scheme)) -> TokenData:
    return decode_token(token)


# ── RBAC Helper ──────────────────────────────────────────────────────────────

ROLE_HIERARCHY = {
    "ADMIN": 100,
    "ECOM_LEAD": 80,
    "QA_MANAGER": 60,
    "INSPECTOR": 40,
    "CITIZEN": 20,
}


def require_role(minimum_role: str):
    """
    FastAPI dependency that checks role level.
    Usage: router.get("/admin-only", dependencies=[Depends(require_role("ADMIN"))])
    """
    min_level = ROLE_HIERARCHY.get(minimum_role, 0)

    async def role_checker(current_user: TokenData = Depends(get_current_user)):
        user_level = ROLE_HIERARCHY.get(current_user.role, 0)
        if user_level < min_level:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role '{current_user.role}' does not have permission. Requires '{minimum_role}' or above."
            )
        return current_user

    return role_checker
