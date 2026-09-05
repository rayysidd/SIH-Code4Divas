"""
ML Pipeline Orchestrator.
Coordinates OCR, Font Measurement, NLP parsing, PDP area estimation,
and annotated image generation.
"""

import os
import re
from typing import Dict, Any, Optional
from .ocr.extractor import (
    extract_text_and_boxes,
    extract_text_sparse,
    extract_text_column_aware,
    extract_barcode_scale,
)
from .nlp.parser import parse_declarations
from .font.measurement import measure_font_height_mm

# ── Label sanity gate ────────────────────────────────────────────────────────
_LMPC_SIGNAL_KEYWORDS = [
    "mrp",
    "net wt",
    "net qty",
    "net quantity",
    "mfg",
    "manufactured",
    "best before",
    "expiry",
    "batch",
    "fssai",
    "consumer care",
    "manufactured by",
    "marketed by",
    "packed by",
    "importer",
    # Extended set — common real-world label phrasing variants
    "nutritional information",
    "ingredients",
    "customer care",
    "use before",
    "mfg lic",
    "fssai lic",
    # Additional real-world variants from user images
    "net weight",
    "nett weight",
    "maximum retail price",
    "manufacturing",
    "lot no",
]


def _looks_like_product_label(ocr_results: list) -> dict:
    """
    Lightweight sanity check: does the extracted text contain ANY signal
    that this is a packaged-commodity label, before running full declaration
    extraction? This is a heuristic, not a trained classifier — its purpose
    is to catch obviously-wrong inputs (electronics boxes, random photos)
    and report a clear message instead of silently returning all-missing
    or (worse) accidentally-matching violations.
    """
    combined_text = " ".join([r["text"] for r in ocr_results]).lower()
    total_chars = len(combined_text.strip())

    if total_chars < 20:
        return {
            "is_likely_label": False,
            "reason": "Very little text detected in image. Ensure the label "
            "is in focus and fills most of the frame.",
        }

    # Strip ALL punctuation AND spaces to make keyword matching bulletproof
    # This ensures 'M . R . P' or 'Mfg . Date' successfully match
    clean_text = re.sub(r'[^a-z0-9]', '', combined_text)
    print(f"[Sanity Gate] Raw text excerpt: {combined_text[:200]}...")

    keyword_hits = sum(1 for kw in _LMPC_SIGNAL_KEYWORDS if kw.replace(' ', '') in clean_text)
    if keyword_hits == 0:
        return {
            "is_likely_label": False,
            "reason": "No Legal Metrology declaration keywords (MRP, Net Qty, "
            "Mfg Date, etc.) were detected. This image may not be a "
            "product label, or the label may be too unclear to read.",
        }

    return {"is_likely_label": True, "reason": None, "keyword_hits": keyword_hits}


# ═══════════════════════════════════════════════════════════════════════════
# PDP Area Estimation (FIX 3)
# ═══════════════════════════════════════════════════════════════════════════


def estimate_pdp_area_cm2(
    image_path: str,
    scale_data: dict,
    package_shape: str = "RECTANGULAR",
) -> tuple:
    """
    Estimates the Principal Display Panel (PDP) area in cm².

    Uses barcode-calibrated mm_per_pixel if available, else falls back to a
    heuristic estimate (typical phone photo of FMCG pack at ~30cm distance).

    Args:
        image_path: Path to the label image.
        scale_data: Output from extract_barcode_scale().
        package_shape: RECTANGULAR or CYLINDRICAL.

    Returns:
        (pdp_area_cm2: float, method_used: str)
    """
    import cv2

    img = cv2.imread(image_path)
    if img is None:
        return 150.0, "default_fallback"

    h_px, w_px = img.shape[:2]

    if scale_data.get("success") and scale_data.get("mm_per_pixel"):
        mm_per_px = scale_data["mm_per_pixel"]
        h_mm = h_px * mm_per_px
        w_mm = w_px * mm_per_px
        # PDP is the face shown — assume full image face is PDP
        area_cm2 = (h_mm / 10) * (w_mm / 10)
        if package_shape == "CYLINDRICAL":
            # 40% rule: we only see ~40% of cylinder surface in one shot
            area_cm2 = area_cm2 * 0.40
        return round(area_cm2, 1), "barcode_calibrated"
    else:
        # Heuristic fallback: typical phone photo of a
        # medium FMCG pack at 30cm distance ≈ 0.08 mm/pixel for 1080p
        HEURISTIC_MM_PER_PX = 0.08
        h_mm = h_px * HEURISTIC_MM_PER_PX
        w_mm = w_px * HEURISTIC_MM_PER_PX
        area_cm2 = (h_mm / 10) * (w_mm / 10)
        return round(area_cm2, 1), "heuristic_fallback"


