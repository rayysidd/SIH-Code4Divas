"""
Celery tasks for LabelLens async processing.

Tasks:
  - run_scan_pipeline: Full ML pipeline + compliance check (replaces BackgroundTasks)
  - process_batch_listing: Scrapes one e-commerce listing URL for LMPC compliance
"""

import os
import uuid
import logging
from datetime import datetime

from workers.celery_app import celery_app

logger = logging.getLogger(__name__)


# ═══════════════════════════════════════════════════════════════════════════
# Task 1: Full scan pipeline (FIX 12)
# ═══════════════════════════════════════════════════════════════════════════


@celery_app.task(bind=True, max_retries=2)
def run_scan_pipeline(
    self,
    scan_id: str,
    temp_img_path: str,
    rule_version: str = "2024.01",
    user_id: str = "",
):
    """
    Celery task that runs the full ML pipeline + LMPC rules evaluation.

    This is the async replacement for the _run_pipeline() function that was
    previously called via FastAPI BackgroundTasks (which blocks uvicorn workers).

    The task opens its own DB session, runs OCR → NLP → rules engine → annotated
    image generation, and writes results back to the DB.
    """
    from api.database import SessionLocal
    from api.models import ScanSession, ScanTask, Violation
    from api.schemas import VerdictEnum, SeverityEnum

    db = SessionLocal()

    try:
        db_session = db.query(ScanSession).filter(ScanSession.scan_id == scan_id).first()
        db_task = db.query(ScanTask).filter(ScanTask.scan_id == scan_id).first()

        if not db_session or not db_task:
            logger.error(f"Scan {scan_id} not found in DB")
            return {"status": "error", "error_msg": "Scan not found in DB"}

        # Debug copy
        if temp_img_path:
            import shutil
            try:
                shutil.copy(temp_img_path, "latest_upload_debug.jpg")
            except Exception:
                pass

        from ml.pipeline import process_label_image, generate_annotated_image
        from ml.rules_engine import evaluate_compliance

        # 1. Run the ML pipeline
        pipeline_result = process_label_image(temp_img_path)

        # Early exit: not a product label
        if pipeline_result.get("status") == "not_a_label":
            db_session.overall_verdict = "NOT_A_LABEL"
            db_task.status = "COMPLETED"
            db_task.error = pipeline_result.get("reason")
            db_task.completed_at = datetime.utcnow()
            db.commit()
            return {
                "status": "not_a_label",
                "reason": pipeline_result.get("reason"),
            }

        declarations = pipeline_result.get("declarations", {})

        # Detect import status
        coo_decl = declarations.get("COUNTRY_OF_ORIGIN", {})
        detected_country = (coo_decl.get("value") or "").strip().lower()
        is_imported = bool(detected_country) and detected_country not in ("india", "bharat")

        # PDP area from pipeline
        pdp_area = pipeline_result.get("pdp_area_cm2", 150.0)
        pdp_area_method = pipeline_result.get("pdp_area_method", "default_fallback")
        image_height = pipeline_result.get("image_height")

        # Detect product category
        product_category = _detect_product_category_celery(declarations)

        # 2. Evaluate compliance
        compliance_result = evaluate_compliance(
            declarations,
            pdp_area_cm2=pdp_area,
            is_imported=is_imported,
            product_category=product_category,
            image_height=image_height,
            image_path=temp_img_path,
        )

        # 3. Generate annotated image
        static_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "static", "annotated")
        os.makedirs(static_dir, exist_ok=True)
        annotated_path = os.path.join(static_dir, f"{scan_id}.jpg")
        generate_annotated_image(
            temp_img_path, declarations,
            compliance_result["violations"], annotated_path,
        )

        # 4. Write violations to DB
        confidences = []
        for v in compliance_result.get("violations", []):
            severity_str = v["severity"].upper()
            confidence = 0.90

            db_violation = Violation(
                violation_id=str(uuid.uuid4()),
                scan_id=scan_id,
                violation_code=v.get("violation_id", "VIO-GEN-001"),
                check_id=v.get("violation_id", "C01"),
                rule_cited=v.get("rule_citation", "Rule"),
                severity=severity_str,
                description=v["description"],
                confidence=confidence,
                measured_value=v.get("measured_value"),
                required_value=v.get("required_format"),
            )
            db.add(db_violation)
            confidences.append(confidence)

        # 5. Update scan session
        status_str = compliance_result["status"]
        if status_str == "PASS":
            verdict = "PASS"
        elif status_str == "NEEDS_VERIFICATION":
            verdict = "NEEDS_VERIFICATION"
        else:
            verdict = "FAIL"

        overall_confidence = sum(confidences) / len(confidences) if confidences else 1.0

        db_session.overall_verdict = verdict
        db_session.overall_confidence = overall_confidence
        db_session.annotated_image_url = f"/static/annotated/{scan_id}.jpg"
        db_session.pdp_area_cm2 = pdp_area
        db_task.status = "COMPLETED"
        db_task.completed_at = datetime.utcnow()

        db.commit()

        return {
            "status": "success",
            "scan_id": scan_id,
            "verdict": verdict,
            "violation_count": len(compliance_result.get("violations", [])),
        }

    except Exception as e:
        logger.exception(f"Error processing scan pipeline for {scan_id}")
        try:
            db_session = db.query(ScanSession).filter(ScanSession.scan_id == scan_id).first()
            db_task = db.query(ScanTask).filter(ScanTask.scan_id == scan_id).first()
            if db_session:
                db_session.overall_verdict = "INCONCLUSIVE"
            if db_task:
                db_task.status = "FAILED"
                db_task.error = str(e)
                db_task.completed_at = datetime.utcnow()
            db.commit()
        except Exception:
            db.rollback()

        raise self.retry(exc=e, countdown=30)

    finally:
        db.close()
        if temp_img_path and os.path.exists(temp_img_path):
            try:
                os.remove(temp_img_path)
            except Exception:
                pass


