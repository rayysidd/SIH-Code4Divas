# Software Requirements Specification (SRS)
## LabelLens — Automated LMPC Label Compliance Verification System
### Version 2.0 | IEEE 830 Compliant Structure | SIH 2026

---

> **Document Owner:** Engineering Team (Grasit)
> **Status:** IMPLEMENTATION IN PROGRESS
> **Classification:** Internal — SIH Submission
> **Standard:** IEEE Std 830-1998 (adapted)
> **Last Updated:** September 2026

---

## TABLE OF CONTENTS

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [System Architecture](#3-system-architecture)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [External Interface Requirements](#6-external-interface-requirements)
7. [Data Requirements](#7-data-requirements)
8. [AI/ML Model Requirements](#8-aiml-model-requirements)
9. [Rules Engine Specification](#9-rules-engine-specification)
10. [Security Requirements](#10-security-requirements)
11. [System Constraints](#11-system-constraints)
12. [Appendix A — API Specification](#appendix-a--api-specification)
13. [Appendix B — Data Models](#appendix-b--data-models)
14. [Appendix C — Violation Code Registry](#appendix-c--violation-code-registry)

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification defines the complete functional and
non-functional requirements for LabelLens, an AI-powered label compliance
verification system for Indian Legal Metrology (Packaged Commodities) Rules, 2011.

This document is the source of truth for all engineering decisions. Any feature
built must trace back to a requirement ID in this document.

### 1.2 Scope

**System Name:** LabelLens

**Components Covered:**
- LabelLens Vision Service (core AI/CV backend)
- LabelLens Rules Engine (LMPC compliance logic)
- LabelLens API Gateway (REST API)
- LabelLens Inspector Mobile App (Android)
- LabelLens Web Dashboard (React SPA)
- LabelLens E-Commerce Scraper + Reconciliation Service

**Out of Scope:**
- Physical net quantity verification (requires weighing)
- FSSAI nutrition table full compliance (separate framework)
- Drug pricing compliance (DPCO 2013, separate system)
- Non-Indian regulatory frameworks

### 1.3 Definitions, Acronyms, Abbreviations

| Term | Definition |
|---|---|
| LMPC | Legal Metrology (Packaged Commodities) Rules, 2011 |
| PDP | Principal Display Panel — the primary face of the package |
| MRP | Maximum Retail Price |
| USP | Unit Sale Price |
| GTIN | Global Trade Item Number (barcode number) |
| EAN-13 | European Article Numbering — 13-digit barcode standard |
| OCR | Optical Character Recognition |
| NER | Named Entity Recognition |
| LayoutLMv3 | Multimodal document understanding model (Microsoft Research) |
| GSR | General Statutory Rule (form of Indian gazette notification) |
| Table I | Font-size table for net quantity declared by weight/volume |
| Table II | Font-size table for net quantity declared by length/area/number |
| Confidence Score | System-generated certainty level for each detection/measurement (0.0–1.0) |
| INCONCLUSIVE | System output when confidence is insufficient to make a PASS/FAIL determination |
| SKU | Stock Keeping Unit |

### 1.4 References

- Legal Metrology (Packaged Commodities) Rules, 2011 — GSR 202(E), 07 March 2011
- GSR 629(E), 23 June 2017 — Major Amendment
- GSR 226(E), 28 March 2022 — Unit Sale Price Amendment
- Amendment Rules 2023 — Multi-piece, electronics, edible oil (effective 01 Jan 2024)
- Legal Metrology Act, 2009 (Act No. 1 of 2010)
- GS1 General Specifications v23.0 — EAN-13 barcode dimensional standards
- LayoutLMv3: Pre-training for Document AI (Microsoft, 2022)
- IEEE Std 830-1998: Recommended Practice for Software Requirements Specifications

### 1.5 Overview

Section 2 provides overall system description and context. Sections 3–9 contain
detailed technical requirements organized by subsystem. Appendices contain API
specification, data models, and the complete violation code registry.

### 1.6 Implementation Status

> **Last Updated:** 03 September 2026

The following table tracks the implementation status of each major subsystem.
Requirements marked ✅ are fully implemented and tested. Requirements marked 🔧 are
partially implemented. Requirements marked ❌ are not yet started.

| Subsystem | Status | Notes |
|-----------|--------|-------|
| **Image Capture (Mobile)** | ✅ Implemented | Flutter camera integration with full-frame and zoomed capture modes |
| **Image Preprocessing** | ✅ Implemented | CLAHE contrast enhancement, dynamic adaptive thresholding, multi-pass OCR |
| **OCR Extraction** | ✅ Implemented | Tesseract OCR with 4-pass thresholding (Normal, Inverted, Otsu-V, Otsu-Green), column-aware layout detection, sparse text mode |
| **Barcode Scale Recovery** | ✅ Implemented | EAN-13 detection via pyzbar, mm_per_pixel calibration, confidence-aware output |
| **NLP Declaration Parser** | ✅ Implemented | Coordinate-based spatial heuristics (replaces LayoutLMv3), line grouping, weighted Euclidean distance key-value association |
| **Font Size Measurement** | ✅ Implemented | Pixel-to-mm conversion via barcode reference chain, 3-state output (measured/inconclusive/no_scale) |
| **Rules Engine** | ✅ Implemented | 8 violation codes (V001–V008), Rule 6(1)(b/d/e/j), Rule 7 Table I, GSR 128(E) 2026 amendment |
| **Label Sanity Gate** | ✅ Implemented | 20+ LMPC signal keywords, dual-OCR-mode merge (PSM 6 + PSM 11) |
| **Inspector Mobile App** | ✅ Implemented | Flutter (Android), JWT auth, camera scan, result display with severity tabs, PDF export |
| **Backend API** | ✅ Implemented | FastAPI + Uvicorn, SQLAlchemy + Alembic, JWT auth, RBAC, scan/report/analytics endpoints |
| **Database** | ✅ Implemented | PostgreSQL via SQLAlchemy ORM + Alembic migrations, SQLite fallback for development |
| **Package Shape Classifier** | ❌ Not Started | MobileNetV3-Small planned |
| **PDP Segmentor** | ❌ Not Started | YOLOv8-Seg planned |
| **LayoutLMv3 Classifier** | 🔧 Replaced | Replaced by coordinate-based spatial heuristics in `parser.py` (simulates layout-aware classification without ML model) |
| **Veg/Non-Veg Symbol Detector** | ❌ Not Started | HSV contour detection planned |
| **E-Commerce Scraper** | ❌ Not Started | Playwright-based scraper planned |
| **Cross-Channel Reconciliation** | ❌ Not Started | Depends on E-Commerce Scraper |
| **Web Dashboard (React)** | ❌ Not Started | React 18 SPA planned |
| **PDF Report Generation** | 🔧 Partial | Export PDF button in mobile app, ReportLab integration pending |
| **Offline Mode** | ❌ Not Started | Local SQLite + sync planned |

#### Key Implementation Decisions

1. **LayoutLMv3 → Coordinate-Based Heuristics:** Instead of training a multimodal
   document understanding model (which requires thousands of labeled images), the
   system uses spatial proximity heuristics that match declaration keywords to their
   nearest values using weighted Euclidean distance. This achieves comparable accuracy
   for structured Indian product labels without ML training overhead.

2. **PaddleOCR → Tesseract 5.x Multi-Pass:** Tesseract was chosen for zero-dependency
   deployment on Windows. A 4-pass thresholding pipeline compensates for Tesseract's
   weaker preprocessing compared to PaddleOCR:
   - Pass 1: Adaptive Gaussian (normal polarity) — standard black-on-white text
   - Pass 2: Adaptive Gaussian (inverted) — white-on-dark text (foil pouches)
   - Pass 3: Otsu on HSV Value channel (PSM 11) — colorful/glossy labels
   - Pass 4: Otsu on Green channel (PSM 11) — labels with green/yellow graphics

3. **React Native → Flutter:** The mobile app uses Flutter (Dart) instead of React
   Native for cross-platform development with native camera performance.

4. **YAML Rules → Hardcoded Python:** Rules engine logic is currently implemented
   directly in Python (`rules_engine.py`) for rapid iteration. Migration to YAML
   configuration is planned for production deployment.

---

## 2. Overall Description

### 2.1 Product Perspective

LabelLens is a new standalone system. It interfaces with:
External Systems (reads from): ├── Camera Input (mobile and USB) ├── E-Commerce Platform Listing Pages (web scraping) ├── GS1 India / Open Food Facts (product database) └── Legal Metrology Gazette (rules updates)

External Systems (writes to): ├── PDF Report Output (inspector workflow) └── Webhook Callbacks (e-commerce API integration)

text


### 2.2 Product Functions Summary
Core Functions: ├── F1: Image Capture & Quality Assessment ├── F2: Package Shape Detection & PDP Segmentation
├── F3: Real-World Scale Estimation ├── F4: OCR & Declaration Field Extraction ├── F5: Declaration Field Classification ├── F6: Font Size Measurement (px → mm) ├── F7: PDP Area Computation ├── F8: Table I/II Font-Size Compliance Check ├── F9: Placement Geometry Compliance Check ├── F10: Color Symbol Detection (Veg/Non-Veg) ├── F11: Rules Engine Compliance Evaluation ├── F12: E-Commerce Listing Extraction ├── F13: Cross-Channel Reconciliation ├── F14: Violation Report Generation └── F15: Inspector PDF Export

text


### 2.3 User Classes and Characteristics

| User Class | Technical Level | Primary Interface | Frequency of Use |
|---|---|---|---|
| Legal Metrology Inspector | Low-Medium | Mobile App | Daily |
| QA Manager | Medium-High | Web Dashboard | Weekly/Daily |
| E-Commerce Compliance Lead | High | API + Web Dashboard | Daily (automated) |
| System Administrator | Expert | Admin Console | Weekly |
| Citizen Reporter | Low | Mobile App (simplified) | Occasional |

### 2.4 Operating Environment

**Server:**
- Cloud: AWS / GCP / Azure (cloud-agnostic preferred)
- OS: Ubuntu 22.04 LTS
- Container: Docker + Kubernetes
- Python 3.11+ (AI/ML services)
- Node.js 20 LTS (API gateway)
- React 18 (web dashboard)

**Mobile (Inspector App):**
- Framework: Flutter (Dart)
- OS: Android 10+
- Min RAM: 3 GB
- Camera: Minimum 12MP, autofocus
- Connectivity: Online required (offline mode planned)

**Browser (Web Dashboard):**
- Chrome 110+, Firefox 110+, Edge 110+, Safari 16+

### 2.5 Design and Implementation Constraints

| Constraint | Description |
|---|---|
| C1 | Font-size measurement MUST output in millimetres, not pixels. All pixel measurements must be converted using computed real-world scale factor. |
| C2 | System MUST output a confidence score (0.0–1.0) for every measurement and detection. Never output a PASS/FAIL without a confidence score. |
| C3 | When scale estimation confidence < 0.6, font-size check MUST return INCONCLUSIVE, not PASS or FAIL. |
| C4 | All rule citations in output MUST include the specific rule number, sub-rule, and amendment basis (e.g., "Rule 7(4)(b) Table I as per GSR 629(E), effective 01 Jan 2018"). |
| C5 | Rules engine logic MUST be externalized as configuration (YAML), not hardcoded in application code, to allow rule updates without code redeployment. |
| C6 | The system MUST NOT store the original package images beyond 90 days without explicit user consent (data minimization). |
| C7 | All PII in manufacturer addresses must be handled per IT Act, 2000 data protection provisions. |

---

## 3. System Architecture

### 3.1 High-Level Architecture
┌─────────────────────────────────────────────────────────────┐ │ INGESTION LAYER │ │ [Image Upload] [Camera Stream] [Listing URL] [API] │ └───────────────────────────┬─────────────────────────────────┘ │ ┌───────────────────────────▼─────────────────────────────────┐ │ PREPROCESSING SERVICE │ │ • Image quality assessment (blur, exposure, resolution) │ │ • Deskewing and perspective correction │ │ • Denoising (OpenCV bilateral filter) │ │ • Contrast enhancement (CLAHE) │ │ • Resolution normalization (min 300 DPI equivalent) │ └───────────────────────────┬─────────────────────────────────┘ │ ┌────────────────┴─────────────────┐ │ │ ┌──────────▼───────────┐ ┌───────────▼────────────────┐ │ VISION PIPELINE │ │ E-COMMERCE PIPELINE │ │ │ │ │ │ 1. Shape Classifier │ │ 1. URL Validator │ │ 2. PDP Segmentor │ │ 2. Page Scraper │ │ 3. Scale Estimator │ │ 3. Declaration Extractor │ │ 4. OCR Engine │ │ 4. Cross-Ref Engine │ │ 5. Layout Classifier │ │ │ │ 6. Font Measurer │ └───────────┬────────────────┘ │ 7. Placement Checker │ │ │ 8. Color Classifier │ │ └──────────┬───────────┘ │ │ │ └────────────────┬─────────────────┘ │ ┌───────────────────────────▼─────────────────────────────────┐ │ RULES ENGINE │ │ • Category Router • Exemption Checker │ │ • Table I/II Lookup • Declaration Validator │ │ • USP Validator • MRP Validator • Date Validator │ └───────────────────────────┬─────────────────────────────────┘ │ ┌───────────────────────────▼─────────────────────────────────┐ │ REPORT GENERATOR │ │ • Violation Aggregator • Annotated Image Generator │ │ • PDF Builder (Inspector-Ready) • JSON Output │ └─────────────────────────────────────────────────────────────┘

text


### 3.2 Microservices Decomposition

> **Note (Implementation Status):** The current implementation uses a monolithic FastAPI
> backend with all ML pipeline modules co-located. The microservices decomposition below
> represents the target production architecture.

| Service | Language/Framework | Responsibility | Status |
|---|---|---|---|
| `api-backend` | Python (FastAPI + Uvicorn) | REST API, auth, image upload, ML pipeline orchestration | ✅ Implemented |
| `ocr-extractor` | Python (Tesseract 5.x + OpenCV) | Multi-pass OCR, barcode scale, column-aware extraction | ✅ Implemented |
| `nlp-parser` | Python (regex + coord heuristics) | Spatial-aware declaration field extraction | ✅ Implemented |
| `font-measurer` | Python (OpenCV) | Pixel-to-mm font height conversion via barcode reference | ✅ Implemented |
| `rules-engine` | Python | LMPC compliance evaluation, violation scoring | ✅ Implemented |
| `mobile-app` | Flutter (Dart) | Inspector mobile UI (Android) | ✅ Implemented |
| `preprocessing-service` | Python (OpenCV) | Image enhancement, quality check | ✅ Implemented (in ocr-extractor) |
| `ecommerce-service` | Python (Playwright) | Scrape listings, extract declarations | ❌ Planned |
| `report-service` | Python (ReportLab) | Generate annotated images + PDF reports | 🔧 Partial |
| `web-dashboard` | React 18 | QA Manager and Admin UI | ❌ Planned |
| `database-service` | PostgreSQL + SQLAlchemy + Alembic | Persistent storage | ✅ Implemented |
| `cache-service` | Redis 7 | API cache, job queue | ❌ Planned |

---

## 4. Functional Requirements

> **Format:** REQ-[SUBSYSTEM]-[NUMBER] | Priority [P0/P1/P2/P3]
> Every requirement is atomic, testable, and traceable to a feature in the PRD.

---

### 4.1 Image Capture & Preprocessing

**REQ-IMG-001** | P0
The system shall accept image inputs in JPEG, PNG, HEIC, WEBP, and PDF formats.
Maximum input file size: 25 MB. For video input (cylindrical package): MP4, MOV,
maximum 30 seconds.

**REQ-IMG-002** | P0
The system shall assess image quality before processing and return a structured
quality report with the following fields:
- `blur_score` (0.0–1.0; Laplacian variance normalized)
- `exposure_score` (0.0–1.0; histogram-based)
- `resolution_score` (0.0–1.0; effective DPI estimation)
- `quality_verdict` : "ACCEPTABLE" | "MARGINAL" | "UNACCEPTABLE"
- `rejection_reason` (if UNACCEPTABLE): "TOO_BLURRY" | "UNDEREXPOSED" | "OVEREXPOSED" | "LOW_RESOLUTION"

**REQ-IMG-003** | P0
If `quality_verdict` is "UNACCEPTABLE", the system shall:
- NOT proceed to compliance analysis.
- Return a guided re-capture instruction specifying what is wrong.
- If called from the mobile app, display the re-capture prompt with visual guidance
  overlay indicating the problem area.

**REQ-IMG-004** | P1
The system shall apply the following preprocessing steps in order:
1. Perspective correction (deskew using document corner detection)
2. Denoising (OpenCV bilateral filter, kernel size adaptive to image resolution)
3. Contrast enhancement (CLAHE with clip limit 2.0, tile grid size 8×8)
4. Resolution normalization (upsample if effective DPI < 150; target 300 DPI)

**REQ-IMG-005** | P1
The system shall support multi-image input for a single package scan:
- Minimum: 1 image (front face)
- Recommended: 3 images (front, back, bottom/neck for barcode)
- Maximum: 12 images per scan session
- For cylindrical packages: video input is the recommended path (see REQ-CYL-*)

---

### 4.2 Package Shape Detection and PDP Segmentation

**REQ-PDP-001** | P0
The system shall classify the package shape into one of:
- `RECTANGULAR` (boxes, packets, pouches with flat faces)
- `CYLINDRICAL` (bottles, cans, tubes)
- `IRREGULAR` (sachets, shaped containers)
- `FLAT_SHEET` (stickers, cards)
- `UNKNOWN`

Classification shall output a confidence score. If confidence < 0.7, return
`UNKNOWN` and prompt for user confirmation.

**REQ-PDP-002** | P0
For **RECTANGULAR** packages:
The system shall detect the Principal Display Panel as the largest flat face
of the package visible in the image.
PDP segmentation shall use a YOLO-based region detector trained on packaging images.
Output: PDP bounding box in image pixel coordinates.

**REQ-PDP-003** | P0
For **CYLINDRICAL** packages:
The system shall attempt multi-frame reconstruction if video input is provided.
If only a single image is provided:
- Segment the visible front face as a partial PDP view
- Flag: `PDP_AREA_ESTIMATE_INCOMPLETE: true`
- Do NOT compute PDP area for font-size tier lookup without circumference data
- Return `INCONCLUSIVE` for all font-size compliance checks
- Explain: "Cylindrical package: circumference required for PDP area (Rule 7(2)(b)).
  Provide video or physical dimensions."

**REQ-PDP-004** | P1
For **IRREGULAR** packages:
Apply 40% of estimated total visible surface area as PDP, per Rule 7(2)(c).
Flag: `PDP_AREA_ESTIMATE_METHOD: IRREGULAR_40PCT_HEURISTIC`
Add: confidence penalty of -0.15 to all font-size measurements.

---

### 4.3 Real-World Scale Estimation

**REQ-SCALE-001** | P0
The system shall attempt to detect an EAN-13 barcode in the input image using a
standard barcode decoder (ZXing / pyzbar).

**REQ-SCALE-002** | P0
If an EAN-13 barcode is detected:
- Extract the barcode's pixel width (`barcode_px_width`)
- Extract the GTIN from the barcode
- Query the product dimensions database for the known barcode magnification factor
  (`barcode_magnification_pct`) for that GTIN, if available
- Compute: `actual_barcode_width_mm = 37.29 × (barcode_magnification_pct / 100)`
  (37.29mm is the EAN-13 nominal width at 100%)
- Compute: `px_per_mm = barcode_px_width / actual_barcode_width_mm`
- Output: `scale_factor_px_per_mm`, `scale_confidence`

**REQ-SCALE-003** | P0
Scale confidence shall be computed as:
IF GTIN found in product DB AND magnification confirmed: scale_confidence = 0.85 ELIF GTIN found but magnification assumed 100%: scale_confidence = 0.60 ELIF barcode detected but GTIN not in product DB: scale_confidence = 0.50 (range 80%-200% magnification unknown) ELIF no barcode detected: scale_confidence = 0.00

text


**REQ-SCALE-004** | P0
If `scale_confidence` < 0.6:
- All font-size measurements shall be flagged: `FONT_SIZE_CHECK: INCONCLUSIVE`
- The violation report shall include: "Scale reference insufficient. Provide a
  ruler or calibration card alongside the package for accurate measurement."
- DO NOT output PASS or FAIL for font-size checks.

**REQ-SCALE-005** | P2
The system shall also accept manual scale input from the user:
- User-provided measurement: "This package's height is X mm"
- Or: User places a known reference card (₹1 coin diameter = 21.93mm detected
  via circle detection)
- Override computed scale factor with manually confirmed scale

---

### 4.4 OCR and Declaration Field Extraction

**REQ-OCR-001** | P0
The system shall perform OCR on the PDP region using a primary engine.
Recommended: PaddleOCR (for Indian language support) with Google Vision API as
fallback for low-confidence results.
OCR shall extract:
- All text strings visible on the PDP
- Bounding box (x1, y1, x2, y2) for each text string in image pixels
- Confidence score (0.0–1.0) for each extracted text string
- Detected language (ISO 639-1 code)

**REQ-OCR-002** | P0
The system shall perform OCR in both English and Devanagari (Hindi) as primary
languages. Attempt detection for the following additional scripts if detected:
Tamil, Telugu, Kannada, Malayalam, Bengali, Gujarati, Marathi.
At minimum, English or Devanagari OCR must succeed for compliance evaluation.

**REQ-OCR-003** | P0
Any OCR string with confidence < 0.4 shall be:
- Included in the raw OCR output
- Flagged: `low_confidence: true`
- Not used as basis for a "field present" determination without user confirmation

**REQ-OCR-004** | P1
The system shall handle the following special OCR challenges:
- Curved text on cylindrical surfaces (use perspective dewarp before OCR)
- Text on foil/metallic backgrounds (use adaptive thresholding)
- Embossed/molded text (use side-lighting enhancement or emboss filter)
- Overprinted text (MRP stickers over original price)

---

### 4.5 Declaration Field Classification (LayoutLM-based)

**REQ-CLASS-001** | P0
The system shall classify each OCR-extracted text region into one of the following
declaration types (or `UNKNOWN`):
DECLARATION_TYPES = [ "MANUFACTURER_NAME", "MANUFACTURER_ADDRESS", "PACKER_NAME", "PACKER_ADDRESS", "IMPORTER_NAME", "IMPORTER_ADDRESS", "BRAND_OWNER", "PRODUCT_GENERIC_NAME", "NET_QUANTITY", "MFG_DATE", "EXPIRY_DATE", "MRP", "UNIT_SALE_PRICE", "CUSTOMER_CARE_PHONE", "CUSTOMER_CARE_EMAIL", "COUNTRY_OF_ORIGIN", "VEG_NON_VEG_SYMBOL", # Not text — handled by REQ-COLOR-* "BARCODE", "BEST_BEFORE", "PROMOTIONAL_PRICE", # Struck-through — NOT MRP "REGULATORY_MARK", "INGREDIENT_LIST", "NUTRITIONAL_INFO", "UNKNOWN" ]

text


**REQ-CLASS-002** | P0
Classification shall use a LayoutLMv3-style multimodal model that fuses:
- OCR text tokens
- Bounding box position on PDP (normalized x, y, w, h)
- Visual features of the surrounding image region (via ViT patch embeddings)

This is required because text content alone is insufficient — "100% Natural" can
false-positive as a quantity declaration with text-only regex.

**REQ-CLASS-003** | P0
The system shall distinguish `MRP` from `PROMOTIONAL_PRICE`. Indicators:
- Struck-through formatting → classify as `PROMOTIONAL_PRICE`
- Prefixed with "was", "original", "offer" → `PROMOTIONAL_PRICE`
- Prefixed with "MRP", "Maximum Retail Price", "Rs.", "₹" (without strikethrough) → `MRP`

**REQ-CLASS-004** | P1
For each declaration type in the mandatory list, the system shall output:
- `field_present`: true | false | inconclusive
- `detected_value`: extracted string
- `bounding_box`: pixel coordinates
- `ocr_confidence`: 0.0–1.0
- `classification_confidence`: 0.0–1.0
- `field_confidence`: min(ocr_confidence, classification_confidence)

---

### 4.6 Font Size Measurement

**REQ-FONT-001** | P0
The system shall measure the height of numerals in the following declaration fields:
- Net Quantity numeral (primary focus per Rule 7(4))
- MRP numeral
- USP numeral

**REQ-FONT-002** | P0
Font height measurement procedure:
1. Isolate the bounding box of the numeral string
2. Apply character segmentation (separate individual digit glyphs)
3. For each digit glyph: measure bounding box height in pixels
4. Take the median height across all digits as `numeral_height_px`
5. Convert: `numeral_height_mm = numeral_height_px / scale_factor_px_per_mm`
6. Output: `numeral_height_mm`, `measurement_confidence`

**REQ-FONT-003** | P0
The system shall also measure the letter height (not numeral) for ALL other
declaration text fields per Rule 7(3) (minimum 1mm for all text).

**REQ-FONT-004** | P0
For embossed/molded/blown text detection:
- Apply surface normal estimation or emboss-filter texture analysis
- If `text_rendering_type` = "EMBOSSED" | "MOLDED" | "BLOWN":
  Apply embossed minimum thresholds (Table I column 3; 2mm floor from Rule 7(3))
- Confidence of embossed detection shall be included in output

**REQ-FONT-005** | P0
Font measurement confidence shall be reduced by the following factors:
base_confidence = min(ocr_confidence, scale_confidence) IF text_rendering_type_confidence < 0.7: base_confidence -= 0.15 IF numeral has < 2 digit characters for measurement: base_confidence -= 0.20 font_measurement_confidence = max(0.0, base_confidence)

text


---

### 4.7 PDP Area Computation

**REQ-AREA-001** | P0
For **RECTANGULAR** packages:
Compute PDP area as follows:
1. Detect PDP bounding box in image pixels: width_px × height_px
2. Convert to real-world dimensions using scale factor:
   - `pdp_width_mm = pdp_width_px / scale_factor_px_per_mm`
   - `pdp_height_mm = pdp_height_px / scale_factor_px_per_mm`
3. `pdp_area_cm2 = (pdp_width_mm × pdp_height_mm) / 100`

**REQ-AREA-002** | P0
For **CYLINDRICAL** packages with video/multi-frame input:
1. Extract frames at regular intervals (every 15°)
2. Estimate cylinder height H in mm (from known scale or user input)
3. Estimate diameter D in mm from reconstruction
4. Compute: `circumference_mm = π × D`
5. Compute: `pdp_area_cm2 = 0.40 × (H_mm × circumference_mm) / 100`
Per Rule 7(2)(b): EXCLUDE top/bottom caps, flanges, shoulders, necks from H.

**REQ-AREA-003** | P0
For **CYLINDRICAL** packages with single-image input:
Output `pdp_area_cm2 = null`
Set `pdp_area_computable = false`
Return `INCONCLUSIVE` for all Table I/II font-size checks.

---

### 4.8 Table I/II Font-Size Compliance Check

**REQ-TABLE-001** | P0
The system shall maintain a rules configuration file (YAML) containing Table I
and Table II lookup data. Structure:

```yaml
table_I:
  # Net Quantity declared by Weight or Volume
  - pdp_area_max_cm2: 50
    min_height_printed_mm: 1.0
    min_height_embossed_mm: 1.5   # VERIFY against GSR 629(E) gazette
  - pdp_area_max_cm2: 100
    min_height_printed_mm: 1.5
    min_height_embossed_mm: 3.0
  - pdp_area_max_cm2: 500
    min_height_printed_mm: 2.5
    min_height_embossed_mm: 4.0
  - pdp_area_max_cm2: 2500
    min_height_printed_mm: 4.0
    min_height_embossed_mm: 6.0
  - pdp_area_max_cm2: null  # >= 2500
    min_height_printed_mm: 6.0
    min_height_embossed_mm: 6.0

table_II:
  # Net Quantity declared by Length, Area, or Number
  - pdp_area_max_cm2: 100
    min_height_mm: 1.0
  - pdp_area_max_cm2: 500
    min_height_mm: 2.0
  - pdp_area_max_cm2: 2500
    min_height_mm: 4.0
  - pdp_area_max_cm2: null
    min_height_mm: 6.0

global_minimums:
  all_text_printed_mm: 1.0       # Rule 7(3)
  all_text_embossed_mm: 2.0      # Rule 7(3)
REQ-TABLE-002 | P0 Given:

pdp_area_cm2 (computed)
declaration_unit_type: "WEIGHT_VOLUME" | "LENGTH_AREA_NUMBER"
text_rendering_type: "PRINTED" | "EMBOSSED"
measured_height_mm
The system shall:

Select Table I (if WEIGHT_VOLUME) or Table II (if LENGTH_AREA_NUMBER)
Find the applicable PDP area tier
Select the minimum height column based on rendering type
Compare: measured_height_mm vs. min_required_mm
Output:
table_used: "TABLE_I" | "TABLE_II"
pdp_area_tier: "< 50cm²" | "50–100cm²" | etc.
min_required_mm: threshold value
measured_mm: actual measured value
compliance_status: "PASS" | "FAIL" | "INCONCLUSIVE"
margin_mm: measured_mm - min_required_mm (negative = violation)
REQ-TABLE-003 | P0 Any font-size check returning compliance_status: FAIL shall generate a violation record with:

Violation Code (see Appendix C)
Rule citation: "Rule 7(4) Table I — as per GSR 629(E), effective 01 Jan 2018"
measured_mm
required_mm
margin_mm (how far below threshold)
Annotated crop of the offending text region
4.9 Placement Geometry Check
REQ-PLACE-001 | P0 The system shall verify that the net quantity declaration bounding box falls within the lower 30% of the PDP bounding box.

text

pdp_lower_30pct_y_start = pdp_top_y + (pdp_height × 0.70)
IF net_qty_box_bottom_y >= pdp_lower_30pct_y_start:
    placement_zone_check = PASS
ELSE:
    placement_zone_check = FAIL
    violation_code = VIO-PLACE-001
REQ-PLACE-002 | P0 The system shall verify the clear-space requirement around the net quantity declaration:

text

h = net_qty_numeral_height_mm (measured)

required_clear_above_mm = h
required_clear_below_mm = h
required_clear_left_mm  = 2 × h
required_clear_right_mm = 2 × h

actual_clear_above_mm = distance_to_nearest_element_above
actual_clear_below_mm = distance_to_nearest_element_below
actual_clear_left_mm  = distance_to_nearest_element_left
actual_clear_right_mm = distance_to_nearest_element_right

FOR each direction IN [above, below, left, right]:
    IF actual_clear_mm < required_clear_mm:
        FLAG violation VIO-PLACE-002 with direction and deficit
REQ-PLACE-003 | P1 "Nearest element" for clear-space computation means:

Any other text bounding box
Any graphic element / logo bounding box
Any colored background boundary that creates visual interruption NOT: The PDP border itself (clear space to PDP edge is not required)
4.10 Color Symbol Detection (Veg/Non-Veg)
REQ-COLOR-001 | P1 The system shall detect the veg/non-veg symbol on applicable packages. This is a computer vision detection task, NOT an OCR task.

REQ-COLOR-002 | P1 Detection method:

Search for filled circle-in-square (or filled circle-in-rounded-square) shapes on the PDP using contour detection
For detected shapes, sample the fill color of the inner circle
Classify:
Fill color HSV: H in [70°–170°] = GREEN → "VEGETARIAN"
Fill color HSV: H in [345°–15°] or [0°–15°] = RED → "NON_VEGETARIAN"
Border color must match fill color category
Output: symbol_detected: true | false, symbol_type: "VEG" | "NON_VEG" | "UNKNOWN"
REQ-COLOR-003 | P1 Veg/non-veg symbol is mandatory for:

Food products (per FSSAI)
Cosmetics with animal-derived ingredients (per LMPC)
Soaps (per LMPC)
If the product category matches and the symbol is absent → generate violation.

4.11 E-Commerce Listing Extraction
REQ-ECOM-001 | P1 The system shall accept an e-commerce product listing URL as input. Supported platforms (v1): Amazon.in, Flipkart.com, Meesho.com, JioMart.com, Nykaa.com, BigBasket.com, Myntra.com.

REQ-ECOM-002 | P1 For each listing URL, extract the following fields using a headless browser scraper (Playwright):

text

extracted_fields:
  - product_title (→ generic name)
  - seller_name (→ manufacturer / packer / marketer)
  - seller_address
  - country_of_origin
  - net_quantity
  - mrp (price shown)
  - manufacture_date
  - expiry_date
  - customer_care_details
  - product_description (search for embedded declarations)
REQ-ECOM-003 | P1 Apply the same declaration classification NLP pipeline to the scraped listing text. Output: same structured declaration object as physical label analysis.

REQ-ECOM-004 | P0 Cross-channel reconciliation: When both physical label analysis and listing analysis are available for the same product (matched by GTIN/barcode):

text

FOR each mandatory field IN rule_6_1_declarations:
  IF label_value EXISTS AND listing_value EXISTS:
    IF label_value != listing_value (with tolerance):
      FLAG: CROSS_CHANNEL_MISMATCH
      violation_code: VIO-XREF-001
      label_value: ...
      listing_value: ...
      field: ...
      rule_violated: "Rule 6(10) — GSR 629(E), 23 June 2017"
  ELIF label_value EXISTS AND listing_value MISSING:
    FLAG: LISTING_DECLARATION_MISSING
    violation_code: VIO-XREF-002
REQ-ECOM-005 | P1 MRP cross-reference tolerance:

Exact match required for MRP (no tolerance)
Exception: if physical label has an MRP revision sticker, use sticker value
If listing MRP < label MRP: flag as potential overcharge risk (consumer protection)
If listing MRP > label MRP: flag as definite violation (listing shows wrong price)
4.12 Rules Engine — Complete Mandatory Declaration Checks
The rules engine evaluates results from the vision pipeline against LMPC rules. Each check produces: status (PASS/FAIL/INCONCLUSIVE/EXEMPT), violation code, rule citation, measured value, required value, confidence.

REQ-RULES-001 | P0 The rules engine SHALL perform all 33 checks defined in the PRD Check Master Table (C01–C33) in the following order:

Exemption checks first (C31) — if exempt, suppress all non-applicable checks
Product category routing
Presence checks (C01–C15)
Format checks (C08–C10)
Font size checks (C06, C11, C23, C24)
Placement checks (C25–C27)
Computed-value validation (C17, C19, C20, C32)
Cross-channel checks (C28–C30)
REQ-RULES-002 | P0 The rules engine SHALL support versioned rule sets:

Default: current rules (effective Jan 2024, inclusive of all amendments through 2023)
Legacy: pre-Jan-2018 rules (pre-GSR 629(E)) for packages manufactured before Jan 2018
Version selection based on: user input OR MFG date extracted from label
REQ-RULES-003 | P0 MRP validation (C08–C10): REQ-RULES-MRP

Python

def validate_mrp(mrp_field):
    checks = {
        "prefix_present": bool(re.search(
            r'(MRP|Maximum\s+Retail\s+Price|Max\.\s+Retail\s+Price)',
            mrp_field.text, re.IGNORECASE)),
        "currency_symbol": bool(re.search(
            r'[₹]|Rs\.?', mrp_field.text)),
        "numeric_value": bool(re.search(
            r'\d+\.\d{2}', mrp_field.text)),
        "tax_inclusive": bool(re.search(
            r'[Ii]ncl(usive)?\.?\s+(of\s+)?all\s+[Tt]ax', mrp_field.text)),
        "not_promotional": mrp_field.classification != "PROMOTIONAL_PRICE",
    }
    return checks
REQ-RULES-004 | P0 USP validation (C18–C20): REQ-RULES-USP

Python

def validate_usp(usp_field, mrp_value, net_qty_value, net_qty_unit,
                 product_category):
    # Check exemptions first
    if product_category in ["COMBO", "MULTI_PIECE", "GROUP"]:
        return {"status": "EXEMPT", "reason": "Rule 6(11) exemption — 2023 amendment"}
    
    usp_numeric = extract_numeric(usp_field.text)
    expected_usp = mrp_value / net_qty_value
    usp_per_unit = extract_unit(usp_field.text)
    
    # Check correct unit tier
    expected_unit = get_expected_usp_unit(net_qty_value, net_qty_unit)
    # e.g., 450g → per g; 2kg → per kg; 750ml → per ml; 5L → per L
    
    return {
        "usp_present": usp_field is not None,
        "correct_unit": usp_per_unit == expected_unit,
        "value_matches_mrp": abs(usp_numeric - expected_usp) <= 0.01,
        "two_decimal_places": "." in str(usp_numeric) and len(str(usp_numeric).split(".")[1]) == 2
    }
REQ-RULES-005 | P0 Date validation (C07, C12):

Python

def validate_mfg_date(date_field):
    patterns = [
        r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[,\s]+\d{4}',
        r'(0[1-9]|1[0-2])[/\-]\d{4}',
        r'\d{4}[/\-](0[1-9]|1[0-2])',
    ]
    for pattern in patterns:
        if re.search(pattern, date_field.text, re.IGNORECASE):
            return {"valid_format": True, "parsed_date": ...}
    return {"valid_format": False, "raw_value": date_field.text}

def validate_expiry_date(date_field):
    result = validate_mfg_date(date_field)
    if result["valid_format"]:
        result["is_past_expiry"] = result["parsed_date"] < datetime.now()
    return result
4.13 Violation Report Generation
REQ-REPORT-001 | P0 Every compliance scan shall produce a structured violation report in JSON format with the following top-level structure:

JSON

{
  "scan_id": "uuid",
  "scan_timestamp": "ISO8601",
  "product_identified": {
    "gtin": "string or null",
    "detected_product_name": "string",
    "product_category": "enum",
    "package_shape": "enum",
    "pdp_area_cm2": "float or null",
    "pdp_area_confidence": "float",
    "pdp_area_computable": "boolean"
  },
  "rule_version_applied": "string",
  "overall_verdict": "PASS | FAIL | INCONCLUSIVE",
  "overall_confidence": "float",
  "violation_count": {
    "critical": "int",
    "high": "int",
    "medium": "int",
    "inconclusive": "int"
  },
  "declarations": {
    "<field_name>": {
      "present": "boolean",
      "value": "string",
      "compliance_status": "PASS | FAIL | INCONCLUSIVE | EXEMPT | NOT_APPLICABLE",
      "checks": [...]
    }
  },
  "violations": [...],
  "font_size_measurements": [...],
  "placement_checks": [...],
  "cross_channel_reconciliation": {...},
  "annotated_image_url": "string",
  "pdf_report_url": "string"
}
REQ-REPORT-002 | P0 Each violation object in the violations array shall contain:

JSON

{
  "violation_id": "uuid",
  "violation_code": "VIO-FONT-001",
  "check_id": "C06",
  "rule_violated": "Rule 7(4) Table I",
  "amendment_basis": "GSR 629(E), effective 01 Jan 2018",
  "severity": "CRITICAL | HIGH | MEDIUM",
  "field": "NET_QUANTITY",
  "description": "MRP numeral height measured at 1.8mm; Rule 7(4) Table I requires minimum 2.5mm for PDP area of 220cm² (tier: 100–500cm²). Violation margin: -0.7mm.",
  "measured_value": "1.8mm",
  "required_value": "2.5mm",
  "margin": "-0.7mm",
  "confidence": 0.82,
  "bounding_box": {"x1": 142, "y1": 380, "x2": 210, "y2": 405},
  "annotated_crop_url": "string",
  "remediation": "Increase MRP numeral font size to minimum 2.5mm for this package's PDP area of 220cm²."
}
REQ-REPORT-003 | P0 PDF report generation shall produce an inspector-ready document containing:

Page 1: Summary (product, scan date, overall verdict, violation count table)
Page 2+: One section per violation with: rule citation, annotated crop, measured vs. required values, remediation guidance
Final page: System metadata, confidence statements, disclaimer
REQ-REPORT-004 | P1 The PDF report footer shall include a legally appropriate disclaimer: "This report is generated by an automated AI system for preliminary compliance assessment only. Final compliance determination must be made by an authorized Legal Metrology Officer. Evidence should be verified before use in enforcement."

5. Non-Functional Requirements
5.1 Performance Requirements
REQ-NFR-PERF-001 | P0 Single package compliance scan (flat rectangular package, good lighting, barcode present) → complete violation report: ≤ 10 seconds (95th percentile).

REQ-NFR-PERF-002 | P1 E-commerce listing extraction and compliance check: ≤ 30 seconds per URL.

REQ-NFR-PERF-003 | P1 PDF report generation: ≤ 5 seconds after compliance evaluation.

REQ-NFR-PERF-004 | P1 API Gateway: ≤ 500ms response time for non-AI endpoints (report fetch, user management). ≤ 15s for AI processing endpoints (P95).

REQ-NFR-PERF-005 | P2 Bulk listing audit: 50,000 URLs processed in ≤ 12 hours (overnight batch). This requires 5+ parallel scraper workers.

5.2 Reliability Requirements
REQ-NFR-REL-001 | P1 System uptime: 99.5% monthly for API and web dashboard.

REQ-NFR-REL-002 | P1 If the AI vision service is unavailable, the API shall return a graceful error (HTTP 503) with retry-after header. It shall NOT return a false PASS or FAIL.

REQ-NFR-REL-003 | P1 Inspector mobile app shall function fully offline for:

Camera capture
Local storage of up to 100 scan sessions
Report viewing for previously completed scans Sync shall occur automatically when connectivity is restored.
5.3 Scalability Requirements
REQ-NFR-SCALE-001 | P2 The vision service shall be horizontally scalable via container orchestration (Kubernetes). Auto-scale threshold: CPU > 70% for > 60 seconds.

REQ-NFR-SCALE-002 | P2 The system shall support up to 500 concurrent scan requests without degradation.

5.4 Accuracy Requirements
REQ-NFR-ACC-001 | P0 Declaration presence detection accuracy: ≥ 90% on a benchmark test set of 100 diverse packages.

REQ-NFR-ACC-002 | P0 Font size measurement error: ≤ ±0.3mm on flat rectangular packages with a confirmed scale reference (barcode with known magnification).

REQ-NFR-ACC-003 | P0 False positive rate (flagging a compliant label as non-compliant): ≤ 8% on the benchmark test set.

REQ-NFR-ACC-004 | P0 Veg/Non-veg symbol classification accuracy: ≥ 95% on a test set of 200 symbol images under varied lighting conditions.

5.5 Usability Requirements
REQ-NFR-USE-001 | P1 Inspector mobile app: A Legal Metrology Officer with no prior training shall be able to complete a package scan and generate a PDF report in ≤ 5 minutes on first use.

REQ-NFR-USE-002 | P1 The inspector app shall support Hindi UI language as the default, with English as an alternate option.

REQ-NFR-USE-003 | P1 Web dashboard: A QA manager shall be able to upload a label image and view the compliance report in ≤ 3 clicks / steps from login.

5.6 Maintainability Requirements
REQ-NFR-MAINT-001 | P0 All LMPC rule thresholds (font size minimums, PDP area tier boundaries, mandatory field list) shall be stored in externalized YAML configuration files, not hardcoded in application logic. Rule updates shall require only a config file change and service restart, not a code change.

REQ-NFR-MAINT-002 | P1 The system shall log the version of the rules configuration applied to every scan. This creates an audit trail for enforcement actions.

REQ-NFR-MAINT-003 | P1 Code coverage: ≥ 80% for the rules engine module (unit tested). Every check in the Check Master Table shall have a corresponding unit test.

6. External Interface Requirements
6.1 User Interfaces
Refer to the UI/UX Specification document (Document 3 of 3) for detailed screen designs, user flows, and interaction patterns.

High-level interface requirements:

REQ-UI-001 | P0 Inspector Mobile App shall display scan results in a traffic-light format:

🔴 Red: FAIL (critical violations present)
🟡 Yellow: INCONCLUSIVE (check requires human judgment)
🟢 Green: PASS (all checks passed)
REQ-UI-002 | P0 Each violation in the mobile app shall be displayable as:

One-line summary (rule code + short description)
Expandable detail view (full description + annotated crop)
REQ-UI-003 | P1 Web dashboard shall support drag-and-drop image upload.

6.2 Hardware Interfaces
REQ-HW-001 | P1 Android camera integration: access camera via Android Camera2 API through React Native camera bridge. Support autofocus, torch control, and resolution selection.

REQ-HW-002 | P2 USB microscope / calibrated camera: optional integration for high-accuracy font-size measurement in lab/office settings.

6.3 Software Interfaces
Interface	Protocol	Auth Method	Data Format
GS1 India Product Database	HTTPS REST	API Key	JSON
Open Food Facts API	HTTPS REST	None (public)	JSON
Google Vision API (fallback OCR)	HTTPS REST	OAuth 2.0 / API Key	JSON
PaddleOCR	Internal library call	N/A	NumPy array
E-Commerce Sites (scraping)	HTTPS	Session cookie simulation	HTML
PostgreSQL 15	TCP (libpq)	Username/Password + SSL	SQL
Redis 7	TCP	Password + TLS	Redis protocol
S3-compatible storage	HTTPS	IAM / access key	REST
6.4 Communications Interfaces
REQ-COMM-001 | P0 All API communications shall use HTTPS (TLS 1.3 minimum).

REQ-COMM-002 | P0 Mobile app shall use HTTPS for all server communications. Local SQLite database shall be encrypted at rest using SQLCipher.

REQ-COMM-003 | P1 Webhook callbacks for e-commerce API integration shall use HTTPS POST with HMAC- SHA256 request signing.

7. Data Requirements
7.1 Data Entities
Entity: ScanSession

text

scan_id         UUID PRIMARY KEY
user_id         UUID FK → User
scan_timestamp  TIMESTAMPTZ NOT NULL
product_gtin    VARCHAR(14)
product_name    TEXT
package_shape   ENUM(RECTANGULAR, CYLINDRICAL, IRREGULAR, FLAT_SHEET, UNKNOWN)
pdp_area_cm2    DECIMAL(10,2)
pdp_area_confidence DECIMAL(3,2)
overall_verdict ENUM(PASS, FAIL, INCONCLUSIVE)
overall_confidence DECIMAL(3,2)
rule_version    VARCHAR(20) NOT NULL
scan_mode       ENUM(INSPECTOR, QA_MANAGER, API, CITIZEN)
input_image_url TEXT NOT NULL
annotated_image_url TEXT
pdf_report_url  TEXT
created_at      TIMESTAMPTZ DEFAULT NOW()
Entity: Violation

text

violation_id    UUID PRIMARY KEY
scan_id         UUID FK → ScanSession
violation_code  VARCHAR(20) NOT NULL
check_id        VARCHAR(10) NOT NULL
rule_cited      TEXT NOT NULL
amendment_basis TEXT
severity        ENUM(CRITICAL, HIGH, MEDIUM)
field_name      VARCHAR(50)
description     TEXT NOT NULL
measured_value  TEXT
required_value  TEXT
margin          TEXT
confidence      DECIMAL(3,2) NOT NULL
bounding_box    JSONB
crop_url        TEXT
remediation     TEXT
created_at      TIMESTAMPTZ DEFAULT NOW()
Entity: Declaration

text

declaration_id  UUID PRIMARY KEY
scan_id         UUID FK → ScanSession
field_type      ENUM(see DECLARATION_TYPES above)
raw_text        TEXT
parsed_value    JSONB
bounding_box    JSONB
ocr_confidence  DECIMAL(3,2)
class_confidence DECIMAL(3,2)
field_confidence DECIMAL(3,2)
present         BOOLEAN
compliance_status ENUM(PASS, FAIL, INCONCLUSIVE, EXEMPT, NOT_APPLICABLE)
Entity: FontMeasurement

text

measurement_id  UUID PRIMARY KEY
scan_id         UUID FK → ScanSession
declaration_id  UUID FK → Declaration
field_type      VARCHAR(50)
numeral_height_px DECIMAL(8,2)
scale_px_per_mm DECIMAL(8,4)
numeral_height_mm DECIMAL(6,2)
rendering_type  ENUM(PRINTED, EMBOSSED, MOLDED, BLOWN, UNKNOWN)
table_used      ENUM(TABLE_I, TABLE_II, RULE_7_3_BASELINE)
pdp_area_tier   VARCHAR(30)
min_required_mm DECIMAL(4,2)
compliance      ENUM(PASS, FAIL, INCONCLUSIVE)
margin_mm       DECIMAL(5,2)
confidence      DECIMAL(3,2)
Entity: EcommerceReconciliation

text

recon_id        UUID PRIMARY KEY
scan_id         UUID FK → ScanSession
listing_url     TEXT NOT NULL
platform        ENUM(AMAZON, FLIPKART, MEESHO, JIOMART, NYKAA, BIGBASKET, OTHER)
scrape_timestamp TIMESTAMPTZ
field_name      VARCHAR(50)
label_value     TEXT
listing_value   TEXT
match_status    ENUM(MATCH, MISMATCH, LABEL_ONLY, LISTING_ONLY)
violation_code  VARCHAR(20)
7.2 Data Retention
Data Type	Retention Period	Reason
Original input images	90 days (default)	Data minimization; user consent required for longer
Annotated violation images	1 year	Evidence for enforcement
Violation reports (JSON)	5 years	Audit trail
PDF reports	5 years	Legal evidence
Scan metadata	7 years	Compliance history
E-commerce scrape snapshots	90 days	Evidence per enforcement cycle
8. AI/ML Model Requirements
8.1 Package Shape Classifier
REQ-ML-SHAPE-001

Architecture: MobileNetV3-Small (optimized for mobile inference)
Input: RGB image, 224×224px
Output: Probability vector over 5 shape classes
Training Data: Minimum 2,000 labeled package images (synthetic augmented)
Target Accuracy: ≥ 85% on test set
8.2 PDP Segmentor
REQ-ML-PDP-001

Architecture: YOLOv8-Seg (segmentation variant)
Input: RGB image, 640×640px
Output: Segmentation mask for PDP region + bounding box
Training Data: Minimum 1,500 labeled package images with PDP annotations
Target IoU: ≥ 0.80 on test set
8.3 Declaration Field Classifier
REQ-ML-CLASS-001

Architecture: LayoutLMv3 (fine-tuned) or Donut (Document Understanding Transformer) — both are multimodal (text + layout + image)
Input: OCR token list with bounding boxes + PDP image patch
Output: Class label per token/token-group from DECLARATION_TYPES enum
Training Data:
Phase 1: Synthetic packages (procedurally generated with known ground truth) Minimum 5,000 synthetic images with deliberate violations injected
Phase 2: Fine-tune on 200–500 hand-labeled real packages
Target Field-Level F1: ≥ 0.88 on test set
8.4 Synthetic Data Generator (Training Data Pipeline)
REQ-ML-SYNTH-001 The system shall include a procedural label image generator capable of producing:

Randomized package templates (rectangular, various sizes)
Randomized placement of all 10 Rule 6(1) declarations
Deliberate violation injection:
Font size set below Table I/II minimum (known exact value)
Field deliberately omitted (with probability)
MRP with missing "Inclusive of all taxes" suffix
Net quantity in wrong placement zone (above lower 30%)
Clear space violation (insufficient margin around net qty)
Output: image + ground-truth JSON (every field, bounding box, font size, pass/fail per check)
This generator solves the training data problem and is also the answer to the judge question: "How did you train without labeled Indian packaging data?"

8.5 Veg/Non-Veg Symbol Detector
REQ-ML-VEG-001

Architecture: Two-stage: (1) contour-based shape detector for dot-in-square symbol, (2) HSV color classifier for fill color
No ML training required for the core classifier — rule-based HSV thresholding
Optional: CNN-based fine-grained symbol detector for ambiguous cases
Target Accuracy: ≥ 95%
8.6 Model Versioning and Update Policy
REQ-ML-VER-001 All ML models shall be versioned (semantic versioning). The model version used in each scan shall be logged in the ScanSession record.

REQ-ML-VER-002 Active learning loop (Phase 2): When an inspector marks a system prediction as incorrect via the app, that correction shall be logged as a training signal. Monthly model re-training batches shall incorporate verified corrections. New model versions shall be A/B tested before full deployment.

9. Rules Engine Specification
9.1 Rule Configuration Schema
YAML

# rules/lmpc_current.yaml
version: "2024.01"
effective_date: "2024-01-01"
amendment_basis: "LMPC Amendment Rules 2023, effective 01 Jan 2024"
description: "LMPC Rules consolidated through Amendment Rules 2023"

mandatory_declarations:
  - field: MANUFACTURER_NAME
    rule: "6(1)(a)"
    required: true
    applicable_categories: [ALL]
    exemptions: [WHOLESALE, INSTITUTIONAL, TRANSPORT]

  - field: MRP
    rule: "6(1)(e)"
    required: true
    format:
      prefix_required: true
      prefix_patterns: ["MRP", "Maximum Retail Price", "Max. Retail Price"]
      currency_symbol_required: true
      currency_symbols: ["₹", "Rs", "Rs."]
      decimal_places: 2
      tax_suffix_required: true
      tax_suffix_patterns: ["Inclusive of all taxes", "Incl. of all taxes",
                             "Incl. all taxes"]
    applicable_categories: [ALL]
    exemptions: [WHOLESALE, INSTITUTIONAL, TRANSPORT]

  # ... (all 10 fields defined similarly)

font_size_rules:
  table_I:
    applicable_when: declaration_unit_type == "WEIGHT_VOLUME"
    tiers: [...]  # as defined in REQ-TABLE-001

  table_II:
    applicable_when: declaration_unit_type == "LENGTH_AREA_NUMBER"
    tiers: [...]

  rule_7_3_baseline:
    all_text_printed_min_mm: 1.0
    all_text_embossed_min_mm: 2.0

placement_rules:
  net_quantity:
    zone: "LOWER_30PCT_OF_PDP"
    clear_space:
      above_mm_factor: 1.0   # 1 × numeral height
      below_mm_factor: 1.0
      left_mm_factor: 2.0    # 2 × numeral height
      right_mm_factor: 2.0

usp_rules:
  effective_date: "2022-10-01"
  exemptions:
    - "USP_EQUALS_MRP"
    - "COMBO_PACKAGE"
    - "MULTI_PIECE_PACKAGE"
    - "GROUP_PACKAGE"
  unit_mapping:
    weight:
      threshold_kg: 1
      below: "per_g"
      above_or_equal: "per_kg"
    volume:
      threshold_L: 1
      below: "per_ml"
      above_or_equal: "per_L"
10. Security Requirements
REQ-SEC-001 | P0 All API endpoints shall require authentication via JWT (JSON Web Token) with RS256 signing. Token expiry: 1 hour (access), 7 days (refresh).

REQ-SEC-002 | P0 User passwords shall be hashed using bcrypt (work factor ≥ 12). Plaintext passwords shall never be stored or logged.

REQ-SEC-003 | P1 Role-Based Access Control (RBAC):

Role	Permissions
INSPECTOR	Create scans, view own reports, export PDF
QA_MANAGER	Create scans, manage SKU workspace, view org reports
ECOM_LEAD	Access API, bulk audit, cross-channel reconciliation
ADMIN	All permissions + user management + rules config
CITIZEN	Submit reports only (no access to others' data)
REQ-SEC-004 | P1 Input images and PDFs shall be scanned for malware before processing.

REQ-SEC-005 | P1 All data at rest shall be encrypted (AES-256 for databases and storage). All data in transit shall use TLS 1.3.

REQ-SEC-006 | P2 Rate limiting:

Anonymous / Citizen: 10 requests/hour
Inspector: 100 requests/hour
QA Manager: 200 requests/hour
API (Enterprise): 1000 requests/hour (configurable per client)
REQ-SEC-007 | P2 Audit logging: every scan, report access, and user action shall be logged with timestamp, user ID, IP address, and action type. Logs shall be immutable (append-only).

11. System Constraints
Constraint	Value	Reason
Max image upload size	25 MB	API gateway limit; OCR quality plateau
Min camera resolution	12 MP	Font size measurement accuracy
Max video duration (cylindrical)	30 seconds	Processing time budget
Min PaddleOCR confidence for field present	0.40	Below this → INCONCLUSIVE
Min scale confidence for font-size check	0.60	Below this → INCONCLUSIVE
PDF report max size	10 MB	Email attachment compatibility
Mobile app offline storage	100 scan sessions	Device storage budget
Rules config YAML max size	500 KB	Config management practicality
Appendix A — API Specification
Base URL
https://api.labellens.in/v1

Endpoints
POST /check/label
Submit a package image for compliance checking.

Request:

http

POST /check/label
Content-Type: multipart/form-data
Authorization: Bearer {jwt_token}

{
  "images": [file1, file2, ...],       // required, max 12 images
  "video": file,                        // optional, for cylindrical
  "package_shape_hint": "CYLINDRICAL",  // optional
  "product_gtin": "8901234567890",      // optional
  "listing_url": "https://...",         // optional, triggers cross-channel
  "rule_version": "2024.01"             // optional, defaults to current
}
Response 200:

JSON

{
  "scan_id": "uuid",
  "status": "COMPLETED",
  "overall_verdict": "FAIL",
  "overall_confidence": 0.87,
  "violation_count": {"critical": 2, "high": 1, "medium": 0, "inconclusive": 1},
  "violations": [...],
  "declarations": {...},
  "pdf_report_url": "https://...",
  "annotated_image_url": "https://..."
}
Response 202 (async):

JSON

{
  "scan_id": "uuid",
  "status": "PROCESSING",
  "poll_url": "/check/label/status/{scan_id}",
  "estimated_completion_seconds": 15
}
GET /check/label/status/{scan_id}
Poll for async scan completion.

POST /check/listing
Submit an e-commerce listing URL for Rule 6(10) compliance check.

Request:

JSON

{
  "listing_url": "https://www.amazon.in/dp/XXXXX",
  "physical_label_scan_id": "uuid"  // optional, for cross-channel
}
POST /check/crosschannel
Submit both label image and listing URL for reconciliation.

GET /report/{scan_id}
Retrieve full scan report as JSON.

GET /report/{scan_id}/pdf
Download PDF report.

POST /batch/listings
Bulk submit up to 10,000 listing URLs for overnight audit.

Request:

JSON

{
  "listing_urls": ["url1", "url2", ...],
  "webhook_url": "https://your-server.com/webhook",
  "report_email": "compliance@yourcompany.com"
}
Appendix B — Data Models
(See Section 7.1 for complete entity definitions)

B.1 Overall Verdict Logic
Python

def compute_overall_verdict(violations, inconclusive_checks):
    critical_violations = [v for v in violations if v.severity == "CRITICAL"]
    high_violations = [v for v in violations if v.severity == "HIGH"]
    
    if len(critical_violations) > 0:
        return "FAIL", compute_confidence(violations)
    
    if len(high_violations) > 0 and high_confidence(high_violations):
        return "FAIL", compute_confidence(violations)
    
    if len(inconclusive_checks) > 0:
        return "INCONCLUSIVE", compute_confidence_with_uncertainty(
            violations, inconclusive_checks)
    
    return "PASS", compute_confidence(violations)
Appendix C — Violation Code Registry
Code	Severity	Rule	Description
VIO-MISS-001	CRITICAL	Rule 6(1)(a)	Manufacturer/packer/importer name absent
VIO-MISS-002	CRITICAL	Rule 6(1)(a)	Manufacturer/packer/importer address absent
VIO-MISS-003	HIGH	Rule 6(1)(a)	PIN code absent from address
VIO-MISS-004	CRITICAL	Rule 6(1)(b)	Generic product name absent
VIO-MISS-005	CRITICAL	Rule 6(1)(c)	Net quantity declaration absent
VIO-MISS-006	CRITICAL	Rule 6(1)(d)	Manufacture date absent
VIO-MISS-007	CRITICAL	Rule 6(1)(e)	MRP declaration absent
VIO-MISS-008	HIGH	Rule 6(1)(f)	Best before/expiry date absent (where required)
VIO-MISS-009	CRITICAL	Rule 6(1)(g)	Country of origin absent (import)
VIO-MISS-010	HIGH	Rule 6(1)(h)	Customer care contact absent
VIO-MISS-011	HIGH	Rule 6(1)(j)	Veg/non-veg symbol absent (where required)
VIO-MISS-012	HIGH	Rule 6(11)	Unit Sale Price absent (post Oct 2022)
VIO-FORMAT-001	HIGH	Rule 6(1)(e)	MRP missing "Inclusive of all taxes" suffix
VIO-FORMAT-002	MEDIUM	Rule 6(1)(e)	MRP missing currency symbol
VIO-FORMAT-003	MEDIUM	Rule 6(1)(e)	MRP not in two decimal places
VIO-FORMAT-004	HIGH	Rule 6(1)(c)	Net quantity in non-metric units
VIO-FORMAT-005	HIGH	Rule 6(11)	USP per wrong unit tier (g vs. kg error)
VIO-FORMAT-006	MEDIUM	Rule 6(11)	USP value does not match MRP ÷ qty
VIO-FORMAT-007	MEDIUM	Rule 6(1)(d)	Manufacture date format invalid
VIO-FORMAT-008	HIGH	Rule 6(1)(e)	MRP sticker fully obscures original MRP
VIO-FONT-001	CRITICAL	Rule 7(4) Table I	Net qty numeral below Table I minimum
VIO-FONT-002	CRITICAL	Rule 7(4) Table I	MRP numeral below Table I minimum
VIO-FONT-003	CRITICAL	Rule 7(4) Table II	Net qty numeral below Table II minimum
VIO-FONT-004	HIGH	Rule 7(3)	Declaration text below 1mm baseline (printed)
VIO-FONT-005	HIGH	Rule 7(3)	Embossed text below 2mm baseline
VIO-PLACE-001	HIGH	Rule 8(1)	Net qty not in lower 30% of PDP
VIO-PLACE-002	HIGH	Rule 8(1)	Insufficient clear space above/below net qty
VIO-PLACE-003	HIGH	Rule 8(1)	Insufficient clear space left/right of net qty
VIO-LANG-001	CRITICAL	Rule 6(2)	No declaration in English or Hindi
VIO-VEG-001	HIGH	Rule 6(1)(j)	Green veg symbol missing on vegetarian product
VIO-VEG-002	HIGH	Rule 6(1)(j)	Non-veg symbol missing on non-vegetarian product
VIO-XREF-001	CRITICAL	Rule 6(10)	MRP mismatch: label vs. e-commerce listing
VIO-XREF-002	CRITICAL	Rule 6(10)	Net quantity mismatch: label vs. listing
VIO-XREF-003	HIGH	Rule 6(10)	Country of origin missing from listing
VIO-XREF-004	HIGH	Rule 6(10)	Manufacturer info missing from listing
VIO-XREF-005	CRITICAL	Rule 6(10)	Mandatory declaration on listing absent
VIO-OIL-001	HIGH	4th Schedule	Edible oil: weight declaration absent when vol. declared
VIO-DATE-001	HIGH	Rule 6(1)(f)	Product past expiry date
VIO-CTRY-001	CRITICAL	Rule 6(1)(g)	"Country of Origin" text not present on import