<!--
  FILE: UIUX_SPEC.md
  PROJECT: LabelLens — Automated LMPC Label Compliance Verification System
  VERSION: 1.0
  DATE: August 2026
  AUDIENCE: UI Engineers, Frontend Devs, Designers, Judges (SIH 2026)
  COMPANION FILES: PRD.md, SRS.md, LMPC_RULES_REFERENCE.md
-->

# 🎨 LabelLens — Complete UI/UX Specification
## User Interface & Experience Design Document
### Smart India Hackathon 2026 — Problem Statement SIH26034

---

> **How to read this document:**
> Every screen is described top-to-bottom, left-to-right, as it physically appears on the device.
> Each section covers: layout → components → states → interactions → edge cases → accessibility.
> No implementation detail is assumed. A designer with zero project context
> can build pixel-accurate wireframes from this document alone.

---

## 📑 TABLE OF CONTENTS

| # | Section |
|---|---|
| 1 | [Design Philosophy & Core Principles](#1-design-philosophy) |
| 2 | [User Personas](#2-user-personas) |
| 3 | [Design System — Tokens, Colors, Typography, Grid](#3-design-system) |
| 4 | [Component Library](#4-component-library) |
| 5 | [Information Architecture & Navigation](#5-information-architecture) |
| 6 | [User Flows & Journey Maps](#6-user-flows) |
| 7 | [Screen Specifications — Mobile App](#7-mobile-screens) |
| 8 | [Screen Specifications — Web Dashboard](#8-web-dashboard-screens) |
| 9 | [Micro-interactions & Animation Spec](#9-micro-interactions) |
| 10 | [Error States & Empty States](#10-error-and-empty-states) |
| 11 | [Accessibility Specification (WCAG 2.1 AA)](#11-accessibility) |
| 12 | [Offline & Low-Connectivity UX](#12-offline-ux) |
| 13 | [Localization & Language Handling](#13-localization) |
| 14 | [Responsive Breakpoints](#14-responsive-breakpoints) |
| 15 | [Handoff Annotations — Dev Notes](#15-dev-handoff) |

---

## 1. Design Philosophy & Core Principles {#1-design-philosophy}

### 1.1 The North Star

LabelLens is used by two very different people in two very different situations:

1. **A Legal Metrology Inspector** standing in a warehouse with a phone, doing 40 scans per shift,
   often in harsh lighting, under time pressure, potentially with limited connectivity.

2. **A Compliance Officer at a brand** sitting at a desktop, reviewing a batch report of 200 SKUs
   before a product launch, needing to export evidence-grade PDFs.

The UI must serve both without compromise. That means:

- **Speed over beauty** for the mobile scan flow (inspector)
- **Density over simplicity** for the web dashboard (compliance officer)
- **Clarity over cleverness** for violation reports (both)

---

### 1.2 The Five Design Principles

#### Principle 1: Evidence First
Every piece of information shown to the user must be traceable to a rule, a measurement, or
a detected value. No vague verdicts. "Font too small" is not enough.
"Measured 1.8mm — Rule 7(4) Table I requires ≥ 2.5mm for PDP area 220cm²" is.

#### Principle 2: Honest Uncertainty
The system knows when it doesn't know. Low-confidence results are displayed as
`INCONCLUSIVE`, never forced into PASS or FAIL. A compliance tool that lies is worse than
one that admits uncertainty. This is surfaced clearly in every verdict.

#### Principle 3: Zero Training Needed for Core Flow
An inspector who has never used the app must be able to:
- Open app → point camera → get PASS/FAIL verdict
...in under 60 seconds, without reading any documentation.
Every subsequent feature is progressively disclosed.

#### Principle 4: Inspector-Grade Output
Every report must be suitable as supporting evidence in a Legal Metrology proceeding.
This means: rule citation, annotated crop, measured vs. required value, scan timestamp,
GPS location, inspector ID. Not a dashboard artifact — a legal document.

#### Principle 5: Respect the Context
- Inspector in a warehouse → dark mode available, one-hand operable, large touch targets
- Compliance officer on desktop → dense data tables, multi-column, keyboard navigable
- Rural inspector on 2G → offline-capable, local inference, sync when connected

---

### 1.3 Interaction Paradigm

| Mode | Dominant Interaction | Primary Device |
|---|---|---|
| Quick Scan (Inspector) | Camera → Tap → Swipe | Phone (one hand) |
| Batch Review (Compliance) | Scroll → Filter → Export | Desktop browser |
| Deep Analysis (QA Engineer) | Multi-view capture → Annotation | Tablet / Desktop |
| Citizen Report | Photo → Submit → Track | Phone |
| Admin / Analytics | Dashboard → Drill-down → Alert | Desktop |

---

## 2. User Personas {#2-user-personas}

---

### Persona 1: "Rajan" — The Field Inspector
Name: Rajan Tiwari Role: Legal Metrology Inspector, State Consumer Affairs Dept. Age: 38 Device: Android (mid-range, ~4GB RAM) — Samsung Galaxy M34 Literacy: Hindi-primary, functional English Context: In retail stores, warehouses, mandis — often loud, bright sunlight or bad lighting Goal: Scan 30–50 packages per inspection shift, generate a seizure notice on-site Frustration: Apps that take too long to load, give unclear results, or need Wi-Fi Quote: "Mujhe result chahiye, explanation nahi" (I need the result, not an explanation)

Key UX Needs:

Large touch targets (≥ 48×48dp)
Hindi UI option
Works offline
One-tap scan initiation
Clear PASS / FAIL color coding
Exportable PDF report in < 3 taps
GPS auto-tags location
Battery-efficient (no background drain)
text


---

### Persona 2: "Priya" — The Brand Compliance Manager
Name: Priya Sharma Role: Regulatory Compliance Manager, FMCG brand Age: 31 Device: MacBook Pro + external monitor; iPhone for quick checks Literacy: English-fluent, data-savvy Context: Office — reviewing batch of 50–200 SKUs before quarterly audit Goal: Zero violations at the next CCPA inspection; track violation trends over time Frustration: Tools that can't export, can't batch process, can't cite the specific rule violated Quote: "I need to show this to our legal team — it has to cite the actual rule number."

Key UX Needs:

Batch upload (bulk CSV + image folder)
Filterable violation table (by rule, severity, SKU)
Exportable PDF with rule citations
E-commerce cross-channel check
Violation trend analytics
Role-based access (she manages a team of 4 QA reviewers)
Keyboard shortcuts for power users
text


---

### Persona 3: "Arjun" — The QA Reviewer (Junior)
Name: Arjun Mehta Role: Quality Assurance Analyst (junior), under Priya Age: 24 Device: Windows laptop + phone for photo capture Literacy: English, tech-comfortable Context: Reviewing flagged SKUs assigned to him by Priya; annotating suspected violations Goal: Clear his review queue by EOD; not get shouted at for false positives Frustration: No way to add notes to violations; can't tell which findings need human review

Key UX Needs:

Review queue (assigned to him)
Ability to confirm / dispute AI findings
Text annotation on violation crops
Status tracking (Reviewed / Escalated / Cleared)
Simple rule reference panel (doesn't need to memorize rules)
text


---

### Persona 4: "Kavitha" — The Citizen Reporter
Name: Kavitha Nair Role: Consumer / Citizen Age: 27 Device: iPhone, good connectivity Literacy: English, Malayalam Context: Shopping at a supermarket; sees a product with no MRP sticker Goal: Report the violation and know it was received Frustration: Govt portals that eat submissions and give no feedback

Key UX Needs:

Super simple (2–3 steps max)
Photo + location auto-captured
Submission confirmation with a tracking ID
Status update when complaint is actioned
No account creation required
text


---

## 3. Design System {#3-design-system}

### 3.1 Color Palette

#### 3.1.1 Primary Brand Colors

| Token | Hex | Usage |
|---|---|---|
| `--color-brand-primary` | `#1A3C6B` | Primary buttons, headers, active states |
| `--color-brand-secondary` | `#2E7D9E` | Secondary actions, links, charts |
| `--color-brand-accent` | `#F4A500` | Highlights, badges, CTAs |
| `--color-brand-accent-dark` | `#C17D00` | Hover state for accent |

#### 3.1.2 Semantic / Status Colors

| Token | Hex | Meaning | Usage |
|---|---|---|---|
| `--color-pass` | `#1B7A3E` | Compliant | PASS badge, check icons, progress fill |
| `--color-pass-bg` | `#E8F5ED` | Compliant background | Card bg for passing items |
| `--color-pass-border` | `#A3D9B5` | Compliant border | Card border for passing items |
| `--color-fail` | `#C0392B` | Violation | FAIL badge, error icons, violation rows |
| `--color-fail-bg` | `#FDECEA` | Violation background | Card bg, table row highlight |
| `--color-fail-border` | `#F5B7B1` | Violation border | Card border |
| `--color-warn` | `#E67E22` | Warning / borderline | WARN badge, advisory icons |
| `--color-warn-bg` | `#FEF5E7` | Warning background | Card bg |
| `--color-warn-border` | `#FAD7A0` | Warning border | Card border |
| `--color-inconclusive` | `#7F8C8D` | Unknown / low confidence | INCONCLUSIVE badge |
| `--color-inconclusive-bg` | `#F2F3F4` | Unknown background | Card bg |

#### 3.1.3 Neutral / Surface Colors

| Token | Hex | Usage |
|---|---|---|
| `--color-surface-0` | `#FFFFFF` | Card backgrounds, panels |
| `--color-surface-1` | `#F8F9FA` | Page background (light mode) |
| `--color-surface-2` | `#F1F3F5` | Table alternating rows |
| `--color-surface-3` | `#E9ECEF` | Dividers, borders |
| `--color-surface-4` | `#DEE2E6` | Input borders (default) |
| `--color-text-primary` | `#1C2230` | Body text, labels |
| `--color-text-secondary` | `#495057` | Subtext, metadata |
| `--color-text-tertiary` | `#868E96` | Placeholder, disabled |
| `--color-text-inverse` | `#FFFFFF` | Text on dark backgrounds |

#### 3.1.4 Dark Mode Tokens

| Token | Hex | Dark Mode Usage |
|---|---|---|
| `--color-dm-surface-0` | `#1C1C1E` | Card / panel background |
| `--color-dm-surface-1` | `#2C2C2E` | Page background |
| `--color-dm-surface-2` | `#3A3A3C` | Table rows, input bg |
| `--color-dm-text-primary` | `#F2F2F7` | Body text |
| `--color-dm-text-secondary` | `#AEAEB2` | Subtext |
| `--color-dm-brand-primary` | `#4A90D9` | Buttons (adjusted for contrast) |
| `--color-dm-pass` | `#30D158` | PASS badge |
| `--color-dm-fail` | `#FF453A` | FAIL badge |
| `--color-dm-warn` | `#FF9F0A` | WARN badge |

---

### 3.2 Typography

#### 3.2.1 Font Families
Primary (Latin + Devanagari): "Noto Sans", "Noto Sans Devanagari", system-ui, sans-serif Monospace (rule citations): "JetBrains Mono", "Fira Code", monospace

text


> **Why Noto Sans?** Full Unicode coverage including Devanagari (Hindi), Malayalam,
> Tamil, Bengali — all languages used by inspectors across Indian states.
> Zero additional font loading for regional language display.

#### 3.2.2 Type Scale

| Token | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| `--type-display-1` | 32px / 2rem | 700 | 1.2 | Page titles (web only) |
| `--type-display-2` | 24px / 1.5rem | 700 | 1.25 | Section headers |
| `--type-heading-1` | 20px / 1.25rem | 600 | 1.3 | Card titles, screen titles (mobile) |
| `--type-heading-2` | 16px / 1rem | 600 | 1.4 | Sub-section headers |
| `--type-heading-3` | 14px / 0.875rem | 600 | 1.4 | Table headers, labels |
| `--type-body-1` | 16px / 1rem | 400 | 1.5 | Primary body text |
| `--type-body-2` | 14px / 0.875rem | 400 | 1.5 | Secondary body, card content |
| `--type-caption` | 12px / 0.75rem | 400 | 1.4 | Timestamps, meta, footnotes |
| `--type-label` | 12px / 0.75rem | 500 | 1.2 | Form labels, chip labels |
| `--type-mono` | 13px / 0.8125rem | 400 | 1.5 | Rule citations, code, measurements |
| `--type-mono-bold` | 13px / 0.8125rem | 600 | 1.5 | Highlighted rule citations |

#### 3.2.3 Special Typography Rules

- **Rule citations** always use `--type-mono`. Example: `Rule 6(1)(e)` in monospace.
- **Measurements** (font size in mm, PDP area in cm²) always use `--type-mono`.
- **PASS / FAIL / INCONCLUSIVE / WARN** badges always use `--type-label` weight 700, ALL CAPS.
- **Hindi text** inherits same size scale but with `line-height: 1.6` minimum
  (Devanagari script requires more vertical space).
- **Minimum body text: 16px on mobile** — never smaller, per accessibility requirements
  and the fact that Rajan is using his phone in bright sunlight.

---

### 3.3 Spacing System

Base unit: **4px**. All spacing is a multiple of 4.

| Token | Value | Usage |
|---|---|---|
| `--space-1` | 4px | Icon padding, tight gaps |
| `--space-2` | 8px | Inner padding (small) |
| `--space-3` | 12px | Icon-text gap |
| `--space-4` | 16px | Card padding (mobile), list item padding |
| `--space-5` | 20px | Section gap (mobile) |
| `--space-6` | 24px | Card padding (web), form group gap |
| `--space-8` | 32px | Section gap (web) |
| `--space-10` | 40px | Page section padding |
| `--space-12` | 48px | Large section gap |
| `--space-16` | 64px | Hero sections |

---

### 3.4 Elevation / Shadow System

| Level | CSS Shadow | Usage |
|---|---|---|
| `--elev-0` | none | Flat, inline elements |
| `--elev-1` | `0 1px 3px rgba(0,0,0,0.08)` | Cards (resting) |
| `--elev-2` | `0 4px 12px rgba(0,0,0,0.10)` | Cards (hover), dropdowns |
| `--elev-3` | `0 8px 24px rgba(0,0,0,0.14)` | Modals, drawers |
| `--elev-4` | `0 16px 48px rgba(0,0,0,0.20)` | Full-screen overlays, camera view |

---

### 3.5 Border Radius

| Token | Value | Usage |
|---|---|---|
| `--radius-sm` | 4px | Tags, chips, small elements |
| `--radius-md` | 8px | Buttons, input fields |
| `--radius-lg` | 12px | Cards |
| `--radius-xl` | 16px | Bottom sheets, modals |
| `--radius-full` | 9999px | Badges, pills, FAB |

---

### 3.6 Iconography

**Icon Set:** [Phosphor Icons](https://phosphoricons.com/) — reason: MIT license,
excellent Devanagari-adjacent glyph support, consistent weight, available as SVG and React/Flutter components.

**Icon Sizes:**

| Context | Size | Touch Target |
|---|---|---|
| Inline (text adjacent) | 16px | n/a |
| Navigation bar | 24px | 48×48dp |
| Action button | 20px | 44×44dp |
| FAB | 28px | 56×56dp |
| Status indicator | 20px | n/a |
| Empty state illustration | 80–120px | n/a |

**Key Icon Mappings:**

| Meaning | Icon | Notes |
|---|---|---|
| PASS / Compliant | `CheckCircle` (filled) | Green (`--color-pass`) |
| FAIL / Violation | `XCircle` (filled) | Red (`--color-fail`) |
| WARN / Advisory | `Warning` (filled) | Orange (`--color-warn`) |
| INCONCLUSIVE | `Question` (filled) | Grey (`--color-inconclusive`) |
| Scan / Camera | `Camera` | Primary action |
| Upload | `UploadSimple` | Batch upload |
| Export / PDF | `FilePdf` | Report generation |
| Location / GPS | `MapPin` | Inspection location |
| Rule Reference | `BookOpen` | LMPC rules viewer |
| Cross-channel | `ArrowsLeftRight` | Reconciliation view |
| Inspector | `IdentificationBadge` | Inspector profile |
| Font Size | `TextAa` | Font measurement results |
| Barcode | `Barcode` | GTIN/barcode detection |
| History | `ClockCounterClockwise` | Past scans |
| Delete / Dismiss | `Trash` | Remove item |
| Filter | `Funnel` | Table/list filter |
| Sort | `ArrowsDownUp` | Column sort |
| Annotate | `PencilSimple` | Add note |
| Expand | `CaretDown` | Accordion |
| Collapse | `CaretUp` | Accordion |
| Sync | `ArrowsClockwise` | Sync offline queue |
| Offline | `WifiX` | Offline indicator |
| Confidence | `Gauge` | Confidence meter |

---

### 3.7 Motion & Animation Tokens

| Token | Duration | Easing | Usage |
|---|---|---|---|
| `--motion-instant` | 0ms | — | No animation (accessibility/reduced motion) |
| `--motion-fast` | 100ms | `ease-out` | Button press, checkbox toggle |
| `--motion-normal` | 200ms | `ease-in-out` | Panel slide, tab switch |
| `--motion-slow` | 350ms | `cubic-bezier(0.4,0,0.2,1)` | Modal appear, drawer open |
| `--motion-page` | 400ms | `cubic-bezier(0.4,0,0.2,1)` | Page transitions |
| `--motion-scan-pulse` | 1500ms | `ease-in-out`, infinite | Camera viewfinder scanning pulse |
| `--motion-result-reveal` | 500ms | `spring(200,20,0,0)` | Verdict card bounce-in |

> **Reduced Motion:** All animations must respect `prefers-reduced-motion: reduce`.
> When set, all transitions default to `--motion-fast` (100ms fade only, no movement).

---

## 4. Component Library {#4-component-library}

### 4.1 Verdict Badge

The single most important reusable component in the system. Appears in scan results,
tables, reports, and notifications.
┌─────────────────────┐ │ ✓ PASS │ — Green fill (#1B7A3E bg), white text │ ✗ FAIL │ — Red fill (#C0392B bg), white text │ ⚠ WARN │ — Orange fill (#E67E22 bg), white text │ ? INCONCLUSIVE │ — Grey fill (#7F8C8D bg), white text └─────────────────────┘

text


**Sizes:**
- `sm`: 20px height, 10px horizontal padding, `--type-label` 11px — for table rows
- `md`: 28px height, 14px horizontal padding, `--type-label` 12px — for cards
- `lg`: 40px height, 20px horizontal padding, `--type-label` 14px — for verdict hero

**States:** Static only. Badges are never interactive (they inform, never act).

**Accessibility:** `role="status"`, `aria-label="Compliance result: PASS"`.

---

### 4.2 Check Row Component

Used in the violation detail list. Shows one rule check and its result.
┌──────────────────────────────────────────────────────────────────────┐ │ [FAIL badge] Rule 6(1)(e) MRP — Inclusive of all taxes missing │ │ [▾ details] │ │ ─────────────────────────────────────────────────────────────────── │ │ Found: "MRP ₹45" │ │ Required: "MRP ₹45.00 (Incl. of all taxes)" │ │ Evidence: [annotated crop thumbnail] [Open full crop →] │ │ Confidence: ████████░░ 82% │ └──────────────────────────────────────────────────────────────────────┘

text


**States:**
- Collapsed (default) — shows badge + rule + short description + expand toggle
- Expanded — shows found value, required value, evidence crop, confidence bar
- Confirmed (inspector marked as confirmed violation) — blue left border added
- Disputed (inspector marked as false positive) — strikethrough, grey left border

**Interaction:** Tap anywhere on row to expand/collapse. Tap [Open full crop →] to open
annotated image in full-screen viewer.

---

### 4.3 Compliance Score Ring

A circular progress indicator showing overall compliance score for a package.
text

    ┌───────────────┐
    │      ○        │
    │   ╔══════╗    │
    │   ║  78% ║    │
    │   ║ Score║    │
    │   ╚══════╝    │
    │  22/28 checks │
    │  passed       │
    └───────────────┘
text


**Colors:** Score ≥ 90% → green ring; 70–89% → orange ring; < 70% → red ring.
**Animation:** Ring fills from 0% to final score over `--motion-slow` on mount.
**Sizes:** 80px (compact, in tables), 140px (card), 200px (verdict hero).

---

### 4.4 Annotated Image Viewer

Full-screen overlay showing the package image with bounding-box overlays.
┌──────────────────────────────────────────────────────────┐ │ [✕ Close] Annotated Label View [↓ Save] │ │ ─────────────────────────────────────────────────────── │ │ │ │ ┌────────────────────────────────────────┐ │ │ │ [Package image fills this area] │ │ │ │ │ │ │ │ ┌─ ─ ─ ─ ─ ─ ─ ─┐ ← red dashed │ │ │ │ │ MRP ₹45 │ box (FAIL) │ │ │ │ └ ─ ─ ─ ─ ─ ─ ─ ┘ │ │ │ │ [1] │ │ │ │ ┌─────────────┐ ← green solid │ │ │ │ │ Net Wt 500g│ box (PASS) │ │ │ │ └─────────────┘ [2] │ │ │ └────────────────────────────────────────┘ │ │ │ │ Legend: [■ FAIL] [■ PASS] [■ WARN] [■ INCONCLUSIVE] │ │ │ │ [1] Rule 6(1)(e) — MRP missing "Incl. of all taxes" │ │ [2] Rule 6(1)(c) — Net quantity ✓ │ │ │ │ ←→ Pinch to zoom · Double-tap to reset │ └──────────────────────────────────────────────────────────┘

text


**Bounding Box Colors:**
- FAIL: `#C0392B` dashed border, 2px, with number callout bubble
- PASS: `#1B7A3E` solid border, 1px
- WARN: `#E67E22` dashed border, 2px
- INCONCLUSIVE: `#7F8C8D` dotted border, 1px
- PDP boundary: `#1A3C6B` solid border, 3px, labeled "PDP"

**Gestures:** Pinch-to-zoom, pan, double-tap to reset, swipe down to dismiss.

---

### 4.5 Rule Reference Panel

A slide-up panel (mobile) or right drawer (web) that shows the full text of a cited rule.
┌──────────────────────────────────────────────────────────┐ │ Rule 7(4) — Table I [✕] │ │ ─────────────────────────────────────────────────────── │ │ Minimum numeral height for net quantity / MRP │ │ declarations, by PDP area │ │ │ │ Source: GSR 629(E), effective 01 Jan 2018 │ │ │ │ ┌──────────────────────────────────────────────────┐ │ │ │ PDP Area (cm²) │ Printed (mm) │ Embossed (mm) │ │ │ ├────────────────┼──────────────┼─────────────────┤ │ │ │ < 50 │ 1.0 │ 1.5* │ │ │ │ 50 – 100 │ 1.5 │ 3.0 │ │ │ │ 100 – 500 │ 2.5 ◄ │ 4.0 │ │ │ │ 500 – 2500 │ 4.0 │ 6.0 │ │ │ │ ≥ 2500 │ 6.0 │ 6.0 │ │ │ └──────────────────────────────────────────────────┘ │ │ │ │ ◄ Your package PDP: 220cm² → threshold: 2.5mm │ │ Measured font height: 1.8mm → VIOLATION │ │ │ │ * Verify against GSR 629(E) gazette (sources conflict) │ │ │ │ [Open Full Rules Reference →] │ └──────────────────────────────────────────────────────────┘

text


---

### 4.6 Confidence Indicator

Shows how confident the AI system is in a particular measurement or detection.
HIGH (≥ 85%): ████████████ 92% [solid bar, brand secondary color] MEDIUM (60–84%): ████████░░░░ 72% [partially filled, warn color] LOW (< 60%): ████░░░░░░░░ 41% [low fill, with warning icon]

text


**Rules:**
- Confidence < 60% → result is shown as `INCONCLUSIVE`, not PASS/FAIL.
- Confidence 60–74% → result shown but with WARN overlay and "Verify manually" note.
- Confidence ≥ 75% → result shown as final verdict.

These thresholds must appear in the UI's Settings screen and be configurable per user role.

---

### 4.7 Scan Progress Stepper

Shows multi-step scan process status (used in cylindrical/multi-view scan mode).
[Camera] → [Processing] → [OCR] → [Font Measure] → [Result] ●──────────●──────────○──────────○──────────────────○ Done Done Active Pending Pending

text


**States per step:** Pending (grey) → Active (animated pulse, brand primary) → Done (green checkmark) → Failed (red X).

---

### 4.8 Primary Button
States: Default: [Brand primary bg] [White text] [Rounded md] [Shadow elev-1] Hover: [Darken 10%] [Shadow elev-2] Pressed: [Darken 15%] [Scale 0.97] [Shadow elev-0] Disabled: [--color-surface-3 bg] [--color-text-tertiary] [No shadow] Loading: [Default colors] [Spinner replaces label] [Pointer-events: none]

text


**Sizes:**
- `sm`: 32px height, 12px/16px padding, 14px text
- `md`: 44px height, 16px/24px padding, 16px text ← default
- `lg`: 52px height, 20px/32px padding, 18px text ← primary CTAs, mobile full-width

**Mobile:** Full-width (`width: 100%`) for all primary actions in the scan flow.

---

### 4.9 Bottom Sheet (Mobile)

Slide-up panel used for: Violation details, Rule reference, Filter options, Export options.
States: Hidden: translateY(100%) — below screen Partial: translateY(40%) — shows top 60% of sheet (peek state) Full: translateY(0) — fully visible

text


**Gesture:** Drag handle at top. Swipe down to dismiss. Swipe up to expand.
**Backdrop:** `rgba(0,0,0,0.5)` blur overlay. Tap to dismiss.
**Border radius:** `--radius-xl` on top-left and top-right corners only.
**Max height:** 90vh. Scrollable content inside if needed.

---

### 4.10 Toast Notification
┌──────────────────────────────────────────────────┐ │ ✓ Report exported to Downloads [✕] │ └──────────────────────────────────────────────────┘

text


**Positions:**
- Mobile: bottom of screen, 16px above bottom nav, full width minus 32px margins
- Web: top-right corner, 320px max-width

**Types:**
- Success: green left border, check icon
- Error: red left border, X icon
- Info: blue left border, info icon
- Warning: orange left border, warning icon

**Duration:** 4000ms auto-dismiss. Persist on hover (web only).

---

## 5. Information Architecture & Navigation {#5-information-architecture}

### 5.1 Mobile App — Navigation Structure
LabelLens Mobile App │ ├── 📷 SCAN (Tab 1 — Default) │ ├── Quick Scan (flat package) │ ├── Cylindrical Scan (multi-view) │ ├── Manual Entry (type GTIN) │ └── Import from Gallery │ ├── 📋 HISTORY (Tab 2) │ ├── Today's scans │ ├── Past scans (paginated) │ ├── Flagged scans (starred) │ └── Pending sync (offline queue) │ ├── 🌐 E-COMMERCE (Tab 3) │ ├── URL input for listing check │ ├── Cross-channel reconciliation │ └── Listing history │ ├── 📊 DASHBOARD (Tab 4) │ ├── Today's stats │ ├── Violation trend (7 days) │ ├── Category breakdown │ └── Location heatmap │ └── 👤 PROFILE (Tab 5) ├── Inspector details ├── Settings │ ├── Language (English / हिंदी) │ ├── Dark mode │ ├── Confidence thresholds │ ├── Offline model management │ └── Report template ├── Sync status └── Help / Rules Reference

text


---

### 5.2 Web Dashboard — Navigation Structure
LabelLens Web Dashboard │ ├── 🏠 OVERVIEW (Home) │ ├── Compliance score summary │ ├── Recent scan activity feed │ ├── Active violations widget │ └── Quick actions │ ├── 📦 PRODUCTS │ ├── All Products (searchable, filterable table) │ ├── Product Detail (scan history, all checks, trend) │ ├── Add Product (manual / import) │ └── Bulk Upload (CSV + image folder) │ ├── ⚠️ VIOLATIONS │ ├── All Violations (filterable by rule, severity, date, SKU) │ ├── Violation Detail (full check, annotated image, export) │ ├── Review Queue (items awaiting human confirmation) │ └── Resolved Violations (archive) │ ├── 🌐 E-COMMERCE CHECKER │ ├── Listing URL input │ ├── Cross-channel comparison table │ ├── Reconciliation report │ └── E-com scan history │ ├── 📈 ANALYTICS │ ├── Compliance rate over time │ ├── Violations by rule (top 10) │ ├── Violations by category │ ├── Inspector performance (admin only) │ └── Heatmap (geo — admin only) │ ├── 🗂️ REPORTS │ ├── Generate PDF report │ ├── Schedule automated reports │ └── Report templates │ ├── 👥 TEAM (Admin only) │ ├── User management │ ├── Role assignment │ └── Audit log │ └── ⚙️ SETTINGS ├── Organization profile ├── API keys ├── Notification preferences ├── Confidence thresholds └── Rule version settings

text


---

### 5.3 User Role → Access Matrix

| Feature | Inspector (Field) | QA Reviewer | Compliance Manager | Admin |
|---|---|---|---|---|
| Mobile scan | ✅ | ✅ | ✅ | ✅ |
| View own scan history | ✅ | ✅ | ✅ | ✅ |
| View all scans (org) | ❌ | ✅ | ✅ | ✅ |
| Confirm / dispute violations | ✅ | ✅ | ✅ | ✅ |
| Bulk upload | ❌ | ✅ | ✅ | ✅ |
| Export individual report | ✅ | ✅ | ✅ | ✅ |
| Export batch report | ❌ | ❌ | ✅ | ✅ |
| E-commerce checker | ❌ | ✅ | ✅ | ✅ |
| Analytics dashboard | ❌ | Limited | ✅ | ✅ |
| User management | ❌ | ❌ | ❌ | ✅ |
| Configure thresholds | ❌ | ❌ | ✅ | ✅ |
| View inspector performance | ❌ | ❌ | ✅ | ✅ |

---

## 6. User Flows & Journey Maps {#6-user-flows}

### 6.1 Core Flow — Inspector Quick Scan (Primary Flow)
[ENTRY] │ App opens → Check for pending offline sync │ │ │ Sync available? ──YES──→ Background sync (banner notification) │ │ │ NO │ │ ▼ [SCAN TAB — Default Screen] │ Tap "Scan Label" (Large FAB button) │ ▼ [PACKAGE TYPE SELECTION] │ ┌──────────────┬──────────────────┬──────────────┐ │ FLAT/BOX │ CYLINDRICAL │ POUCH/OTHER │ └──────┬───────┴────────┬─────────┴──────┬───────┘ │ │ │ ▼ ▼ ▼ [CAMERA VIEW] [MULTI-FRAME [CAMERA VIEW] GUIDE SCREEN]

text


#### Sub-flow A: Flat Package Scan
[CAMERA VIEW — Flat Package] │ Viewfinder shows:

Rectangle guide overlay (dashed, auto-detect edges)
"Hold steady" / "Move closer" coaching text
Auto-capture when package fills guide + blur < threshold │ Auto-capture OR tap shutter button │ ▼ [PROCESSING SCREEN] │ Shows stepper: [Captured ✓] → [OCR...] → [Measure...] → [Check...] Progress animation (not a spinner — show actual step progress) │ ▼ (2–8 seconds on-device inference) [VERDICT SCREEN]
text


#### Sub-flow B: Cylindrical Package Scan (Multi-View)
[MULTI-VIEW GUIDE SCREEN] │ Instructions: "Hold package vertically. Rotate slowly for 4 captures." [Progress indicator: ○ ○ ○ ○ — 4 frames needed] │ Camera view with rotation guide arrows │ Auto-capture each 90° rotation (gyroscope + edge detection) OR tap shutter manually for each │ After 4 frames captured: │ ▼ [PROCESSING SCREEN] Shows: [Captured 4 frames ✓] → [3D Reconstruction...] → [Dewarping...] → [OCR...] → [Measure...] │ ▼ [VERDICT SCREEN]

text


#### Verdict Screen → Post-Scan Actions
[VERDICT SCREEN] │ Overall verdict: PASS / FAIL / INCONCLUSIVE (large hero badge) Compliance score ring (e.g., 18/28 checks passed) │ ┌──────────────────────────────────────┐ │ PASS (8) FAIL (6) WARN (3) INCONCLUSIVE (2) │ │ [Filter tabs] │ └──────────────────────────────────────┘ │ List of all checks (Check Row components) │ BOTTOM ACTION BAR: [📤 Export Report] [📌 Flag] [✏️ Add Note] [🗺️ View Map] │ ───────────────────────────────────────────── TAP [Export Report] │ ▼ [EXPORT OPTIONS BOTTOM SHEET]

PDF (Inspector Report — with rule citations)
PDF (Summary — one page)
JSON (API export)
Share via WhatsApp / Email │ SELECT PDF Inspector Report │ ▼ [GENERATING...] → [DONE — report saved to Downloads + shared]
text


---

### 6.2 Flow — Compliance Manager Batch Upload (Web)
[PRODUCTS PAGE] │ Click [+ Bulk Upload] button (top right) │ ▼ [UPLOAD MODAL — Step 1 of 3: Select Files] │ Drag-and-drop zone: "Drop image files here, or click to browse" Accepts: JPG, PNG, HEIC, WEBP, MP4 (for cylindrical video) Max: 500 files per batch, 10MB per file │ OR: Upload CSV with GTIN list (system fetches product data from GS1 DB) │ [Next →] │ ▼ [UPLOAD MODAL — Step 2 of 3: Configure Batch] │ Product Category: [Dropdown — Food / Cosmetics / Electronics / General / ...] Package Type: [Flat / Cylindrical / Pouch / Multi-piece / Auto-detect] Rule Version: [Current (Jan 2024) / Pre-2022 / Pre-2018] Reference Object: [EAN-13 barcode / GS1 DB lookup / Manual (enter package dims)] │ [Start Processing →] │ ▼ [BATCH PROCESSING — LIVE PROGRESS TABLE] │ ┌──────────────────────────────────────────────────────────────────────┐ │ Batch #B20260826-001 72/200 processed ETA: 4m 12s │ │ [████████████░░░░░░░░░░░░░░░░] 36% │ │ │ │ File Status Verdict Checks │ │ product_001.jpg ✓ Complete FAIL 21/28 │ │ product_002.jpg ✓ Complete PASS 28/28 │ │ product_003.heic ⟳ Processing — — │ │ product_004.jpg Queued — — │ └──────────────────────────────────────────────────────────────────────┘ │ On completion: [View Full Report] [Export Batch PDF] [Filter Failures Only]

text


---

### 6.3 Flow — E-Commerce Cross-Channel Reconciliation
[E-COMMERCE CHECKER TAB / PAGE] │ Input: "Paste product listing URL" [Amazon.in / Flipkart / Meesho / Other / Manual entry] │ Optional: Scan physical label first (link to existing scan) OR upload physical label image separately │ [▶ Check Listing] │ ▼ [PROCESSING] — Scraping listing + comparing with physical label data │ ▼ [CROSS-CHANNEL REPORT] │ ┌──────────────────────────────────────────────────────────────────────┐ │ Cross-Channel Compliance Report │ │ Physical Label: product_005.jpg Listing: amazon.in/dp/B09XXXX │ │ ─────────────────────────────────────────────────────────────────── │ │ │ │ Declaration Physical Label E-com Listing Match? │ │ ─────────────────────────────────────────────────────────────────── │ │ MRP ₹89.00 ₹89.00 ✓ MATCH │ │ Net Quantity 500g 500g ✓ MATCH │ │ Mfr. Name ABC Foods Pvt Ltd ABC Foods ⚠ PARTIAL │ │ Country of Origin India — ✗ MISSING │ │ Customer Care 1800-XXX-XXXX — ✗ MISSING │ │ MFG Date Jan 2026 — ✗ MISSING │ │ │ │ Overall: FAIL — 3 declarations missing from e-commerce listing │ │ Rule basis: Rule 6(10), LMPC Rules 2011 (as amended GSR 629(E) 2017)│ │ │ │ [Export CCPA Complaint Draft →] [Export Report →] │ └──────────────────────────────────────────────────────────────────────┘

text


---

### 6.4 Flow — Citizen Reporter
[CITIZEN MODE — Minimal UI, no login required] │ Screen 1: "Spotted a label violation? Report it." Large camera button │ Tap camera → Capture photo of product │ ▼ Screen 2: "What's the problem?" (radio list) ○ MRP not visible or missing ○ No manufacturer details ○ No net quantity ○ Product damaged / tampered ○ Other (text field) │ Auto-captured: GPS location, timestamp, photo │ [Submit Report] │ ▼ Screen 3: "Report Submitted ✓" Your tracking ID: LLR-20260826-0042 "We'll update you when your report is reviewed." [Track Report] [Submit Another]

text


---

## 7. Mobile Screen Specifications {#7-mobile-screens}

> **Device targets:** 360px–430px width, 640px–932px height.
> **Safe areas:** Bottom navigation bar is 64dp. iOS home indicator: 34px safe area bottom.
> **One-thumb zone:** All primary interactive elements within bottom 60% of screen.

---

### Screen M-01: Splash / Launch Screen
┌─────────────────────────────────┐ 320×693 (iPhone SE viewport) │ │ │ │ │ │ │ [LabelLens Logo] │ │ 70×70px logo mark │ │ "LabelLens" wordmark │ │ │ │ │ │ │ │ ───────────────────────── │ │ [████████████████░░░░░░░] │ Loading bar — model loading progress │ Loading inspection model... │ │ │ │ Dept. of Consumer Affairs │ Small lockup, tertiary text color │ │ └─────────────────────────────────┘

text


**Logic:**
- While loading: shows model loading progress (0–100%)
- If user has existing session: skip to Scan Tab
- If first launch: show Onboarding flow (Screen M-02)
- Background: `--color-brand-primary` (#1A3C6B)
- All text: white

---

### Screen M-02: Onboarding (First Launch — 3 slides)

#### Slide 1 of 3
┌─────────────────────────────────┐ │ [Skip]│ │ │ │ [Illustration: Phone scanning │ │ a grocery package, with │ │ PASS checkmark appearing] │ │ ~200×200px │ │ │ │ Scan Any Label in Seconds │ heading-1 │ │ │ Point your camera at any │ body-1 │ packaged product. LabelLens │ │ checks all 10 mandatory LMPC │ │ declarations automatically. │ │ │ │ ●○○ │ dot indicator │ │ │ ┌─────────────────────────┐ │ │ │ Next → │ │ primary button, full width │ └─────────────────────────┘ │ └─────────────────────────────────┘

text


#### Slide 2 of 3
[Illustration: Font size measurement overlay on a label]

Font Size & Placement — Measured, Not Guessed

We measure actual font height in mm and compare against Rule 7 Table I/II thresholds. No other app does this for Indian LMPC rules.

○●○

[Next →]

text


#### Slide 3 of 3
[Illustration: Physical label + online listing side-by-side with arrows]

Check Across Every Channel

Compare what's on the physical label with what's listed online. Catch the gap before CCPA does.

○○●

[Get Started →] ← navigates to Role Selection (M-03)

text


---

### Screen M-03: Role Selection (First Launch)
┌─────────────────────────────────┐ │ ← Who are you? │ │ │ │ Choose your role so we can │ │ show the right tools. │ │ │ │ ┌───────────────────────────┐ │ │ │ 🏛️ Legal Metrology │ │ ← tappable card │ │ Inspector │ │ │ │ Field inspections, │ │ │ │ seizure notices │ │ │ └───────────────────────────┘ │ │ │ │ ┌───────────────────────────┐ │ │ │ 🏢 Brand / Compliance │ │ ← tappable card │ │ Officer │ │ │ │ Pre-launch checks, │ │ │ │ batch review │ │ │ └───────────────────────────┘ │ │ │ │ ┌───────────────────────────┐ │ │ │ 👤 Citizen / Consumer │ │ ← tappable card │ │ Reporter │ │ │ │ Report violations │ │ │ └───────────────────────────┘ │ │ │ │ You can change this in │ │ Settings at any time. │ └─────────────────────────────────┘

text


---

### Screen M-04: Scan Tab — Home (Inspector Role)
┌─────────────────────────────────┐ │ LabelLens 🔔 👤 │ ← top bar: app name, notif, profile │ ───────────────────────────── │ │ │ │ ┌─────────────────────────┐ │ │ │ Today's Scans: 14 │ │ ← compact stats card │ │ ✓ 11 Pass ✗ 3 Fail │ │ │ │ Location: Sadar Bazaar │ │ │ └─────────────────────────┘ │ │ │ │ ─────── QUICK SCAN ───────── │ │ │ │ ┌───────────────────────────┐ │ │ │ │ │ │ │ [📷 Camera Preview │ │ ← live camera preview (cropped square) │ │ tap to full screen] │ │ │ │ │ │ │ └───────────────────────────┘ │ │ │ │ ┌─────────────────────────┐ │ │ │ 📷 Scan Label │ │ ← PRIMARY CTA — 52px height │ └─────────────────────────┘ │ │ │ │ ─────── OR ────────────────── │ │ │ │ [🖼️ From Gallery] [⌨️ Enter GTIN] [🔗 URL Check] │ │ │ │ ─────── RECENT ─────────────── │ │ │ │ product_012 ✗ FAIL 12m ago │ ← recent scan row │ product_011 ✓ PASS 28m ago │ │ product_010 ✓ PASS 41m ago │ │ │ │ [View All History →] │ │ │ │ [📷 Scan] [📋 History] [🌐 Web] [📊 Stats] [👤 Me] │ ← bottom nav └─────────────────────────────────┘

text


---

### Screen M-05: Package Type Selection (Modal / Bottom Sheet)

Triggered when user taps "Scan Label".
┌─────────────────────────────────┐ │ ─── [drag handle] ─── │ │ │ │ Select Package Type │ heading-1 │ │ │ ┌───────────────────────────┐ │ │ │ 📦 Flat / Box / Sachet │ │ ← card button │ │ Labels on flat surface │ │ │ └───────────────────────────┘ │ │ │ │ ┌───────────────────────────┐ │ │ │ 🧴 Cylindrical / Bottle │ │ ← card button (multi-view) │ │ Bottles, cans, tubes │ │ │ │ Requires 4 captures │ │ │ └───────────────────────────┘ │ │ │ │ ┌───────────────────────────┐ │ │ │ 🛍️ Pouch / Flexible │ │ ← card button │ │ Stand-up pouches, bags │ │ │ └───────────────────────────┘ │ │ │ │ ┌───────────────────────────┐ │ │ │ 🔍 Auto-detect │ │ ← AI picks type automatically │ │ Let AI decide (slower) │ │ │ └───────────────────────────┘ │ │ │ │ [Cancel] │ └─────────────────────────────────┘

text


---

### Screen M-06: Camera Viewfinder — Flat Package
┌─────────────────────────────────┐ │ [✕] [⚡ Flash]│ ← top: close + flash toggle │ │ │ │ │ ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ │ │ │ │ │ ← scan guide rectangle (animates to match │ │ │ │ detected package edge) │ │ POSITION LABEL │ │ │ │ WITHIN FRAME │ │ │ │ │ │ │ │ │ │ │ └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘ │ │ │ │ ───────────────────────────── │ │ │ │ [📷 Capture] │ ← shutter button, 72dp, centered │ │ │ [🖼️ Gallery] [💡 Tips] │ ← flanking the shutter │ │ │ ┌─────────────────────────────┐│ │ │ ⚡ Ensure all text visible ││ ← coaching tip bar │ │ Good lighting preferred ││ │ └─────────────────────────────┘│ └─────────────────────────────────┘

text


**Dynamic Coaching States:**

| Condition | Message |
|---|---|
| Package not detected | "Point camera at the label" |
| Too far | "Move closer to the label" |
| Too close / blurry | "Back up slightly" |
| Low light | "Try better lighting or use flash" |
| Package detected, hold still | "Hold steady..." |
| Auto-capture triggered | [Shutter animation + flash] |
| Good position | Guide rectangle turns green |

---

### Screen M-07: Camera Viewfinder — Cylindrical Package (Multi-View)
┌─────────────────────────────────┐ │ [✕] Cylindrical Scan 1/4 │ ← top: close, title, frame counter │ │ │ ○ ○ ○ ○ ← progress dots for 4 frames │ │ │ [Camera feeds cylindrical │ │ package in frame] │ │ │ │ ← ROTATE → │ ← rotation arrows (animated) │ Rotate 90° clockwise │ │ │ │ [Compass/rotation indicator: │ │ ──── 0° │90° │180°│270°──── ]│ ← shows rotation progress │ ▲ │ │ You are here │ │ │ │ ───────────────────────────── │ │ │ │ [📷 Capture View 1] │ │ │ │ ┌─────────────────────────────┐│ │ │ 📐 Hold bottle upright ││ │ │ Rotate slowly between ││ │ │ each capture ││ │ └─────────────────────────────┘│ └─────────────────────────────────┘

text


**After each capture:** Captured frame thumbnail appears below progress dots. Frame dot turns filled green. Counter updates: `2/4`.

---

### Screen M-08: Processing Screen
┌─────────────────────────────────┐ │ │ │ │ │ [Thumbnail of captured image] │ │ 120×120px, rounded-lg │ │ │ │ ───────────────────────── │ │ │ │ Analyzing label... │ ← heading-1 │ │ │ ───────────────────────── │ │ │ │ ✓ Image captured │ ← step 1 done │ ⟳ OCR + field extraction │ ← step 2 active (animated) │ ○ Font size measurement │ ← step 3 pending │ ○ Placement geometry │ ← step 4 pending │ ○ Rule compliance check │ ← step 5 pending │ ○ Generating report │ ← step 6 pending │ │ │ [████████░░░░░░░░░░░░░░░░░] │ ← progress bar │ Processing on device │ │ │ │ ───────────────────────── │ │ 🔒 Your data stays on device │ ← privacy reassurance │ (unless you choose to sync)│ │ │ └─────────────────────────────────┘

text


**Timing targets:**
- On-device inference: 3–8 seconds for flat package
- Cylindrical reconstruction: 8–15 seconds
- If exceeding 20 seconds: show "This is taking longer than usual..." with option to cancel

---

### Screen M-09: Verdict Screen — FAIL Example
┌─────────────────────────────────┐ │ ← Scan Result [📤 Share]│ ← top bar │ │ │ ┌─────────────────────────┐ │ │ │ ✗ │ │ ← verdict hero section │ │ FAIL │ │ large badge (40px height) │ │ │ │ │ │ [Score Ring: 18/28] │ │ 140px ring │ │ 18 of 28 checks │ │ │ │ passed │ │ │ │ │ │ │ │ 6 violations found │ │ fail color text │ └─────────────────────────┘ │ │ │ │ ─ Product Info ────────────── │ │ Detected: "Sunflower Oil 1L" │ │ GTIN: 8901234567890 │ │ Scanned: 26 Aug 2026, 14:32 │ │ Location: Sadar Bazaar, Delhi │ │ │ │ ─ Filter Results ─────────────│ │ [All 28] [✗ FAIL 6] [⚠ 3] [✓ 18] [? 1] │ ← filter tabs │ │ │ ─ Violations ─────────────────│ │ │ │ ┌──────────────────────────┐ │ │ │ [FAIL] Rule 6(1)(e) │ │ ← check row, collapsed │ │ MRP: "Incl. of all taxes"│ │ │ │ text missing │ ▾│ │ └──────────────────────────┘ │ │ │ │ ┌──────────────────────────┐ │ │ │ [FAIL] Rule 7(4) Table I │ │ ← check row, collapsed │ │ Font height: 1.8mm │ │ │ │ Required: ≥ 2.5mm │ ▾│ │ └──────────────────────────┘ │ │ │ │ ┌──────────────────────────┐ │ │ │ [FAIL] Rule 6(1)(h) │ │ │ │ Customer care details │ │ │ │ missing │ ▾│ │ └──────────────────────────┘ │ │ │ │ [Show all 6 violations...] │ │ │ │ ─ Actions ─────────────────── │ │ ┌─────────────────────────┐ │ │ │ 📄 Export PDF Report │ │ ← primary button │ └─────────────────────────┘ │ │ │ │ [✏️ Add Note] [📌 Flag] [🔁 Rescan] │ │ │ │ [📷 Scan] [📋 History] [🌐] [📊] [👤] │ └─────────────────────────────────┘

text


---

### Screen M-10: Verdict Screen — PASS Example
┌─────────────────────────────────┐ │ ← Scan Result [📤 Share]│ │ │ │ ┌─────────────────────────┐ │ │ │ ✓ │ │ │ │ PASS │ │ ← green hero │ │ │ │ │ │ [Score Ring: 28/28] │ │ │ │ All 28 checks passed │ │ │ │ │ │ │ │ Fully LMPC Compliant │ │ │ └─────────────────────────┘ │ │ │ │ ─ Product Info ────────────── │ │ Detected: "Whole Wheat Biscuits" │ GTIN: 8901234567891 │ │ Scanned: 26 Aug 2026, 14:45 │ │ │ │ ─ All Checks ──────────────── │ │ [All 28] [✓ PASS 28] │ │ │ │ ✓ Rule 6(1)(a) Manufacturer name + PIN │ │ ✓ Rule 6(1)(b) Generic product name │ │ ✓ Rule 6(1)(c) Net quantity (500g) │ │ ✓ Rule 6(1)(d) MFG date (Jan 2026) │ │ ✓ Rule 6(1)(e) MRP ₹35.00 (incl. taxes) │ │ ✓ Rule 6(1)(h) Consumer care: 1800-... │ │ ✓ Rule 7(4) Font 4.2mm ≥ 2.5mm ✓ │ │ ✓ Rule 8(1) Placement: lower 30% ✓ │ │ ... [Show all 28 →] │ │ │ │ ┌─────────────────────────┐ │ │ │ 📄 Export PDF Report │ │ │ └─────────────────────────┘ │ │ │ │ [📷 Scan] [📋 History] [🌐] [📊] [👤] │ └─────────────────────────────────┘

text


---

### Screen M-11: Violation Detail — Expanded Check Row

Activated by tapping on a violation row.
┌─────────────────────────────────┐ │ ← Violation Detail Rule 7(4)│ │ │ │ ┌─ [FAIL badge] ─────────────┐ │ │ │ │ │ │ │ Font Size Violation │ │ heading-1 │ │ Rule 7(4) Table I │ │ │ │ GSR 629(E), eff. Jan 2018 │ │ caption, monospace │ │ │ │ │ └────────────────────────────┘ │ │ │ │ ─ Annotated Image ─────────── │ │ ┌────────────────────────────┐ │ │ │ [Package image with MRP │ │ ← 240px height image │ │ region highlighted in │ │ │ │ red dashed box] │ │ │ │ [Zoom 🔍] │ │ │ └────────────────────────────┘ │ │ │ │ ─ Measurement ──────────────── │ │ Measured font height: 1.8 mm │ ← monospace, fail color │ Required minimum: 2.5 mm │ ← monospace, body color │ Shortfall: 0.7 mm │ ← monospace, fail color │ PDP area computed: 220 cm² │ ← monospace │ Tier applies: 100–500 cm² │ │ Confidence: [████████░░] 82% │ │ │ │ ─ Rule Text ────────────────── │ │ ┌────────────────────────────┐ │ │ │ Rule 7(4) — The height of │ │ │ │ numerals used in net │ │ │ │ quantity and MRP │ │ │ │ declarations shall not be │ │ │ │ less than: │ │ │ │ │ │ │ │ PDP 100–500 cm² → 2.5mm │ │ ← highlighted row │ │ [View full table →] │ │ │ └────────────────────────────┘ │ │ │ │ ─ Inspector Actions ───────── │ │ [✓ Confirm Violation] [✗ Dispute — False Positive] │ │ [✏️ Add Note] │ │ │ │ ─ Note ─────────────────────── │ │ [Text field: "Add inspection │ │ note..."] │ │ │ └─────────────────────────────────┘

text


---

### Screen M-12: Scan History
┌─────────────────────────────────┐ │ Scan History [🔍 Search]│ │ │ │ [Filter Bar] │ │ [All] [FAIL] [PASS] [Today] [This Week] [Flagged] │ │ │ │ ─ Today, 26 Aug 2026 ───────── │ │ │ │ ┌──────────────────────────┐ │ │ │ [thumbnail] Sunflower Oil │ │ │ FAIL 14:32 Sadar Bazaar │ │ │ 6 violations · 18/28 ✓ │ │ └──────────────────────────┘ │ │ │ │ ┌──────────────────────────┐ │ │ │ [thumbnail] Wheat Biscuits │ │ │ PASS 14:45 Sadar Bazaar │ │ │ 28/28 ✓ fully compliant │ │ └──────────────────────────┘ │ │ │ │ ─ Yesterday, 25 Aug 2026 ───── │ │ │ │ ┌──────────────────────────┐ │ │ │ [thumbnail] Soap Bar │ │ │ │ WARN 11:20 Lajpat Nagar │ │ │ 2 advisories · 26/28 ✓ │ │ │ └──────────────────────────┘ │ │ │ │ [Pending Sync: 3 scans] [🔄 Sync Now] │ ← if offline queue exists │ │ │ [📷 Scan] [📋 History] [🌐] [📊] [👤] │ └─────────────────────────────────┘

text


---

### Screen M-13: Settings
┌─────────────────────────────────┐ │ Settings │ │ │ │ ─ Account ──────────────────── │ │ Inspector ID: LMO-DL-0042 │ │ Name: Rajan Tiwari │ │ District: Delhi │ │ [Edit Profile] │ │ │ │ ─ Display ──────────────────── │ │ Language: [English ▾] │ │ Dark Mode: [toggle ●────] │ │ Text Size: [●──────] Larger │ │ │ │ ─ Scan Settings ──────────── │ │ Confidence threshold: │ │ Min. for PASS/FAIL verdict: │ │ [●──────────] 75% │ │ │ │ Default package type: │ │ [Auto-detect ▾] │ │ │ │ Scale reference: │ │ [EAN-13 Barcode (default) ▾] │ │ │ │ ─ Offline / Storage ───────── │ │ On-device model: v2.4 │ │ Model size: 248 MB │ │ Last updated: 22 Aug 2026 │ │ [Update Model] │ │ │ │ Offline scan queue: 3 scans │ │ [Sync Now] │ │ │ │ Storage used: 1.2 GB │ │ [Clear old scans] │ │ │ │ ─ Report ───────────────────── │ │ Report template: Inspector │ │ Organization name: DCA Delhi │ │ Officer stamp: [Upload] │ │ │ │ ─ About ────────────────────── │ │ App version: 1.0.0 │ │ Rules version: Jan 2024 │ │ [View rules changelog] │ │ [Privacy policy] │ │ │ │ [📷 Scan] [📋 History] [🌐] [📊] [👤] │ └─────────────────────────────────┘

text


---

## 8. Web Dashboard Screen Specifications {#8-web-dashboard-screens}

> **Layout system:** 12-column grid, 24px gutter, 1280px max-width container.
> **Sidebar width:** 240px (collapsed: 64px icon-only).
> **Top bar height:** 56px.

---

### Screen W-01: Web Dashboard — Overview / Home
┌──────────────────────────────────────────────────────────────────────────────────┐ │ LabelLens 🔔 Priya S. ▾ [Logout]│ ← top bar │ ─────────────────────────────────────────────────────────────────────────────── │ │ │ │ ┌──────────┐ ┌──────────────────────────────────────────────────────────────┐ │ │ │ │ │ Good morning, Priya. 26 Aug 2026 │ │ │ │ 🏠 Home │ │ You have 12 products pending review. │ │ │ │ │ │ │ │ │ │ 📦 Products│ │ ─ Compliance Overview ──────────────────────────────────── │ │ │ │ │ │ │ │ │ │ ⚠️ Violations│ │ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ │ │ │ │ │ │ │ SCANNED │ │ PASS RATE │ │ VIOLATIONS │ │ │ │ │ 🌐 E-Com │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ 247 │ │ 78.5% │ │ 53 │ │ │ │ │ 📈 Analytics│ │ │ this month │ │ ▲3.2% MoM │ │ open today │ │ │ │ │ │ │ └──────────────┘ └──────────────┘ └──────────────┘ │ │ │ │ 🗂️ Reports │ │ │ │ │ │ │ │ ─ Compliance Rate — Last 30 Days ───────────────────────── │ │ │ │ 👥 Team │ │ [Line chart: compliance % over 30 days — multiple lines │ │ │ │ │ │ for different product categories, e.g. Food, Cosmetics] │ │ │ │ ⚙️ Settings│ │ │ │ │ │ │ │ ─ Top 5 Violated Rules ─────────────────────────────────── │ │ │ │ │ │ Rule 7(4) Font Size ████████████████ 38% │ │ │ │ │ │ Rule 6(1)(e) MRP format ████████████ 28% │ │ │ │ │ │ Rule 6(1)(h) Consumer care ████████ 19% │ │ │ │ │ │ Rule 6(11) USP missing ████ 12% │ │ │ │ │ │ Rule 6(10) E-com listing ███ 9% │ │ │ │ │ │ │ │ │ │ │ │ ─ Recent Activity ─────────────────────────────────────── │ │ │ │ │ │ 14:32 Sunflower Oil 1L FAIL (6) Arjun M. │ │ │ │ │ │ 14:28 Wheat Biscuits PASS Arjun M. │ │ │ │ │ │ 13:55 Shampoo 200ml WARN (2) System │ │ │ │ │ │ 13:40 Soap Bar 100g FAIL (3) System │ │ │ │ │ │ [View all →] │ │ │ └──────────┘ └──────────────────────────────────────────────────────────────┘ │ └──────────────────────────────────────────────────────────────────────────────────┘

text


---

### Screen W-02: Products Table
┌ Products [+ Add Product] [⇑ Bulk Upload] ┐ │ │ │ ┌──────────────────────────────────────────────────────────────────────────┐ │ │ │ [🔍 Search products...] [Filter: Category ▾] [Verdict ▾] [Date ▾] │ │ │ │ Showing 1–25 of 247 products│ │ │ └──────────────────────────────────────────────────────────────────────────┘ │ │ │ │ ┌──┬────────────────────┬────────────┬────────────┬───────┬──────────┬──────┐ │ │ │ │ Product │ GTIN │ Category │Verdict│ Score │Action│ │ │ ├──┼────────────────────┼────────────┼────────────┼───────┼──────────┼──────┤ │ │ │☐ │[img] Sunflower Oil │89012345678 │ Food │[FAIL] │18/28 ██▒│ ⋯ │ │ │ │ │ 1L 500ml │90 │ │ │ 64% │ │ │ │ ├──┼────────────────────┼────────────┼────────────┼───────┼──────────┼──────┤ │ │ │☐ │[img] Wheat Biscuit │89012345678 │ Food │[PASS] │28/28 ███│ ⋯ │ │ │ │ │ 200g │91 │ │ │100% │ │ │ │ ├──┼────────────────────┼────────────┼────────────┼───────┼──────────┼──────┤ │ │ │☐ │[img] Shampoo 200ml │89012345678 │ Cosmetics │[WARN] │26/28 ██▒│ ⋯ │ │ │ │ │ │92 │ │ │ 93% │ │ │ │ ├──┼────────────────────┼────────────┼────────────┼───────┼──────────┼──────┤ │ │ │☐ │[img] Soap Bar 100g │89012345678 │ Cosmetics │[FAIL] │22/28 ██▒│ ⋯ │ │ │ │ │ │93 │ │ │ 79% │ │ │ │ └──┴────────────────────┴────────────┴────────────┴───────┴──────────┴──────┘ │ │ │ │ [☐ Select all] Selected: 0 [Export Selected ▾] │ │ │ │ ← Prev [1] [2] [3] ... [10] Next → │ └──────────────────────────────────────────────────────────────────────────────────┘

text


**Row Actions (⋯ menu):**
- View full report
- Rescan / update
- Add to comparison
- Export PDF
- Delete

**Bulk Actions (when rows selected):**
- Export batch PDF
- Export CSV
- Mark as reviewed
- Delete selected

---

### Screen W-03: Product Detail Page
┌ ← Products / Sunflower Oil 1L ┐ │ │ │ ┌───────────────────────────┐ ┌────────────────────────────────────────────┐ │ │ │ │ │ Sunflower Oil 1L — 500ml │ │ │ │ [Product label image │ │ GTIN: 8901234567890 │ │ │ │ with bounding boxes │ │ Category: Food — Edible Oil │ │ │ │ overlaid] │ │ Manufacturer: ABC Foods Pvt Ltd │ │ │ │ │ │ Last scanned: 26 Aug 2026, 14:32 │ │ │ │ [View annotated image →] │ │ │ │ │ │ [View label reconstruction →]│ │ Overall Verdict: [FAIL badge] │ │ │ │ │ │ Compliance Score: │ │ │ │ [Package: Cylindrical] │ │ [Score ring: 18/28] │ │ │ │ [PDP: 40% × H × C │ │ │ │ │ │ = 220 cm²] │ │ [📄 Export PDF] [📤 Share] [🔁 Rescan] │ │ │ └───────────────────────────┘ └────────────────────────────────────────────┘ │ │ │ │ ─ Compliance Checks ────────────────────────────────────────────────────────── │ │ │ │ [All (28)] [FAIL (6)] [WARN (3)] [PASS (18)] [INCONCLUSIVE (1)] │ │ │ │ ┌─────────────────────────────────────────────────────────────────────────────┐ │ │ │ ✗ Rule 6(1)(e) │ MRP declaration missing "Incl. of all taxes" │ ▾ │ │ │ │ │ Found: "MRP ₹89" Required: +taxes text │ │ │ │ ├─────────────────────────────────────────────────────────────────────────────┤ │ │ │ ✗ Rule 7(4) │ Numeral height 1.8mm < 2.5mm required │ ▾ │ │ │ │ │ PDP: 220cm² (tier: 100–500cm² → min 2.5mm) │ │ │ │ ├─────────────────────────────────────────────────────────────────────────────┤ │ │ │ ✗ Rule 6(1)(h) │ Customer care details absent │ ▾ │ │ │ ├─────────────────────────────────────────────────────────────────────────────┤ │ │ │ ✗ Rule 6(11) │ Unit sale price not declared │ ▾ │ │ │ ├─────────────────────────────────────────────────────────────────────────────┤ │ │ │ ✗ Rule 8(1) │ Net qty not in lower 30% of PDP │ ▾ │ │ │ ├─────────────────────────────────────────────────────────────────────────────┤ │ │ │ ✗ Rule 6(1)(c) │ Dual declaration missing (edible oil) │ ▾ │ │ │ │ │ Volume only; weight declaration required │ │ │ │ ├─────────────────────────────────────────────────────────────────────────────┤ │ │ │ ⚠ Rule 7(3) │ Some text region: 0.9mm — advisory (min 1mm) │ ▾ │ │ │ ├─────────────────────────────────────────────────────────────────────────────┤ │ │ │ ✓ Rule 6(1)(a) │ Manufacturer: ABC Foods Pvt Ltd, PIN 110001 │ │ │ │ │ ✓ Rule 6(1)(b) │ Generic name: "Refined Sunflower Oil" │ │ │ │ │ ✓ Rule 6(1)(c) │ Net quantity: 500ml │ │ │ │ └─────────────────────────────────────────────────────────────────────────────┘ │ │ │ │ ─ Scan History ─────────────────────────────────────────────────────────────── │ │ 26 Aug 2026 FAIL 18/28 Rajan T. Delhi Sadar Bazaar [View] │ │ 15 Aug 2026 FAIL 17/28 System Batch B20260815-001 [View] │ └────────────────────────────────────────────────────────────────────────────────────┘

text


---

### Screen W-04: Violations Table
┌ Violations [Export All ▾] ┐ │ │ │ ┌─────────────────────────────────────────────────────────────────────────┐ │ │ │ [Search] [Rule ▾] [Severity ▾] [Category ▾] [Status ▾] [Date range ▾]│ │ │ │ 53 open violations │ │ │ └─────────────────────────────────────────────────────────────────────────┘ │ │ │ │ ┌──┬──────────────┬───────────────┬────────┬───────────┬──────────┬──────────┐ │ │ │ │ Product │ Rule │ Severity│ Category │ Status │ Detected │ │ │ ├──┼──────────────┼───────────────┼────────┼───────────┼──────────┼──────────┤ │ │ │☐ │Sunflower Oil │ Rule 7(4) │[FAIL] │ Food │ Open │26 Aug │ │ │ │ │ │ Font too small│ │ │ │ │ │ │ ├──┼──────────────┼───────────────┼────────┼───────────┼──────────┼──────────┤ │ │ │☐ │Soap Bar 100g │ Rule 6(1)(h) │[FAIL] │ Cosmetics │ In Review│26 Aug │ │ │ │ │ │ No consumer │ │ │ Arjun M. │ │ │ │ │ │ │ care details │ │ │ │ │ │ │ ├──┼──────────────┼───────────────┼────────┼───────────┼──────────┼──────────┤ │ │ │☐ │Shampoo 200ml │ Rule 6(11) │[WARN] │ Cosmetics │ Open │25 Aug │ │ │ │ │ │ USP format │ │ │ │ │ │ │ └──┴──────────────┴───────────────┴────────┴───────────┴──────────┴──────────┘ │ │ │ │ Selected: 0 [Bulk: Assign ▾] [Export ▾] │ └───────────────────────────────────────────────────────────────────────────────────┘

text


---

### Screen W-05: E-Commerce Cross-Channel Checker
┌ E-Commerce Compliance Checker ┐ │ │ │ ─ Step 1: Physical Label ───────────────────────────────────────────────────── │ │ │ │ ┌──────────────────────────────────┐ OR ┌─────────────────────────────────┐ │ │ │ Drag & drop label image here │ │ Select from existing scans │ │ │ │ or click to upload │ │ [Search product ▾] │ │ │ │ [↑ Upload Image] │ │ │ │ │ └──────────────────────────────────┘ └─────────────────────────────────┘ │ │ │ │ ─ Step 2: E-Commerce Listing URL ───────────────────────────────────────────── │ │ │ │ ┌────────────────────────────────────────────────────────────────────┐ [Check] │ │ │ https://www.amazon.in/dp/B09XXXX... │ │ │ └────────────────────────────────────────────────────────────────────┘ │ │ │ │ Platform auto-detected: [Amazon.in logo] │ │ │ │ ─ Or enter listing details manually ────────────────────────────────────────── │ │ [Product name] [MRP shown on listing] [Net qty shown] [Mfr. name shown] [Country]│ │ │ │ [▶ Run Cross-Channel Check] │ │ │ │ ─────────────────────────────────────────────────────────────────────────────── │ │ │ │ ─ RESULT — Cross-Channel Reconciliation Report ─────────────────────────────── │ │ │ │ Overall: FAIL — 3 declarations absent from e-commerce listing │ │ Rule basis: Rule 6(10), LMPC Rules 2011 (GSR 629(E), eff. Jan 2018) │ │ │ │ ┌──────────────────────┬──────────────────────┬──────────────────┬──────────┐ │ │ │ Declaration │ Physical Label │ E-com Listing │ Status │ │ │ ├──────────────────────┼──────────────────────┼──────────────────┼──────────┤ │ │ │ MRP │ ₹89.00 (incl. taxes) │ ₹89.00 │ ⚠ PARTIAL│ │ │ │ Net Quantity │ 500ml │ 500ml │ ✓ MATCH │ │ │ │ Manufacturer Name │ ABC Foods Pvt Ltd │ ABC Foods │ ⚠ PARTIAL│ │ │ │ Country of Origin │ India │ — │ ✗ MISSING│ │ │ │ Customer Care │ 1800-123-4567 │ — │ ✗ MISSING│ │ │ │ MFG Date │ Jan 2026 │ — │ ✗ MISSING│ │ │ │ Generic Name │ Refined Sunflower Oil │ Sunflower Oil │ ✓ MATCH │ │ │ │ Mfr. Address │ Full + PIN │ — │ ✗ MISSING│ │ │ └──────────────────────┴──────────────────────┴──────────────────┴──────────┘ │ │ │ │ [📄 Export CCPA Complaint Draft] [📄 Export Compliance Report] │ └───────────────────────────────────────────────────────────────────────────────────┘

text


---

### Screen W-06: PDF Report Preview (Inspector Grade)

This describes the output PDF layout, not a web screen — it determines what the export
looks like.
┌─── PAGE 1 OF PDF REPORT ─────────────────────────────────────────────────────────┐ │ │ │ [Government Logo / Org Logo] LEGAL METROLOGY LABEL INSPECTION REPORT │ │ Automated Compliance Verification │ │ │ │ ─────────────────────────────────────────────────────────────────────────────── │ │ INSPECTION DETAILS │ │ Report ID: LLR-20260826-DL-042 │ │ Inspection Date: 26 August 2026, 14:32 IST │ │ Inspector ID: LMO-DL-0042 │ │ Inspector Name: Rajan Tiwari │ │ Inspection Location: 28.6512° N, 77.2315° E — Sadar Bazaar, Delhi │ │ │ │ PRODUCT DETAILS │ │ Product Name: Refined Sunflower Oil (as detected) │ │ GTIN: 8901234567890 (as detected from barcode) │ │ Package Type: Cylindrical │ │ PDP Area: 220 cm² (computed: 40% × H(12cm) × C(46.0cm)) │ │ Font Size Tier: 100–500 cm² (Table I, Rule 7(4)) │ │ │ │ ─────────────────────────────────────────────────────────────────────────────── │ │ OVERALL VERDICT: ✗ FAIL │ │ Compliance Score: 18 of 28 checks passed (64.3%) │ │ Critical violations: 5 Warnings: 3 Inconclusive: 1 │ │ │ │ ─────────────────────────────────────────────────────────────────────────────── │ │ VIOLATION DETAILS │ │ │ │ [1] Rule 6(1)(e) — Maximum Retail Price Declaration │ │ Violation: "(Inclusive of all taxes)" text missing from MRP declaration │ │ Found on label: "MRP ₹89" │ │ Required: "MRP ₹89.00 (Inclusive of all taxes)" or equivalent │ │ Authority: Rule 6(1)(e), LMPC Rules 2011 │ │ [Annotated crop image — 200×100px inline] │ │ Confidence: 91% │ │ │ │ [2] Rule 7(4) Table I — Numeral Font Size │ │ Violation: MRP/net quantity numeral height below minimum │ │ Measured: 1.8 mm Required: ≥ 2.5 mm (PDP 220cm², tier 100–500cm²) │ │ Shortfall: 0.7 mm │ │ Authority: Rule 7(4) Table I, GSR 629(E), effective 01 January 2018 │ │ [Annotated crop image with measurement overlay — 200×100px inline] │ │ Confidence: 82% │ │ │ │ [3] Rule 6(1)(h) — Consumer Care Details │ │ Violation: No consumer care phone / email / address found on PDP │ │ Authority: Rule 6(1)(h), GSR 629(E), effective 01 January 2018 │ │ Confidence: 95% │ │ │ │ [4] Rule 6(11) — Unit Sale Price │ │ Violation: Unit sale price not declared │ │ Required: Price per ml (since net volume < 1L) │ │ Authority: Rule 6(11), GSR 226(E), effective 01 October 2022 │ │ Confidence: 89% │ │ │ │ [5] Rule 6(1)(c) — Dual Net Quantity (Edible Oil) │ │ Violation: Edible oil declared by volume only; weight declaration required │ │ Found: 500ml only Required: 500ml + weight equivalent in grams │ │ Authority: Fourth Schedule Item 11, amended 2023, eff. 01 Jan 2024 │ │ Confidence: 94% │ │ │ │ ─────────────────────────────────────────────────────────────────────────────── │ │ ADVISORY NOTICES (Non-critical) │ │ [W1] Rule 7(3): Minor text region — 0.9mm, minimum 1.0mm. Advisory. │ │ │ │ ─────────────────────────────────────────────────────────────────────────────── │ │ INCONCLUSIVE CHECKS │ │ [I1] Rule 8(1) Placement geometry — Low confidence (41%) due to package angle. │ │ Manual verification recommended. │ │ │ │ ─────────────────────────────────────────────────────────────────────────────── │ │ NOTE: This report is generated by LabelLens automated system. Results with │ │ confidence < 75% are marked INCONCLUSIVE and require human verification. │ │ This report may be used as supporting evidence in proceedings under the Legal │ │ Metrology Act, 2009. Inspector signature and seal must be appended for │ │ official use. │ │ │ │ ___________________________ ___________________________ │ │ Inspector Signature Official Seal │ │ │ │ System ID: LabelLens v1.0 | Rule DB: Jan 2024 | Generated: 26 Aug 2026 14:35 │ └───────────────────────────────────────────────────────────────────────────────────┘

text


---

### Screen W-07: Analytics Dashboard
┌ Analytics [Date range: Aug 2026 ▾] [Export ▾] ┐ │ │ │ ─ KPI Cards (4-column) ─────────────────────────────────────────────────────── │ │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │ │ │ 247 │ │ 78.5% │ │ 53 │ │ 4.2s │ │ │ │ Products │ │ Pass Rate │ │ Open │ │ Avg scan │ │ │ │ scanned │ │ ▲3.2% MoM│ │ violations│ │ time │ │ │ └──────────┘ └──────────┘ └──────────┘ └──────────┘ │ │ │ │ ─ Compliance Trend ─────────────────────── ─ Violations by Rule ─────────── │ │ [Line chart: daily compliance % │ [Bar chart: top 10 rules, │ │ for last 30 days] │ horizontal bars, sorted by │ │ │ violation count] │ │ ───────────────────────────────────────── ───────────────────────────────── │ │ │ │ ─ By Category ──────────────────────────── ─ Location Heatmap ────────────── │ │ [Pie chart: Food 45%, Cosmetics 30%, │ [India map with colored │ │ Electronics 15%, General 10%] │ markers for inspection │ │ │ locations, clustered] │ │ ───────────────────────────────────────── ───────────────────────────────── │ │ │ │ ─ Violation Resolution Rate ───────────────────────────────────────────────── │ │ [Stacked bar: Open / In Review / Resolved — per week for last 8 weeks] │ └───────────────────────────────────────────────────────────────────────────────────┘

text


---

## 9. Micro-interactions & Animation Spec {#9-micro-interactions}

### 9.1 Camera Auto-Capture Trigger

When the system detects a good package position:

1. Guide rectangle border turns from dashed white → solid green (`--color-pass`)
2. Border pulses once (scale 1.0 → 1.03 → 1.0, 300ms)
3. "Hold steady..." text appears below guide
4. After 800ms steady detection: shutter fires
5. White flash overlay: opacity 0 → 0.8 → 0 in 200ms
6. Screen briefly freezes on captured frame (100ms)
7. Transitions to Processing Screen

---

### 9.2 Verdict Reveal Animation

When Processing completes → Verdict Screen:

1. Screen fades in (opacity 0 → 1, 200ms)
2. Verdict badge scales from 0 → 1.1 → 1.0 (spring, 400ms) — "pop" effect
3. Score ring animates: fills from 0% to final score (500ms, ease-out)
4. Check rows stagger in: each row fades + slides up 8px, 50ms apart, starting from first row
5. Total stagger: up to 1.2s for 24 rows (happens while user reads verdict, not blocking)

---

### 9.3 PASS vs FAIL Screen Entry

- **PASS:** Background briefly flashes `--color-pass-bg` for 300ms, then returns to normal.
  Confetti particle effect (subtle, 20 particles, 0.5s) — only on 100% score.
- **FAIL:** Verdict badge has a brief horizontal shake animation (translate -4px +4px -4px, 300ms).
  No color flash.
- **INCONCLUSIVE:** Gentle pulse on the question mark icon (opacity 1 → 0.6 → 1, 1s, 2 cycles).

---

### 9.4 Check Row Expand / Collapse

- Tap on row: content expands with `max-height` transition (200ms, ease-in-out)
- Arrow icon rotates 180° simultaneously
- Evidence crop image fades in (100ms delay after expansion starts)

---

### 9.5 Score Ring Fill
CSS animation target: stroke-dasharray: [circumference] stroke-dashoffset: circumference → (circumference * (1 - score))

Duration: 600ms Easing: cubic-bezier(0.34, 1.56, 0.64, 1) — slight overshoot for "snap" feel Color: animated from --color-brand-primary → final status color (≥90%: pass green, 70–89%: warn orange, <70%: fail red)

text


---

### 9.6 Sync Indicator

When offline scans are being synced:
- Sync icon in top bar rotates continuously (360°, 1s linear infinite)
- When complete: icon snaps to check position (rotation stops, scale 1 → 1.2 → 1, 300ms)
- Toast: "3 scans synced successfully"

---

### 9.7 Button States (Micro)

- **Press:** scale(0.97) + shadow drops to elev-0, 80ms
- **Release:** spring back to 1.0, 150ms
- **Loading:** Label fades out (100ms), spinner fades in (100ms)
- **Success:** spinner → checkmark, green flash, 300ms total

---

## 10. Error States & Empty States {#10-error-and-empty-states}

### 10.1 Error States

#### Camera Permission Denied
[Camera icon with X overlay — 80px]

Camera Access Required

LabelLens needs camera access to scan labels.

Your images are processed on your device and never uploaded without your permission.

[Open Settings] [Use Gallery Instead]

text


---

#### OCR Failed — No Text Detected
[Document with question mark — 80px]

No Text Found on Label

We couldn't detect readable text on this image. This can happen with: • Very reflective packaging • Unusual fonts or embossed-only text • Blurry or dark images

[Try Again] [Adjust Settings] [Manual Entry]

text


---

#### Cylindrical Reconstruction Failed
[3D shape with warning — 80px]

3D Reconstruction Incomplete

We couldn't reconstruct the full label surface. We'll proceed with the frames we have, but font-size and placement checks may be marked INCONCLUSIVE.

[Continue with partial result] [Rescan]

text


---

#### Network Error (E-Commerce Check)
[Globe with X — 80px]

Couldn't reach the listing

Check your internet connection and try again. The listing may also have: • Bot protection enabled • Changed URL structure

[Try Again] [Enter details manually]

text


---

#### Low Confidence — Full Scan
[Gauge at ~30% — 80px]

Result Confidence Too Low

Overall confidence is below 60%. The result cannot be reliably classified.

Possible reasons: • Poor lighting during capture • Damaged or obscured label • Unusual packaging material

Verdict: INCONCLUSIVE

[Rescan with better lighting] [View what we found] [Manual override — Inspector only]

text


---

### 10.2 Empty States

#### Scan History — First Use
[Scan icon — 100px, light brand color]

No Scans Yet

Start by pointing your camera at any packaged commodity label.

[📷 Start First Scan]

text


---

#### Violations Table — All Clear
[Check circle with sparkles — 100px, green]

No Open Violations

All scanned products are currently compliant. Keep monitoring to stay ahead.

[+ Add Products for Review]

text


---

#### Offline Queue — Nothing Pending
[Cloud with check — 80px]

All Synced

No pending scans. You're up to date.

text


---

## 11. Accessibility Specification (WCAG 2.1 AA) {#11-accessibility}

### 11.1 Color Contrast Requirements

| Element | Foreground | Background | Contrast Ratio | Requirement |
|---|---|---|---|---|
| Body text | #1C2230 | #FFFFFF | 16.4:1 | ✓ WCAG AA (≥4.5:1) |
| Secondary text | #495057 | #FFFFFF | 9.7:1 | ✓ WCAG AA |
| PASS badge text | #FFFFFF | #1B7A3E | 7.1:1 | ✓ WCAG AA |
| FAIL badge text | #FFFFFF | #C0392B | 5.8:1 | ✓ WCAG AA |
| WARN badge text | #FFFFFF | #E67E22 | 3.2:1 | ⚠ Fails AA (use #7B4206 for text instead) |
| Dark mode body | #F2F2F7 | #1C1C1E | 15.8:1 | ✓ WCAG AA |
| Placeholder text | #868E96 | #FFFFFF | 4.6:1 | ✓ WCAG AA (barely) |

> **WARN badge fix:** Use `#FFFFFF` text on `#C07030` (darker orange) for WARN badges.
> Or use dark text `#7B4206` on `#FEF5E7` background variant for large text contexts.

---

### 11.2 Touch Target Sizes

| Element | Minimum Size | Our Spec |
|---|---|---|
| Navigation tab | 44×44dp | 64dp height (nav bar), full width |
| Primary button | 44×44dp | 52dp height, full width on mobile |
| List row tap target | 44dp height | 72dp height |
| FAB / Shutter button | 44×44dp | 72×72dp |
| Icon button | 44×44dp | 48×48dp |
| Toggle switch | 44dp wide | 51dp wide, 31dp high |
| Expand chevron | 44×44dp | 44×44dp touch area (visual: 20px icon) |

---

### 11.3 Screen Reader Support (ARIA)
Key ARIA annotations:

Verdict badge: role="status" aria-live="polite" aria-label="Compliance result: FAIL. 6 violations found."

Score ring: role="img" aria-label="Compliance score: 18 of 28 checks passed, 64 percent"

Check row (collapsed): role="button" aria-expanded="false" aria-label="Rule 6(1)(e) violation: MRP missing inclusive of all taxes text. Tap to expand."

Check row (expanded): aria-expanded="true"

Progress bar (processing): role="progressbar" aria-valuenow="3" aria-valuemax="6" aria-valuetext="Step 3 of 6: Font size measurement"

Camera viewfinder: aria-label="Camera viewfinder. Point camera at product label. [Coaching text]"

Filter tabs: role="tablist" aria-label="Filter compliance results" Each tab: role="tab", aria-selected="true/false"

Table: role="table" aria-label="Compliance violations" Column headers: role="columnheader", aria-sort="ascending/descending/none"

text


---

### 11.4 Keyboard Navigation (Web)

| Key | Action |
|---|---|
| `Tab` | Move between interactive elements |
| `Shift+Tab` | Reverse tab order |
| `Enter` / `Space` | Activate button, expand row |
| `Arrow Up/Down` | Navigate within table rows |
| `Arrow Left/Right` | Switch between filter tabs |
| `Escape` | Close modal, bottom sheet, dropdown |
| `Ctrl+E` | Export report (shortcut, web) |
| `Ctrl+S` | Start new scan (shortcut, web) |
| `Ctrl+F` | Focus search/filter |
| `/` | Focus search (global shortcut, web) |
| `?` | Open keyboard shortcuts help modal |

**Focus ring:** Visible at all times. Uses `outline: 2px solid --color-brand-secondary`,
`outline-offset: 2px`. Never suppressed globally — only removed with explicit
`:not(:focus-visible)` for mouse-only interactions.

---

### 11.5 Font Size & Zoom

- All text in `rem` / `em` units — scales with OS/browser text size settings.
- App fully usable at 200% browser zoom (tested minimum).
- No text in fixed `px` for body content.
- Touch targets remain ≥ 44dp even at 200% zoom.

---

### 11.6 Motion / Animation

- All animations respect `prefers-reduced-motion: reduce`.
- When reduced motion is active:
  - All transitions → 100ms cross-fade only (no movement)
  - Score ring → snaps to final value (no animation)
  - Confetti → disabled
  - Shake/pulse/bounce animations → disabled

---

## 12. Offline & Low-Connectivity UX {#12-offline-ux}

### 12.1 Offline Indicator
Top bar (when offline): ┌────────────────────────────────────┐ │ LabelLens [📶 Offline] 🔔 👤 │ └────────────────────────────────────┘

text


Color: `--color-warn` orange pill badge.
Tapping "Offline" opens: Network status bottom sheet with "Sync when connected" toggle.

---

### 12.2 What Works Offline

| Feature | Offline Status | Notes |
|---|---|---|
| Camera scan | ✅ Full | On-device ML model |
| OCR | ✅ Full | On-device |
| Font size measurement | ✅ Full | On-device |
| Rule compliance check | ✅ Full | Rules DB local |
| View past scan history | ✅ Full | Local SQLite |
| PDF export | ✅ Full | Generated locally |
| Sync scan to server | ❌ Queued | Sends when reconnected |
| E-commerce listing check | ❌ Unavailable | Requires network |
| Batch upload | ❌ Unavailable | Requires network |
| Web dashboard | ❌ Unavailable | Server-rendered |
| Model update | ❌ Unavailable | Download only on Wi-Fi |

---

### 12.3 Offline Queue

When scans are made offline, they are added to an offline queue (shown in Scan History tab
and in sync status bar).
┌───────────────────────────────────────────┐ │ 📶 3 scans pending sync │ │ [━━━━━━━━━━━━━━━━━━━━━━━━━━━━━] │ │ Tap to view queue [Sync Now] │ └───────────────────────────────────────────┘

text


Sync is automatic when connectivity is restored. Manual sync available via "Sync Now" button.
On sync failure: retry with exponential backoff (5s → 30s → 5m → 30m).

---

### 12.4 2G / Slow Connection Handling

- All images lazy-loaded with skeleton placeholders.
- PDF export is local — no upload required.
- Server requests timeout at 10s with retry prompt.
- Model updates only trigger on Wi-Fi (with option to enable on cellular in Settings).
- Web dashboard degrades gracefully: tables load first, charts load last.

---

## 13. Localization & Language Handling {#13-localization}

### 13.1 Supported Languages — Phase 1

| Language | Code | Script | Target Users |
|---|---|---|---|
| English | `en-IN` | Latin | All roles |
| Hindi | `hi` | Devanagari | Field inspectors (Northern India) |

### 13.2 Supported Languages — Phase 2 (Roadmap)

Tamil (`ta`), Telugu (`te`), Kannada (`kn`), Malayalam (`ml`), Bengali (`bn`),
Marathi (`mr`), Gujarati (`gu`), Punjabi (`pa`)

---

### 13.3 Language Switching

- Available in Settings (Profile tab on mobile, Settings on web)
- Switching reloads the app (no hot-swap — too complex for initial version)
- Selected language persists across sessions

---

### 13.4 Localization Rules

- **Rule citations** remain in English regardless of UI language (they reference
  legal gazette text, which is in English).
- **Measurements** (mm, cm², etc.) remain in Arabic numerals regardless of language.
- **Date format:** `DD MMM YYYY` (e.g., `26 अग 2026` in Hindi).
- **Currency:** Always `₹` symbol (Unicode U+20B9).
- **Numbers:** Indian numbering system (lakh, crore) for analytics only;
  all measurements in standard international format.

---

### 13.5 Hindi UI — Key String Examples

| English | Hindi |
|---|---|
| Scan Label | लेबल स्कैन करें |
| PASS | उत्तीर्ण |
| FAIL | अनुत्तीर्ण |
| Violation | उल्लंघन |
| Export Report | रिपोर्ट निर्यात करें |
| Net Quantity | शुद्ध मात्रा |
| MRP | अधिकतम खुदरा मूल्य |
| Manufacturer | निर्माता |
| Compliant | अनुपालित |
| Font too small | फ़ॉन्ट बहुत छोटा है |

---

## 14. Responsive Breakpoints {#14-responsive-breakpoints}

| Breakpoint | Width | Layout | Notes |
|---|---|---|---|
| `xs` | < 360px | Single column, compressed | Old/small phones — degrade gracefully |
| `sm` | 360px–599px | Single column | Primary mobile target |
| `md` | 600px–959px | Single column + wider cards | Large phones, small tablets |
| `lg` | 960px–1279px | Sidebar collapsed (64px) + content | Tablet landscape, small laptop |
| `xl` | 1280px–1535px | Full sidebar (240px) + content | Desktop — primary web target |
| `2xl` | ≥ 1536px | Full sidebar + 2-column content | Large monitors |

### Sidebar Behavior

- `xs`–`md`: No sidebar. Bottom navigation bar (mobile).
- `lg`: Sidebar collapsed (icons only, hover to expand with tooltip).
- `xl`+: Sidebar fully expanded (icons + labels).

### Table Behavior

- `xs`–`sm`: Card view (stacked layout per row, no traditional table).
- `md`: Condensed table (hide non-critical columns: GTIN, exact scan time).
- `lg`+: Full table all columns.

---

## 15. Dev Handoff Annotations {#15-dev-handoff}

### 15.1 Tech Stack Constraints

| Layer | Recommendation | Reason |
|---|---|---|
| Mobile | Flutter | Single codebase, iOS + Android, excellent camera plugin ecosystem, good offline SQLite support |
| Web Frontend | React + TypeScript | Priya's team uses it; large ecosystem; Recharts for analytics |
| Design tokens | CSS custom properties (web) + Flutter ThemeData (mobile) | Single source of truth |
| Icons | Phosphor Icons | Available as Flutter + React packages |
| Charts | Recharts (web) | MIT license, composable |
| PDF generation | pdf (Flutter) / jsPDF (web) | On-device generation |
| Camera | camera (Flutter plugin) + custom viewfinder overlay | |
| OCR | On-device: TesseractOCR or custom model via TFLite | No cloud dependency |
| Offline DB | SQLite via sqflite (Flutter) | |
| State management | Riverpod (Flutter) / Zustand (React) | |

---

### 15.2 Critical Implementation Notes for Developers

#### Note 1: Camera Guide Rectangle
The scan guide rectangle must NOT be a static overlay. It should use the camera feed's
edge detection output to dynamically adjust its position + size to match the detected
package boundary. Use a `CustomPainter` (Flutter) or Canvas API (web) for this.

#### Note 2: Score Ring
Use SVG `circle` with `stroke-dasharray` + `stroke-dashoffset` for the ring.
Do NOT use a third-party chart library for this — the animation needs precise control.

#### Note 3: Bounding Box Overlay on Image Viewer
All bounding boxes are defined in **normalized coordinates** (0–1 for both x and y),
computed relative to the original image dimensions. The viewer must re-project these
to screen coordinates accounting for zoom, pan, and device pixel ratio. Use a
transformation matrix — do not hardcode pixel values.

#### Note 4: PDF Export
Must be generated entirely on-device/locally. No server call.
PDF must embed:
- Full annotated image (all bounding boxes rendered)
- All check results
- Rule citations in monospace font
- Inspector ID + timestamp + GPS coordinates
- Digital signature field (empty — inspector fills manually)

#### Note 5: Confidence Thresholds
Thresholds (default: FAIL/PASS ≥ 75%, WARN ≥ 60%) must be stored in user settings,
not hardcoded. A legal metrology officer may need to lower the threshold in field
conditions. Changes to thresholds are logged in the audit trail.

#### Note 6: Dark Mode
System dark mode preference (`prefers-color-scheme: dark`) should be respected by default.
User override available in Settings. Dark mode token set (see Section 3.1.4) must
be fully implemented — do not use any `!important` hacks.

#### Note 7: Haptic Feedback (Mobile)
- Auto-capture triggered: medium impact haptic
- PASS verdict: success haptic (double tap pattern)
- FAIL verdict: error haptic (long vibration)
- Button tap: light impact
- Toggle switch: selection haptic

#### Note 8: Accessibility — Dynamic Type
On iOS: `UIFont.preferredFont(forTextStyle:)` for all text styles.
On Android: `sp` units only (not `dp`) for all text sizes.
This ensures OS-level text size settings are respected.

---

### 15.3 Component File Structure (Frontend)
src/ ├── design-system/ │ ├── tokens/ │ │ ├── colors.ts │ │ ├── typography.ts │ │ ├── spacing.ts │ │ ├── shadows.ts │ │ └── motion.ts │ └── components/ │ ├── VerdictBadge/ │ ├── CheckRow/ │ ├── ComplianceScoreRing/ │ ├── AnnotatedImageViewer/ │ ├── RuleReferencePanel/ │ ├── ConfidenceIndicator/ │ ├── ScanProgressStepper/ │ ├── Button/ │ ├── BottomSheet/ │ └── Toast/ ├── features/ │ ├── scan/ │ │ ├── CameraViewfinder/ │ │ ├── PackageTypeSelector/ │ │ ├── ProcessingScreen/ │ │ └── VerdictScreen/ │ ├── history/ │ ├── ecommerce/ │ ├── dashboard/ │ ├── reports/ │ └── settings/ └── pages/ ├── mobile/ (Flutter) └── web/ (React)

text


---

### 15.4 QA Checklist — Before Design Handoff Sign-off

- [ ] All colors verified for WCAG 2.1 AA contrast (see Section 11.1)
- [ ] All touch targets ≥ 44×44dp (see Section 11.2)
- [ ] Dark mode tested for all screens
- [ ] Hindi UI tested — no truncation on any label
- [ ] Reduced motion tested — no layout shift
- [ ] Offline scenario tested end-to-end (airplane mode)
- [ ] Camera denied state tested
- [ ] Low confidence (< 60%) verdict path tested
- [ ] PDF export tested on both iOS and Android
- [ ] Screen reader (TalkBack/VoiceOver) walkthrough completed
- [ ] Keyboard navigation (web) tested with Tab/Enter only
- [ ] 200% browser zoom tested (web)
- [ ] 360px width tested (xs breakpoint)
- [ ] 2560px width tested (2xl breakpoint)
- [ ] Stagger animation doesn't block initial viewport render
- [ ] Score ring animation disabled with prefers-reduced-motion

---

*End of UI/UX Specification Document*

---
Document metadata: File: UIUX_SPEC.md Version: 1.0.0 Project: LabelLens — LMPC Compliance Verification Date: August 2026 Author: [Your Team Name] Status: Ready for design review Companion files: PRD.md — Product requirements SRS.md — Software requirements LMPC_RULES.md — Complete regulatory reference