"""
Legal Metrology Rules Engine.
Evaluates ML pipeline outputs against LMPC Rules 2011 (including 2026 amendments).
"""

from typing import Dict, Any


def get_min_font_height_mm(pdp_area_cm2: float) -> float:
    """Returns the minimum font height in mm per Rule 7 Table I (GSR 629(E))."""
    if pdp_area_cm2 < 50:
        return 1.0
    elif pdp_area_cm2 <= 100:
        return 2.0
    elif pdp_area_cm2 <= 500:
        return 4.0
    else:
        return 6.0


def evaluate_compliance(
    declarations: Dict[str, Any],
    pdp_area_cm2: float = 150.0,
    is_imported: bool = False,
    ecommerce_has_coo_filter: bool = False,
) -> Dict[str, Any]:
    """
    Evaluates extracted declarations against LMPC Rules.

    Args:
        declarations: Output from parse_declarations().
        pdp_area_cm2: Principal Display Panel area in cm2.
        is_imported: Whether the product is imported (triggers Rule 6(10A)).
        ecommerce_has_coo_filter: Whether e-commerce platform has COO filter.
    """
    violations = []
    priority_score = 0

    min_req_height = get_min_font_height_mm(pdp_area_cm2)

    # 1. Check MRP - Rule 6(1)(e)
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
        # Check taxes included suffix
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

        # Check font size — three-way: measured-fail, measured-pass, or inconclusive
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

    # 2. Check Net Quantity - Rule 6(1)(b)
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
        # Check font size — three-way: measured-fail, measured-pass, or inconclusive
        font_measurement = net_qty.get("font_measurement", {})
        actual_height = net_qty.get("physical_size_mm")
        font_status = font_measurement.get("status")

        if font_status == "no_scale" or font_status is None:
            violations.append(
                {
                    "violation_id": "V005-INC",
                    "rule_citation": "Rule 7 Table I, LMPC Rules 2011",
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
                    "rule_citation": "Rule 7 Table I, LMPC Rules 2011",
                    "description": f"Net quantity font size ({actual_height}mm) is smaller than required minimum.",
                    "severity": "HIGH",
                    "measured_value": f"{actual_height}mm",
                    "required_format": f"Min {min_req_height}mm",
                    "penalty_range": "Notice for rectification — Rule 32",
                }
            )
            priority_score += 20

    # 3. Check Mfg Date - Rule 6(1)(d)
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

    # 4. Check Country of Origin - Rule 6(1)(j) & Rule 6(10A)
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
    }
