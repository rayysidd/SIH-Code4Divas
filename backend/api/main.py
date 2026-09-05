"""
LabelLens API — Main application entry point.
Automated Legal Metrology (Packaged Commodities) Rules Compliance Verification.
SIH 2026 — Problem Statement SIH26034.

Base URL: https://api.labellens.in/v1
"""

from datetime import datetime, timedelta
from .auth import get_password_hash
from .models import User, InviteCode
from .database import SessionLocal
from alembic import command
from alembic.config import Config
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .routers import (
    scans,
    reports,
    auth_router,
    analytics,
    citizens,
    batch,
    rules_router,
)

app = FastAPI(
    title="LabelLens Backend API",
    description="Automated LMPC Label Compliance Verification API providing computer vision endpoints, "
    "cross-channel reconciliation, batch auditing, citizen reporting, and analytics.",
    version="1.0.0",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

API_V1_PREFIX = "/v1"

# Include routers
app.include_router(auth_router.router, prefix=API_V1_PREFIX)
app.include_router(scans.router, prefix=API_V1_PREFIX)
app.include_router(batch.router, prefix=API_V1_PREFIX)
app.include_router(citizens.router, prefix=API_V1_PREFIX)
app.include_router(reports.router, prefix=API_V1_PREFIX)
app.include_router(analytics.router, prefix=API_V1_PREFIX)
app.include_router(rules_router.router, prefix=API_V1_PREFIX)

# Mount static files for annotated images and uploads
import os as _os
_static_annotated_dir = _os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "..", "static", "annotated")
_os.makedirs(_static_annotated_dir, exist_ok=True)
app.mount("/static/annotated", StaticFiles(directory=_static_annotated_dir), name="annotated")


@app.on_event("startup")
async def run_migrations():
    alembic_cfg = Config("alembic.ini")
    command.upgrade(alembic_cfg, "head")

    db = SessionLocal()
    try:
        if not db.query(User).filter(User.username == "admin").first():
            db.add(
                User(
                    user_id="00000000-0000-0000-0000-000000000001",
                    username="admin",
                    full_name="System Admin",
                    email="admin@labellens.local",
                    role="ADMIN",
                    password_hash=get_password_hash("admin123"),
                    is_active=True,
                )
            )
        if not db.query(User).filter(User.username == "rajan").first():
            db.add(
                User(
                    user_id="00000000-0000-0000-0000-000000000002",
                    username="rajan",
                    full_name="Rajan Tiwari",
                    email="rajan@labellens.local",
                    role="INSPECTOR",
                    password_hash=get_password_hash("inspector123"),
                    is_active=True,
                    district="Mumbai North",
                )
            )
        if not db.query(User).filter(User.username == "priya").first():
            db.add(
                User(
                    user_id="00000000-0000-0000-0000-000000000003",
                    username="priya",
                    full_name="Priya Sharma",
                    email="priya@labellens.local",
                    role="QA_MANAGER",
                    password_hash=get_password_hash("manager123"),
                    is_active=True,
                )
            )

        db.flush()

        if not db.query(InviteCode).filter(InviteCode.code == "INSP-2026-DEMO").first():
            db.add(
                InviteCode(
                    code="INSP-2026-DEMO",
                    role="INSPECTOR",
                    district="Mumbai North",
                    issued_by="00000000-0000-0000-0000-000000000001",
                    used=False,
                    expires_at=datetime.utcnow() + timedelta(days=30),
                )
            )
        if not db.query(InviteCode).filter(InviteCode.code == "QAM-2026-DEMO").first():
            db.add(
                InviteCode(
                    code="QAM-2026-DEMO",
                    role="QA_MANAGER",
                    issued_by="00000000-0000-0000-0000-000000000001",
                    used=False,
                    expires_at=datetime.utcnow() + timedelta(days=30),
                )
            )
        db.commit()
    except Exception as e:
        print(f"Error seeding DB: {e}")
        db.rollback()
    finally:
        db.close()


@app.on_event("startup")
async def startup_ocr_check():
    """Verify Tesseract OCR is available at boot — log loudly if not."""
    from ml.ocr.extractor import verify_ocr_available

    try:
        verify_ocr_available()
    except RuntimeError as e:
        print(f"[STARTUP WARNING] {e}")
        # Do not crash the server — but log loudly so it's impossible to miss
        # during development. In production, consider raising to prevent
        # accepting scans that will silently fail.


# ── Health check (no auth) ───────────────────────────────────────────────────


@app.get("/health", tags=["System"])
def health_check():
    return {"status": "ok", "version": "1.0.0", "rules_version": "LMPC-2026-GSR128E"}


@app.get("/v1/health", tags=["System"])
def health_check_v1():
    return health_check()


@app.get("/", tags=["System"])
def root():
    return {
        "service": "LabelLens API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
    }
