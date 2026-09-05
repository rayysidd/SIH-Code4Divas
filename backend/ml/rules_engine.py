"""
Legal Metrology Rules Engine.
Evaluates ML pipeline outputs against LMPC Rules 2011 (including 2026 amendments).

Violation codes:
  V001 – MRP missing
  V002 – MRP missing "incl. of all taxes"
  V003 – MRP font size too small (V003-INC if inconclusive)
  V004 – Net quantity missing
  V005 – Net quantity font size too small (V005-INC if inconclusive)
  V006 – Mfg date missing
  V007 – Country of origin missing (imported products)
  V008 – E-commerce COO filter missing (GSR 128(E))
  V009 – Manufacturer name/address missing
  V010 – Generic name missing
  V011 – Best-before date missing (food/cosmetics only)
  V012 – Customer care info missing
  V013 – Veg/Non-veg symbol missing (food/cosmetics only)
  V014 – Unit sale price missing (post-2022-10, non-combo)
  V015 – MRP missing currency symbol (₹ / Rs.)
  V016 – Net quantity not in lower 30% of PDP
"""

import re
from typing import Dict, Any, Optional


# ═══════════════════════════════════════════════════════════════════════════
# Font size tables — Rule 7, Table I and Table II
# ═══════════════════════════════════════════════════════════════════════════


def detect_unit_type(declarations: Dict[str, Any]) -> str:
    """
    Determines whether the product uses WEIGHT_VOLUME or LENGTH_AREA_NUMBER
    units, based on the NET_QUANTITY declaration's unit field or raw text.

    Returns:
        'WEIGHT_VOLUME' or 'LENGTH_AREA_NUMBER'
    """
    nq = declarations.get("NET_QUANTITY", {})
    unit = (nq.get("unit") or "").lower()
    raw = (nq.get("raw_text") or "").lower()

    length_area_number_indicators = [
        "pcs", "piece", "pieces", "nos", "unit", "units",
        "tablet", "tablets", "cm", " m ", "metre", "meter",
        "sq", "sqm",
    ]

    for indicator in length_area_number_indicators:
        if indicator in unit or indicator in raw:
            return "LENGTH_AREA_NUMBER"

    return "WEIGHT_VOLUME"


def get_min_font_height_mm(
    pdp_area_cm2: float,
    unit_type: str = "WEIGHT_VOLUME",
) -> float:
    """
    Returns the minimum font height in mm per Rule 7.

    Table I  — for weight/volume products (g, kg, ml, L)
    Table II — for length/area/number products (m, cm, pcs, nos, tablets)

    Args:
        pdp_area_cm2: Principal Display Panel area in cm².
        unit_type: 'WEIGHT_VOLUME' or 'LENGTH_AREA_NUMBER'.
    """
    if unit_type == "LENGTH_AREA_NUMBER":
        # Table II (GSR 629(E))
        if pdp_area_cm2 < 100:
            return 1.0
        elif pdp_area_cm2 < 500:
            return 2.0
        elif pdp_area_cm2 < 2500:
            return 4.0
        else:
            return 6.0
    else:
        # Table I (gazette-corrected tiers)
        if pdp_area_cm2 < 50:
            return 1.0
        elif pdp_area_cm2 < 100:
            return 1.5
        elif pdp_area_cm2 < 500:
            return 2.5
        elif pdp_area_cm2 < 2500:
            return 4.0
        else:
            return 6.0


# ═══════════════════════════════════════════════════════════════════════════
# Main compliance evaluator
# ═══════════════════════════════════════════════════════════════════════════


