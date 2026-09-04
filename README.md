# LabelLens

**Automated Legal Metrology (Packaged Commodities) Rules Compliance Verification**  
*SIH 2026 — Problem Statement SIH26034*

LabelLens is an AI-powered compliance auditing system that uses computer vision and NLP to verify product labels against the Indian **Legal Metrology (Packaged Commodities) Rules 2011**, including the latest **2026 amendments (GSR 128(E))**.

---

## 🔍 What It Does

Point your phone camera at any pre-packaged consumer product and LabelLens will:

1. **Extract** all text from the label using a multi-pass OCR pipeline
2. **Parse** mandatory declarations (MRP, Net Quantity, Mfg Date, Country of Origin)
3. **Measure** font sizes against Rule 7 Table I minimum requirements
4. **Evaluate** compliance against 8+ LMPC violation codes
5. **Generate** an inspector-ready compliance report with severity ratings

---

## 🏗️ Architecture

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│                 │      │                 │      │                 │
│  Flutter Mobile ├─────►│   FastAPI Core  │◄─────┤  React Web App  │
│  (Inspector App)│      │  (Backend API)  │      │   (Dashboard)   │
│                 │      │                 │      │                 │
└─────────────────┘      └────────┬────────┘      └─────────────────┘
                                  │
                 ┌────────────────┼────────────────┐
                 │                │                │
        ┌────────▼───────┐ ┌─────▼──────┐ ┌───────▼──────┐
        │  OCR Extractor │ │ NLP Parser │ │ Rules Engine │
        │  (Tesseract +  │ │ (Coord-    │ │ (LMPC 2011   │
        │   Multi-Pass)  │ │  Based)    │ │  + 2026 Amd) │
        └────────────────┘ └────────────┘ └──────────────┘
                                  │
                         ┌────────▼────────┐
                         │  PostgreSQL DB  │
                         └─────────────────┘
