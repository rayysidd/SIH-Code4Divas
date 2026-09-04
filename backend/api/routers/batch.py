"""
/v1/batch/* — Batch processing endpoints.
Implements: POST /batch/listings (bulk submit up to 10,000 listing URLs)
"""

import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..schemas import BatchListingsRequest
from ..auth import get_current_user, require_role, TokenData
from ..database import get_db
from ..models import BatchJob

router = APIRouter(prefix="/batch", tags=["Batch Processing"])


@router.post("/listings", summary="Bulk submit listing URLs for overnight audit")
async def batch_listings(
    request: BatchListingsRequest,
    current_user: TokenData = Depends(require_role("QA_MANAGER")),
    db: Session = Depends(get_db)
):
    """
    Bulk submit up to 10,000 listing URLs for overnight audit.
    SRS Appendix A — POST /batch/listings.
    Returns a batch ID for tracking.
    """
    batch_id = f"B{uuid.uuid4().hex[:12].upper()}"

    new_job = BatchJob(
        batch_id=batch_id,
        submitted_by=current_user.user_id,
        total_urls=len(request.listing_urls),
        webhook_url=request.webhook_url,
        report_email=request.report_email,
        status="QUEUED"
    )
    db.add(new_job)
    db.commit()

    return {
        "batch_id": batch_id,
        "status": "QUEUED",
        "total_urls": len(request.listing_urls),
        "webhook_url": request.webhook_url,
        "report_email": request.report_email,
        "estimated_completion": "6-8 hours",
        "message": f"Batch {batch_id} queued with {len(request.listing_urls)} URLs."
    }


@router.get("/listings/{batch_id}", summary="Get batch processing status")
async def get_batch_status(
    batch_id: str,
    current_user: TokenData = Depends(require_role("QA_MANAGER")),
    db: Session = Depends(get_db)
):
    """
    Poll for batch processing completion.
    """
    job = db.query(BatchJob).filter(BatchJob.batch_id == batch_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Batch job not found")
        
    return {
        "batch_id": job.batch_id,
        "status": job.status,
        "processed": job.processed_urls,
        "total": job.total_urls,
        "pending": job.total_urls - job.processed_urls,
        "submitted_at": job.created_at,
        "completed_at": job.completed_at
    }