# ═══════════════════════════════════════════════════════════════════════════
# Annotated Image Generation (FIX 5)
# ═══════════════════════════════════════════════════════════════════════════


def generate_annotated_image(
    image_path: str,
    declarations: dict,
    violations: list,
    output_path: str,
) -> bool:
    """
    Draws colored bounding boxes around detected declarations on the original image.

    Color coding:
        Green   = PASS (field present, no violation)
        Red     = CRITICAL violation
        Orange  = HIGH violation
        Yellow  = MEDIUM / INCONCLUSIVE violation

    Args:
        image_path: Path to the original label image.
        declarations: Output from parse_declarations().
        violations: List of violation dicts from evaluate_compliance().
        output_path: Where to save the annotated JPEG.

    Returns:
        True if file was written successfully, False otherwise.
    """
    import cv2

    img = cv2.imread(image_path)
    if img is None:
        return False

    COLOR_MAP = {
        "PASS": (0, 200, 0),          # Green (BGR)
        "CRITICAL": (0, 0, 220),      # Red
        "HIGH": (0, 100, 220),        # Orange
        "MEDIUM": (0, 200, 220),      # Yellow
        "INCONCLUSIVE": (180, 180, 0),  # Cyan-ish
    }

    # Build a set of field names that have violations, mapped to their severity
    field_violation_severity = {}
    for v in violations:
        desc = v.get("description", "").upper()
        vid = v.get("violation_id", "")
        sev = v.get("severity", "MEDIUM")
        # Map violation IDs and descriptions back to field names
        field_mappings = {
            "V001": "MRP", "V002": "MRP", "V003": "MRP", "V003-INC": "MRP",
            "V015": "MRP",
            "V004": "NET_QUANTITY", "V005": "NET_QUANTITY", "V005-INC": "NET_QUANTITY",
            "V016": "NET_QUANTITY",
            "V006": "MFG_DATE",
            "V007": "COUNTRY_OF_ORIGIN", "V008": "COUNTRY_OF_ORIGIN",
            "V009": "MANUFACTURER_NAME",
            "V010": "GENERIC_NAME",
            "V011": "BEST_BEFORE_DATE",
            "V012": "CUSTOMER_CARE",
            "V013": "VEG_NONVEG_SYMBOL",
            "V014": "UNIT_SALE_PRICE",
        }
        mapped_field = field_mappings.get(vid)
        if mapped_field:
            # Keep the highest severity for each field
            existing = field_violation_severity.get(mapped_field)
            severity_order = {"CRITICAL": 4, "HIGH": 3, "MEDIUM": 2, "INCONCLUSIVE": 1}
            if existing is None or severity_order.get(sev, 0) > severity_order.get(existing, 0):
                field_violation_severity[mapped_field] = sev

    for field_name, decl in declarations.items():
        if not isinstance(decl, dict) or not decl.get("present") or not decl.get("bounding_box"):
            continue
        box = decl["bounding_box"]
        x = int(box.get("x", 0))
        y = int(box.get("y", 0))
        w = int(box.get("w", 0))
        h = int(box.get("h", 0))

        if w <= 0 or h <= 0:
            continue

        # Determine color
        sev = field_violation_severity.get(field_name)
        if sev:
            color = COLOR_MAP.get(sev, COLOR_MAP["MEDIUM"])
        else:
            color = COLOR_MAP["PASS"]

        cv2.rectangle(img, (x, y), (x + w, y + h), color, 2)
        label = field_name.replace("_", " ")
        # Draw label background for readability
        font_scale = 0.4
        thickness = 1
        (tw, th), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, font_scale, thickness)
        cv2.rectangle(img, (x, max(y - th - 6, 0)), (x + tw + 4, max(y - 2, 0)), color, -1)
        cv2.putText(
            img, label, (x + 2, max(y - 5, th + 2)),
            cv2.FONT_HERSHEY_SIMPLEX, font_scale, (255, 255, 255), thickness,
        )

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    cv2.imwrite(output_path, img)
    return os.path.exists(output_path)


