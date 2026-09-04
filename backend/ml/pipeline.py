"""
ML Pipeline Orchestrator.
Coordinates OCR, Font Measurement, and NLP parsing.
"""

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


import re

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


def process_label_image(
    image_path: str, fallback_reference_mm: Optional[float] = None
) -> Dict[str, Any]:
    """
    Runs the full ML pipeline on a label image to extract LMPC declarations.

    Args:
        image_path: Absolute path to the label image.
        fallback_reference_mm: Fallback mm per pixel if no barcode is found.

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

    # 4. NLP Parsing (Layout-Aware Heuristics)
    declarations = parse_declarations(ocr_results)

    # 5. Enhance with physical font sizes
    for decl_type, decl_data in declarations.items():
        if decl_data.get("present") and decl_data.get("bounding_box"):
            box = decl_data["bounding_box"]
            font_measurement = measure_font_height_mm(
                box, mm_per_pixel=mm_per_pixel, confidence=confidence
            )
            decl_data["font_measurement"] = font_measurement
            decl_data["physical_size_mm"] = font_measurement.get("measured_mm")

    return {
        "status": "success",
        "raw_ocr_count": len(ocr_results),
        "scale_data": scale_data,
        "declarations": declarations,
    }