```

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile App** | Flutter (Dart) | Inspector field scanning app (Android) |
| **Backend API** | Python, FastAPI, Uvicorn | REST API, image processing orchestration |
| **OCR Engine** | Tesseract OCR 5.x + OpenCV | Multi-pass text extraction with adaptive thresholding |
| **Barcode Scanning** | pyzbar + zbar DLL | EAN-13 barcode detection for physical scale calibration |
| **NLP Parser** | Custom Python (regex + coordinate heuristics) | Spatial-aware declaration field extraction |
| **Font Measurement** | OpenCV + barcode reference chain | Pixel-to-mm conversion for Rule 7 compliance |
| **Rules Engine** | Python (hardcoded LMPC logic) | Violation evaluation with severity scoring |
| **Database** | PostgreSQL + SQLAlchemy + Alembic | Scan history, user management, reports |
| **Web Dashboard** | React 18 | QA Manager and Admin interface |

---

## 🔬 ML Pipeline — How It Works

### 1. Multi-Pass OCR Extraction (`ml/ocr/extractor.py`)

The OCR engine runs **four parallel thresholding passes** to handle diverse label types:

| Pass | Technique | Best For |
|------|-----------|----------|
| **Normal** | Adaptive Gaussian Threshold (C=10) | Standard black-on-white text |
| **Inverted** | Adaptive Gaussian Threshold (Inverted) | White-on-dark text (foil pouches) |
| **Otsu Value** | Otsu on HSV Value Channel (PSM 11) | Colorful/glossy labels (e.g., Parle-G) |
| **Otsu Green** | Otsu on Green Channel (PSM 11) | Labels with green/yellow graphics near text |

All passes are merged with deduplication. CLAHE contrast enhancement is applied before thresholding. A dynamic block size is computed based on image resolution to prevent text hollowing in high-res photos.

### 2. Column-Aware Layout Detection (`ml/ocr/extractor.py`)

Detects vertical gutters in two-column layouts (common on back-of-pack labels) using projection profiles. Splits the image at the gutter and runs OCR on each half independently to prevent cross-column text scrambling.

### 3. Coordinate-Based NLP Parser (`ml/nlp/parser.py`)

Unlike simple regex matching, the parser uses **spatial proximity heuristics**:

- **Line Grouping:** Stitches fragmented OCR boxes into logical lines based on Y-axis baseline alignment (±12px tolerance)
- **Key-Value Association:** For each declaration keyword (e.g., "MRP"), finds the nearest value box using weighted Euclidean distance with directional penalties
- **Fallback Anchors:** Uses contextual anchors (e.g., "TAXES" as fallback for "MRP") when OCR garbles the primary keyword
- **OCR Typo Tolerance:** Fuzzy matching for common OCR misreads (e.g., "inet" → "incl")

### 4. Physical Font Size Measurement (`ml/font/measurement.py`)

Converts pixel bounding box heights to physical millimeters using the **EAN-13 Reference Chain**:

```
EAN-13 nominal width (37.29mm) → barcode pixel width → mm_per_pixel → font_height_mm
```

Outputs confidence-aware results with three states:
- **`measured`** (confidence ≥ 0.6): Reliable for automated PASS/FAIL
- **`inconclusive`** (confidence < 0.6): Flagged for manual verification
- **`no_scale`**: No barcode found in image

### 5. Label Sanity Gate (`ml/pipeline.py`)

Before running full compliance analysis, a lightweight keyword check verifies the image actually contains a product label. Checks for 20+ LMPC signal keywords (MRP, Net Qty, Mfg, FSSAI, Batch, etc.) using both PSM 6 and PSM 11 OCR passes merged together.

---

## 📋 LMPC Rules Evaluated

| Violation ID | Rule Citation | Description | Severity |
|-------------|--------------|-------------|----------|
| V001 | Rule 6(1)(e) | MRP missing from principal display panel | CRITICAL |
| V002 | Rule 6(1)(e) + GSR 629(E) | MRP missing "inclusive of all taxes" wording | CRITICAL |
| V003 | Rule 7 Table I | MRP font size below minimum requirement | HIGH |
| V004 | Rule 6(1)(b) | Net quantity declaration missing | CRITICAL |
| V005 | Rule 7 Table I | Net quantity font size below minimum | HIGH |
| V006 | Rule 6(1)(d) | Month/year of manufacture or packing missing | HIGH |
| V007 | Rule 6(1)(j) | Country of origin missing (imported products) | CRITICAL |
| V008 | Rule 6(10A) + GSR 128(E) 2026 | E-commerce COO filter missing for imported products | HIGH |

### Font Size Requirements (Rule 7 Table I)

| PDP Area (cm²) | Minimum Font Height |
|----------------|-------------------|
| < 50 | 1.0 mm |
| 50 – 100 | 2.0 mm |
| 100 – 500 | 4.0 mm |
| > 500 | 6.0 mm |

---

## 📱 Supported Product Types

LabelLens works on **any pre-packaged commodity** sold in India that is required to carry LMPC declarations:

- **Food & Beverages** — Snacks, spices, bottled water, dairy products
- **FMCG & Cosmetics** — Shampoos, soaps, toothpaste, skincare
- **Electronics** — Smartphone boxes, chargers, headphones, laptops
- **General Consumer Goods** — Toys, stationery, hardware, clothing

> **Note:** The app scans the **legal compliance label** (containing MRP, Net Qty, Manufacturer details). For electronics, this is typically a separate sticker on the box, not the factory/logistics tracking label.

---

## 🚀 Getting Started

### Prerequisites

- Python 3.11+
- Flutter SDK (≥3.2.0)
- Tesseract OCR 5.x installed and on PATH
- Microsoft Visual C++ 2013 Redistributable (x64) — required for pyzbar on Windows
- PostgreSQL (or use Docker)

### Running the Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn api.main:app --host 0.0.0.0 --reload --port 8000
```

