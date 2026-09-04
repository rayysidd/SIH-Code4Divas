# 📋 LMPC Rules Reference: Complete Regulatory Bible for CV-Based Label Compliance
## Legal Metrology (Packaged Commodities) Rules, 2011 — Consolidated Through All Amendments
### For SIH Problem Statement: Automated Label Compliance Verification System

---

> **Document Purpose:** Single-source reference for every rule, sub-rule, clause, proviso, and
> amendment relevant to automated label compliance checking under Indian Legal Metrology law.
> No rule omitted. Covers base rules (GSR 202(E), 07 March 2011) + all amendments through 2023.
> Organized by rule number. Each entry includes: rule text → what it means → what your CV system must check.

---

## 🗂️ TABLE OF CONTENTS

| Section | Content |
|---|---|
| [Part 0](#part-0) | Parent Act + Gazette Notification Index |
| [Part 1](#part-1) | Rule 2 — Definitions (CV-Relevant Terms Only) |
| [Part 2](#part-2) | Rule 3 — Application & Scope |
| [Part 3](#part-3) | Rule 4 — General Requirements for Pre-Packaged Commodities |
| [Part 4](#part-4) | Rule 5 — Standard Quantities (Scheduled Commodities) |
| [Part 5](#part-5) | Rule 6 — **Mandatory Declarations on Every Package** ⭐ CORE |
| [Part 6](#part-6) | Rule 7 — **Principal Display Panel: Area, Font Size, Placement** ⭐ CORE |
| [Part 7](#part-7) | Rule 8 — **Manner of Declarations: Placement Geometry** ⭐ CORE |
| [Part 8](#part-8) | Rule 9 — Declaration of Name & Address |
| [Part 9](#part-9) | Rule 10 — Declaration of Net Quantity |
| [Part 10](#part-10) | Rule 11 — Exemptions |
| [Part 11](#part-11) | Rule 12 — Import Packages |
| [Part 12](#part-12) | Rule 13 — Wholesale Packages |
| [Part 13](#part-13) | Rule 14–25 — Quantity Tolerances & Verification |
| [Part 14](#part-14) | Rule 26 — E-Commerce Obligations |
| [Part 15](#part-15) | Rule 27–33 — Enforcement, Penalties, Relaxations |
| [Part 16](#part-16) | Schedules: Tables I–IV (Font Size Lookup Tables) |
| [Part 17](#part-17) | Amendment Tracker (Chronological) |
| [Part 18](#part-18) | CV System Check Master Table |

---

## PART 0 — Parent Act + Gazette Notification Index {#part-0}

### 0.1 Parent Legislation
- **Legal Metrology Act, 2009** (Act No. 1 of 2010) — the enabling statute.
- The LMPC Rules are subordinate legislation under **Section 52(1) and 52(2)** of the Act.
- Enforcement powers vest in **Legal Metrology Officers, Controllers, and the Director** of Legal Metrology.

### 0.2 Primary Gazette Notifications (All Must Be Read Together)

| Notification | Date | Key Change |
|---|---|---|
| **GSR 202(E)** | 07 March 2011 | Base rules enacted |
| **GSR 784(E)** | 24 October 2011 | Minor amendments to Rule 26(a) |
| **GSR 385(E)** | 14 May 2015 | Definitions of "institutional consumer" and "industrial consumer" revised; effective 01 Jan 2016 |
| **GSR 629(E)** | 23 June 2017 | **Major amendment** — font sizes, PDP area, e-commerce, country of origin, consumer care details; effective 01 Jan 2018 |
| **GSR (Amendment Rules 2021)** | 02 November 2021 | Unit Sale Price introduced; e-commerce Rule 6(11) extended |
| **GSR 226(E)** | 28 March 2022 | Unit Sale Price format finalized; effective 01 Oct 2022 |
| **GSR (Amendment Rules 2022 — 2nd)** | 30 September 2022 | Further USP and e-commerce clarifications |
| **GSR (Amendment Rules 2023)** | 06 October 2023 | Multi-piece/combo exemptions; MFG date for electronics; edible oil dual declaration; effective 01 Jan 2024 |
| **Draft Amendment 2025** | February 2025 | Medical devices — Rules 2, 7, 33 modified (not yet in force as of August 2026 — verify gazette) |

> ⚠️ **CV System Note:** Your rules engine must be versioned. A package manufactured before Jan 2018
> is not required to comply with GSR 629(E). Timestamp of manufacture matters for enforcement tier.

---

## PART 1 — Rule 2: Definitions (CV-Relevant) {#part-1}

> Rule 2 defines all terms used in the Rules. Only definitions that directly affect what your CV system
> must detect or measure are included here.

---

### Rule 2(b) — "Commodity"
**Text:** Any article, material, or thing which may be bought or sold; includes all goods.

**CV Impact:** Determines whether the LMPC Rules apply at all. Your system should flag if the scanned item is an exempted category (see Rule 11).

---

### Rule 2(d) — "Consumer" *(as amended by GSR 629(E))*
**Text:** "Consumer" shall have the same meaning as assigned to it in clause (d) of sub-section (1) of Section 2 of the Consumer Protection Act.

**CV Impact:** Differentiates retail sale from wholesale/institutional sale. Different rules apply. If a package is labeled "NOT FOR RETAIL SALE" your system should route it to the wholesale ruleset (Rule 13).

---

### Rule 2(f) — "Declaration"
**Text:** Any written, printed, or graphic matter on or accompanying any package.

**CV Impact:** Your OCR scope is not limited to printed text — it includes embossed, molded, blown, and perforated text. Your CV system must handle all these rendering modes (they also have different font-size minimums — see Rule 7).

---

### Rule 2(g) — "General Package"
**Text:** A pre-packaged commodity not falling under the definition of a "retail package" or "wholesale package."

**CV Impact:** Edge case. Route to appropriate ruleset.

---

### Rule 2(i) — "Institutional Consumer"
**Text (as amended GSR 385(E)/2015):** Means a consumer who buys packaged commodities directly from the manufacturer or importer or wholesale dealer for use by that industry. The package size or quantity must be greater than the normal retail size.

**CV Impact:** Institutional packages are partially exempt from some declaration requirements (e.g., MRP need not appear). Your system must detect if a package is labeled "For Institutional Use Only" and apply reduced rule set.

---

### Rule 2(j) — "Label" / "Labeling"
**Text:** Any written, printed, or graphic matter on the package or on any tag, card, sticker affixed to or accompanying the package.

**CV Impact:** Labels can be **affixed stickers**, not just printed text. Your CV must detect both integrated print and physically separate stickers as valid label surfaces. This also means an MRP sticker placed over the original price is a valid label update (see Rule 6(1)(f) proviso on MRP revision stickers).

---

### Rule 2(k) — "Manufacturer"
**Text:** Person by whom or under whose direction the packaged commodity was manufactured, processed, or assembled.

**CV Impact:** Your system must locate and classify the manufacturer name+address field as a distinct declaration type. If "Marketed by" or "Brand Owner" appears, that is also legally sufficient per the Sept 2025 FAQ.

---

### Rule 2(l) — "Net Quantity"
**Text:** The quantity of the commodity contained in the package, excluding the weight of the packaging material.

**CV Impact:** Net quantity is distinct from gross weight. Your classifier must distinguish "Net Wt," "Net Vol," "Net Content," "Net Qty" from gross weight declarations. Any gross weight figure must not be confused as net quantity.

---

### Rule 2(m) — "Pre-Packaged Commodity" / "Retail Package"
**Text:** A commodity which, without the purchaser being present, is placed in a package of whatever nature, whether sealed or not, in such a manner that the product contained therein has a pre-determined quantity.

**CV Impact:** This is your scope boundary. Only pre-packaged commodities (pre-measured before sale) fall under LMPC Rules.

---

### Rule 2(n) — "Principal Display Panel (PDP)"
**Text:** The part of a package that is most likely to be displayed, presented, shown, or examined by the customer at the time of purchase.

**CV Impact:** **Critical for your system.** The PDP is the primary surface for mandatory declarations. Your CV must identify and segment the PDP from the full package surface. See Rule 7 for geometric definition of PDP area by package shape.

---

### Rule 2(o) — "Retail Package"
**Text:** A package intended for retail sale to the ultimate consumer.

**CV Impact:** Standard target for full Rule 6 compliance. As opposed to wholesale packages (Rule 13) or institutional packages.

---

### Rule 2(p) — "Wholesale Package"
**Text:** A package containing a number of retail packages intended not for retail but for wholesale distribution.

**CV Impact:** Must show "For Wholesale/Retail Only" and the number of retail packages inside. Different from Rule 6 full-declaration requirement. Your system must classify package type first.

---

### Rule 2(q) — "Unit Sale Price" *(added by 2021/2022 Amendment)*
**Text:** The price per unit of measurement of the commodity (per gram, per kg, per ml, per litre, per cm, per metre, per number/unit), inclusive of all taxes, rounded to two decimal places.

**CV Impact:** A new mandatory field since October 2022. Your OCR must search for this field separately from MRP. See Rule 6(11) for full specification.

---

## PART 2 — Rule 3: Application & Scope {#part-2}

### Rule 3(1) — Applicability
**Text:** These rules apply to every commodity which is packed and intended for retail sale.

**CV Impact:** Your system is scoped to retail packages. Commercial/industrial/wholesale packages follow reduced rule sets.

---

### Rule 3(2) — Overriding Legislation
**Text:** Where any other Central Act or Rules made thereunder make specific provision for any of the matters covered under these Rules, the provisions of that other Act/Rules shall prevail.

**CV Impact (important):**
- **Food products** → **FSSAI (Food Safety and Standards Act, 2006)** rules prevail over LMPC for labeling of food articles. LMPC still governs **net quantity and MRP** even for food.
- **Drugs/Pharmaceuticals** → **Drugs & Cosmetics Act** + **DPCO 2013** prevail.
- **Alcoholic beverages** → State Excise Laws prevail for MRP within that state.
- **Medical Devices** → Medical Devices Rules, 2017 (and pending 2025 LMPC amendment).

> ⚠️ **Your CV system must have a product-category classifier BEFORE applying rules.** A packet of chips and a bottle of syrup follow different compliance paths.

---

## PART 3 — Rule 4: General Conditions for Pre-Packaged Commodities {#part-3}

### Rule 4(1) — No False or Misleading Statements
**Text:** No pre-packaged commodity shall contain any declaration which is false or misleading in any particular.

**CV Impact:** While hard to fully automate, your system can flag:
- MRP format inconsistencies (e.g., "was ₹199, now ₹149" — only the current MRP should be the declared one).
- Struck-through prices next to MRP — the struck-through price must not be a false reference price.
- Visual prominence of a promotional price exceeding the declared MRP visually.

---

### Rule 4(2) — No Exaggeration of Net Quantity
**Text:** No package shall have any declaration of the quantity of a commodity contained therein which is in excess of the actual content or is likely to mislead the purchaser regarding the actual content.

**CV Impact:** Your system cannot verify actual physical content from a photo, but can flag mismatched units (e.g., "1 kg" on a visually tiny package — heuristic anomaly detection, not a hard rule).

---

## PART 4 — Rule 5: Standard Quantities {#part-4}

### Rule 5 — Commodities to be Packed in Specified Quantities
**Text:** Certain commodities (listed in the **Second Schedule**) must be packed only in specified standard quantities.

> ⚠️ **Amendment Note:** The **Second Schedule was omitted by the 2022 Amendment Rules (GSR 226(E), effective 01 Oct 2022).** Standard quantity restrictions for most commodities have been removed. Manufacturers may now freely choose package sizes.

**CV Impact:** Pre-October 2022 packages may still be expected to conform. For post-2022 packages, no quantity-tier validation needed for the schedule.

---

## PART 5 — Rule 6: Mandatory Declarations on Every Package ⭐ {#part-5}

> **This is the single most important rule for your system. Every sub-clause is a checkable field.**

---

### Rule 6(1) — The Ten Mandatory Declarations

Every retail package must carry ALL of the following. Each is a distinct CV detection target:

---

#### Rule 6(1)(a) — Name and Address of Manufacturer / Packer / Importer

**Text:** The name and address of the manufacturer, packer, or, in the case of imported packages, the importer. If the commodity is manufactured by one party and marketed by another under their brand, the brand owner's name and address (with the words "Marketed by" or "Brand Owner") is sufficient.

**Format Required:**
- Name (individual or company)
- Full postal address including PIN code
- For manufacturers: "Manufactured by" or "Mfd. by"
- For packers: "Packed by" or "Pkd. by"
- For importers: "Imported by"
- For brand owners: "Marketed by" / "Brand Owner"

**Exceptions (Explanation II):**
- If brand name and address of brand owner appear on the label as a marketer → brand owner is legally responsible for violations.
- Food articles → Food Safety and Standards Act provisions apply instead (Rule 3(2) override).

**CV Checks:**
- [ ] Field present on PDP
- [ ] Contains at least one of: "Mfd. by" / "Packed by" / "Imported by" / "Marketed by" / "Brand Owner"
- [ ] PIN code present in address (6 digits)
- [ ] For imported goods: importer name + Indian address present
- [ ] Detect the phrase "Country of Origin" separately (see Rule 6(1)(g) below)

---

#### Rule 6(1)(b) — Common or Generic Name of Commodity

**Text:** The common or generic name of the commodity contained in the package.

**Format Required:** Plain language name of the product (e.g., "Refined Sunflower Oil," "Whole Wheat Biscuits"). Brand names alone are not sufficient.

**Exceptions:**
- Food articles → FSSAI rules govern product name declaration.

**CV Checks:**
- [ ] Product name / generic name field present
- [ ] Not just a brand name (brand name alone is insufficient as generic name)
- [ ] Classifier: distinguish brand name token vs. generic name token using layout position (generic name usually directly below brand name or prominently on PDP)

---

#### Rule 6(1)(c) — Net Quantity

**Text:** The net quantity of the commodity in terms of standard unit of weights and measures (metric system). For commodities sold by number, the number of units must be declared.

**Format Required:**
- Weight: grams (g) or kilograms (kg)
- Volume: millilitres (ml) or litres (L)
- Length: centimetres (cm) or metres (m)
- Area: cm² or m²
- Number: count/units/pieces/tablets etc.

**Numerals must conform to font-size minimums in Tables I and II of Rule 7 / Schedule.**

**Units:**
- Use only SI/metric units.
- Dual declaration: for edible oils, vanaspati ghee, and butter oil *(amended 2023)*: if declared by volume, **must also declare by weight**.

**Exceptions:**
- Packages less than 10g or 10ml are exempt from net quantity declaration *(proviso to Rule 6, as amended by GSR 784(E) 2011 and GSR 385(E) 2015 — tobacco products are NOT exempt)*.

**CV Checks:**
- [ ] Net quantity present
- [ ] Uses metric units (g, kg, ml, L, m, cm)
- [ ] Numeral is present and extractable
- [ ] Unit follows immediately after numeral (e.g., "500 g" or "500g")
- [ ] Font size of numeral meets Table I or Table II threshold (computed from PDP area — see Rule 7)
- [ ] For edible oils: both weight AND volume present if declared by volume
- [ ] No non-standard units (lb, oz, fl oz) used as primary declaration
- [ ] "Net Wt" / "Net Vol" / "Net Qty" / "Net Content" prefix or equivalent

---

#### Rule 6(1)(d) — Month and Year of Manufacture / Packing

**Text:** The month and year in which the commodity is manufactured or pre-packed.

**Format Required:**
- "Mfg. Date" / "Mfd." / "Manufactured" followed by month and year
- Month can be abbreviated (Jan, Feb… or 01, 02…)
- Year: 4-digit or 2-digit (4-digit preferred)
- Format examples: "Mfg: Jan 2024", "Mfg. 01/2024", "MFD: 2024-01"

**Exceptions (as amended by 2023 Amendment, effective 01 April 2024):**
- Spare parts and accessories used for servicing with warranty and NOT sold to end customers → exempt from MFG date declaration.
- Electronic products, spare parts, and accessories → MFG month and year may be declared **anywhere on the retail package** (not necessarily PDP), provided it is **visible and legible**.

**CV Checks:**
- [ ] MFG date field present
- [ ] Month identifier present (text or number 01–12)
- [ ] Year present (4 digits preferred)
- [ ] If product is electronic: MFG date may be off-PDP — scan full package surface
- [ ] Date format parsed to confirm it is a valid date (e.g., "13/2024" is invalid — no 13th month)

---

#### Rule 6(1)(e) — Maximum Retail Price (MRP)

**Text:** The maximum retail price at which the commodity in packaged form may be sold to the ultimate consumer inclusive of all taxes.

**Format Required:**
- Prefix: "Maximum Retail Price" or "MRP" or "Max. Retail Price"
- Currency symbol: "₹" or "Rs." (both accepted per Sept 2025 FAQ)
- Price: numeric, with two decimal places (e.g., ₹45.00)
- Suffix: "(Inclusive of all taxes)" or "(Incl. of all taxes)" or equivalent
- May also appear as: "MRP (Incl. of all taxes): ₹45.00"

**Important Provisos:**
- Where GST rate changes (e.g., post-GST Council meeting Sept 2025), a sticker or stamp showing revised MRP over old MRP is permitted **temporarily** — but the original MRP must remain visible.
- Multiple MRPs may appear for different regions/states — all are valid if the highest applicable one is charged.
- A struck-through "was ₹199" is not the MRP — only the final declared price is the MRP.

**CV Checks:**
- [ ] "MRP" or "Maximum Retail Price" text present
- [ ] "₹" or "Rs." symbol present
- [ ] Numeric price value present
- [ ] "(Inclusive of all taxes)" or abbreviated equivalent present
- [ ] Two decimal places in price value
- [ ] If MRP sticker present: original price still visible underneath (not fully obscured)
- [ ] Classifier: distinguish promotional struck-through price from MRP declaration
- [ ] Font size of MRP numeral meets font-size minimums (same Table I/II threshold)

---

#### Rule 6(1)(f) — Best Before / Expiry Date (Where Applicable)

**Text:** In the case of commodities which are likely to deteriorate or are of short shelf life, the date or month and year up to which the commodity is best for consumption or use ("best before" or "use by" date).

**Format Required:**
- "Best Before" / "BB" / "Expiry" / "Use By" / "Best Before End" / "BBE"
- Month and year minimum; day + month + year preferred for short shelf-life products

**Applicability:** Not all products require this. Products with indefinite shelf life (many non-food items) are exempt. However:
- Any food product with a shelf life under 3 months → date mandatory under FSSAI too.
- Cosmetics → expiry date required.
- Drugs → expiry mandatory under Drugs & Cosmetics Act.

**CV Checks:**
- [ ] Detect "Best Before" / "Exp." / "Use By" token presence
- [ ] Parse associated date — is it a valid future date? (past expiry is an enforcement trigger, not technically a label format violation, but worth flagging)
- [ ] Date format parseable (DD/MM/YY, MM/YYYY, etc.)

---

#### Rule 6(1)(g) — Country of Origin *(added by GSR 629(E) 2017)*

**Text:** In the case of imported packages, the country of origin or manufacture or assembly must be declared. For goods manufactured in India, the full address of the manufacturing location with PIN code covers this implicitly.

**Format Required:**
- "Country of Origin: [Country Name]" or "Made in [Country]" or "Product of [Country]"
- For assembled products: "Assembled in [Country]" with origin of major components if mandated by separate rules (e.g., Electronics sector)

**CV Checks:**
- [ ] For imported goods: "Country of Origin" or "Made in" text present
- [ ] Country name follows the field label
- [ ] If "Made in India": already covered by manufacturer address (Rule 6(1)(a)) — no separate field needed

---

#### Rule 6(1)(h) — Customer Care Details *(added by GSR 629(E) 2017)*

**Text:** Name, address, and telephone number / email of the customer care officer / complaint redressal officer, or a toll-free number.

**Format Required:**
- At minimum: one contact detail (phone or email or address)
- Toll-free number is fully compliant
- Must be associated with "Consumer Care" / "Customer Care" / "Helpline" / "Grievance" label

**CV Checks:**
- [ ] Customer care phone number or email present
- [ ] Prefixed with "Consumer Care" / "Helpline" / "Customer Care" or equivalent
- [ ] Phone number: 10-digit Indian format or toll-free format (1800-xxx-xxxx)
- [ ] Email: valid email format (regex: presence of @, domain)

---

#### Rule 6(1)(i) — Month and Year of Expiry for Certain Categories

*(Separate from Rule 6(1)(f) for certain regulated categories — drugs, cosmetics, foods — governed primarily by their own Acts but worth checking for completeness.)*

**CV Checks:**
- [ ] For products where expiry is mandatory: confirm expiry date field present and parseable.

---

#### Rule 6(1)(j) — Veg / Non-Veg Symbol (for Food, Cosmetics, Soaps)

**Text (via FSSAI for food, and FSS Regulations):** Green dot (solid green circle inside a green square) = Vegetarian. Red/brown dot (solid red/brown circle inside a red/brown square) = Non-Vegetarian.

> **Note:** For **soaps and cosmetics**, LMPC incorporates the veg/non-veg dot requirement for animal-derived ingredients. This is **color-based detection, not OCR.**

**CV Checks:**
- [ ] Detect presence of colored dot-in-square symbol on PDP
- [ ] Classify color: green (veg) vs. red/brown (non-veg)
- [ ] Symbol must be on PDP (not hidden on back)
- [ ] This is a computer vision detection task, not a text extraction task

---

### Rule 6(2) — Declarations Must Be in English or Hindi

**Text:** All declarations required under Rule 6(1) shall be in English or Hindi. Regional language declarations may be added additionally.

**CV Checks:**
- [ ] Detect language of each declaration field
- [ ] At least one of {English, Hindi (Devanagari)} present for each mandatory field
- [ ] Mixed-language labels (English + regional) are valid — do not flag as violation

---

### Rule 6(3) — Declarations Must Be Legible and Prominent

**Text:** All declarations shall be in a legible and prominent manner, with good contrast against the background.

**CV Checks:**
- [ ] OCR confidence score as a legibility proxy (low confidence = legibility concern)
- [ ] Contrast ratio check: text color vs. background color (WCAG contrast ratio ≥ 3:1 as a heuristic minimum — the rule has no exact number, but "legible" is the standard)

---

### Rule 6(5) — Multi-Piece Package / Combination Package / Group Package

**Text:**
- **Multi-Piece Package:** Two or more individual labeled pieces of the same commodity with identical quantity, sold individually or as a whole. *(Definition added 2023)*
- **Combination Package:** Package containing different commodities (e.g., gift set with shampoo + conditioner).
- **Group Package:** Package containing multiple units of one commodity sold together.

**Declaration Rules:**
- Multi-piece: outer package must declare total quantity + number of pieces + individual piece quantity.
- Combination: each inner product's declarations are sufficient if visible; outer package should declare contents list.
- Group: outer package declares total quantity.

**CV Checks:**
- [ ] If "Contains X pieces of Y g each" type declaration present — parse count and per-unit quantity
- [ ] Validate: count × per-unit quantity = total declared quantity
- [ ] Identify if this is a multi-piece / combo / group scenario and apply reduced USP rule (Rule 6(11) exemption)

---

### Rule 6(6) — Imported Packages

**Text:** In the case of imported packages, the importer shall be responsible for ensuring compliance. The country of origin must appear in addition to all other mandatory declarations.

**CV Checks:**
- [ ] "Imported by" + importer name + Indian address present
- [ ] "Country of Origin" present
- [ ] All other Rule 6(1) declarations present (same as domestic)

---

### Rule 6(7) — Wholesale Packages

**Text:** A wholesale package must declare:
- "This package is not meant for retail sale"
- The number of retail packages inside
- The net quantity or number per retail package

**CV Checks:**
- [ ] "Not for retail sale" or "Wholesale only" text present
- [ ] Number of retail units inside declared
- [ ] Per-unit quantity declared

---

### Rule 6(8) — Transport Packages / Shipping Cartons

**Text:** Transport or shipper cartons must be marked "Wholesale Package" or "Transportation Only" and are not subject to full Rule 6(1) requirements.

**CV Checks:**
- [ ] "Transportation Only" or "Wholesale Package" or "Shipper Carton" text
- [ ] Route to wholesale/transport ruleset; suppress retail Rule 6(1) checks

---

### Rule 6(10) — E-Commerce Seller Obligations *(GSR 629(E), 2017)*

**Text:** Every e-commerce entity which sells commodities online shall ensure that the declarations required under Rule 6(1) are made available to the consumer on the product page / listing before the consumer decides to purchase.

**Specifics:**
- All Rule 6(1) declarations must appear on the product listing page
- This is enforceable — non-compliance = selling non-standard packages (penalty under Legal Metrology Act Section 18)
- The CCPA has been actively enforcing this (₹10 lakh fines to Amazon, Flipkart, Meesho, Meta; BIS raids on 22 warehouses for 16,970+ non-compliant listings — Feb 2026)

**Declarations Required on E-Commerce Listing (same as physical label):**
1. Manufacturer / packer name and address
2. Country of origin
3. Net quantity
4. MRP (inclusive of all taxes)
5. Customer care details
6. Best before date (if applicable)
7. Common/generic name
8. Month and year of manufacture

**CV / NLP Checks (Web scraping / listing analysis):**
- [ ] All 8 fields above present on listing page
- [ ] MRP on listing = MRP on physical label (cross-channel reconciliation — **your unique differentiator**)
- [ ] Net quantity on listing = net quantity on physical label
- [ ] Country of origin present on listing
- [ ] Manufacturer address on listing

---

### Rule 6(11) — Unit Sale Price (USP) *(Introduced 2021, finalized 2022, amended 2023)*

**Text (as substituted by GSR 226(E), 28 March 2022, effective 01 Oct 2022):**

> "The unit sale price in rupees, rounded off to the nearest two decimal places, shall be declared on every pre-packaged commodity as follows:
> - per gram (g) where net quantity < 1 kg; per kilogram (kg) where net quantity ≥ 1 kg
> - per centimetre (cm) where net length < 1 m; per metre (m) where net length ≥ 1 m
> - per millilitre (ml) where net volume < 1 litre; per litre (L) where net volume ≥ 1 litre
> - per number or unit if sold by count"

**Exceptions (all added by 2022–2023 amendments):**
1. **USP not required** when USP = MRP (i.e., single-unit product where price per unit is the same as total price)
2. **USP not required** for Combination Packages *(2023)*
3. **USP not required** for Group Packages *(2023)*
4. **USP not required** for Multi-Piece Packages *(2023)*
5. **USP not required** on e-commerce listings (only on physical label) — per FAQ clarification
6. **USP not required** in advertisements

**Format Required:**
- "₹ X.XX per g" or "₹ X.XX / kg" etc.
- Must be rounded to 2 decimal places

**CV Checks:**
- [ ] USP field present on label (post Oct 2022 products)
- [ ] USP expressed per correct unit (g vs. kg, ml vs. L based on net quantity size)
- [ ] USP value rounded to 2 decimal places
- [ ] Verify: USP = MRP ÷ net quantity (within rounding tolerance)
- [ ] If combo/multi-piece package: USP absence is valid — do not flag
- [ ] If USP = MRP: USP absence is valid — do not flag

---

## PART 6 — Rule 7: Principal Display Panel (PDP) — Area, Font Size, Placement ⭐ {#part-6}

> **This is the most technically complex rule and the one that most teams will get wrong.**
> Font size compliance cannot be checked from a flat photo without real-world scale.
> Your system must compute PDP area in cm² from real-world dimensions, then look up the font-size threshold.

---

### Rule 7(1) — Definition of Principal Display Panel

**Text:** The principal display panel means that part of a package that is most likely to be displayed, presented, shown, or examined by the customer at the time of purchase.

**This is a qualitative definition** — in practice, it is the front face of the package.

---

### Rule 7(2) — How to Compute PDP Area

The area of the Principal Display Panel depends on the **shape of the package**:

#### Rule 7(2)(a) — Rectangular Package
**Text:** PDP area = area of one entire side (Length × Width) of the package.

**For compliance:** The manufacturer MUST use one full side as PDP — they cannot carve out a smaller region.

**CV System:**
- Detect package as rectangular
- Measure the physical dimensions of the face presented to the camera (requires reference object or stereo/depth data for real-world scale)
- PDP area = L × W in cm²

---

#### Rule 7(2)(b) — Cylindrical / Pipe-Shaped Package *(Critical — Rule 7(4)(b))*

**Text:** PDP area = **40% × (Height × Circumference)** of the cylindrical surface.

> ⚠️ **This is the hardest sub-rule in the entire document for a CV system.**
> A flat single-image capture of a cylindrical package CANNOT give you the circumference.
> You need: multi-view capture OR depth/stereo OR physical measurement.

**Formula:** PDP = 0.40 × H × (π × D), where D = diameter of cylinder

**Important exclusions from PDP area calculation:**
- Top and bottom caps of the cylinder
- Flanges at top and bottom of cans
- Shoulder and neck of bottles and jars

**CV System:**
- Detect cylindrical package shape
- Use multi-frame / turntable video + 3D reconstruction to recover full circumference
- Alternatively: if diameter of bottle mouth or known barcode width is available, estimate diameter
- Compute PDP = 0.40 × H × (π × D) in cm²
- Flag as "insufficient data for font-size compliance check" if circumference cannot be recovered

---

#### Rule 7(2)(c) — Any Other Shape
**Text:** PDP area = **40% of total surface area** of the package, or the area designated by the manufacturer as the principal display panel.

**CV System:**
- Detect non-rectangular, non-cylindrical package
- Estimate total surface area (may require 3D reconstruction or model-fitting)
- Apply 40% rule

---

### Rule 7(3) — Minimum Height of ALL Declarations (Letters, Not Just Numerals)

**Text:** The height of any letter used in any declaration on a package shall not be less than **1 mm**.

If the declaration is **embossed, perforated, molded, blown, or formed**, the minimum letter height is **2 mm**.

> This is the baseline floor for ALL text on the package — not just MRP/net quantity numerals.

**CV Checks:**
- [ ] Measure average letter height in mm for each detected text region
- [ ] All text ≥ 1 mm (printed) or ≥ 2 mm (embossed/molded)
- [ ] Flag any declaration text block where measured font height < threshold

---

### Rule 7(4) — Minimum Height of NUMERALS in Net Quantity / MRP Declarations

**Text:** The height of numerals used in declarations of net quantity and retail sale price shall not be less than the heights specified in **Table I** (for weight/volume) or **Table II** (for length/area/number), based on the PDP area.

> **This is the tiered font-size table that is the central check of your problem statement.**

---

#### TABLE I — Net Quantity Declared by Weight or Volume

*Governs: net weight, net volume, MRP numerals*

| PDP Area (A) in cm² | Min Height of Numerals — Printed/Normal (mm) | Min Height — Embossed / Molded / Blown (mm) |
|---|---|---|
| A < 50 cm² | **1.0 mm** | **1.5 mm** *(verify against gazette — some sources cite 2.0 mm for this cell)* |
| 50 ≤ A < 100 cm² | **1.5 mm** | **3.0 mm** |
| 100 ≤ A < 500 cm² | **2.5 mm** | **4.0 mm** |
| 500 ≤ A < 2500 cm² | **4.0 mm** | **6.0 mm** |
| A ≥ 2500 cm² | **6.0 mm** | **6.0 mm** |

> ⚠️ **Caution:** The cell for A < 50 cm² embossed/molded has conflicting values in secondary sources
> (1.5mm vs. 2.0mm). Always verify against the original gazette GSR 629(E) before hardcoding.

---

#### TABLE II — Net Quantity Declared by Length, Area, or Number

*Governs: number of units, length in metres/cm, area in cm²/m²*

| PDP Area (A) in cm² | Min Height of Numerals (mm) |
|---|---|
| A < 100 cm² | **1.0 mm** |
| 100 ≤ A < 500 cm² | **2.0 mm** |
| 500 ≤ A < 2500 cm² | **4.0 mm** |
| A ≥ 2500 cm² | **6.0 mm** |

> Note: Table II does not have a separate column for embossed/molded — the general Rule 7(3) minimum of 2mm for embossed applies as a floor.

---

### Rule 7(5) — Font Size Is a Minimum, Not a Maximum

**Text (confirmed by Sept 2025 FAQ):** Font sizes prescribed under Rule 7 are **minimum requirements**. Larger font sizes are always permissible.

**CV Check:** Only flag violations where measured size < minimum. Larger fonts are compliant.

---

### Rule 7(6) — Declarations May Be Grouped or Split

**Text (confirmed by Sept 2025 FAQ):** Declarations on the principal display panel can either be grouped together in one place OR split between pre-printed areas and separate sticker/label areas — both are valid.

**CV Check:** Do not require all declarations to appear in a single block. Scan full PDP for each declaration independently.

---

## PART 7 — Rule 8: Manner of Declaration — Placement Geometry ⭐ {#part-7}

> **This is the second most technically difficult rule, and one that virtually no team will implement.**
> It defines spatial/geometric constraints on where and how the net quantity declaration must appear.

---

### Rule 8(1) — Clear Space Around Net Quantity Declaration

**Text:** The declaration of net quantity shall be:
- Placed in the **lower 30%** of the principal display panel
- Surrounded by adequate clear (blank) space:
  - Clear space **above and below** the declaration ≥ the **height of the numeral** in the declaration
  - Clear space **left and right** of the declaration ≥ **twice the height** of the numeral in the declaration

**Geometric Constraint Summary:**