"""
OCR Extraction Module.
Implements REQ-ML-002: Extract text and bounding boxes from label images.
Implements REQ-ML-001 (Reference Chain): Physical scale recovery via Barcode.
"""

import os
import platform
import cv2
import numpy as np
import pytesseract
from typing import List, Dict, Any

try:
    from pyzbar.pyzbar import decode

    PYZBAR_AVAILABLE = True
except (ImportError, FileNotFoundError, OSError):
    PYZBAR_AVAILABLE = False
    print("Warning: pyzbar not available (missing DLLs). Barcode scanning disabled.")

# ── Tesseract binary path configuration ──────────────────────────────────────
# Configure tesseract binary path explicitly — do not rely on PATH alone.
_TESSERACT_CMD = os.environ.get("TESSERACT_CMD")
if _TESSERACT_CMD:
    pytesseract.pytesseract.tesseract_cmd = _TESSERACT_CMD
elif platform.system() == "Windows":
    # Common default install location on Windows
    _default_win_path = r"C:\Program Files\Tesseract-OCR\tesseract.exe"
    if os.path.exists(_default_win_path):
        pytesseract.pytesseract.tesseract_cmd = _default_win_path

# EAN-13 nominal width at 100% magnification is ~37.29mm
EAN13_NOMINAL_WIDTH_MM = 37.29


def verify_ocr_available() -> None:
    """Call this once at FastAPI startup. Raises if Tesseract is not usable."""
    try:
        version = pytesseract.get_tesseract_version()
        print(f"[OCR] Tesseract version {version} detected and working.")
    except Exception as e:
        raise RuntimeError(
            f"Tesseract OCR is not available: {e}\n"
            f"Set TESSERACT_CMD environment variable to the tesseract binary path, "
            f"or install Tesseract and ensure it's on your system PATH."
        )


def extract_barcode_scale(image_path: str) -> Dict[str, Any]:
    """
    Detects a barcode in the image and calculates the mm_per_pixel ratio.
    """
    if not PYZBAR_AVAILABLE:
        return {"success": False, "reason": "pyzbar not available"}
    try:
        img = cv2.imread(image_path)
        if img is None:
            return {"success": False, "reason": "Image read error"}

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        barcodes = decode(gray)

        for barcode in barcodes:
            # Check if it's EAN13
            if barcode.type == "EAN13":
                # Bounding box of the barcode
                x, y, w, h = barcode.rect

                # Assume nominal magnification (100%) for standard FMCG goods
                # A more advanced version would look up the specific GTIN magnification
                mm_per_pixel = EAN13_NOMINAL_WIDTH_MM / w

                return {
                    "success": True,
                    "gtin": barcode.data.decode("utf-8"),
                    "type": barcode.type,
                    "rect": {"x": x, "y": y, "w": w, "h": h},
                    "mm_per_pixel": mm_per_pixel,
                    "confidence_interval": "±20% (due to unknown magnification factor)",
                }

        return {"success": False, "reason": "No EAN-13 barcode found"}

    except Exception as e:
        return {"success": False, "reason": str(e)}


def _run_ocr_on_thresh(thresh_img, custom_config: str) -> List[Dict[str, Any]]:
    """Run Tesseract on a single thresholded image, return confident word results."""
    d = pytesseract.image_to_data(
        thresh_img, config=custom_config, output_type=pytesseract.Output.DICT
    )
    results = []
    n_boxes = len(d["text"])
    for i in range(n_boxes):
        text = d["text"][i].strip()
        conf = int(d["conf"][i])
        if text and conf > 30:
            results.append(
                {
                    "text": text,
                    "confidence": conf / 100.0,
                    "box": {
                        "x": d["left"][i],
                        "y": d["top"][i],
                        "w": d["width"][i],
                        "h": d["height"][i],
                    },
                }
            )
    return results


