"""
Font Measurement Module.
Implements REQ-ML-003: Calculate physical font size in mm from image pixels.

Two functions available:
  - calculate_physical_font_size(): Legacy, returns bare float (mm).
  - measure_font_height_mm(): Enhanced, returns confidence-aware dict
    with status, confidence interval, and rule-compliance readiness.
"""

from typing import Dict, Optional


def calculate_physical_font_size(
    bounding_box: Dict[str, float], 
    image_dpi: Optional[float] = None,
    reference_object_pixels: Optional[float] = None,
    reference_object_mm: Optional[float] = None
) -> float:
    """
    Calculate the physical height of a font in millimeters based on its bounding box.
    
    Needs either the image DPI or a reference object mapping (e.g., a known 
    barcode width or a standard credit card in the frame).
    
    Args:
        bounding_box: Dictionary with 'h' (height in pixels).
        image_dpi: Resolution of the image in Dots Per Inch.
        reference_object_pixels: Height/Width of a known object in pixels.
        reference_object_mm: Physical Height/Width of that object in mm.
        
    Returns:
        float: Calculated height in millimeters.
    """
    pixel_height = bounding_box.get('h', 0)
    
    if pixel_height <= 0:
        return 0.0
        
    # Method 1: Using known reference object in the scene (preferred for mobile scans)
    if reference_object_pixels and reference_object_mm:
        # mm_per_pixel = reference_mm / reference_pixels
        mm_per_pixel = reference_object_mm / reference_object_pixels
        return pixel_height * mm_per_pixel
        
    # Method 2: Using EXIF DPI (common for flatbed scanners, less reliable for mobile)
    if image_dpi and image_dpi > 0:
        # 1 inch = 25.4 mm
        # height_inches = pixels / DPI
        # height_mm = height_inches * 25.4
        return (pixel_height / image_dpi) * 25.4
        
    # Fallback/Heuristic: Assume a standard mobile camera focal length / distance
    # For a typical 1080p image taken at 15cm distance, ~10 pixels ≈ 1mm.
    # This is a highly inaccurate fallback and should be flagged as low confidence.
    return pixel_height * 0.1


def measure_font_height_mm(
    bounding_box: Dict[str, float],
    mm_per_pixel: Optional[float] = None,
    confidence: float = 1.0
) -> Dict:
    """
    Converts a pixel bounding box to physical mm height with confidence-aware output.
    
    This is the primary function used by the ML pipeline for LMPC Rule 7
    (Table I) font size verification. It returns structured data suitable
    for the rules engine verdict.
    
    Args:
        bounding_box: {'x': int, 'y': int, 'w': int, 'h': int} from OCR.
        mm_per_pixel: Physical scale from barcode calibration (EAN-13 reference chain).
                      Obtained from ocr.extractor.extract_barcode_scale().
        confidence: Confidence in the mm_per_pixel estimate (0.0–1.0).
                    Barcode-based calibration typically yields 0.8–0.95.
                    Heuristic fallback yields < 0.5.
    
    Returns:
        dict with keys:
            measured_mm (float|None): Physical height in millimeters.
            confidence (float): Confidence score for the measurement.
            confidence_interval (list|None): [lower_bound_mm, upper_bound_mm] at ~80% CI.
            status (str): 'measured' | 'inconclusive' | 'no_scale'
                - 'measured': confident result, usable for pass/fail verdict.
                - 'inconclusive': low confidence, recommend physical verification.
                - 'no_scale': no mm_per_pixel available, cannot measure.
    """
    pixel_height = bounding_box.get('h', 0)
    
    # No scale reference available
    if not mm_per_pixel or mm_per_pixel <= 0 or pixel_height <= 0:
        return {
            'measured_mm': None,
            'confidence': 0.0,
            'confidence_interval': None,
            'status': 'no_scale'
        }
    
    # Core measurement: pixel height × physical scale
    measured = pixel_height * mm_per_pixel
    
    # Uncertainty model:
    # The primary source of error is the barcode magnification assumption.
    # EAN-13 magnification ranges 80%–200% (SC0–SC9), but FMCG goods
    # typically use 80%–120%. We model uncertainty proportional to (1 - confidence).
    # At confidence=1.0 → ±0% error; at confidence=0.5 → ±25% error.
    uncertainty_fraction = (1.0 - confidence) * 0.5
    uncertainty = measured * uncertainty_fraction
    
    lower_bound = max(0.0, measured - uncertainty)
    upper_bound = measured + uncertainty
    
    # Status determination:
    # Below 0.6 confidence, the measurement is too unreliable for automated
    # pass/fail verdicts — flag for physical verification by inspector.
    if confidence >= 0.6:
        status = 'measured'
    else:
        status = 'inconclusive'
    
    return {
        'measured_mm': round(measured, 2),
        'confidence': round(confidence, 2),
        'confidence_interval': [
            round(lower_bound, 2),
            round(upper_bound, 2)
        ],
        'status': status
    }
