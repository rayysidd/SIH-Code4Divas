"""
NLP Parsing Module.
Implements REQ-ML-004: Parse raw OCR text into structured entities.
Upgraded to use bounding-box heuristics (Simulating LayoutLMv3).

Extracts all 11 LMPC mandatory declaration types:
  MRP, NET_QUANTITY, MFG_DATE, COUNTRY_OF_ORIGIN,
  MANUFACTURER_NAME, MANUFACTURER_ADDRESS, GENERIC_NAME,
  BEST_BEFORE_DATE, CUSTOMER_CARE, VEG_NONVEG_SYMBOL, UNIT_SALE_PRICE
"""

import re
from typing import List, Dict, Any, Optional


def parse_declarations(
    ocr_results: List[Dict[str, Any]],
    image_path: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Parses a list of OCR text fragments to find specific LMPC declarations.

    Args:
        ocr_results: List of OCR word dicts with 'text', 'confidence', 'box'.
        image_path: Optional path to the original image (needed for VEG/NONVEG
                    symbol detection via OpenCV).

    Returns:
        Dict mapping all 11 declaration type names to their extraction results.
        Absent declarations have present=False, value=None.
    """
    import json
    try:
        with open("debug_ocr.json", "w") as f:
            json.dump(ocr_results, f, indent=2)
    except Exception:
        pass

    grouped_lines = _group_lines(ocr_results)
    try:
        with open("debug_ocr_grouped.json", "w") as f:
            json.dump(grouped_lines, f, indent=2)
    except Exception:
        pass

    declarations = {
        "MRP": _extract_mrp(grouped_lines),
        "NET_QUANTITY": _extract_net_quantity(grouped_lines),
        "MFG_DATE": _extract_mfg_date(grouped_lines),
        "COUNTRY_OF_ORIGIN": _extract_country_of_origin(grouped_lines),
        "MANUFACTURER_NAME": _empty_declaration(),
        "MANUFACTURER_ADDRESS": _empty_declaration(),
        "GENERIC_NAME": _extract_generic_name(grouped_lines),
        "BEST_BEFORE_DATE": _extract_best_before_date(grouped_lines),
        "CUSTOMER_CARE": _extract_customer_care(grouped_lines),
        "VEG_NONVEG_SYMBOL": _empty_declaration(),
        "UNIT_SALE_PRICE": _empty_declaration(),
    }

    # Manufacturer name + address are extracted together
    mfr_name, mfr_addr = _extract_manufacturer(grouped_lines)
    declarations["MANUFACTURER_NAME"] = mfr_name
    declarations["MANUFACTURER_ADDRESS"] = mfr_addr

    # VEG/NONVEG symbol detection via OpenCV (separate from OCR)
    if image_path:
        declarations["VEG_NONVEG_SYMBOL"] = detect_veg_nonveg_symbol(image_path)

    # Unit Sale Price — try OCR first, then compute from MRP / NET_QUANTITY
    declarations["UNIT_SALE_PRICE"] = _extract_unit_sale_price(
        grouped_lines, declarations
    )

    return declarations


def _empty_declaration() -> Dict[str, Any]:
    """Returns a declaration stub with present=False."""
    return {
        "present": False,
        "value": None,
        "raw_text": None,
        "confidence": 0.0,
        "bounding_box": None,
        "physical_size_mm": None,
    }


# ── Bounding box helpers ────────────────────────────────────────────────────


def _get_bounding_box_for_match(
    match_text: str, ocr_results: List[Dict[str, Any]]
) -> Optional[Dict[str, Any]]:
    """
    Heuristic: Finds the maximum bounding box height among the OCR chunks that make up the match.
    In a real LayoutLMv3 system, the model directly classifies the bounding box.
    """
    matched_boxes = []
    # Simple token overlap check
    match_tokens = match_text.lower().split()

    for res in ocr_results:
        res_text = res["text"].lower()
        if any(
            token in res_text or res_text in token
            for token in match_tokens
            if len(token) > 1
        ):
            matched_boxes.append(res["box"])

    if not matched_boxes:
        return None

    # Create a bounding box that encompasses the found boxes
    min_x = min(b["x"] for b in matched_boxes)
    min_y = min(b["y"] for b in matched_boxes)
    max_x = max(b["x"] + b["w"] for b in matched_boxes)

    # We mainly care about the maximum height of the characters for Rule 7
    max_h = max(b["h"] for b in matched_boxes)

    return {"x": min_x, "y": min_y, "w": max_x - min_x, "h": max_h}


def _distance(box1, box2):
    c1_x = box1["x"] + box1["w"] / 2
    c1_y = box1["y"] + box1["h"] / 2
    c2_x = box2["x"] + box2["w"] / 2
    c2_y = box2["y"] + box2["h"] / 2
    # Heavily penalize vertical distance over horizontal, because text on the same line
    # (even if far to the right) is much more related than text below it.
    return (c1_x - c2_x) ** 2 + ((c1_y - c2_y) * 5) ** 2


# ── Line grouping ───────────────────────────────────────────────────────────


def _group_lines(ocr_results: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    if not ocr_results:
        return []
    # Sort by Y first, then X
    boxes = sorted(ocr_results, key=lambda b: (b["box"]["y"], b["box"]["x"]))
    lines = []
    current_line = [boxes[0]]

    for box in boxes[1:]:
        prev_box = current_line[-1]
        # If it's roughly on the same Y baseline (within half a box height)
        # and horizontally close (within 2-3 average character widths)
        y_diff = abs(box["box"]["y"] - prev_box["box"]["y"])
        x_gap = box["box"]["x"] - (prev_box["box"]["x"] + prev_box["box"]["w"])

        # Thresholds: ~50% of height for Y variance, ~1.5x height for X gap
        if y_diff < prev_box["box"]["h"] * 0.75 and 0 <= x_gap < prev_box["box"]["h"] * 2.0:
            current_line.append(box)
        else:
            # Merge current line
            if current_line:
                min_x = min(b["box"]["x"] for b in current_line)
                min_y = min(b["box"]["y"] for b in current_line)
                max_x = max(b["box"]["x"] + b["box"]["w"] for b in current_line)
                max_h = max(b["box"]["h"] for b in current_line)
                text = " ".join(b["text"] for b in current_line)
                conf = sum(b["confidence"] for b in current_line) / len(current_line)
                lines.append(
                    {
                        "text": text,
                        "confidence": conf,
                        "box": {
                            "x": min_x,
                            "y": min_y,
                            "w": max_x - min_x,
                            "h": max_h,
                        },
                    }
                )
            current_line = [box]

    if current_line:
        min_x = min(b["box"]["x"] for b in current_line)
        min_y = min(b["box"]["y"] for b in current_line)
        max_x = max(b["box"]["x"] + b["box"]["w"] for b in current_line)
        max_h = max(b["box"]["h"] for b in current_line)
        text = " ".join(b["text"] for b in current_line)
        conf = sum(b["confidence"] for b in current_line) / len(current_line)
        lines.append(
            {
                "text": text,
                "confidence": conf,
                "box": {"x": min_x, "y": min_y, "w": max_x - min_x, "h": max_h},
            }
        )

    return lines


# ── Spatial key-value finder ────────────────────────────────────────────────


def _find_nearest_value(
    key_pattern: str, value_pattern: str, ocr_results: List[Dict[str, Any]]
) -> Optional[tuple]:
    key_boxes = []
    value_boxes = []

    # 1. Classify all boxes
    for res in ocr_results:
        text = res["text"]
        if re.search(key_pattern, text, re.IGNORECASE):
            key_boxes.append(res)

        val_match = re.search(value_pattern, text, re.IGNORECASE)
        if val_match:
            # Save the matched value along with the box
            value_boxes.append((res, val_match))

    if not key_boxes or not value_boxes:
        return None

    # 2. Find the closest value box to any key box
    best_match = None
    min_dist = float("inf")

    for k_box in key_boxes:
        for v_box, v_match in value_boxes:
            # Heuristic: Value should generally be to the right or below the key
            # We add a heavy penalty if the value is above or far to the left
            dx = v_box["box"]["x"] - k_box["box"]["x"]
            dy = v_box["box"]["y"] - k_box["box"]["y"]

            penalty = 1.0
            if dx < -k_box["box"]["w"]:
                penalty += 3.0  # Far left
            if dy < -k_box["box"]["h"]:
                penalty += 3.0  # Above

            dist = _distance(k_box["box"], v_box["box"]) * penalty
            if dist < min_dist:
                min_dist = dist
                best_match = (v_box, v_match)

    if min_dist > 1000000:
        return None

    return best_match


# ═══════════════════════════════════════════════════════════════════════════
# EXTRACTORS — one per declaration type
# ═══════════════════════════════════════════════════════════════════════════


def _extract_mrp(ocr_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    # Look for "MRP", allowing prefixes like "*" or falling back to "TAXES" anchor
    key_pat = r'(?:M\.?R\.?P\.?|TAXES)'
    # Look for digits
    val_pat = r'(\d+(?:\.\d{1,2})?)'

    match_tuple = _find_nearest_value(key_pat, val_pat, ocr_results)

    result = {
        "present": False,
        "value": None,
        "raw_text": None,
        "confidence": 0.0,
        "taxes_included_suffix": False,
        "bounding_box": None,
        "physical_size_mm": None,
        "has_currency_symbol": False,
    }

    if match_tuple:
        v_box, v_match = match_tuple
        result["present"] = True
        result["value"] = float(v_match.group(1))
        result["raw_text"] = v_box["text"]
        result["bounding_box"] = v_box["box"]
        result["confidence"] = 0.92

        # Check if taxes suffix exists anywhere in the doc
        combined_text = " ".join([r["text"] for r in ocr_results])
        if re.search(r"tax(?:es)?", combined_text, re.IGNORECASE):
            result["taxes_included_suffix"] = True

        # Check for currency symbol ₹ or Rs. / Rs
        if re.search(r"[₹]|Rs\.?", combined_text, re.IGNORECASE):
            result["has_currency_symbol"] = True

    return result


def _extract_net_quantity(ocr_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    # Key: Net Wt, Weight, Qty
    key_pat = r'(?:Net\s*)?(?:Qty|Quantity|Weight|Wt|Content)'
    # Value: Digits followed immediately by a unit, or just digits if unit is separate
    val_pat = r'^(\d+(?:\.\d+)?)\s*(g|kg|ml|l|gram|grams|pcs|nos|pieces|units|tablets|cm|m)?$'

    match_tuple = _find_nearest_value(key_pat, val_pat, ocr_results)

    result = {
        "present": False,
        "value": None,
        "unit": None,
        "raw_text": None,
        "confidence": 0.0,
        "bounding_box": None,
        "physical_size_mm": None,
        "is_dual_declaration": False,
    }

    if match_tuple:
        v_box, v_match = match_tuple
        result["present"] = True
        result["value"] = float(v_match.group(1))
        result["raw_text"] = v_box["text"]
        result["bounding_box"] = v_box["box"]
        result["confidence"] = 0.95

        unit = v_match.group(2)
        if not unit:
            # Unit might be in the next box to the right
            unit_match = _find_nearest_value(
                r"^" + val_pat + r"$",
                r"^(g|kg|ml|l|gram|grams|pcs|nos|pieces|units|tablets|cm|m)$",
                ocr_results,
            )
            if unit_match:
                unit = unit_match[1].group(1)

        if unit:
            result["unit"] = unit.lower()

    return result


def _extract_mfg_date(ocr_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    key_pat = r'(?:Mfg|Manufactured|Packed|Pkd|Date\s*of\s*Mfg)'
    val_pat = r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}[/-]\d{2,4}|[A-Za-z]{3,}\s*\d{4})'

    match_tuple = _find_nearest_value(key_pat, val_pat, ocr_results)

    result = {
        "present": False,
        "value": None,
        "raw_text": None,
        "bounding_box": None,
        "physical_size_mm": None,
    }

    if match_tuple:
        v_box, v_match = match_tuple
        result["present"] = True
        result["value"] = v_match.group(1)
        result["raw_text"] = v_box["text"]
        result["bounding_box"] = v_box["box"]

    return result


def _extract_country_of_origin(ocr_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    combined_text = " ".join([r["text"] for r in ocr_results])
    coo_pattern = r'(?:Made\s+in|Country\s+of\s+Origin)[\s\.:]*([a-zA-Z\s]+)'
    match = re.search(coo_pattern, combined_text, re.IGNORECASE)

    result = {
        "present": False,
        "value": None,
        "raw_text": None,
        "bounding_box": None,
        "physical_size_mm": None,
    }

    if match:
        result["present"] = True
        words = match.group(1).strip().split()
        result["value"] = " ".join(words[:2])
        result["raw_text"] = match.group(0)

    return result


# ── NEW: Manufacturer Name + Address ────────────────────────────────────────


def _extract_manufacturer(
    grouped_lines: List[Dict[str, Any]],
) -> tuple:
    """
    Extracts MANUFACTURER_NAME and MANUFACTURER_ADDRESS from grouped OCR lines.

    Looks for anchoring keywords ("Mfd. by", "Manufactured by", "Packed by",
    "Marketed by", "Brand Owner", "Imported by"), then extracts the company name
    on the same line and the address from subsequent lines until a 6-digit PIN
    code is found.

    Returns:
        (manufacturer_name_decl, manufacturer_address_decl) — two dicts
    """
    name_result = _empty_declaration()
    addr_result = _empty_declaration()

    anchor_pat = re.compile(
        r"(?:Mfd\.?\s*by|Manufactured\s*by|Packed\s*by|Marketed\s*by|"
        r"Brand\s*Owner|Imported\s*by|Mfg\.?\s*by)",
        re.IGNORECASE,
    )
    pin_pat = re.compile(r"\b\d{6}\b")

    anchor_idx = None
    anchor_keyword = None
    for i, line in enumerate(grouped_lines):
        m = anchor_pat.search(line["text"])
        if m:
            anchor_idx = i
            anchor_keyword = m.group(0)
            break

    if anchor_idx is None:
        return name_result, addr_result

    # The company name is whatever follows the keyword on the same line
    anchor_line = grouped_lines[anchor_idx]
    after_keyword = anchor_pat.sub("", anchor_line["text"]).strip(" :,.-")
    company_name = after_keyword if after_keyword else None

    # Collect address lines: the next 1-3 lines after the anchor
    address_parts = []
    address_box = None
    collected = 0
    for j in range(anchor_idx + 1, min(anchor_idx + 4, len(grouped_lines))):
        line = grouped_lines[j]
        line_text = line["text"].strip()

        # Stop collecting if we hit another known declaration keyword
        if re.search(
            r"(?:M\.?R\.?P|Net\s*(?:Wt|Qty|Quantity)|Best\s*Before|"
            r"Customer\s*Care|Consumer\s*Care|Expiry|Use\s*By|"
            r"Country\s*of\s*Origin|Made\s*in|FSSAI)",
            line_text,
            re.IGNORECASE,
        ):
            break

        address_parts.append(line_text)
        if address_box is None:
            address_box = dict(line["box"])
        else:
            # Expand bounding box to encompass this line
            address_box["h"] = (
                line["box"]["y"] + line["box"]["h"] - address_box["y"]
            )
            address_box["w"] = max(
                address_box["w"],
                line["box"]["x"] + line["box"]["w"] - address_box["x"],
            )
        collected += 1

        # Stop if this line contains a PIN code (end of address)
        if pin_pat.search(line_text):
            break

    full_address = ", ".join(address_parts) if address_parts else None

    # If we didn't get a company name from the same line, use the first address line
    if not company_name and address_parts:
        company_name = address_parts[0]

    # Build name result
    if company_name:
        name_result = {
            "present": True,
            "value": company_name.strip(),
            "raw_text": f"{anchor_keyword} {company_name}".strip(),
            "confidence": 0.85,
            "bounding_box": anchor_line["box"],
            "physical_size_mm": None,
        }

    # Build address result
    if full_address:
        combined_raw = f"{anchor_keyword} {company_name or ''} {full_address}".strip()
        addr_result = {
            "present": True,
            "value": full_address,
            "raw_text": combined_raw,
            "confidence": 0.80,
            "bounding_box": address_box,
            "physical_size_mm": None,
            "has_pin_code": bool(pin_pat.search(full_address)),
        }

    return name_result, addr_result


# ── NEW: Generic Name ──────────────────────────────────────────────────────


_KNOWN_KEYWORD_PATTERNS = re.compile(
    r"(?:M\.?R\.?P|Net\s*(?:Wt|Qty|Quantity|Weight)|Mfg|Manufactured|"
    r"Packed|Best\s*Before|Expiry|Customer\s*Care|Consumer\s*Care|"
    r"Country\s*of|Made\s*in|FSSAI|Ingredients|Nutritional|"
    r"Batch|Lot|Use\s*By|Imported|Marketed|Brand\s*Owner|"
    r"Helpline|Grievance|Toll\s*Free|USP|Unit\s*Sale)",
    re.IGNORECASE,
)


def _extract_generic_name(grouped_lines: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Heuristic: The generic/common name is typically the largest or most prominent
    text on the label after the brand name. We look for the first non-numeric
    text block with height > 1.5× average line height that does not match known
    keyword patterns.
    """
    result = _empty_declaration()

    if not grouped_lines:
        return result

    # Calculate average line height
    heights = [line["box"]["h"] for line in grouped_lines]
    avg_height = sum(heights) / len(heights) if heights else 0

    if avg_height <= 0:
        return result

    threshold = avg_height * 1.5

    for line in grouped_lines:
        text = line["text"].strip()
        box_h = line["box"]["h"]

        # Skip very short text
        if len(text) < 3:
            continue

        # Skip purely numeric text
        if re.match(r"^[\d\s.,₹/%-]+$", text):
            continue

        # Skip lines that match known declaration keywords
        if _KNOWN_KEYWORD_PATTERNS.search(text):
            continue

        # This line has height > 1.5× average and isn't a known keyword — likely generic name
        if box_h > threshold:
            result = {
                "present": True,
                "value": text,
                "raw_text": text,
                "confidence": 0.70,
                "bounding_box": line["box"],
                "physical_size_mm": None,
            }
            break

    return result


# ── NEW: Best Before Date ──────────────────────────────────────────────────


def _extract_best_before_date(grouped_lines: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Looks for "Best Before" / "BB" / "Exp" / "Expiry" / "Use By" / "BBE"
    then extracts the associated date using the same regex patterns as MFG_DATE.
    """
    key_pat = r"(?:Best\s*Before|BB[E]?|Exp(?:iry)?|Use\s*By)"
    val_pat = r"(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}[/-]\d{2,4}|[A-Za-z]{3,}\s*\d{4}|\d+\s*(?:months?|days?|years?))"

    match_tuple = _find_nearest_value(key_pat, val_pat, grouped_lines)

    result = {
        "present": False,
        "value": None,
        "raw_text": None,
        "bounding_box": None,
        "physical_size_mm": None,
    }

    if match_tuple:
        v_box, v_match = match_tuple
        result["present"] = True
        result["value"] = v_match.group(1)
        result["raw_text"] = v_box["text"]
        result["bounding_box"] = v_box["box"]

    return result


# ── NEW: Customer Care ─────────────────────────────────────────────────────


def _extract_customer_care(grouped_lines: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Looks for "Consumer Care" / "Customer Care" / "Helpline" / "Grievance" /
    "Toll Free". Extracts 10-digit Indian phone, toll-free 1800 number, or
    email address.
    """
    result = {
        "present": False,
        "value": None,
        "contact_type": None,
        "raw_text": None,
        "bounding_box": None,
        "physical_size_mm": None,
    }

    combined_text = " ".join([line["text"] for line in grouped_lines])

    # Check for anchor keywords
    anchor_pat = re.compile(
        r"(?:Consumer\s*Care|Customer\s*Care|Helpline|Grievance|Toll\s*Free)",
        re.IGNORECASE,
    )
    if not anchor_pat.search(combined_text):
        # Also try to find standalone 1800 numbers or email without explicit keyword
        pass  # fall through to pattern detection below

    # Pattern 1: Toll-free number (1800-XXX-XXXX or 1800 XXX XXXX variants)
    toll_free = re.search(r"(1800[\s-]?\d{3}[\s-]?\d{3,4})", combined_text)
    if toll_free:
        result["present"] = True
        result["value"] = toll_free.group(1).strip()
        result["contact_type"] = "TOLL_FREE"
        result["raw_text"] = toll_free.group(0)
        result["confidence"] = 0.90
        # Find bounding box for the match
        for line in grouped_lines:
            if toll_free.group(1) in line["text"] or "1800" in line["text"]:
                result["bounding_box"] = line["box"]
                break
        return result

    # Pattern 2: 10-digit Indian mobile number
    phone_match = re.search(r"\b([6-9]\d{9})\b", combined_text)
    if phone_match:
        result["present"] = True
        result["value"] = phone_match.group(1)
        result["contact_type"] = "PHONE"
        result["raw_text"] = phone_match.group(0)
        result["confidence"] = 0.85
        for line in grouped_lines:
            if phone_match.group(1) in line["text"]:
                result["bounding_box"] = line["box"]
                break
        return result

    # Pattern 3: Email address
    email_match = re.search(
        r"([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})", combined_text
    )
    if email_match:
        result["present"] = True
        result["value"] = email_match.group(1)
        result["contact_type"] = "EMAIL"
        result["raw_text"] = email_match.group(0)
        result["confidence"] = 0.88
        for line in grouped_lines:
            if "@" in line["text"]:
                result["bounding_box"] = line["box"]
                break
        return result

    return result


# ── NEW: Veg / Non-Veg Symbol (OpenCV) ─────────────────────────────────────


def detect_veg_nonveg_symbol(image_path: str) -> Dict[str, Any]:
    """
    Detects the FSSAI Veg/Non-Veg symbol using OpenCV.

    Looks for a small square bounding box (aspect ratio ~1:1, area < 5% of image)
    that contains a circle. Samples the dominant hue inside:
      - Green (HSV hue 40–80) → VEG
      - Red/Brown (hue 0–20 or 160–180) → NON_VEG

    Returns:
        Declaration dict with present, value ("VEG" or "NON_VEG"), bounding_box.
    """
    import cv2
    import numpy as np

    result = _empty_declaration()

    try:
        img = cv2.imread(image_path)
        if img is None:
            return result

        img_h, img_w = img.shape[:2]
        total_area = img_h * img_w
        max_symbol_area = total_area * 0.05
        min_symbol_area = total_area * 0.0003  # very small symbols are noise

        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

        # Look for green and red regions separately
        # Green mask: hue 40–80
        green_lower = np.array([35, 50, 50])
        green_upper = np.array([85, 255, 255])
        green_mask = cv2.inRange(hsv, green_lower, green_upper)

        # Red mask: hue 0–20 and 160–180
        red_lower1 = np.array([0, 50, 50])
        red_upper1 = np.array([20, 255, 255])
        red_lower2 = np.array([155, 50, 50])
        red_upper2 = np.array([180, 255, 255])
        red_mask = cv2.bitwise_or(
            cv2.inRange(hsv, red_lower1, red_upper1),
            cv2.inRange(hsv, red_lower2, red_upper2),
        )

        for color_name, mask in [("VEG", green_mask), ("NON_VEG", red_mask)]:
            # Find contours in the mask
            contours, _ = cv2.findContours(
                mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
            )

            for cnt in contours:
                area = cv2.contourArea(cnt)
                if area < min_symbol_area or area > max_symbol_area:
                    continue

                x, y, w, h = cv2.boundingRect(cnt)
                aspect_ratio = float(w) / h if h > 0 else 0

                # Must be roughly square (aspect ratio 0.7 – 1.4)
                if not (0.7 <= aspect_ratio <= 1.4):
                    continue

                # Check for circle inside: use Hough circles on the ROI
                roi_gray = cv2.cvtColor(
                    img[y : y + h, x : x + w], cv2.COLOR_BGR2GRAY
                )
                if roi_gray.shape[0] < 10 or roi_gray.shape[1] < 10:
                    continue

                circles = cv2.HoughCircles(
                    roi_gray,
                    cv2.HOUGH_GRADIENT,
                    dp=1.2,
                    minDist=max(w // 3, 5),
                    param1=50,
                    param2=25,
                    minRadius=max(w // 6, 3),
                    maxRadius=w // 2,
                )

                if circles is not None:
                    result = {
                        "present": True,
                        "value": color_name,
                        "raw_text": f"{'Green' if color_name == 'VEG' else 'Red/Brown'} symbol detected",
                        "confidence": 0.75,
                        "bounding_box": {"x": x, "y": y, "w": w, "h": h},
                        "physical_size_mm": None,
                    }
                    return result

    except Exception as e:
        print(f"[VEG/NONVEG] Detection error: {e}")

    return result


# ── NEW: Unit Sale Price ───────────────────────────────────────────────────


def _extract_unit_sale_price(
    grouped_lines: List[Dict[str, Any]],
    declarations: Dict[str, Any],
) -> Dict[str, Any]:
    """
    Looks for "USP" / "Unit Sale Price" / "₹ X.XX per" / "₹ X.XX/".
    If not found on the label, computes USP = MRP / NET_QUANTITY (if both
    are present and numeric).
    """
    result = {
        "present": False,
        "value": None,
        "unit": None,
        "raw_text": None,
        "computed": False,
        "bounding_box": None,
        "physical_size_mm": None,
        "confidence": 0.0,
    }

    combined_text = " ".join([line["text"] for line in grouped_lines])

    # Pattern 1: Explicit "USP" / "Unit Sale Price" on label
    usp_pat = re.compile(
        r"(?:USP|Unit\s*Sale\s*Price)\s*[:\s]*[₹Rs.]*\s*(\d+(?:\.\d{1,2})?)\s*(?:per\s*|/)?\s*(g|kg|ml|l|piece|pcs|unit)?",
        re.IGNORECASE,
    )
    usp_match = usp_pat.search(combined_text)

    if usp_match:
        result["present"] = True
        result["value"] = float(usp_match.group(1))
        result["unit"] = usp_match.group(2).lower() if usp_match.group(2) else None
        result["raw_text"] = usp_match.group(0)
        result["confidence"] = 0.85
        # Find bounding box
        for line in grouped_lines:
            if re.search(r"USP|Unit\s*Sale", line["text"], re.IGNORECASE):
                result["bounding_box"] = line["box"]
                break
        return result

    # Pattern 2: "₹ X.XX per g" or "₹ X.XX/kg" anywhere
    per_pat = re.compile(
        r"[₹Rs.]*\s*(\d+(?:\.\d{1,2})?)\s*(?:per\s*|/)\s*(g|kg|ml|l|piece|pcs|unit)",
        re.IGNORECASE,
    )
    per_match = per_pat.search(combined_text)
    if per_match:
        result["present"] = True
        result["value"] = float(per_match.group(1))
        result["unit"] = per_match.group(2).lower()
        result["raw_text"] = per_match.group(0)
        result["confidence"] = 0.80
        return result

    # Fallback: compute from MRP / NET_QUANTITY
    mrp = declarations.get("MRP", {})
    nq = declarations.get("NET_QUANTITY", {})
    if (
        mrp.get("present")
        and nq.get("present")
        and mrp.get("value")
        and nq.get("value")
    ):
        try:
            mrp_val = float(mrp["value"])
            nq_val = float(nq["value"])
            if nq_val > 0:
                computed_usp = round(mrp_val / nq_val, 4)
                result["present"] = True
                result["value"] = computed_usp
                result["unit"] = nq.get("unit")
                result["raw_text"] = f"Computed: ₹{mrp_val} / {nq_val}{nq.get('unit', '')}"
                result["computed"] = True
                result["confidence"] = 0.60
        except (ValueError, TypeError):
            pass

    return result
