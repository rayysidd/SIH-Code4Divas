"""
Regression test: Dark-background label OCR.

Verifies that extract_text_and_boxes() correctly reads white text on a
dark/black background — the exact scenario that was broken before the
dual-polarity thresholding fix (THRESH_BINARY alone produced unreadable
output for this polarity, causing _looks_like_product_label() to reject
valid labels).

Before the fix, this test would FAIL because:
- cv2.adaptiveThreshold with THRESH_BINARY on a dark background inverts
  the text into near-invisible smears → Tesseract returns ≈0 words
  → _looks_like_product_label() returns is_likely_label=False.

After the fix, the dual-polarity approach (THRESH_BINARY + THRESH_BINARY_INV)
correctly reads the inverted-polarity text.
"""

import os
import sys
import tempfile

import cv2
import numpy as np
import pytest

# Ensure the backend package is importable from test runner
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from ml.ocr.extractor import extract_text_and_boxes
from ml.pipeline import _looks_like_product_label


def _create_dark_bg_label_image(path: str) -> None:
    """
    Generate a synthetic label image: white text on a black background.
    Contains keywords that should trigger the product-label sanity gate.

    Uses a large canvas (1600x1200) with thick text (scale 1.8, thickness 3)
    to ensure Tesseract can reliably read cv2.putText-rendered glyphs.
    """
    img = np.zeros((1200, 1600, 3), dtype=np.uint8)  # Black background

    font = cv2.FONT_HERSHEY_SIMPLEX
    white = (255, 255, 255)
    scale = 1.8
    thickness = 3

    # Typical back-of-pack label fields — generous vertical spacing
    lines = [
        ("MRP Rs 150", (80, 120)),
        ("Inclusive of all taxes", (80, 220)),
        ("Batch No AB12345", (80, 340)),
        ("Mfg Date 01 2026", (80, 460)),
        ("Best Before 12 months", (80, 580)),
        ("Net Qty 250g", (80, 700)),
        ("FSSAI Lic No 12345678901234", (80, 820)),
        ("Manufactured by Test Corp", (80, 940)),
    ]

    for text, origin in lines:
        cv2.putText(img, text, origin, font, scale, white, thickness, cv2.LINE_AA)

    cv2.imwrite(path, img)


@pytest.fixture
def dark_bg_image_path():
    """Create a temporary dark-background label image for testing."""
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
        path = f.name
    _create_dark_bg_label_image(path)
    yield path
    # Cleanup
    if os.path.exists(path):
        os.remove(path)


class TestDarkBackgroundOCR:
    """
    Regression tests for the dual-polarity OCR fix.

    These tests verify that the OCR pipeline correctly handles images with
    light/white text on dark backgrounds (foil pouches, black plastic, etc.)
    """

    def test_extract_text_finds_words_on_dark_bg(self, dark_bg_image_path):
        """
        extract_text_and_boxes() should return a non-trivial number of
        confident words from a dark-background image.

        REGRESSION: Before the fix, this returned ≈0 words because
        THRESH_BINARY produced unreadable output for this polarity.
        """
        results = extract_text_and_boxes(dark_bg_image_path)

        # Should find at least some words — the image has 8 lines of text
        assert len(results) > 3, (
            f"Expected >3 confident words from dark-bg image, got {len(results)}. "
            f"Words found: {[r['text'] for r in results]}"
        )

    def test_dark_bg_label_passes_sanity_gate(self, dark_bg_image_path):
        """
        _looks_like_product_label() should return is_likely_label=True for
        a dark-background image containing standard LMPC keywords.

        REGRESSION: Before the fix, this returned is_likely_label=False
        because the OCR stage failed to extract readable text, so zero
        keywords matched.
        """
        ocr_results = extract_text_and_boxes(dark_bg_image_path)
        label_check = _looks_like_product_label(ocr_results)

        assert label_check["is_likely_label"] is True, (
            f"Dark-bg label failed sanity gate. "
            f"Reason: {label_check.get('reason')}. "
            f"OCR found {len(ocr_results)} words: "
            f"{[r['text'] for r in ocr_results]}"
        )

    def test_dark_bg_detects_specific_keywords(self, dark_bg_image_path):
        """
        Verify that specific label keywords (MRP, Batch, FSSAI) are
        actually present in the OCR output from the dark-bg image.
        """
        results = extract_text_and_boxes(dark_bg_image_path)
        all_text = " ".join(r["text"].lower() for r in results)

        # At least one of these core keywords should be found
        core_keywords = ["mrp", "batch", "fssai", "mfg", "qty"]
        found = [kw for kw in core_keywords if kw in all_text]

        assert len(found) >= 1, (
            f"Expected at least 1 core keyword in dark-bg OCR output. "
            f"Searched for: {core_keywords}. "
            f"Full OCR text: '{all_text}'"
        )