# ═══════════════════════════════════════════════════════════════════════════
# Main pipeline
# ═══════════════════════════════════════════════════════════════════════════


def process_label_image(
    image_path: str,
    fallback_reference_mm: Optional[float] = None,
    package_shape: str = "RECTANGULAR",
) -> Dict[str, Any]:
    """
    Runs the full ML pipeline on a label image to extract LMPC declarations.

    Args:
        image_path: Absolute path to the label image.
        fallback_reference_mm: Fallback mm per pixel if no barcode is found.
        package_shape: RECTANGULAR or CYLINDRICAL.

    Returns:
        A dictionary containing the parsed LabelData ready for the Rules Engine.
    """
    # 1. Physical Scale Recovery (Reference Chain)
    scale_data = extract_barcode_scale(image_path)
    mm_per_pixel = scale_data.get("mm_per_pixel")
    confidence = scale_data.get("confidence", 0.8) if scale_data.get("success") else 0.0

    # 2. OCR Extraction — column-aware for declaration parsing (PSM 6)
    ocr_results = extract_text_column_aware(image_path)

    # 2b. Sparse OCR pass (PSM 11) — finds text in any arrangement,
    #     robust for multi-column layouts where PSM 6 scrambles text.
    #     Used only for the sanity gate keyword check, not for declaration parsing.
    sparse_results = extract_text_sparse(image_path)

    # Merge both result sets for the sanity gate (deduplicated by text+position).
    # This maximizes keyword detection: whichever PSM mode catches the text wins.
    seen_texts = {r["text"].lower() for r in ocr_results}
    merged_for_gate = list(ocr_results)
    for sr in sparse_results:
        if sr["text"].lower() not in seen_texts:
            merged_for_gate.append(sr)
            seen_texts.add(sr["text"].lower())

    # 3. Sanity check: does this look like a product label at all?
    label_check = _looks_like_product_label(merged_for_gate)
    if not label_check["is_likely_label"]:
        # Surface what Tesseract actually read so the client can diagnose
        # whether OCR read garbage vs. read fine but missed the keyword list.
        ocr_preview = " ".join([r["text"] for r in merged_for_gate])[:300]
        return {
            "status": "not_a_label",
            "reason": label_check["reason"],
            "ocr_preview": ocr_preview,
            "raw_ocr_count": len(ocr_results),
            "scale_data": scale_data,
            "declarations": {},
        }

    # 4. NLP Parsing (Layout-Aware Heuristics) — pass image_path for VEG/NONVEG
    declarations = parse_declarations(ocr_results, image_path=image_path)

    # 5. Enhance with physical font sizes
    for decl_type, decl_data in declarations.items():
        if decl_data.get("present") and decl_data.get("bounding_box"):
            box = decl_data["bounding_box"]
            font_measurement = measure_font_height_mm(
                box, mm_per_pixel=mm_per_pixel, confidence=confidence
            )
            decl_data["font_measurement"] = font_measurement
            decl_data["physical_size_mm"] = font_measurement.get("measured_mm")

    # 6. PDP area estimation
    pdp_area_cm2, pdp_area_method = estimate_pdp_area_cm2(
        image_path, scale_data, package_shape
    )

    # 7. Get image dimensions for placement checks
    import cv2
    img = cv2.imread(image_path)
    image_height = img.shape[0] if img is not None else None

    return {
        "status": "success",
        "raw_ocr_count": len(ocr_results),
        "scale_data": scale_data,
        "declarations": declarations,
        "pdp_area_cm2": pdp_area_cm2,
        "pdp_area_method": pdp_area_method,
        "image_height": image_height,
    }
