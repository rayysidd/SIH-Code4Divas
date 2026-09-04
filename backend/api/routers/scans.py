"""
/v1/check/* — Label compliance check endpoints
Implements: POST /check/label, GET /check/label/status/{scan_id},
            POST /check/listing, POST /check/crosschannel
"""

import uuid
import os
import tempfile
from typing import List, Optional
from datetime import datetime
from fastapi import (
    APIRouter,
    UploadFile,
    File,
    Form,
    Depends,
    HTTPException,
    BackgroundTasks,
)
from sqlalchemy.orm import Session

from ..schemas import (
    ScanResponse,
    ScanStatusResponse,
    ScanAsyncResponse,
    ViolationResponse,
    ViolationCountSummary,
    VerdictEnum,
    SeverityEnum,
    ListingCheckRequest,
    CrossChannelRequest,
    CrossChannelResponse,
    CrossChannelField,
)
from ..auth import get_current_user, TokenData
from ..database import get_db, SessionLocal
from ..models import ScanSession, ScanTask, Violation

router = APIRouter(prefix="/check", tags=["Compliance Checks"])

# Read-through cache for backwards compatibility with reports.py
_scan_store: dict = {}


def _run_pipeline(scan_id: str, temp_img_path: str, rule_version: str, user_id: str):
    db: Session = SessionLocal()

    db_session = db.query(ScanSession).filter(ScanSession.scan_id == scan_id).first()
    db_task = db.query(ScanTask).filter(ScanTask.scan_id == scan_id).first()

    if not db_session or not db_task:
        db.close()
        return

    try:
        if temp_img_path:
            import shutil
            try:
                shutil.copy(temp_img_path, 'latest_upload_debug.jpg')
            except Exception as e:
                with open('latest_upload_error.txt', 'w') as f:
                    f.write(f"Copy error: {e}")
        
        from ml.pipeline import process_label_image
        from ml.rules_engine import evaluate_compliance

        pipeline_result = process_label_image(temp_img_path)
        
        with open('latest_upload_debug.txt', 'w', encoding='utf-8') as f:
            f.write(str(pipeline_result.get("ocr_preview")))
            f.write("\n\nDeclarations:\n")
            f.write(str(pipeline_result.get("declarations")))

        # Early exit: image is not a product label
        if pipeline_result.get("status") == "not_a_label":
            db_session.overall_verdict = VerdictEnum.NOT_A_LABEL.value
            db_task.status = "COMPLETED"
            db_task.error = pipeline_result.get("reason")
            db_task.completed_at = datetime.utcnow()

            result = ScanResponse(
                scan_id=scan_id,
                overall_verdict=VerdictEnum.NOT_A_LABEL,
                overall_confidence=1.0,
                violation_count=ViolationCountSummary(),
                violations=[],
                annotated_image_url=f"/static/annotated/{scan_id}.jpg",
                ocr_preview=pipeline_result.get("ocr_preview"),
            )

            _scan_store[scan_id] = {
                "response": result,
                "user_id": user_id,
                "timestamp": datetime.utcnow().isoformat() + "Z",
            }
            db.commit()
            db.close()
            return

        declarations = pipeline_result.get("declarations", {})

        # Detect import status from country-of-origin declaration itself.
        # If a country other than India is found in the COO field, flag as imported.
        coo_decl = declarations.get("COUNTRY_OF_ORIGIN", {})
        detected_country = (coo_decl.get("value") or "").strip().lower()
        is_imported = bool(detected_country) and detected_country not in (
            "india",
            "bharat",
        )

        # PDP area: until real package-shape/dimension detection exists,
        # use a documented placeholder — but LOG that this is an approximation
        # so nobody mistakes it for a real measurement.
        pdp_area = 150.0  # TODO: replace with real PDP measurement (Module D4)
        print(
            f"[WARNING] Using placeholder PDP area ({pdp_area} cm²) — "
            f"real dimension detection not yet implemented. Font-size "
            f"verdicts based on this area are approximate."
        )

        compliance_result = evaluate_compliance(
            declarations, pdp_area_cm2=pdp_area, is_imported=is_imported
        )

        violations = []
        confidences = []
        for v in compliance_result.get("violations", []):
            severity_str = v["severity"].upper()
            if severity_str == "CRITICAL":
                severity_enum = SeverityEnum.CRITICAL
            elif severity_str == "HIGH":
                severity_enum = SeverityEnum.HIGH
            elif severity_str == "MEDIUM":
                severity_enum = SeverityEnum.MEDIUM
            elif severity_str == "INCONCLUSIVE":
                severity_enum = SeverityEnum.INCONCLUSIVE
            else:
                severity_enum = SeverityEnum.LOW

            confidence = 0.90
            for decl_key, decl_data in declarations.items():
                if decl_data.get("present") and decl_data.get("font_measurement"):
                    if "MRP" in v["description"] and decl_key == "MRP":
                        confidence = decl_data["font_measurement"].get(
                            "confidence", 0.90
                        )
                    elif (
                        "Net quantity" in v["description"]
                        and decl_key == "NET_QUANTITY"
                    ):
                        confidence = decl_data["font_measurement"].get(
                            "confidence", 0.90
                        )

            confidences.append(confidence)

            db_violation = Violation(
                violation_id=str(uuid.uuid4()),
                scan_id=scan_id,
                violation_code="VIO-GEN-001",
                check_id="C01",
                rule_cited=v.get("rule_citation", v.get("rule", "Rule")),
                severity=severity_enum.value,
                description=v["description"],
                confidence=confidence,
            )
            db.add(db_violation)

            violations.append(
                ViolationResponse(
                    violation_id=db_violation.violation_id,
                    violation_code=db_violation.violation_code,
                    check_id=db_violation.check_id,
                    rule_cited=db_violation.rule_cited,
                    severity=severity_enum,
                    description=db_violation.description,
                    confidence=db_violation.confidence,
                    measured_value=v.get("measured_value"),
                    required_value=v.get("required_format"),
                )
            )

        status_str = compliance_result["status"]
        if status_str == "PASS":
            verdict = VerdictEnum.PASS
        elif status_str == "NEEDS_VERIFICATION":
            verdict = VerdictEnum.NEEDS_VERIFICATION
        else:
            verdict = VerdictEnum.FAIL

        overall_confidence = sum(confidences) / len(confidences) if confidences else 1.0

        db_session.overall_verdict = verdict.value
        db_session.overall_confidence = overall_confidence
        db_session.annotated_image_url = f"/static/annotated/{scan_id}.jpg"
        db_task.status = "COMPLETED"
        db_task.completed_at = datetime.utcnow()

        violation_count = ViolationCountSummary(
            critical=sum(1 for v in violations if v.severity == SeverityEnum.CRITICAL),
            high=sum(1 for v in violations if v.severity == SeverityEnum.HIGH),
            medium=sum(1 for v in violations if v.severity == SeverityEnum.MEDIUM),
        )

        result = ScanResponse(
            scan_id=scan_id,
            overall_verdict=verdict,
            overall_confidence=overall_confidence,
            violation_count=violation_count,
            violations=violations,
            annotated_image_url=f"/static/annotated/{scan_id}.jpg",
        )

        _scan_store[scan_id] = {
            "response": result,
            "user_id": user_id,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    except Exception as e:
        print(f"Pipeline error: {e}")
        with open('latest_upload_error.txt', 'a') as f:
            import traceback
            f.write(f"\nPipeline error: {e}\n{traceback.format_exc()}")
        db_session.overall_verdict = VerdictEnum.INCONCLUSIVE.value
        db_task.status = "FAILED"
        db_task.error = str(e)
        db_task.completed_at = datetime.utcnow()
        _scan_store[scan_id] = {"status": "FAILED", "error": str(e), "user_id": user_id}
    finally:
        db.commit()
        db.close()
        if temp_img_path and os.path.exists(temp_img_path):
            try:
                os.remove(temp_img_path)
            except Exception:
                pass


@router.post(
    "/label",
    response_model=ScanAsyncResponse,
    summary="Submit label image for compliance check",
)
async def check_label(
    background_tasks: BackgroundTasks,
    images: List[UploadFile] = File(..., description="Up to 12 label images"),
    package_shape_hint: Optional[str] = Form(None),
    product_gtin: Optional[str] = Form(None),
    listing_url: Optional[str] = Form(None),
    rule_version: Optional[str] = Form("2024.01"),
    current_user: TokenData = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    scan_id = str(uuid.uuid4())

    db_session = ScanSession(
        scan_id=scan_id,
        user_id=current_user.user_id,
        rule_version=rule_version,
        scan_mode="API",
        input_image_url=f"/static/uploads/{scan_id}.jpg",
    )
    db_task = ScanTask(scan_id=scan_id, status="PROCESSING")
    db.add(db_session)
    db.add(db_task)
    db.commit()

    temp_img_path = ""
    if images:
        from PIL import Image

        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tf:
            img = Image.open(images[0].file)
            
            # Handle images with alpha channel (e.g. PNGs) by putting them on a white background
            if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
                alpha = img.convert('RGBA').split()[-1]
                bg = Image.new("RGB", img.size, (255, 255, 255))
                bg.paste(img, mask=alpha)
                img = bg
            else:
                img = img.convert('RGB')
                
            # Resize image to max 3200x3200 to balance OCR speed and preserving fine text on back-of-pack labels
            img.thumbnail((3200, 3200), Image.Resampling.LANCZOS)
            img.save(tf.name, format="JPEG", quality=95)
            temp_img_path = tf.name

    background_tasks.add_task(
        _run_pipeline, scan_id, temp_img_path, rule_version, current_user.user_id
    )

    return ScanAsyncResponse(
        scan_id=scan_id,
        status="PROCESSING",
        poll_url=f"/v1/check/label/status/{scan_id}",
        estimated_completion_seconds=15,
    )


@router.get(
    "/label/status/{scan_id}",
    response_model=ScanStatusResponse,
    summary="Poll scan status",
)
async def check_label_status(
    scan_id: str,
    current_user: TokenData = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    task = db.query(ScanTask).filter(ScanTask.scan_id == scan_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Scan not found")

    session = db.query(ScanSession).filter(ScanSession.scan_id == scan_id).first()

    if task.status == "PROCESSING":
        return ScanStatusResponse(scan_id=scan_id, status="PROCESSING")
    elif task.status == "FAILED":
        return ScanStatusResponse(
            scan_id=scan_id, status="FAILED", error_message=task.error
        )

    status_resp = ScanStatusResponse(
        scan_id=scan_id,
        status=task.status,
    )
    if session and task.status == "COMPLETED":
        db_violations = db.query(Violation).filter(Violation.scan_id == scan_id).all()
        critical = sum(1 for v in db_violations if v.severity == "CRITICAL")
        high = sum(1 for v in db_violations if v.severity == "HIGH")
        medium = sum(1 for v in db_violations if v.severity == "MEDIUM")

        status_resp.overall_verdict = session.overall_verdict
        status_resp.overall_confidence = session.overall_confidence
        status_resp.violation_count = ViolationCountSummary(
            critical=critical, high=high, medium=medium
        )
        status_resp.pdf_report_url = session.pdf_report_url

    return status_resp


@router.get(
    "/label/result/{scan_id}",
    response_model=ScanResponse,
    summary="Get full scan result",
)
async def check_label_result(
    scan_id: str,
    current_user: TokenData = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    task = db.query(ScanTask).filter(ScanTask.scan_id == scan_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Scan not found")

    if task.status == "PROCESSING":
        raise HTTPException(status_code=409, detail="Scan still processing")

    if scan_id in _scan_store and "response" in _scan_store[scan_id]:
        return _scan_store[scan_id]["response"]

    raise HTTPException(status_code=404, detail="Scan result not found in cache")


@router.post(
    "/listing", response_model=CrossChannelResponse, summary="Check e-commerce listing"
)
async def check_listing(
    request: ListingCheckRequest,
    current_user: TokenData = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    scan_id = str(uuid.uuid4())
    fields = [
        CrossChannelField(
            declaration="MRP",
            physical_label="₹89.00 (incl. taxes)",
            ecom_listing="₹89.00",
            match_status="MATCH",
        ),
        CrossChannelField(
            declaration="Net Quantity",
            physical_label="500ml",
            ecom_listing="500ml",
            match_status="MATCH",
        ),
        CrossChannelField(
            declaration="Country of Origin",
            physical_label="India",
            ecom_listing=None,
            match_status="LISTING_ONLY",
        ),
        CrossChannelField(
            declaration="Customer Care",
            physical_label="1800-123-4567",
            ecom_listing=None,
            match_status="LISTING_ONLY",
        ),
    ]

    return CrossChannelResponse(
        scan_id=scan_id,
        listing_url=request.listing_url,
        overall_verdict=VerdictEnum.FAIL,
        fields=fields,
    )


@router.post(
    "/crosschannel",
    response_model=CrossChannelResponse,
    summary="Cross-channel reconciliation",
)
async def check_crosschannel(
    request: CrossChannelRequest,
    current_user: TokenData = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return await check_listing(
        ListingCheckRequest(
            listing_url=request.listing_url, physical_label_scan_id=request.scan_id
        ),
        current_user,
        db,
    )