The API will be available at `http://localhost:8000`. Swagger documentation is at `http://localhost:8000/docs`.

**Environment Variables:**
| Variable | Default | Description |
|----------|---------|-------------|
| `TESSERACT_CMD` | Auto-detected | Path to tesseract binary |
| `DATABASE_URL` | `sqlite:///./database.db` | Database connection string |

### Running with Docker

```bash
docker-compose up --build
```

### Running the Mobile App (Flutter)

```bash
cd apps/mobile
flutter pub get
flutter run
```

*For testing on a physical device, update `API_BASE_URL`:*
```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_LOCAL_IP:8000/v1
```

### Running the Web Dashboard (React)

```bash
cd apps/web
npm install
npm run dev
```

---

## 🔐 Demo Credentials

| Role | Username | Password |
|------|----------|----------|
| **Admin** | `admin` | `admin123` |
| **Inspector** | `rajan` | `inspector123` |
| **QA Manager** | `priya` | `manager123` |

---

## 📁 Project Structure

```
LabelLens/
├── apps/
│   ├── mobile/                 # Flutter Inspector App (Android)
│   │   └── lib/
│   │       ├── main.dart
│   │       ├── screens/        # Camera, Scan Result, History screens
│   │       ├── services/       # API service (HTTP client)
│   │       ├── models/         # Data models
│   │       ├── providers/      # State management
│   │       └── widgets/        # Reusable UI components
│   └── web/                    # React Web Dashboard
├── backend/
│   ├── api/
│   │   ├── main.py             # FastAPI entry point
│   │   ├── routers/            # REST endpoints (scans, reports, auth, etc.)
│   │   ├── models.py           # SQLAlchemy ORM models
│   │   └── database.py         # DB session management
│   ├── ml/
│   │   ├── pipeline.py         # ML pipeline orchestrator
│   │   ├── rules_engine.py     # LMPC compliance evaluator
│   │   ├── ocr/
│   │   │   └── extractor.py    # Multi-pass Tesseract OCR + barcode scale
│   │   ├── nlp/
│   │   │   └── parser.py       # Coordinate-based declaration parser
│   │   └── font/
│   │       └── measurement.py  # Pixel-to-mm font size converter
│   ├── alembic/                # Database migrations
│   ├── requirements.txt
│   └── Dockerfile
├── packages/                   # Shared packages
├── LMPC_RULES_REFERENCE.md     # Complete LMPC rules reference
├── SRS.md                      # Software Requirements Specification
├── PRD.md                      # Product Requirements Document
├── UIUX_SPEC.md                # UI/UX Design Specification
├── docker-compose.yml
└── README.md
```

---

## 🧪 How to Test

For the best demonstration of LabelLens:

1. Start the backend (`uvicorn`) and mobile app (`flutter run`)
2. Log in as **Inspector** (`rajan` / `inspector123`)
3. Select **Scan Label**
4. Point the camera at a packaged product's **legal compliance label**
5. Ensure the MRP, Net Quantity, and ideally the barcode are visible in the frame
6. The system will:
   - Run multi-pass OCR to extract all text
   - Use coordinate-based heuristics to parse declaration fields
   - Calibrate physical scale using the barcode (if visible)
   - Evaluate all mandatory declarations against LMPC rules
   - Display violations with severity ratings and rule citations

### Tips for Best Results

- **Lighting:** Ensure even lighting without harsh shadows or glare
- **Focus:** Hold the phone steady and let autofocus lock before capturing
- **Frame:** Fill as much of the frame as possible with the label
- **Barcode:** Including a barcode in the frame enables physical font-size measurement
- **Colorful labels:** The multi-pass OCR handles glossy/colored backgrounds, but clean captures still produce the best results

---

## 📜 License

This project was developed for **Smart India Hackathon 2026** (Problem Statement SIH26034).

---

## 👥 Team

**Team ** — SIH 2026