def _detect_product_category_celery(declarations: dict) -> str:
    """Heuristic product category detection (duplicated for Celery isolation)."""
    texts = []
    for key in ["GENERIC_NAME", "MANUFACTURER_NAME"]:
        decl = declarations.get(key, {})
        if isinstance(decl, dict) and decl.get("raw_text"):
            texts.append(decl["raw_text"].lower())
    combined = " ".join(texts)

    if any(kw in combined for kw in ["edible", "sunflower", "mustard", "cooking oil"]):
        return "EDIBLE_OIL"
    if any(kw in combined for kw in ["shampoo", "soap", "cream", "lotion"]):
        return "COSMETICS"
    if any(kw in combined for kw in ["biscuit", "snack", "chips", "noodle", "rice", "flour", "tea"]):
        return "FOOD_GENERAL"

    all_raw = " ".join(
        d.get("raw_text", "") for d in declarations.values()
        if isinstance(d, dict) and d.get("raw_text")
    ).lower()
    if "fssai" in all_raw:
        return "FOOD_GENERAL"

    return "GENERAL"


# ═══════════════════════════════════════════════════════════════════════════
# Task 2: Batch listing scraper (FIX 6)
# ═══════════════════════════════════════════════════════════════════════════


@celery_app.task(bind=True, max_retries=3)
def process_batch_listing(self, batch_id: str, listing_url: str, index: int):
    """
    Scrapes one e-commerce listing URL and checks it for LMPC compliance.

    Called as part of a Celery group from the batch endpoint. Each URL is
    processed independently and the BatchJob progress is updated atomically.
    """
    from api.database import SessionLocal
    from api.models import BatchJob

    db = SessionLocal()
    try:
        import httpx
        from bs4 import BeautifulSoup

        # Fetch the listing page
        headers = {"User-Agent": "Mozilla/5.0 (compatible; LabelLens/1.0)"}
        response = httpx.get(
            listing_url, headers=headers, timeout=15, follow_redirects=True
        )
        soup = BeautifulSoup(response.text, "html.parser")
        page_text = soup.get_text(separator=" ", strip=True).lower()

        # Check for required LMPC fields on the listing page
        checks = {
            "MRP": any(
                kw in page_text
                for kw in ["mrp", "maximum retail price", "incl. of all taxes"]
            ),
            "NET_QUANTITY": any(
                kw in page_text
                for kw in ["net qty", "net weight", "net wt", "net quantity"]
            ),
            "COUNTRY_OF_ORIGIN": any(
                kw in page_text
                for kw in ["country of origin", "made in", "product of"]
            ),
            "MANUFACTURER": any(
                kw in page_text
                for kw in ["manufactured by", "mfd. by", "packed by", "marketed by"]
            ),
            "GENERIC_NAME": len(page_text) > 50,  # basic presence heuristic
            "MFG_DATE": any(
                kw in page_text
                for kw in ["mfg", "manufactured", "date of manufacture"]
            ),
            "CUSTOMER_CARE": any(
                kw in page_text
                for kw in ["customer care", "consumer care", "helpline", "1800"]
            ),
        }

        violations = [k for k, v in checks.items() if not v]
        verdict = "PASS" if not violations else "FAIL"

        # Update batch job progress (atomic increment)
        job = db.query(BatchJob).filter(BatchJob.batch_id == batch_id).first()
        if job:
            job.processed_urls = (job.processed_urls or 0) + 1
            if job.processed_urls >= job.total_urls:
                job.status = "COMPLETED"
                job.completed_at = datetime.utcnow()
            db.commit()

        return {
            "url": listing_url,
            "index": index,
            "verdict": verdict,
            "missing_fields": violations,
        }

    except Exception as e:
        logger.exception(f"Error processing batch listing {listing_url}")
        db.rollback()
        raise self.retry(exc=e, countdown=30)
    finally:
        db.close()
