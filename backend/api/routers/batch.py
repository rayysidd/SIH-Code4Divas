"""
/v1/batch/* — Batch processing endpoints.
Implements: POST /batch/listings (bulk submit up to 10,000 listing URLs)

URLs are enqueued as a Celery group for parallel processing.
Each URL is scraped and checked for LMPC compliance keywords.
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

    Each URL is enqueued as a Celery task (process_batch_listing) for
    parallel processing. The BatchJob record tracks progress.
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

    # Enqueue all URLs as Celery tasks for parallel execution
    try:
        from workers.tasks.scan_task import process_batch_listing
        from celery import group

        task_group = group(
            process_batch_listing.s(batch_id, url, i)
            for i, url in enumerate(request.listing_urls)
        )
        task_group.apply_async()

        # Update status to PROCESSING once tasks are enqueued
        new_job.status = "PROCESSING"
        db.commit()
    except Exception as e:
        # If Celery/Redis is unavailable, leave as QUEUED and log error
        print(f"[Batch] Could not enqueue Celery tasks: {e}. Job {batch_id} remains QUEUED.")

    return {
        "batch_id": batch_id,
        "status": new_job.status,
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


@router.get("/listings", summary="List all batch jobs")
async def list_batch_jobs(
    current_user: TokenData = Depends(require_role("QA_MANAGER")),
    db: Session = Depends(get_db),
):
    """
    Return all batch jobs for the current user, newest first.
    """
    jobs = (
        db.query(BatchJob)
        .filter(BatchJob.submitted_by == current_user.user_id)
        .order_by(BatchJob.created_at.desc())
        .all()
    )
    return [
        {
            "batch_id": j.batch_id,
            "status": j.status,
            "total_urls": j.total_urls,
            "processed": j.processed_urls,
            "created_at": j.created_at.isoformat() + "Z" if j.created_at else None,
            "completed_at": j.completed_at.isoformat() + "Z" if j.completed_at else None,
        }
        for j in jobs
    ]
