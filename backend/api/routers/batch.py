"""
/v1/batch/* — Batch processing endpoints.
Implements: POST /batch/listings (bulk submit up to 10,000 listing URLs)

URLs are enqueued as a Celery group for parallel processing.
Each URL is scraped and checked for LMPC compliance keywords.
"""

import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..schemas import BatchListingsRequest
from ..auth import get_current_user, require_role, TokenData
from ..database import get_db
from ..models import BatchJob, BatchListingResult

router = APIRouter(prefix="/batch", tags=["Batch Processing"])


class SingleListingCheckRequest(BaseModel):
    listing_url: str



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

    # Enqueue all URLs as Celery tasks for parallel execution if Redis is available
    try:
        from workers.celery_app import is_redis_available
        if is_redis_available():
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
        else:
            print(f"[Batch] Redis broker not running. Job {batch_id} remains QUEUED.")
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


@router.post("/listings/check", summary="Synchronous single-URL e-commerce compliance check")
async def check_single_listing(
    body: SingleListingCheckRequest,
    current_user: TokenData = Depends(require_role("ECOM_LEAD")),
    db: Session = Depends(get_db),
):
    """
    Synchronous single-URL check without Celery/BatchJob.
    Evaluates LMPC keyword declarations and writes BatchListingResult with batch_id=None.
    """
    from workers.tasks.scan_task import evaluate_listing_url

    res = evaluate_listing_url(body.listing_url)
    verdict = res["verdict"]
    missing_fields = res["missing_fields"]

    record = BatchListingResult(
        id=str(uuid.uuid4()),
        batch_id=None,
        listing_url=body.listing_url,
        index=None,
        verdict=verdict,
        missing_fields=missing_fields,
        checked_by=current_user.user_id,
        checked_at=datetime.utcnow(),
    )
    db.add(record)
    db.commit()

    return {
        "id": record.id,
        "listing_url": body.listing_url,
        "verdict": verdict,
        "missing_fields": missing_fields,
        "checked_at": record.checked_at.isoformat() + "Z" if record.checked_at else None,
    }


@router.get("/listings/{batch_id}/results", summary="Get all results for a batch job")
async def get_batch_results(
    batch_id: str,
    current_user: TokenData = Depends(require_role("QA_MANAGER")),
    db: Session = Depends(get_db),
):
    """
    Returns all BatchListingResult rows for that batch_id.
    """
    results = (
        db.query(BatchListingResult)
        .filter(BatchListingResult.batch_id == batch_id)
        .order_by(BatchListingResult.index.asc().nullslast())
        .all()
    )
    return [
        {
            "id": r.id,
            "batch_id": r.batch_id,
            "listing_url": r.listing_url,
            "index": r.index,
            "verdict": r.verdict,
            "missing_fields": r.missing_fields or [],
            "checked_by": r.checked_by,
            "checked_at": r.checked_at.isoformat() + "Z" if r.checked_at else None,
        }
        for r in results
    ]

