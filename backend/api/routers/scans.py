"""
/v1/check/* — Label compliance check endpoints
Implements: POST /check/label, GET /check/label/status/{scan_id},
            POST /check/listing, POST /check/crosschannel
"""

import uuid
import os
import re
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

        from ml.pipeline import process_label_image, generate_annotated_image
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
        coo_decl = declarations.get("COUNTRY_OF_ORIGIN", {})
        detected_country = (coo_decl.get("value") or "").strip().lower()
        is_imported = bool(detected_country) and detected_country not in (
            "india",
            "bharat",
        )

        # PDP area from pipeline (real estimation via barcode or heuristic)
        pdp_area = pipeline_result.get("pdp_area_cm2", 150.0)
        pdp_area_method = pipeline_result.get("pdp_area_method", "default_fallback")
        image_height = pipeline_result.get("image_height")

        print(
            f"[PDP Area] {pdp_area} cm² (method: {pdp_area_method})"
        )

        # Detect product category heuristically from declarations
        product_category = _detect_product_category(declarations)

        compliance_result = evaluate_compliance(
            declarations,
            pdp_area_cm2=pdp_area,
            is_imported=is_imported,
            product_category=product_category,
            image_height=image_height,
            image_path=temp_img_path,
        )

        # Generate annotated image with bounding boxes
        annotated_dir = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "static", "annotated"
        )
        os.makedirs(annotated_dir, exist_ok=True)
        annotated_path = os.path.join(annotated_dir, f"{scan_id}.jpg")
        generate_annotated_image(
            temp_img_path, declarations,
            compliance_result["violations"], annotated_path
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
                if isinstance(decl_data, dict) and decl_data.get("present") and decl_data.get("font_measurement"):
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
                violation_code=v.get("violation_id", "VIO-GEN-001"),
                check_id=v.get("violation_id", "C01"),
                rule_cited=v.get("rule_citation", v.get("rule", "Rule")),
                severity=severity_enum.value,
                description=v["description"],
                confidence=confidence,
                measured_value=v.get("measured_value"),
                required_value=v.get("required_format"),
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
        db_session.pdp_area_cm2 = pdp_area
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
            pdp_area_cm2=pdp_area,
            pdp_area_method=pdp_area_method,
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


def _detect_product_category(declarations: dict) -> str:
    """
    Heuristic product category detection from label declarations.
    Returns one of: FOOD_GENERAL, EDIBLE_OIL, COSMETICS, ELECTRONICS, GENERAL.
    """
    # Check generic name and combined text for category hints
    texts_to_check = []
    for key in ["GENERIC_NAME", "MANUFACTURER_NAME"]:
        decl = declarations.get(key, {})
        if isinstance(decl, dict) and decl.get("raw_text"):
            texts_to_check.append(decl["raw_text"].lower())

    combined = " ".join(texts_to_check)

    oil_keywords = ["edible", "sunflower", "mustard", "groundnut", "coconut oil",
                     "soybean oil", "palm oil", "refined oil", "cooking oil"]
    if any(kw in combined for kw in oil_keywords):
        return "EDIBLE_OIL"

    cosmetics_keywords = ["shampoo", "soap", "cream", "lotion", "face wash",
                          "deodorant", "perfume", "moisturizer", "sunscreen"]
    if any(kw in combined for kw in cosmetics_keywords):
        return "COSMETICS"

    food_keywords = ["biscuit", "snack", "chips", "noodle", "rice", "flour",
                     "sugar", "salt", "spice", "masala", "tea", "coffee",
                     "chocolate", "candy", "milk", "juice", "water",
                     "bread", "cereal", "dal", "atta", "ghee"]
    if any(kw in combined for kw in food_keywords):
        return "FOOD_GENERAL"

    # Check for FSSAI mentions (strong food indicator)
    all_raw = " ".join(
        d.get("raw_text", "") for d in declarations.values()
        if isinstance(d, dict) and d.get("raw_text")
    ).lower()
    if "fssai" in all_raw:
        return "FOOD_GENERAL"

    return "GENERAL"


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

    # Try to use Celery for async processing; fall back to BackgroundTasks
    try:
        from workers.tasks.scan_task import run_scan_pipeline
        run_scan_pipeline.delay(scan_id, temp_img_path, rule_version, current_user.user_id)
    except Exception:
        # Celery/Redis not available — fall back to FastAPI BackgroundTasks
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


# ═══════════════════════════════════════════════════════════════════════════
# Scan History & Violations Listing (real DB queries)
# ═══════════════════════════════════════════════════════════════════════════


@router.get(
    "/scans",
    summary="List all scans for the current user",
)
async def list_scans(
    current_user: TokenData = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Return all scans for the authenticated user, ordered newest first.
    """
    rows = (
        db.query(ScanSession)
        .filter(ScanSession.user_id == current_user.user_id)
        .order_by(ScanSession.created_at.desc())
        .all()
    )
    return [
        {
            "scan_id": s.scan_id,
            "overall_verdict": s.overall_verdict or "PROCESSING",
            "overall_confidence": s.overall_confidence or 0.0,
            "created_at": s.created_at.isoformat() + "Z" if s.created_at else None,
            "rule_version": s.rule_version,
        }
        for s in rows
    ]


@router.get(
    "/violations",
    summary="List all violations for the current user's scans",
)
async def list_violations(
    current_user: TokenData = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Return all violations across the user's scans, newest first.
    """
    rows = (
        db.query(Violation)
        .join(ScanSession, Violation.scan_id == ScanSession.scan_id)
        .filter(ScanSession.user_id == current_user.user_id)
        .order_by(Violation.created_at.desc() if hasattr(Violation, 'created_at') else Violation.violation_id.desc())
        .all()
    )
    return [
        {
            "violation_id": v.violation_id,
            "scan_id": v.scan_id,
            "violation_code": v.violation_code,
            "rule_cited": v.rule_cited,
            "severity": v.severity,
            "description": v.description,
            "confidence": v.confidence,
            "measured_value": v.measured_value,
            "required_value": v.required_value,
        }
        for v in rows
    ]


# ═══════════════════════════════════════════════════════════════════════════
# E-Commerce Listing Checker (FIX 13 — real scraper)
# ═══════════════════════════════════════════════════════════════════════════


@router.post(
    "/listing", response_model=CrossChannelResponse, summary="Check e-commerce listing"
)
async def check_listing(
    request: ListingCheckRequest,
    current_user: TokenData = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Scrapes a real e-commerce listing URL and checks for LMPC-required
    declarations (MRP, Net Qty, Country of Origin, Manufacturer, etc.).
    """
    import httpx
    from bs4 import BeautifulSoup

    scan_id = str(uuid.uuid4())

    try:
        headers = {"User-Agent": "Mozilla/5.0 (compatible; LabelLens/1.0)"}
        resp = httpx.get(
            request.listing_url, headers=headers, timeout=15, follow_redirects=True
        )
        soup = BeautifulSoup(resp.text, "html.parser")
        page_text = soup.get_text(separator=" ", strip=True)
        page_lower = page_text.lower()
    except Exception as e:
        raise HTTPException(
            status_code=422, detail=f"Could not fetch listing: {e}"
        )

    def find_field(patterns: list) -> tuple:
        for pat in patterns:
            if pat in page_lower:
                idx = page_lower.index(pat)
                snippet = page_text[max(0, idx - 10) : idx + 60].strip()
                return True, snippet
        return False, None

    fields = []
    checks = [
        (
            "MRP",
            ["mrp", "maximum retail price"],
            "MRP ₹XX (incl. of all taxes)",
        ),
        (
            "Net Quantity",
            ["net qty", "net weight", "net wt", "net quantity", "net content"],
            "Net Qty: X g",
        ),
        (
            "Country of Origin",
            ["country of origin", "made in", "product of"],
            "Country of Origin: India",
        ),
        (
            "Manufacturer",
            ["manufactured by", "mfd. by", "packed by", "marketed by", "brand owner"],
            "Manufactured by: XYZ Ltd",
        ),
        (
            "Manufacturing Date",
            ["mfg", "manufactured", "date of manufacture"],
            "Mfg: MM/YYYY",
        ),
        (
            "Customer Care",
            ["customer care", "consumer care", "helpline", "1800"],
            "1800-XXX-XXXX",
        ),
        (
            "Generic Name",
            ["net qty", "ingredients", "description"],
            "Product description present",
        ),
    ]

    verdict = VerdictEnum.PASS
    for declaration, patterns, required in checks:
        found, snippet = find_field(patterns)
        status = "MATCH" if found else "MISSING"
        if not found:
            verdict = VerdictEnum.FAIL
        fields.append(
            CrossChannelField(
                declaration=declaration,
                physical_label=None,
                ecom_listing=snippet,
                match_status=status,
            )
        )

    return CrossChannelResponse(
        scan_id=scan_id,
        listing_url=request.listing_url,
        overall_verdict=verdict,
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