def _merge_polarities(results_normal: List[Dict[str, Any]], results_inv: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Intelligently merge OCR results from both polarities (normal and inverted).
    Keeps the most confident words from both, avoiding duplicates where they overlap.
    This preserves text in images that contain both dark-on-light and light-on-dark regions.
    """
    def get_iou(boxA, boxB):
        xA = max(boxA["x"], boxB["x"])
        yA = max(boxA["y"], boxB["y"])
        xB = min(boxA["x"] + boxA["w"], boxB["x"] + boxB["w"])
        yB = min(boxA["y"] + boxA["h"], boxB["y"] + boxB["h"])
        interArea = max(0, xB - xA) * max(0, yB - yA)
        if interArea == 0:
            return 0.0
        boxAArea = boxA["w"] * boxA["h"]
        boxBArea = boxB["w"] * boxB["h"]
        return interArea / float(boxAArea + boxBArea - interArea)

    # Penalize inverted results slightly because inverted thresholding often creates thick high-confidence noise
    for r in results_inv:
        r["confidence"] *= 0.90
        
    all_results = results_normal + results_inv
    # Greedily pick highest confidence boxes first
    all_results.sort(key=lambda r: r["confidence"], reverse=True)

    final_results = []
    for r in all_results:
        overlap = False
        for f in final_results:
            if get_iou(r["box"], f["box"]) > 0.3:
                overlap = True
                break
        if not overlap:
            final_results.append(r)

    # Re-sort top-to-bottom, left-to-right to maintain roughly correct reading order
    final_results.sort(key=lambda r: (r["box"]["y"], r["box"]["x"]))
    return final_results


def extract_text_and_boxes(image_path: str) -> List[Dict[str, Any]]:
    """
    Extracts text and bounding box coordinates from an image using Tesseract OCR.

    Uses dual-polarity thresholding to handle both dark-on-light and light-on-dark
    text (e.g. foil pouches, dark plastic packaging). CLAHE is applied first to
    normalize uneven contrast from glossy/reflective surfaces.
    """
    try:
        img = cv2.imread(image_path)
        if img is None:
            raise ValueError(f"Could not read image at {image_path}")

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # Step 2: CLAHE — normalize contrast before thresholding.
        # Helps text on glossy/reflective packaging (foil pouches catch glare
        # unevenly) become more uniformly readable.
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        gray = clahe.apply(gray)

        blur = cv2.GaussianBlur(gray, (3, 3), 0)

        # Step 1: Dual-polarity thresholding — try both text polarities.
        # Dynamically calculate block size based on image resolution to prevent
        # thick text in high-res phone photos from being hollowed out.
        min_dim = min(gray.shape[:2])
        block_size = max(11, (min_dim // 100) | 1)  # Ensure odd number

        # 1. Normal Adaptive Threshold (Good for simple labels)
        thresh_normal = cv2.adaptiveThreshold(
            blur, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, block_size, 10
        )
        
        # 2. Inverted Adaptive Threshold (Good for white-on-dark text)
        thresh_inv = cv2.adaptiveThreshold(
            blur, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, block_size, 10
        )
        
        # 3. Otsu on Value Channel (Good for colorful/complex glossy labels)
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        v_channel = hsv[:,:,2]
        _, thresh_otsu_v = cv2.threshold(v_channel, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        # 4. Otsu on Green Channel (Removes green/yellow graphics touching black text like Veg symbols)
        g_channel = img[:,:,1]
        _, thresh_otsu_g = cv2.threshold(g_channel, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        custom_config = r"--oem 3 --psm 6"
        custom_config_sparse = r"--oem 3 --psm 11"

        data_normal = pytesseract.image_to_data(thresh_normal, config=custom_config, output_type=pytesseract.Output.DICT)
        data_inv = pytesseract.image_to_data(thresh_inv, config=custom_config, output_type=pytesseract.Output.DICT)
        data_otsu = pytesseract.image_to_data(thresh_otsu_v, config=custom_config_sparse, output_type=pytesseract.Output.DICT)
        data_otsu_g = pytesseract.image_to_data(thresh_otsu_g, config=custom_config_sparse, output_type=pytesseract.Output.DICT)

        def _process_tesseract_data(d):
            results = []
            n_boxes = len(d["text"])
            for i in range(n_boxes):
                text = d["text"][i].strip()
                conf = int(d["conf"][i])
                if text and conf > 30:
                    results.append({
                        "text": text,
                        "confidence": conf / 100.0,
                        "box": {"x": d["left"][i], "y": d["top"][i], "w": d["width"][i], "h": d["height"][i]}
                    })
            return results

        results_normal = _process_tesseract_data(data_normal)
        results_inv = _process_tesseract_data(data_inv)
        results_otsu = _process_tesseract_data(data_otsu)
        results_otsu_g = _process_tesseract_data(data_otsu_g)

        return _merge_polarities(results_normal, results_inv + results_otsu + results_otsu_g)

    except pytesseract.TesseractNotFoundError:
        raise RuntimeError(
            "Tesseract binary not found. Set pytesseract.pytesseract.tesseract_cmd "
            "to the full path of tesseract.exe (Windows) or install tesseract-ocr "
            "via your package manager (Linux/Mac) and ensure it's on PATH."
        )
    except Exception as e:
        raise RuntimeError(f"OCR extraction failed: {e}") from e


def extract_text_sparse(image_path: str) -> List[Dict[str, Any]]:
    """
    Extract text using PSM 11 (sparse text — find as much text as possible
    in no particular order). This mode does NOT assume any reading order or
    block structure, making it robust for multi-column layouts where PSM 6
    scrambles text by reading across columns on each scan line.

    Use this for keyword-presence checks (sanity gate) where reading order
    doesn't matter — only whether the words exist somewhere in the image.
    Do NOT use for declaration extraction which needs spatial coherence.
    """
    try:
        img = cv2.imread(image_path)
        if img is None:
            raise ValueError(f"Could not read image at {image_path}")

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # Same CLAHE + blur preprocessing as extract_text_and_boxes
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        gray = clahe.apply(gray)
        blur = cv2.GaussianBlur(gray, (3, 3), 0)

        # Dual-polarity, same as main extractor with dynamic block size
        min_dim = min(gray.shape[:2])
        block_size = max(11, (min_dim // 100) | 1)

        thresh_normal = cv2.adaptiveThreshold(
            blur, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, block_size, 10
        )
        thresh_inv = cv2.adaptiveThreshold(
            blur, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, block_size, 10
        )

        sparse_config = r"--oem 3 --psm 11"

        results_normal = _run_ocr_on_thresh(thresh_normal, sparse_config)
        results_inv = _run_ocr_on_thresh(thresh_inv, sparse_config)

        merged = _merge_polarities(results_normal, results_inv)
        print(f"[OCR-Sparse] Merged polarities: {len(merged)} words (Normal: {len(results_normal)}, Inv: {len(results_inv)})")
        return merged

    except pytesseract.TesseractNotFoundError:
        raise RuntimeError("Tesseract binary not found.")
    except Exception as e:
        raise RuntimeError(f"Sparse OCR extraction failed: {e}") from e


# ── Column-aware extraction ──────────────────────────────────────────────────

def _detect_column_gap(gray_img) -> int | None:
    """
    Detect a vertical gutter between two text columns using a projection
    profile. Returns the x-coordinate of the gap center, or None if no
    clear two-column layout is detected.

    Only looks in the middle third of the image (to avoid matching margins)
    and requires the gap to be at least 2% of the image width.
    """
    h, w = gray_img.shape[:2]

    # Binary threshold for projection (invert so text = white = high values)
    _, binary = cv2.threshold(gray_img, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

    # Vertical projection: sum of white (text) pixels per column
    projection = np.sum(binary, axis=0).astype(float)

    # Smooth to avoid noise spikes — kernel proportional to image width
    kernel_size = max(5, w // 50)
    if kernel_size % 2 == 0:
        kernel_size += 1
    smoothed = np.convolve(projection, np.ones(kernel_size) / kernel_size, mode='same')

    # Only search in the middle third
    search_start = w // 3
    search_end = 2 * w // 3
    search_region = smoothed[search_start:search_end]

    if len(search_region) == 0:
        return None

    # Find the overall text density to set a relative threshold
    overall_mean = np.mean(smoothed)
    if overall_mean < 1.0:
        # Almost no text in the image — can't detect columns
        return None

    # A gutter column has much less text than average — threshold at 20%
    gap_threshold = overall_mean * 0.20

    # Find contiguous low-density runs in the search region
    is_gap = search_region < gap_threshold
    min_gap_width = max(int(w * 0.02), 5)

    best_gap_center = None
    best_gap_width = 0
    current_start = None

    for i, gap in enumerate(is_gap):
        if gap:
            if current_start is None:
                current_start = i
        else:
            if current_start is not None:
                gap_width = i - current_start
                if gap_width >= min_gap_width and gap_width > best_gap_width:
                    best_gap_width = gap_width
                    best_gap_center = search_start + current_start + gap_width // 2
                current_start = None

    # Check if the last run extends to the end
    if current_start is not None:
        gap_width = len(search_region) - current_start
        if gap_width >= min_gap_width and gap_width > best_gap_width:
            best_gap_width = gap_width
            best_gap_center = search_start + current_start + gap_width // 2

    if best_gap_center is not None:
        print(
            f"[OCR-Columns] Detected column gap at x={best_gap_center} "
            f"(width={best_gap_width}px in image of {w}px)"
        )

    return best_gap_center


def extract_text_column_aware(image_path: str) -> List[Dict[str, Any]]:
    """
    Column-aware text extraction: detects whether the label has a two-column
    layout (common on back-of-pack labels), splits at the gutter if found,
    and runs extract_text_and_boxes() on each half independently.

    This prevents Tesseract's PSM 6 from reading across both columns on each
    scan line, which produces scrambled/interleaved text.

    Falls back to full-image extraction if no clear column gap is detected.
    Capped at two-way split only (no 3+ column detection).
    """
    import tempfile

    try:
        img = cv2.imread(image_path)
        if img is None:
            raise ValueError(f"Could not read image at {image_path}")

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        gap_x = _detect_column_gap(gray)

        if gap_x is None:
            # No column gap detected — single-column layout, use full image
            print("[OCR-Columns] No column gap detected, using full-image extraction.")
            return extract_text_and_boxes(image_path)

        h, w = img.shape[:2]
        print(f"[OCR-Columns] Splitting image at x={gap_x} into left [0:{gap_x}] and right [{gap_x}:{w}]")

        # Split into left and right halves
        left_img = img[:, :gap_x]
        right_img = img[:, gap_x:]

        results = []

        # Process left half
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tf:
            left_path = tf.name
        cv2.imwrite(left_path, left_img)
        try:
            left_results = extract_text_and_boxes(left_path)
            results.extend(left_results)
            print(f"[OCR-Columns] Left half: {len(left_results)} words")
        finally:
            if os.path.exists(left_path):
                os.remove(left_path)

        # Process right half — offset bounding boxes by gap_x
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tf:
            right_path = tf.name
        cv2.imwrite(right_path, right_img)
        try:
            right_results = extract_text_and_boxes(right_path)
            for r in right_results:
                r["box"]["x"] += gap_x
            results.extend(right_results)
            print(f"[OCR-Columns] Right half: {len(right_results)} words")
        finally:
            if os.path.exists(right_path):
                os.remove(right_path)

        print(f"[OCR-Columns] Total column-aware: {len(results)} words")
        return results

    except Exception as e:
        # If column detection fails for any reason, fall back gracefully
        print(f"[OCR-Columns] Column detection failed ({e}), falling back to full-image.")
        return extract_text_and_boxes(image_path)

