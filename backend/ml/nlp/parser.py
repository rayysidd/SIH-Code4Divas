"""
NLP Parsing Module.
Implements REQ-ML-004: Parse raw OCR text into structured entities.
Upgraded to use bounding-box heuristics (Simulating LayoutLMv3).
"""

import re
from typing import List, Dict, Any, Optional

def parse_declarations(ocr_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Parses a list of OCR text fragments to find specific LMPC declarations.
    """
    import json
    with open("debug_ocr.json", "w") as f:
        json.dump(ocr_results, f, indent=2)
        
    grouped_lines = _group_lines(ocr_results)
    with open("debug_ocr_grouped.json", "w") as f:
        json.dump(grouped_lines, f, indent=2)
        
    declarations = {
        "MRP": _extract_mrp(grouped_lines),
        "NET_QUANTITY": _extract_net_quantity(grouped_lines),
        "MFG_DATE": _extract_mfg_date(grouped_lines),
        "COUNTRY_OF_ORIGIN": _extract_country_of_origin(grouped_lines),
    }
    
    return declarations

def _get_bounding_box_for_match(match_text: str, ocr_results: List[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
    """
    Heuristic: Finds the maximum bounding box height among the OCR chunks that make up the match.
    In a real LayoutLMv3 system, the model directly classifies the bounding box.
    """
    matched_boxes = []
    # Simple token overlap check
    match_tokens = match_text.lower().split()
    
    for res in ocr_results:
        res_text = res["text"].lower()
        if any(token in res_text or res_text in token for token in match_tokens if len(token) > 1):
            matched_boxes.append(res["box"])
            
    if not matched_boxes:
        return None
        
    # Create a bounding box that encompasses the found boxes
    min_x = min(b["x"] for b in matched_boxes)
    min_y = min(b["y"] for b in matched_boxes)
    max_x = max(b["x"] + b["w"] for b in matched_boxes)
    
    # We mainly care about the maximum height of the characters for Rule 7
    max_h = max(b["h"] for b in matched_boxes)
    
    return {
        "x": min_x,
        "y": min_y,
        "w": max_x - min_x,
        "h": max_h
    }

def _distance(box1, box2):
    c1_x = box1["x"] + box1["w"] / 2
    c1_y = box1["y"] + box1["h"] / 2
    c2_x = box2["x"] + box2["w"] / 2
    c2_y = box2["y"] + box2["h"] / 2
    # Heavily penalize vertical distance over horizontal, because text on the same line
    # (even if far to the right) is much more related than text below it.
    return (c1_x - c2_x)**2 + ((c1_y - c2_y) * 5)**2

def _group_lines(ocr_results: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    if not ocr_results: return []
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
                lines.append({"text": text, "confidence": conf, "box": {"x": min_x, "y": min_y, "w": max_x - min_x, "h": max_h}})
            current_line = [box]
            
    if current_line:
        min_x = min(b["box"]["x"] for b in current_line)
        min_y = min(b["box"]["y"] for b in current_line)
        max_x = max(b["box"]["x"] + b["box"]["w"] for b in current_line)
        max_h = max(b["box"]["h"] for b in current_line)
        text = " ".join(b["text"] for b in current_line)
        conf = sum(b["confidence"] for b in current_line) / len(current_line)
        lines.append({"text": text, "confidence": conf, "box": {"x": min_x, "y": min_y, "w": max_x - min_x, "h": max_h}})
        
    return lines

def _find_nearest_value(key_pattern: str, value_pattern: str, ocr_results: List[Dict[str, Any]]) -> Optional[tuple]:
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
    min_dist = float('inf')
    
    for k_box in key_boxes:
        for v_box, v_match in value_boxes:
            # Heuristic: Value should generally be to the right or below the key
            # We add a heavy penalty if the value is above or far to the left
            dx = v_box["box"]["x"] - k_box["box"]["x"]
            dy = v_box["box"]["y"] - k_box["box"]["y"]
            
            penalty = 1.0
            if dx < -k_box["box"]["w"]: penalty += 3.0 # Far left
            if dy < -k_box["box"]["h"]: penalty += 3.0 # Above
            
            dist = _distance(k_box["box"], v_box["box"]) * penalty
            if dist < min_dist:
                min_dist = dist
                best_match = (v_box, v_match)
                
    if min_dist > 1000000:
        return None
        
    return best_match

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
        "physical_size_mm": None
    }
    
    if match_tuple:
        v_box, v_match = match_tuple
        result["present"] = True
        result["value"] = float(v_match.group(1))
        result["raw_text"] = v_box["text"]
        result["bounding_box"] = v_box["box"]
        result["confidence"] = 0.92
        
        # Check if taxes suffix exists anywhere in the doc
        combined_text = " ".join([r['text'] for r in ocr_results])
        if re.search(r'tax(?:es)?', combined_text, re.IGNORECASE):
            result["taxes_included_suffix"] = True
            
    return result

def _extract_net_quantity(ocr_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    # Key: Net Wt, Weight, Qty
    key_pat = r'(?:Net\s*)?(?:Qty|Quantity|Weight|Wt)'
    # Value: Digits followed immediately by a unit, or just digits if unit is separate
    val_pat = r'^(\d+(?:\.\d+)?)\s*(g|kg|ml|l|gram|grams)?$'
    
    match_tuple = _find_nearest_value(key_pat, val_pat, ocr_results)
    
    result = {
        "present": False,
        "value": None,
        "unit": None,
        "raw_text": None,
        "confidence": 0.0,
        "bounding_box": None,
        "physical_size_mm": None,
        "is_dual_declaration": False
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
            # Unit might be in the next box to the right!
            # Let's just find the closest unit to this number box
            unit_match = _find_nearest_value(r'^' + val_pat + r'$', r'^(g|kg|ml|l|gram|grams)$', ocr_results)
            if unit_match:
                unit = unit_match[1].group(1)
        
        if unit:
            result["unit"] = unit.lower()
            
    return result

def _extract_mfg_date(ocr_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    key_pat = r'(?:Mfg|Manufactured|Packed|Pkd|Use\s*by)'
    val_pat = r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}[/-]\d{2,4}|[A-Za-z]{3,}\s*\d{4})'
    
    match_tuple = _find_nearest_value(key_pat, val_pat, ocr_results)
    
    result = {
        "present": False,
        "value": None,
        "raw_text": None,
        "bounding_box": None,
        "physical_size_mm": None
    }
    
    if match_tuple:
        v_box, v_match = match_tuple
        result["present"] = True
        result["value"] = v_match.group(1)
        result["raw_text"] = v_box["text"]
        result["bounding_box"] = v_box["box"]
        
    return result

def _extract_country_of_origin(ocr_results: List[Dict[str, Any]]) -> Dict[str, Any]:
    # For country of origin, it's usually on a single line, so combined text is okay, but let's stick to simple text search
    combined_text = " ".join([r['text'] for r in ocr_results])
    coo_pattern = r'(?:Made\s+in|Country\s+of\s+Origin)[\s\.:]*([a-zA-Z\s]+)'
    match = re.search(coo_pattern, combined_text, re.IGNORECASE)
    
    result = {
        "present": False,
        "value": None,
        "raw_text": None,
        "bounding_box": None,
        "physical_size_mm": None
    }
    
    if match:
        result["present"] = True
        words = match.group(1).strip().split()
        result["value"] = " ".join(words[:2]) 
        result["raw_text"] = match.group(0)
        
    return result
