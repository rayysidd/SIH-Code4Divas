"""
Regression test: Multi-column label OCR.

Verifies that extract_text_column_aware() and extract_text_sparse()
correctly handle images with multi-column text layouts, such as back-of-pack
labels with a gutter in the middle.

Before the fix, Tesseract's PSM 6 would read across the gutter on each
scan line, scrambling the text (e.g. mixing column 1 and column 2).
After the fix, we use column-aware splitting (for declarations) and
a sparse PSM 11 pass (for keyword detection).
"""

import os
import sys
import tempfile

import cv2
import numpy as np
import pytest

# Ensure the backend package is importable from test runner
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from ml.ocr.extractor import (
    extract_text_column_aware,
    extract_text_sparse,
    _detect_column_gap,
)
from ml.pipeline import _looks_like_product_label, process_label_image


def _create_two_column_label_image(path: str) -> None:
    """
    Generate a synthetic 2-column label image.
    Left column: Ingredients, Mfg Info
    Right column: Nutritional Info, Prices
    """
    img = np.ones((1200, 1600, 3), dtype=np.uint8) * 255  # White background

    font = cv2.FONT_HERSHEY_SIMPLEX
    black = (0, 0, 0)
    scale = 1.2
    thickness = 2

    # Left column (x=100)
    left_lines = [
        ("INGREDIENTS:", (100, 120)),
        ("Sugar, Water, Coffee Extract", (100, 180)),
        ("Manufactured by:", (100, 300)),
        ("Test Corp Ltd", (100, 360)),
        ("Best Before: 12 months", (100, 480)),
        ("Batch No AB12345", (100, 540)),
        ("Net Qty 250g", (100, 600)),
        ("FSSAI Lic No 12345678901234", (100, 660)),
    ]

    # Right column (x=900) - leaves a wide gutter between x=600 and x=900
    right_lines = [
        ("NUTRITIONAL INFO (per 100g):", (900, 120)),
        ("Energy: 250 kcal", (900, 180)),
        ("Protein: 2g", (900, 240)),
        ("Carbs: 60g", (900, 300)),
        ("MRP Rs 150", (900, 480)),
        ("Inclusive of all taxes", (900, 540)),
        ("Mfg Date 01 2026", (900, 600)),
        ("Customer Care: 1800-000", (900, 660)),
    ]

    for text, origin in left_lines + right_lines:
        cv2.putText(img, text, origin, font, scale, black, thickness, cv2.LINE_AA)

    cv2.imwrite(path, img)


@pytest.fixture
def column_image_path():
    """Create a temporary two-column label image for testing."""
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
        path = f.name
    _create_two_column_label_image(path)
    yield path
    # Cleanup
    if os.path.exists(path):
        os.remove(path)


class TestColumnOCR:
    """
    Regression tests for the multi-column layout OCR fix.
    """

    def test_detect_column_gap(self, column_image_path):
        """
        _detect_column_gap should correctly identify the gutter
        between the two text columns.
        """
        img = cv2.imread(column_image_path)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        gap_x = _detect_column_gap(gray)
        
        # Gutter should be detected roughly in the middle (between x=600 and x=900)
        assert gap_x is not None, "Failed to detect column gap"
        assert 700 <= gap_x <= 850, f"Gap detected at unexpected x: {gap_x}"

    def test_extract_text_column_aware_preserves_order(self, column_image_path):
        """
        extract_text_column_aware should read column-by-column,
        so left column words appear before right column words.
        """
        results = extract_text_column_aware(column_image_path)
        all_text = " ".join(r["text"].lower() for r in results)
        
        # Without column awareness, PSM 6 reads across:
        # "INGREDIENTS: NUTRITIONAL INFO... Sugar, Energy:..."
        # With column awareness, it reads left then right:
        # "... FSSAI Lic No ... NUTRITIONAL INFO ..."
        
        # Check that a left-column item (FSSAI) appears BEFORE a right-column top item (Nutritional)
        idx_fssai = all_text.find("fssai")
        idx_nutritional = all_text.find("nutritional")
        
        assert idx_fssai != -1, "FSSAI not found in OCR output"
        assert idx_nutritional != -1, "Nutritional not found in OCR output"
        assert idx_fssai < idx_nutritional, (
            "Right column read before left column finished. "
            "Text appears scrambled across columns."
        )

    def test_pipeline_passes_sanity_gate(self, column_image_path):
        """
        Process label image should correctly pass the sanity gate
        by combining sparse and column-aware results.
        """
        result = process_label_image(column_image_path)
        
        assert result["status"] == "success", (
            f"Failed sanity gate or pipeline. Result: {result}"
        )