def evaluate_compliance(
    declarations: Dict[str, Any],
    pdp_area_cm2: float = 150.0,
    is_imported: bool = False,
    ecommerce_has_coo_filter: bool = False,
    product_category: str = "GENERAL",
    image_height: Optional[int] = None,
    image_path: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Evaluates extracted declarations against LMPC Rules.

    Args:
        declarations: Output from parse_declarations().
        pdp_area_cm2: Principal Display Panel area in cm².
        is_imported: Whether the product is imported (triggers Rule 6(10A)).
        ecommerce_has_coo_filter: Whether e-commerce platform has COO filter.
        product_category: One of FOOD_GENERAL, EDIBLE_OIL, COSMETICS, ELECTRONICS, GENERAL.
        image_height: Height of the original image in pixels (for placement checks).
        image_path: Path to original image (reserved for future use).
    """
    violations = []
    priority_score = 0

    # Determine unit type for font table selection
    unit_type = detect_unit_type(declarations)
    min_req_height = get_min_font_height_mm(pdp_area_cm2, unit_type)

    # Combined raw text for keyword searches
    raw_texts = []
    for decl_data in declarations.values():
        if isinstance(decl_data, dict) and decl_data.get("raw_text"):
            raw_texts.append(decl_data["raw_text"])
    combined_raw = " ".join(raw_texts).lower()

    # ── 1. MRP — Rule 6(1)(e) ────────────────────────────────────────────
    mrp = declarations.get("MRP", {})
    if not mrp.get("present"):
        violations.append(
            {
                "violation_id": "V001",
                "rule_citation": "Rule 6(1)(e), LMPC Rules 2011",
                "description": "MRP missing from principal display panel.",
                "severity": "CRITICAL",
                "measured_value": "Missing",
                "required_format": "MRP ₹XX.XX",
                "penalty_range": "First offence: up to ₹25,000 — Section 36(1), LMA 2009",
            }
        )
        priority_score += 30
    else:
        # V002: Check taxes included suffix
        if not mrp.get("taxes_included_suffix"):
            violations.append(
                {
                    "violation_id": "V002",
                    "rule_citation": "Rule 6(1)(e), LMPC Rules 2011 as amended by GSR 629(E), 23.06.2017",
                    "description": "MRP declaration missing required 'inclusive of all taxes' wording",
                    "severity": "CRITICAL",
                    "measured_value": mrp.get("raw_text", "MRP"),
                    "required_format": "MRP ₹XX (incl. of all taxes)",
                    "penalty_range": "First offence: up to ₹25,000 — Section 36(1), LMA 2009",
                }
            )
            priority_score += 20

        # V015: Check currency symbol ₹ or Rs.
        if not mrp.get("has_currency_symbol"):
            raw = (mrp.get("raw_text") or "").lower()
            if not re.search(r"[₹]|rs\.?", raw, re.IGNORECASE):
                violations.append(
                    {
                        "violation_id": "V015",
                        "rule_citation": "Rule 6(1)(e), LMPC Rules 2011",
                        "description": "MRP declaration missing currency symbol (₹ or Rs.).",
                        "severity": "MEDIUM",
                        "measured_value": mrp.get("raw_text", ""),
                        "required_format": "MRP ₹XX.XX or MRP Rs. XX.XX",
                        "penalty_range": "Notice for rectification — Rule 32",
                    }
                )
                priority_score += 10

        # V003: MRP font size — three-way: measured-fail, measured-pass, or inconclusive
        font_measurement = mrp.get("font_measurement", {})
        actual_height = mrp.get("physical_size_mm")
        font_status = font_measurement.get("status")

        if font_status == "no_scale" or font_status is None:
            violations.append(
                {
                    "violation_id": "V003-INC",
                    "rule_citation": "Rule 7 Table I, LMPC Rules 2011",
                    "description": "MRP font size could not be verified — no barcode "
                    "reference found in image for physical scale calibration.",
                    "severity": "INCONCLUSIVE",
                    "measured_value": "Unmeasured",
                    "required_format": f"Min {min_req_height}mm — requires physical verification",
                    "penalty_range": "N/A — flagged for manual inspection",
                }
            )
        elif actual_height is not None and actual_height < min_req_height:
            violations.append(
                {
                    "violation_id": "V003",
                    "rule_citation": "Rule 7 Table I, LMPC Rules 2011",
                    "description": f"MRP font size ({actual_height}mm) is smaller than required minimum.",
                    "severity": "HIGH",
                    "measured_value": f"{actual_height}mm",
                    "required_format": f"Min {min_req_height}mm",
                    "penalty_range": "Notice for rectification — Rule 32",
                }
            )
            priority_score += 20

    # ── 2. Net Quantity — Rule 6(1)(b) ───────────────────────────────────
    net_qty = declarations.get("NET_QUANTITY", {})
    if not net_qty.get("present"):
        violations.append(
            {
                "violation_id": "V004",
                "rule_citation": "Rule 6(1)(b), LMPC Rules 2011",
                "description": "Net quantity declaration is missing.",
                "severity": "CRITICAL",
                "measured_value": "Missing",
                "required_format": "Net Qty: X g/ml",
                "penalty_range": "First offence: up to ₹25,000 — Section 36(1), LMA 2009",
            }
        )
        priority_score += 30
    else:
        # V005: Net quantity font size
        font_measurement = net_qty.get("font_measurement", {})
        actual_height = net_qty.get("physical_size_mm")
        font_status = font_measurement.get("status")

        table_label = "Table II" if unit_type == "LENGTH_AREA_NUMBER" else "Table I"

        if font_status == "no_scale" or font_status is None:
            violations.append(
                {
                    "violation_id": "V005-INC",
                    "rule_citation": f"Rule 7 {table_label}, LMPC Rules 2011",
                    "description": "Net quantity font size could not be verified — no barcode "
                    "reference found in image for physical scale calibration.",
                    "severity": "INCONCLUSIVE",
                    "measured_value": "Unmeasured",
                    "required_format": f"Min {min_req_height}mm — requires physical verification",
                    "penalty_range": "N/A — flagged for manual inspection",
                }
            )
        elif actual_height is not None and actual_height < min_req_height:
            violations.append(
                {
                    "violation_id": "V005",
                    "rule_citation": f"Rule 7 {table_label}, LMPC Rules 2011",
                    "description": f"Net quantity font size ({actual_height}mm) is smaller than required minimum.",
                    "severity": "HIGH",
                    "measured_value": f"{actual_height}mm",
                    "required_format": f"Min {min_req_height}mm",
                    "penalty_range": "Notice for rectification — Rule 32",
                }
            )
            priority_score += 20

    # ── 3. Mfg Date — Rule 6(1)(d) ──────────────────────────────────────
    mfg = declarations.get("MFG_DATE", {})
    if not mfg.get("present"):
        violations.append(
            {
                "violation_id": "V006",
                "rule_citation": "Rule 6(1)(d), LMPC Rules 2011",
                "description": "Month and year of manufacture/packing missing.",
                "severity": "HIGH",
                "measured_value": "Missing",
                "required_format": "Mfg: MM/YYYY",
                "penalty_range": "First offence: up to ₹10,000",
            }
        )
        priority_score += 20

    # ── 4. Country of Origin — Rule 6(1)(j) & Rule 6(10A) ───────────────
    coo = declarations.get("COUNTRY_OF_ORIGIN", {})
    if is_imported and not coo.get("present"):
        violations.append(
            {
                "violation_id": "V007",
                "rule_citation": "Rule 6(1)(j), LMPC Rules 2011",
                "description": "Country of origin is mandatory for imported products but is missing.",
                "severity": "CRITICAL",
                "measured_value": "Missing",
                "required_format": "Made in [Country]",
                "penalty_range": "Seizure of goods — Section 15, LMA 2009",
            }
        )
        priority_score += 30

    # E-Commerce Amendment GSR 128(E) 2026
    if is_imported and not ecommerce_has_coo_filter:
        violations.append(
            {
                "violation_id": "V008",
                "rule_citation": "Rule 6(10A), LMPC Rules 2011 (GSR 128(E), 13.02.2026)",
                "description": "Country-of-origin searchable filter mandatory on e-commerce platforms for imported products",
                "severity": "HIGH",
                "measured_value": "Filter missing",
                "required_format": "Search filter present",
                "penalty_range": "Notice to E-commerce entity",
            }
        )
        priority_score += 20

    # ── 5. Manufacturer Name / Address — Rule 6(1)(a) ────────────────────
    mfr_name = declarations.get("MANUFACTURER_NAME", {})
    mfr_addr = declarations.get("MANUFACTURER_ADDRESS", {})

    mfr_missing = not mfr_name.get("present")
    addr_missing = not mfr_addr.get("present")

    # Even if name is present, address must contain a PIN code and one of the keywords
    if not addr_missing:
        has_pin = mfr_addr.get("has_pin_code", False)
        raw = (mfr_addr.get("raw_text") or "").lower()
        has_keyword = any(
            kw in raw
            for kw in [
                "mfd. by", "mfd by", "manufactured by", "packed by",
                "marketed by", "imported by", "brand owner",
            ]
        )
        if not has_pin:
            addr_missing = True  # address without PIN is incomplete

    if mfr_missing or addr_missing:
        violations.append(
            {
                "violation_id": "V009",
                "rule_citation": "Rule 6(1)(a), LMPC Rules 2011",
                "description": "Manufacturer/packer name and address (with PIN code) missing or incomplete.",
                "severity": "CRITICAL",
                "measured_value": "Missing" if mfr_missing else "Incomplete (no PIN code)",
                "required_format": "Mfd. by: Company Name, Full Address, City - PIN",
                "penalty_range": "First offence: up to ₹25,000 — Section 36(1), LMA 2009",
            }
        )
        priority_score += 30

    # ── 6. Generic Name — Rule 6(1)(b) ──────────────────────────────────
    generic = declarations.get("GENERIC_NAME", {})
    if not generic.get("present"):
        violations.append(
            {
                "violation_id": "V010",
                "rule_citation": "Rule 6(1)(b), LMPC Rules 2011",
                "description": "Generic or common name of the commodity is missing from the label.",
                "severity": "HIGH",
                "measured_value": "Missing",
                "required_format": "Generic name in prominent text",
                "penalty_range": "First offence: up to ₹10,000",
            }
        )
        priority_score += 15

    # ── 7. Best Before Date — Rule 6(1)(f) ──────────────────────────────
    # Only applicable for food and cosmetics categories
    food_cosmetic_categories = ["FOOD_GENERAL", "EDIBLE_OIL", "COSMETICS"]
    if product_category in food_cosmetic_categories:
        bb = declarations.get("BEST_BEFORE_DATE", {})
        if not bb.get("present"):
            violations.append(
                {
                    "violation_id": "V011",
                    "rule_citation": "Rule 6(1)(f), LMPC Rules 2011",
                    "description": "Best before / expiry date is missing (required for food and cosmetics).",
                    "severity": "MEDIUM",
                    "measured_value": "Missing",
                    "required_format": "Best Before: DD/MM/YYYY or X months from Mfg",
                    "penalty_range": "Notice for rectification — Rule 32",
                }
            )
            priority_score += 10

    # ── 8. Customer Care — Rule 6(1)(h) GSR 629(E) ─────────────────────
    care = declarations.get("CUSTOMER_CARE", {})
    if not care.get("present"):
        violations.append(
            {
                "violation_id": "V012",
                "rule_citation": "Rule 6(1)(h), LMPC Rules 2011 (GSR 629(E))",
                "description": "Customer care / consumer complaint contact information is missing.",
                "severity": "HIGH",
                "measured_value": "Missing",
                "required_format": "Phone: 10-digit or 1800-XXX-XXXX, or email",
                "penalty_range": "First offence: up to ₹10,000",
            }
        )
        priority_score += 15
    else:
        # Validate format
        contact_type = care.get("contact_type", "")
        value = care.get("value", "")
        valid_contact = False
        if contact_type == "PHONE" and re.match(r"^[6-9]\d{9}$", str(value)):
            valid_contact = True
        elif contact_type == "TOLL_FREE" and "1800" in str(value):
            valid_contact = True
        elif contact_type == "EMAIL" and "@" in str(value):
            valid_contact = True

        if not valid_contact and value:
            violations.append(
                {
                    "violation_id": "V012",
                    "rule_citation": "Rule 6(1)(h), LMPC Rules 2011 (GSR 629(E))",
                    "description": f"Customer care contact '{value}' does not match valid format.",
                    "severity": "MEDIUM",
                    "measured_value": str(value),
                    "required_format": "10-digit phone, 1800-XXX-XXXX, or valid email",
                    "penalty_range": "Notice for rectification",
                }
            )
            priority_score += 5

    # ── 9. Veg / Non-Veg Symbol — FSSAI / Rule 6(1)(j) ─────────────────
    if product_category in food_cosmetic_categories:
        veg = declarations.get("VEG_NONVEG_SYMBOL", {})
        if not veg.get("present"):
            violations.append(
                {
                    "violation_id": "V013",
                    "rule_citation": "FSSAI (Packaging and Labelling) Regulations / Rule 6(1)(j)",
                    "description": "Veg/Non-veg symbol (green/red dot) not detected on label.",
                    "severity": "MEDIUM",
                    "measured_value": "Not detected",
                    "required_format": "Green circle (veg) or Red/Brown circle (non-veg) in square border",
                    "penalty_range": "Notice for rectification — FSSAI Regulation 2.4.5",
                }
            )
            priority_score += 10

    # ── 10. Unit Sale Price — Rule 6(11) GSR 226(E) ─────────────────────
    usp = declarations.get("UNIT_SALE_PRICE", {})
    # Only check if: product after 2022-10, not a combo, and USP != MRP
    should_check_usp = True

    # Check MFG_DATE year >= 2022, month >= 10
    mfg_val = (mfg.get("value") or "")
    if mfg_val:
        year_match = re.search(r"(\d{4})", str(mfg_val))
        if year_match:
            year = int(year_match.group(1))
            if year < 2022:
                should_check_usp = False
            elif year == 2022:
                month_match = re.search(r"(\d{1,2})[/-]", str(mfg_val))
                if month_match and int(month_match.group(1)) < 10:
                    should_check_usp = False
    else:
        # If date unknown, still flag (conservative approach)
        pass

    # Skip for combo/multi-piece packages
    combo_indicators = ["combo", "gift set", "assorted", "multipack", "multi-pack"]
    if any(ind in combined_raw for ind in combo_indicators):
        should_check_usp = False

    if should_check_usp and not usp.get("present"):
        violations.append(
            {
                "violation_id": "V014",
                "rule_citation": "Rule 6(11), LMPC Rules 2011 (GSR 226(E))",
                "description": "Unit sale price (USP) is missing from the label.",
                "severity": "HIGH",
                "measured_value": "Missing",
                "required_format": "USP: ₹X.XX per g/ml/unit",
                "penalty_range": "First offence: up to ₹10,000",
            }
        )
        priority_score += 15
    elif should_check_usp and usp.get("present") and usp.get("computed"):
        # Validate computed USP = MRP / NET_QUANTITY ± 0.02
        mrp_val = mrp.get("value")
        nq_val = net_qty.get("value")
        if mrp_val and nq_val and float(nq_val) > 0:
            expected = float(mrp_val) / float(nq_val)
            actual_usp = float(usp.get("value", 0))
            if abs(actual_usp - expected) > 0.02:
                violations.append(
                    {
                        "violation_id": "V014",
                        "rule_citation": "Rule 6(11), LMPC Rules 2011 (GSR 226(E))",
                        "description": f"Unit sale price (₹{actual_usp}) does not match MRP/Qty (₹{round(expected, 4)}).",
                        "severity": "MEDIUM",
                        "measured_value": f"₹{actual_usp}",
                        "required_format": f"₹{round(expected, 4)} (MRP ÷ Net Qty ± 0.02)",
                        "penalty_range": "Notice for rectification",
                    }
                )
                priority_score += 5

    # ── 11. Net Quantity Placement — Rule 8(1) ──────────────────────────
    if (
        net_qty.get("present")
        and net_qty.get("bounding_box")
        and image_height
        and image_height > 0
    ):
        box = net_qty["bounding_box"]
        nq_bottom_y = box["y"] + box["h"]
        nq_y_fraction = nq_bottom_y / image_height
        if nq_y_fraction < 0.70:
            violations.append(
                {
                    "violation_id": "V016",
                    "rule_citation": "Rule 8(1), LMPC Rules 2011",
                    "description": "Net quantity declaration is not in the lower 30% of the Principal Display Panel.",
                    "severity": "MEDIUM",
                    "measured_value": f"Top {round(nq_y_fraction * 100)}% of panel",
                    "required_format": "Lower 30% of PDP",
                    "penalty_range": "Notice for rectification — Rule 32",
                }
            )
            priority_score += 10

    # ── Final scoring ────────────────────────────────────────────────────
    # Cap score at 100
    priority_score = min(priority_score, 100)

    # Determine overall status with INCONCLUSIVE awareness
    has_critical_or_high = any(
        v["severity"] in ("CRITICAL", "HIGH") for v in violations
    )
    has_inconclusive = any(v["severity"] == "INCONCLUSIVE" for v in violations)

    if has_critical_or_high:
        overall_status = "FAIL"
    elif has_inconclusive:
        overall_status = "NEEDS_VERIFICATION"
    else:
        overall_status = "PASS"

    return {
        "status": overall_status,
        "violations": violations,
        "inspection_priority_score": priority_score,
        "min_required_font_height_mm": min_req_height,
        "font_table_used": "Table II" if unit_type == "LENGTH_AREA_NUMBER" else "Table I",
        "unit_type": unit_type,
    }
