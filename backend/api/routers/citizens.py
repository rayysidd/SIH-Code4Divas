"""
/v1/citizens/* — Citizen reporter endpoints.
Implements: citizen complaint submission (no auth required).
Flow: UIUX_SPEC §6.4 — Citizen Reporter flow.
"""

import uuid
from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, Depends, UploadFile, File, Form
from sqlalchemy.orm import Session

from ..schemas import CitizenReportResponse
from ..auth import get_current_user, require_role, TokenData
from ..database import get_db
from ..models import CitizenReport

router = APIRouter(prefix="/citizens", tags=["Citizen Reports"])


@router.post("/report", response_model=CitizenReportResponse, summary="Submit citizen violation report")
async def submit_citizen_report(
    image: UploadFile = File(..., description="Photo of the product"),
    problem_type: str = Form(..., description="Type of violation observed"),
    description: Optional[str] = Form(None),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    db: Session = Depends(get_db)
):
    """
    Submit a citizen violation report. No authentication required.
    Auto-captures: GPS location, timestamp, photo.
    Returns a tracking ID for follow-up.
    """
    tracking_id = f"LLR-{datetime.utcnow().strftime('%Y%m%d')}-{str(uuid.uuid4())[:4].upper()}"

    report = CitizenReport(
        tracking_id=tracking_id,
        problem_type=problem_type,
        description=description,
        latitude=latitude,
        longitude=longitude,
        status="SUBMITTED"
    )
    db.add(report)
    db.commit()

    return CitizenReportResponse(
        tracking_id=tracking_id,
        status="SUBMITTED",
        message="Your report has been submitted. We'll update you when reviewed.",
    )


@router.get("/report/{tracking_id}", summary="Track citizen report status")
async def track_citizen_report(tracking_id: str, db: Session = Depends(get_db)):
    """
    Check the status of a previously submitted citizen report.
    """
    report = db.query(CitizenReport).filter(CitizenReport.tracking_id == tracking_id).first()
    if not report:
        return {"tracking_id": tracking_id, "status": "NOT_FOUND", "message": "Report not found."}
    return report


@router.get("/reports", summary="List all citizen reports (admin)")
async def list_citizen_reports(
    current_user: TokenData = Depends(require_role("ADMIN")),
    db: Session = Depends(get_db)
):
    """
    Return all citizen reports. Admin-only endpoint.
    Used by the web dashboard's Citizen Reports page.
    """
    return db.query(CitizenReport).order_by(CitizenReport.submitted_at.desc()).all()
