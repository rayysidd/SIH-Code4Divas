# LABELGUARD AI — PRODUCT REQUIREMENTS DOCUMENT (PRD)
## Automated Multi-Channel Label Compliance Verification System
### Under Indian Legal Metrology (Packaged Commodities) Rules, 2011

---

**Document Control**

| Field | Value |
|---|---|
| Document ID | LG-PRD-001 |
| Version | 1.0.0 |
| Status | Draft — For SIH Submission |
| Created | August 2026 |
| Author | Team LabelGuard |
| Problem Statement | SIH26034 — Automated verification of packaged commodity labels against LMPC Rules |
| Classification | Internal / Hackathon Submission |
| Review Cycle | Before each presentation round |

---

## TABLE OF CONTENTS

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement & Context](#2-problem-statement--context)
3. [Market & Regulatory Context](#3-market--regulatory-context)
4. [Goals & Non-Goals](#4-goals--non-goals)
5. [User Personas](#5-user-personas)
6. [User Stories & Jobs-to-be-Done](#6-user-stories--jobs-to-be-done)
7. [Product Overview & Architecture Vision](#7-product-overview--architecture-vision)
8. [Feature Specifications](#8-feature-specifications)
9. [Success Metrics & KPIs](#9-success-metrics--kpis)
10. [Competitive Landscape](#10-competitive-landscape)
11. [Unique Value Proposition](#11-unique-value-proposition)
12. [Constraints, Assumptions & Dependencies](#12-constraints-assumptions--dependencies)
13. [Release Strategy & Roadmap](#13-release-strategy--roadmap)
14. [Risk Register](#14-risk-register)
15. [Appendix](#15-appendix)

---

## 1. EXECUTIVE SUMMARY

**LabelGuard AI** is an automated, AI-powered label compliance verification platform built specifically for the Indian Legal Metrology (Packaged Commodities) Rules, 2011 (LMPC Rules) and all amendments through 2026.

The platform solves a problem that is real, large-scale, and currently unsolved by any government or commercial tool: **no existing system can automatically verify whether a packaged commodity's label is compliant with Indian LMPC rules — including font size in millimetres, correct placement geometry, Unit Sale Price, cross-channel e-commerce declaration matching, and omni-channel reconciliation.**

Where competing teams will build "OCR → regex → MRP found: PASS," LabelGuard AI builds a fundamentally different product: a **declaration reconciliation engine** that checks whether the same legally-required declarations appear correctly on the physical label, the e-commerce listing, and the QR/e-label — and whether they agree with each other.

This is not an incremental improvement. It is a new category of compliance tool for an enforcement regime that fined Amazon, Flipkart, Meesho, and Meta ₹10 lakh each and raided 22 warehouses (February 2026) precisely because no automated cross-channel verification existed.

---

## 2. PROBLEM STATEMENT & CONTEXT

### 2.1 The Regulatory Reality

The Legal Metrology (Packaged Commodities) Rules, 2011 mandate that every pre-packaged commodity sold in India must carry **10 distinct mandatory declarations** on its Principal Display Panel (PDP). These rules have been substantially amended in 2017, 2021, 2022, 2023, and 2026 — adding Unit Sale Price, Customer Care details, Country of Origin, e-commerce listing obligations, and cross-channel declaration consistency requirements.

**Key facts:**
- Over **10 lakh** registered manufacturers and importers operate in India
- **Approximately 50,000** Legal Metrology inspectors across states handle enforcement
- CCPA and BIS raided **22 warehouses** in February 2026 and flagged **16,970+ non-compliant listings**
- Amazon, Flipkart, Meesho, and Meta were each fined **₹10 lakh** for e-commerce listing non-compliance
- Physical inspection is manual, time-consuming, and entirely dependent on inspector expertise

### 2.2 Why Existing Approaches Fail

| Existing Approach | Why It Fails for LMPC |
|---|---|
| Manual inspector checks | Human-dependent, slow, non-scalable, no cross-channel coverage |
| eMaap portal (Dept. of Consumer Affairs) | License/registration tracking only — no label content verification |
| Label Score AI (GoVisually) | Built for US FDA / EU rules — no concept of mm-font-size tiers scaled to PDP area |
| NutriSight / Open Food Facts | Nutrition table OCR only — no compliance rule engine, no LMPC rules |
| Trax / Focal Systems / ParallelDots | Shelf planogram compliance — completely different problem space |
| Generic OCR + regex | Cannot check: font size in mm, placement geometry, cylindrical PDP area, cross-channel consistency |

### 2.3 The Three Gaps LabelGuard AI Fills

**Gap 1 — Physical Label:** No tool verifies all 10 LMPC declarations including font-size-in-mm against Table I/II thresholds, placement in the lower 30% of PDP, and clear-space geometry rules.

**Gap 2 — E-Commerce Listing:** Rule 6(10) mandates all LMPC declarations on product listing pages. The 2026 amendments make this enforceable. No tool audits listing compliance at scale.

**Gap 3 — Cross-Channel Reconciliation:** A declaration set now legally must exist simultaneously on the physical label, QR/e-label (since 2022 electronics amendment), and e-commerce listing. Nothing checks whether they agree. MRP on the listing must match MRP on the label. Net quantity must match. No tool does this check today.

---

## 3. MARKET & REGULATORY CONTEXT

### 3.1 Regulatory Timeline (Enforcement Urgency)
2011 ──── LMPC Base Rules (GSR 202E) enacted 2017 ──── GSR 629(E): Font size tables, PDP area rules, e-commerce obligations, Country of Origin, Customer Care — MAJOR AMENDMENT 2021 ──── Unit Sale Price introduced 2022 ──── USP finalized (Oct 2022 effective); Second Schedule omitted; QR codes permitted 2023 ──── Multi-piece/combo exemptions; edible oil dual declaration; electronics MFG date 2026 ──── CCPA fines Amazon/Flipkart/Meesho/Meta ₹10L each; BIS raids 22 warehouses; Amendment Rules 2026 — enhanced e-commerce disclosure obligations

text


### 3.2 Enforcement Bodies & Their Needs

| Body | Role | Their Pain Point |
|---|---|---|
| **Legal Metrology Officers (state)** | Physical inspection | Manual, time-consuming, relies entirely on inspector training |
| **CCPA (Central Consumer Protection Authority)** | E-commerce enforcement | No automated tool to audit millions of product listings |
| **BIS (Bureau of Indian Standards)** | Quality/standards enforcement | Warehouse raids are reactive — no proactive listing monitoring |
| **District Collectors / State Controllers** | Complaint handling | No structured digital evidence format from field inspectors |
| **Manufacturers / Brand Owners** | Self-compliance | No self-audit tool that reflects actual LMPC rules (not FDA/EU rules) |
| **E-commerce Platforms (Amazon, Flipkart)** | Platform compliance | Need seller-facing compliance tool before listing goes live |

### 3.3 Market Size Estimate

- ~10 lakh registered manufacturers/importers in India (Legal Metrology Dept. data)
- ~7 crore+ SKUs on major Indian e-commerce platforms
- Compliance software market in India: growing at ~18% CAGR (2024–2029)
- Addressable B2G segment (government licensing): Direct contract potential with 28 state LM departments

---

## 4. GOALS & NON-GOALS

### 4.1 Goals — Version 1.0 (MVP / Hackathon Demo)

| Goal | Priority | Success Criterion |
|---|---|---|
| Detect all 10 mandatory LMPC declarations from a product label photo | P0 | ≥ 90% precision on test set |
| Classify each declaration by type (MRP, net qty, MFG date, etc.) | P0 | Confusion matrix F1 ≥ 0.85 per class |
| Measure font size of net quantity / MRP numerals and compare to Table I/II threshold | P0 | Correct tier lookup for computed PDP area |
| Check net quantity declaration placement in lower 30% of PDP | P0 | Geometric check with bounding box |
| Check clear-space geometry around net quantity declaration (Rule 8(1)) | P1 | Pixel-to-mm conversion with scale reference |
| Compute PDP area from real-world dimensions (flat rectangular packages) | P0 | Within ±10% error vs. physical measurement |
| Detect veg/non-veg color symbol | P1 | Color classification ≥ 95% accuracy |
| Verify Unit Sale Price present and mathematically consistent | P1 | USP = MRP ÷ qty within rounding tolerance |
| Generate inspector-ready violation report (Rule citation + measured value + required value) | P0 | Structured output format per Appendix A of LMPC reference doc |
| Web dashboard for scan results and violation history | P1 | Working demo in browser |

### 4.2 Goals — Version 2.0 (Post-Hackathon Roadmap)

| Goal | Priority |
|---|---|
| Cylindrical package multi-view reconstruction for Rule 7(4)(b) PDP area | P0 v2 |
| E-commerce listing scraping and NLP-based declaration extraction | P0 v2 |
| Cross-channel reconciliation (physical label vs. listing vs. QR e-label) | P0 v2 |
| LayoutLMv3 / Donut-based declaration classifier replacing regex | P0 v2 |
| Synthetic data generation pipeline for training (procedurally injected violations) | P1 v2 |
| Active learning loop — inspector corrections retrain model | P2 v2 |
| Batch processing API for e-commerce platform integration | P1 v2 |
| Citizen reporting mode with heatmap | P2 v2 |
| Offline / on-device inference for rural inspectors | P2 v2 |
| Multi-language support (Devanagari OCR) | P1 v2 |

### 4.3 Non-Goals (Explicitly Out of Scope)

| Non-Goal | Reason |
|---|---|
| Physical net quantity verification (actually weighing the product) | Requires physical instrument, not CV-based |
| FSSAI nutrition label compliance | Different regulatory framework; separate product |
| Drug/pharmaceutical label compliance (DPCO 2013) | Requires separate domain expertise and ruleset |
| State Excise compliance for alcohol | State-level, highly variable, out of LMPC scope |
| Detecting counterfeit products | Authentication problem, different from compliance |
| Real-time shelf monitoring | Planogram compliance is a different problem (Trax's domain) |
| Financial/legal advice to manufacturers | Not a compliance advisory — detection only |

---

## 5. USER PERSONAS

### Persona 1 — Pradeep, Field Legal Metrology Inspector (Primary)
Age: 35 Location: Pune, Maharashtra
Device: Android smartphone (mid-range), occasionally a tablet Connectivity: 4G in cities; 2G/offline in rural inspections Pain Points:

Manual checklist takes 20–30 min per product
Cannot verify font size without physical ruler
No standardized evidence format for court proceedings
Trained 5 years ago — unsure about 2022 USP amendment
Has to inspect 15–20 products per day in market raids Goals:
Quick scan: pass/fail in < 30 seconds
Court-admissible violation report automatically generated
Offline mode for rural inspections Quote: "I know what to look for, but I can't carry a ruler to every market."
text


### Persona 2 — Ananya, Compliance Head at an FMCG Brand (Secondary)
Age: 40 Location: Gurugram, Haryana Device: MacBook, iPhone, dashboard via browser Pain Points:

Managing compliance across 200+ SKUs
Different amendments apply to different manufacturing dates
Amazon rejecting listings due to missing USP or Country of Origin
Legal Metrology notice received last quarter for an old SKU
No single source of truth for what's currently required Goals:
Pre-launch label audit before printing
Batch audit of entire product catalog
Amendment tracker — know which rules apply to which SKU by manufacturing date Quote: "I need to know before the label goes to print, not after a notice arrives."
text


### Persona 3 — Vikram, E-Commerce Marketplace Compliance Team (Secondary)
Age: 32 Location: Bengaluru, Karnataka Device: Desktop + API access Pain Points:

7 crore+ listings on platform; cannot manually review for LMPC
CCPA fines hitting the platform directly for seller non-compliance
Sellers uploading listings without Country of Origin, MRP, net qty
No automated pre-listing check exists Goals:
API-based pre-listing compliance gate
Seller-facing compliance scorecard
Automated flagging before item goes live Quote: "We get fined for what our sellers list. We need this gate before publish."
text


### Persona 4 — Sunita, Consumer / Citizen Reporter (Tertiary)
Age: 28 Location: Chennai, Tamil Nadu Device: Android smartphone Pain Points:

Buys products with missing MRP or expired dates
No easy way to report violations to authorities
Doesn't know which specific law is being violated Goals:
Simple scan: "is this product's label legal?"
Easy violation report submission to CCPA
Nearby violation heatmap Quote: "I want to know if I'm being cheated before I pay."
text


---

## 6. USER STORIES & JOBS-TO-BE-DONE

### Epic 1 — Physical Label Scan & Compliance Check

| Story ID | User Story | Acceptance Criteria | Priority |
|---|---|---|---|
| US-01 | As an inspector, I want to photograph a product label and get a PASS/FAIL in under 30 seconds | Scan-to-result ≤ 30s for flat packages on device | P0 |
| US-02 | As an inspector, I want to see exactly which rule is violated, not just "MRP missing" | Output includes: "Rule 6(1)(e) — MRP declaration absent" | P0 |
| US-03 | As an inspector, I want font size measured in mm and compared to the legal minimum | Measured: 1.8mm; Required: 2.5mm (PDP area 220cm²) — FAIL | P0 |
| US-04 | As an inspector, I want a downloadable PDF violation report I can attach to a court notice | PDF with annotated crops, rule citations, measured vs. required values | P0 |
| US-05 | As an inspector, I want the app to work offline in low-connectivity areas | Core inference works offline; sync reports when reconnected | P2 |
| US-06 | As a brand compliance head, I want to upload multiple product images in batch | Batch upload ≥ 50 images; async processing with results dashboard | P1 |
| US-07 | As a brand compliance head, I want to know which amendment version applies to my product | Input MFG date → system selects correct rule version for that date | P1 |
| US-08 | As an inspector, I want to detect the veg/non-veg symbol | Color classification with bounding box highlighting | P1 |

### Epic 2 — E-Commerce Listing Audit

| Story ID | User Story | Acceptance Criteria | Priority |
|---|---|---|---|
| US-09 | As a marketplace compliance officer, I want to input a product listing URL and get LMPC compliance results | System scrapes listing → extracts declarations → checks all 8 required fields | P0 v2 |
| US-10 | As a marketplace compliance officer, I want to check 1000 listings in a batch overnight | Async batch API with status polling and results export (CSV + PDF) | P1 v2 |
| US-11 | As a seller, I want to check my listing before it goes live | Self-service listing compliance check with guided fix suggestions | P1 v2 |

### Epic 3 — Cross-Channel Reconciliation

| Story ID | User Story | Acceptance Criteria | Priority |
|---|---|---|---|
| US-12 | As a compliance officer, I want to compare the MRP on a physical label against the MRP on an e-commerce listing | System flags if |label MRP - listing MRP| > ₹0.01 | P0 v2 |
| US-13 | As a CCPA enforcement officer, I want a reconciliation report showing mismatches across channels | Report shows: field name, physical label value, listing value, QR value, mismatch flag | P0 v2 |
| US-14 | As an inspector, I want to scan a QR code on the label and verify the e-label declarations match the physical label | QR decoded → e-label fetched → declarations compared field by field | P1 v2 |

### Epic 4 — Reporting & Evidence Generation

| Story ID | User Story | Acceptance Criteria | Priority |
|---|---|---|---|
| US-15 | As an inspector, I want the violation report to be in a format usable as court evidence | Report includes: date/time, GPS location, product photos, violation details, rule citations, inspector ID | P0 |
| US-16 | As a department head, I want a dashboard showing violation trends by region and product category | Web dashboard with heatmap, trend charts, top violating categories | P1 |
| US-17 | As a citizen, I want to report a violation with a photo and receive a case reference number | Citizen portal → photo + location → auto-LMPC check → submission to CCPA portal → case ID returned | P2 |

---

## 7. PRODUCT OVERVIEW & ARCHITECTURE VISION

### 7.1 System at a Glance
┌─────────────────────────────────────────────────────────────────────┐ │ LABELGUARD AI PLATFORM │ │ │ │ ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │ │ │ MOBILE APP │ │ WEB PORTAL │ │ REST API (B2B) │ │ │ │ (Inspector/ │ │ (Brand/Mfr/ │ │ (E-commerce platform │ │ │ │ Citizen) │ │ Dashboard) │ │ integration) │ │ │ └──────┬───────┘ └──────┬───────┘ └──────────┬───────────┘ │ │ │ │ │ │ │ └───────────────────▼────────────────────────┘ │ │ ┌──────────────────┐ │ │ │ API GATEWAY │ │ │ │ (FastAPI/REST) │ │ │ └────────┬─────────┘ │ │ │ │ │ ┌──────────────────▼──────────────────────┐ │ │ │ CORE PROCESSING PIPELINE │ │ │ │ │ │ │ ┌─────────┴──────┐ ┌─────────────────┐ ┌─────────┴──────────┐ │ │ │ IMAGE INTAKE │ │ CV PIPELINE │ │ RULES ENGINE │ │ │ │ & PRE-PROC │ │ (Detection, │ │ (LMPC Rule │ │ │ │ Module │ │ OCR, Font │ │ Lookup, │ │ │ │ │ │ Measurement) │ │ Violation │ │ │ └────────────────┘ └─────────────────┘ │ Classification) │ │ │ └────────────────────┘ │ │ ┌──────────────────────────────────────────────┐ │ │ │ RECONCILIATION ENGINE (v2) │ │ │ │ Physical Label ↔ E-Commerce ↔ QR e-label │ │ │ └──────────────────────────────────────────────┘ │ │ │ │ ┌────────────────┐ ┌─────────────────┐ ┌───────────────────────┐ │ │ │ REPORT GEN │ │ DATABASE │ │ MODEL STORE │ │ │ │ (PDF/JSON) │ │ (PostgreSQL + │ │ (CV Models, OCR, │ │ │ │ │ │ MongoDB) │ │ LayoutLM, Rules DB) │ │ │ └────────────────┘ └─────────────────┘ └───────────────────────┘ │ └─────────────────────────────────────────────────────────────────────┘

text


### 7.2 Core Processing Pipeline (Detail)
INPUT: Product label image (JPG/PNG/HEIC from mobile or upload) │ ▼ [STEP 1: PRE-PROCESSING]

Deskewing and perspective correction
Illumination normalization
Resolution enhancement (ESRGAN super-resolution if < 150 DPI effective)
Package shape classification: Rectangular / Cylindrical / Other │ ▼ [STEP 2: PDP IDENTIFICATION]
Detect Principal Display Panel region
Compute PDP area in cm² (requires real-world scale — see STEP 2A)
STEP 2A (SCALE RECOVERY): → Detect and decode EAN-13 / EAN-8 barcode (known nominal geometry) → Fuse with product database for known magnification (if GTIN available) → If confidence < threshold → output INCONCLUSIVE for font-size checks
For cylindrical packages → flag for multi-view reconstruction (v2) │ ▼ [STEP 3: DECLARATION DETECTION]
Full-image OCR (PaddleOCR / Google Vision API as fallback)
LayoutLMv3 / Donut-based classifier assigns each text region a declaration type: {MRP, NET_QTY, MFG_DATE, BEST_BEFORE, MANUFACTURER, PRODUCT_NAME, COUNTRY_ORIGIN, CUSTOMER_CARE, USP, VEG_SYMBOL, OTHER}
Spatial bounding boxes retained for every token │ ▼ [STEP 4: FIELD EXTRACTION & PARSING]
MRP → regex parser: extracts ₹ symbol, numeric value, "incl. of all taxes" text
Net Qty → extracts numeric + unit, validates metric unit
MFG Date → date parser: validates month (01–12) and year
USP → extracts value + unit, validates against MRP/qty math
Customer Care → phone number regex, email regex
PIN code → 6-digit regex within manufacturer address block │ ▼ [STEP 5: FONT SIZE MEASUREMENT]
For each net qty / MRP declaration: → Measure bounding box height of tallest numeral in pixels → Convert pixels → mm using recovered scale factor → Look up required minimum from Table I or Table II based on PDP area → Compare measured vs. required → PASS / FAIL / INCONCLUSIVE │ ▼ [STEP 6: PLACEMENT GEOMETRY CHECK (Rule 8(1))]
Locate bounding box of net qty declaration block
Check: is centroid in lower 30% of PDP? → PASS / FAIL
Measure pixel distances to nearest neighboring element above/below/left/right
Convert to mm; compare against h (above/below) and 2h (left/right) │ ▼ [STEP 7: VEG/NON-VEG SYMBOL CHECK]
HSV color space analysis for green / red dot-in-square symbol
Shape detection: inner circle + outer square
Classification: VEG (green) / NON-VEG (red/brown) / ABSENT │ ▼ [STEP 8: RULES ENGINE EVALUATION]
For each of the 33 checks in the Check Master Table: → Input: extracted field values + measurements → Rule lookup: correct rule version for package MFG date → Exemption check: product category, package type, weight < 10g? → Output: PASS / FAIL / INCONCLUSIVE + rule citation + measured + required │ ▼ [STEP 9: REPORT GENERATION]
Structured JSON output
Annotated image with color-coded bounding boxes (green = pass, red = fail, yellow = inconclusive)
PDF violation report: rule citation, crop evidence, measured vs. required, inspector metadata
Overall verdict: COMPLIANT / NON-COMPLIANT / PARTIALLY COMPLIANT (n checks inconclusive)
text


---

## 8. FEATURE SPECIFICATIONS

### Feature F-01: Label Image Capture & Upload

**Description:** Users capture or upload one or more product label images. The system validates the image before processing.

**Inputs:**
- JPEG / PNG / HEIC / WEBP images up to 20MB per image
- Camera stream from mobile (live capture mode)
- Batch upload: up to 200 images at once (web portal)
- URL of product listing page (e-commerce audit mode, v2)

**Processing:**
- Image quality assessment: minimum effective resolution check (≥ 1MP for flat packages)
- Blur detection (Laplacian variance threshold)
- If quality insufficient → prompt user to retake with guidance overlay

**Outputs:**
- Accepted image queued for processing
- Quality rejection with specific reason: "Image too blurry" / "Label not fully in frame" / "Insufficient resolution"

---

### Feature F-02: PDP Detection & Area Computation

**Description:** Identifies the Principal Display Panel and computes its area in cm² for Table I / Table II lookup.

**Inputs:**
- Pre-processed label image
- Package shape indicator (auto-detected or user-selected)

**Processing:**

| Package Type | PDP Area Formula | CV Method |
|---|---|---|
| Rectangular | L × W of one face | Homography + scale recovery |
| Cylindrical | 0.40 × H × (π × D) | Multi-view + 3D reconstruction (v2) / single-view estimation with uncertainty |
| Other | 40% of total surface | Model fitting + estimation |

**Scale Recovery Methods (in order of preference):**
1. Stereo/depth camera data (if available on device)
2. Known product in database (GTIN decoded from barcode → dimensions lookup)
3. EAN-13 barcode geometry (decoded + magnification estimation from db)
4. User-provided reference object (coin or ruler in frame)
5. If all fail: flag as INCONCLUSIVE for font-size checks

**Outputs:**
- PDP region mask
- PDP area in cm² with confidence interval
- Scale factor: pixels/mm with confidence
- Table I/II tier: {<50, 50–100, 100–500, 500–2500, ≥2500}

---

### Feature F-03: Declaration Detection & Classification

**Description:** Detects and classifies all text regions on the PDP by declaration type.

**Architecture:**
- **Stage 1 OCR:** PaddleOCR (multilingual, supports Hindi/Devanagari/English)
- **Stage 2 Layout Classification:** LayoutLMv3 fine-tuned on Indian packaging data
  - Input: OCR tokens + bounding box positions + pixel patches
  - Output: declaration type label per token group
  - Classes: {MRP, NET_QTY, MFG_DATE, BEST_BEFORE, MANUFACTURER_ADDRESS, PRODUCT_NAME, COUNTRY_ORIGIN, CUSTOMER_CARE, USP, VEG_NV_SYMBOL, IMPORTER, PACKER, MARKETING_ENTITY, OTHER, PROMOTIONAL_TEXT}

**Training Data Strategy:**
- Synthetic data generation: procedurally generated label images with:
  - Randomized backgrounds, fonts, colors, layouts
  - Deliberately injected violations (undersized font, missing field, wrong MRP format)
  - Known ground truth bounding boxes and labels
- Pre-train on synthetic (10,000+ images)
- Fine-tune on hand-labeled seed set (500+ real product images)
- Active learning loop: inspector corrections → retrain (v2)

**Outputs:**
- Per-token: {text, bounding_box, declaration_type, confidence}
- Grouped declaration blocks: {type, full_text, bounding_box, token_list}

---

### Feature F-04: Font Size Measurement (Rule 7(4))

**Description:** Measures the height of numerals in MRP and net quantity declarations in millimetres and checks against Table I or Table II thresholds.

**Algorithm:**
For each {MRP, NET_QTY} declaration bounding box: a. Isolate the numeral characters (digit tokens) b. Measure pixel height of the tallest digit in the group c. Apply scale_factor (pixels/mm) to convert → measured_height_mm d. Look up tier from computed PDP area e. Get required_minimum_mm from Table I (weight/vol) or Table II (length/count) f. Compare: measured_height_mm ≥ required_minimum_mm → PASS | FAIL g. If scale_factor confidence < 0.7 → INCONCLUSIVE

Separately check: all other declaration text ≥ 1mm (Rule 7(3) floor)

If embossed/molded/blown text detected (texture analysis): → Apply 2mm floor for all text, column-specific values from Table I

text


**Output:**
```json
{
  "check_id": "C06",
  "rule": "Rule 7(4) — Table I",
  "declaration": "NET_QTY",
  "measured_height_mm": 1.8,
  "required_minimum_mm": 2.5,
  "pdp_area_cm2": 220,
  "pdp_tier": "100–500 cm²",
  "scale_confidence": 0.82,
  "result": "FAIL",
  "violation_text": "Rule 7(4) Table I violation — net quantity numeral height measured at 1.8mm; 
                     minimum required for PDP area 220cm² is 2.5mm. Deficit: 0.7mm."
}
Feature F-05: Placement Geometry Check (Rule 8(1))
Description: Verifies that the net quantity declaration is in the lower 30% of the PDP and is surrounded by adequate clear space.

Algorithm:

text

1. Get PDP bounding box [PDP_top, PDP_bottom, PDP_left, PDP_right]
2. Get net_qty declaration bounding box [NQ_top, NQ_bottom, NQ_left, NQ_right]
3. Get numeral height h_px (in pixels) → convert to h_mm

CHECK A — Lower 30% placement:
   lower_30_threshold = PDP_top + 0.70 × (PDP_bottom - PDP_top)
   If NQ_centroid_y ≥ lower_30_threshold → PASS
   Else → FAIL

CHECK B — Clear space above (≥ h):
   Nearest element above NQ_top → gap_above_px → gap_above_mm
   If gap_above_mm ≥ h_mm → PASS; Else FAIL

CHECK C — Clear space below (≥ h):
   Nearest element below NQ_bottom → gap_below_px → gap_below_mm
   If gap_below_mm ≥ h_mm → PASS; Else FAIL

CHECK D — Clear space left (≥ 2h):
   Nearest element left of NQ_left → gap_left_px → gap_left_mm
   If gap_left_mm ≥ 2 × h_mm → PASS; Else FAIL

CHECK E — Clear space right (≥ 2h):
   Nearest element right of NQ_right → gap_right_px → gap_right_mm
   If gap_right_mm ≥ 2 × h_mm → PASS; Else FAIL
Feature F-06: Unit Sale Price Validation (Rule 6(11))
Description: Detects USP declaration, validates format, and cross-checks arithmetic against MRP and net quantity.

Logic:

text

1. Check if USP field present (post Oct 2022 packages)
2. Parse USP value (₹ X.XX per [unit])
3. Validate unit tier:
   - If net_qty < 1 kg → USP must be per gram
   - If net_qty ≥ 1 kg → USP must be per kilogram
   - If net_qty < 1 L → USP must be per ml
   - If net_qty ≥ 1 L → USP must be per litre
4. Math check: |declared_USP - (MRP / net_qty_in_unit)| ≤ ₹0.01
5. Exemption checks:
   - USP == MRP → absence allowed
   - Combo/group/multi-piece package → absence allowed
   - Pre-Oct 2022 MFG date → USP not required
Feature F-07: Report Generation
Description: Generates structured violation reports in JSON, PDF, and a web-viewable format.

JSON Output Schema:

JSON

{
  "scan_id": "LG-2026-08-15-00342",
  "scan_timestamp": "2026-08-15T14:32:11+05:30",
  "inspector_id": "LM-MH-PNE-042",
  "location": {"lat": 18.5204, "lng": 73.8567, "address": "MG Road, Pune 411001"},
  "product": {
    "detected_name": "Refined Sunflower Oil",
    "gtin": "8901030853166",
    "mfg_date": "2025-10",
    "mrp_declared": 185.00,
    "net_qty_declared": "1L",
    "applicable_rule_version": "LMPC Rules as amended through GSR 714(E)/2023"
  },
  "pdp_analysis": {
    "shape": "rectangular",
    "area_cm2": 220,
    "table_tier": "100–500 cm²",
    "scale_confidence": 0.82,
    "scale_method": "EAN-13 barcode geometry"
  },
  "checks": [
    {
      "check_id": "C06",
      "rule": "Rule 7(4) Table I",
      "result": "FAIL",
      "measured": "1.8mm",
      "required": "≥ 2.5mm",
      "evidence_crop": "crop_C06.jpg",
      "violation_text": "Net quantity numeral height 1.8mm — minimum 2.5mm for 220cm² PDP"
    }
  ],
  "summary": {
    "total_checks": 20,
    "pass": 16,
    "fail": 3,
    "inconclusive": 1,
    "verdict": "NON_COMPLIANT",
    "critical_violations": 2
  }
}
PDF Report Sections:

Cover page: scan ID, inspector ID, timestamp, GPS, product photo
PDP analysis summary (area, tier, scale method, confidence)
Per-violation page: annotated image crop + rule citation + measured vs. required
Overall verdict + recommended enforcement action
QR code linking to digital case file
Feature F-08: E-Commerce Listing Audit (v2)
Description: Scrapes an e-commerce product listing URL and checks for all 8 mandatory LMPC declarations required under Rule 6(10).

Supported Platforms (v2): Amazon.in, Flipkart, Myntra, Meesho, Snapdeal, JioMart

Checks:

Manufacturer / importer name and address
Country of origin
Net quantity (in metric units)
MRP (₹, inclusive of all taxes)
Customer care contact
Best before / expiry date (where applicable)
Generic product name
Month and year of manufacture
Cross-Channel Reconciliation Output:

Field	Physical Label	E-Commerce Listing	QR e-Label	Status
MRP	₹185.00	₹185.00	₹185.00	✅ MATCH
Net Qty	1L	1 Litre	1000ml	✅ MATCH (semantic)
Manufacturer	XYZ Foods Pvt Ltd, Pune 411001	XYZ Foods Pvt Ltd	—	⚠️ ADDRESS MISSING ON LISTING
Country of Origin	India	India	—	✅ MATCH
MFG Date	Oct 2025	Oct 2025	—	✅ MATCH
9. SUCCESS METRICS & KPIS
Product Performance Metrics
Metric	Target (v1)	Target (v2)
Declaration detection precision	≥ 90%	≥ 95%
Declaration detection recall	≥ 85%	≥ 92%
Font size measurement accuracy (vs. manual)	±0.3mm	±0.1mm
PDP area computation error (vs. physical)	≤ ±15%	≤ ±10%
End-to-end scan time (flat package, mobile)	≤ 30 seconds	≤ 15 seconds
Veg/non-veg symbol detection accuracy	≥ 95%	≥ 98%
False positive rate (flagging compliant labels)	≤ 10%	≤ 5%
Cross-channel reconciliation accuracy	—	≥ 90%
Business / Adoption Metrics
Metric	6 Month Target	12 Month Target
State LM departments onboarded (pilot)	2	8
Scans completed	10,000	1,00,000
FMCG brands using self-audit portal	20	200
E-commerce listings audited via API	—	10 lakh
Citizen violation reports submitted	—	5,000
10. COMPETITIVE LANDSCAPE
Competitor	What They Do	Why They Don't Solve This
eMaap (Dept. of Consumer Affairs)	License/registration tracking for Legal Metrology	Not label content verification at all
Label Score AI (GoVisually)	OCR label compliance checker	Built for US FDA/EU rules — no concept of mm-font-size tiers scaled to Indian PDP area
NutriSight (Open Food Facts)	CV + OCR for nutrition tables	Proves packaging OCR is feasible; doesn't touch LMPC compliance rules or font measurement
Trax / Focal Systems / ParallelDots	Retail shelf planogram compliance	Different problem entirely — stock facings, not label text
Generic OCR + regex tools	Detect text from images	Cannot check font size in mm, placement geometry, cylindrical PDP area, or cross-channel consistency
Our Differentiation
text

         FONT SIZE          PLACEMENT       CROSS-CHANNEL      INDIAN LMPC
         IN MM              GEOMETRY        RECONCILIATION     RULES NATIVE
           │                   │                │                  │
LabelGuard ✅                 ✅               ✅                 ✅
eMaap      ❌                 ❌               ❌                 🔶 (registration only)
LabelScore ❌                 ❌               ❌                 ❌ (FDA/EU only)
NutriSight ❌                 ❌               ❌                 ❌ (nutrition only)
Trax       ❌                 ❌               ❌                 ❌ (shelf/planogram)
11. UNIQUE VALUE PROPOSITION
Primary UVP
"LabelGuard AI is the only system that verifies whether a product's mandatory declarations are correct, compliant, and consistent — on the physical label, the e-commerce listing, and the QR e-label — against the actual Indian Legal Metrology rules, including font size in millimetres."

Supporting Claims
Only tool with mm-accurate font-size measurement against Table I/II thresholds — the exact checks that existing tools cannot do from a flat photo
Only tool built natively for Indian LMPC rules — not a foreign compliance tool retrofitted
Cross-channel reconciliation — checks if physical label, listing, and QR e-label agree (a new legal requirement under 2026 amendments)
Inspector-ready output — violation reports structured for Legal Metrology court proceedings, not just a dashboard metric
Amendment-versioned rule engine — applies the correct rule version based on the product's manufacture date
12. CONSTRAINTS, ASSUMPTIONS & DEPENDENCIES
Technical Constraints
Constraint	Impact	Mitigation
Font size in mm cannot be computed from a flat photo without known scale	INCONCLUSIVE results for some packages	Multi-method scale recovery; honest uncertainty reporting
Cylindrical PDP area (Rule 7(4)(b)) requires circumference — not gettable from one image	Cannot check font-size tier for bottles from single image	Multi-view reconstruction in v2; flat-package priority for v1 demo
No public labeled dataset of Indian FMCG labels for training	Model accuracy lower than optimal	Synthetic data generation pipeline with procedurally injected violations
Handwritten / embossed text has lower OCR accuracy	Missed declarations in some cases	Texture detection → route to higher-accuracy specialized model
Rural inspector devices: older Android, low RAM	Inference latency too high for on-device models	Compressed model for mobile; cloud fallback when online
Assumptions
The physical label image is of the Principal Display Panel (the front face), not a random side
The manufacturer date is visible on the label (used for rule version selection)
At least one scale reference is present or product is in the GTIN database
E-commerce listing HTML is scrapeable (not fully JavaScript-rendered without a headless browser)
The 2026 LMPC Amendment Rules (e-commerce disclosure) are in effect as of the submission date
External Dependencies
Dependency	Type	Risk
PaddleOCR / Google Vision API	OCR engine	API rate limits; cost at scale
GS1 India barcode database	Product dimension lookup	Coverage gaps for smaller brands
E-commerce platform HTML structure	Web scraping	Structure changes without notice; rate limiting
LayoutLMv3 model	Classification backbone	Compute requirements; fine-tuning data quality
Legal gazette text (GSR 202(E), 629(E) etc.)	Rules database	Rule interpretation ambiguities
13. RELEASE STRATEGY & ROADMAP
Phase 1 — SIH Demo / MVP (4 weeks)
Goal: Working demo that impresses judges and proves core technical feasibility

Week	Deliverable
Week 1	Image pipeline: pre-processing, OCR, basic field extraction (MRP, net qty, dates)
Week 2	Font size measurement on flat packages with EAN-13 scale recovery; Table I lookup
Week 3	Placement geometry check; veg/non-veg symbol; USP validation; rules engine v1
Week 4	PDF report generation; web dashboard; demo prep; edge case hardening
MVP Demo Script:

Point phone at flat FMCG product
System detects all 10 fields in real time
Font size measured: "Measured 1.8mm — Rule requires 2.5mm for this PDP area — FAIL"
Placement check: "Net qty declaration is in upper 40% of PDP — must be in lower 30% — FAIL"
PDF report generated and downloaded in 5 seconds
Phase 2 — Post-SIH Hardening (Month 2–3)
LayoutLMv3 declaration classifier (replacing regex)
Synthetic data generation pipeline
Multi-language OCR (Hindi/Devanagari)
Mobile app (React Native)
Inspector authentication and GPS tagging
Phase 3 — E-Commerce Audit Module (Month 4–6)
Web scraper for Amazon.in, Flipkart (top 2 platforms)
NLP-based declaration extraction from listing text
Cross-channel reconciliation engine
Batch API for platform integration
Phase 4 — Scale & Government Integration (Month 7–12)
Cylindrical package multi-view reconstruction
State LM department pilot integration
CCPA complaint portal API integration
Citizen reporting mode
Active learning loop
14. RISK REGISTER
Risk ID	Risk	Probability	Impact	Mitigation
R01	Scale reference unavailable for font-size check	High	High	Output INCONCLUSIVE; never false PASS — judges see honesty as maturity
R02	OCR fails on embossed/molded packaging	Medium	High	Texture detection → specialized pipeline; flag for manual review
R03	LMPC rules amended post-development	Medium	Medium	Versioned rules engine; amendment tracker document
R04	E-commerce platforms block scraping	High	High	Use official seller API (Flipkart Seller Hub API); position as platform partner
R05	Model trained on synthetic data underperforms on real labels	High	High	Early real-label annotation sprint; active learning from day one
R06	Font size measurement error exceeds tolerance	Medium	High	Conservative thresholds; require human confirmation for borderline cases
R07	Privacy / PDPA compliance for citizen-reported photos	Low	High	No PII in label photos; GPS data opt-in only; PDPA audit
R08	SIH judges conflate with "another OCR tool"	Medium	High	Lead with cross-channel reconciliation angle + live font-size measurement demo
15. APPENDIX
A — LMPC Rule Version vs. MFG Date Lookup
MFG Date Range	Applicable Rule Version
Before 01 Jan 2018	GSR 202(E)/2011 base + GSR 385(E)/2015
01 Jan 2018 – 30 Sep 2022	+ GSR 629(E)/2017 (font sizes, PDP, e-commerce, CoO)
01 Oct 2022 – 31 Dec 2023	+ USP mandatory; Second Schedule omitted
01 Jan 2024 onwards	+ Amendment 2023 (multi-piece, edible oil, electronics MFG date)
2026 onwards	+ Amendment Rules 2026 (enhanced e-commerce disclosures)
B — Glossary
Term	Definition
PDP	Principal Display Panel — the face of the package most visible at point of sale
MRP	Maximum Retail Price — inclusive of all taxes, declared in ₹
USP	Unit Sale Price — price per standard metric unit (per g, per kg, per ml, per L, etc.)
Table I	Font size lookup table for weight/volume declarations (5 PDP area tiers)
Table II	Font size lookup table for length/area/number declarations (4 tiers)
LMPC	Legal Metrology (Packaged Commodities) Rules, 2011
CCPA	Central Consumer Protection Authority
BIS	Bureau of Indian Standards
GSR	Gazette of India, Statutory Rules and Orders
GTIN	Global Trade Item Number (encoded in EAN/UPC barcodes)
CoO	Country of Origin
LayoutLMv3	Microsoft's multimodal document understanding model (text + layout + image)