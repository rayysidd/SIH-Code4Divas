import { LabelData, DeclarationType } from './types';

export enum ExemptionReason {
  WHOLESALE_PACKAGE = 'WHOLESALE_PACKAGE',
  SMALL_PACKAGE_SUB_10 = 'SMALL_PACKAGE_SUB_10',
  FAST_FOOD_RESTAURANT = 'FAST_FOOD_RESTAURANT',
  PHARMACEUTICAL_DRUG = 'PHARMACEUTICAL_DRUG', // Governed by Drugs & Cosmetics Act
  AGRICULTURAL_PRODUCE_OVER_50KG = 'AGRICULTURAL_PRODUCE_OVER_50KG',
}

/**
 * Checks if a specific declaration rule is exempted for this package.
 *
 * Implements all 5 LMPC exemption categories:
 *   1. SMALL_PACKAGE_SUB_10    — Rule 26
 *   2. PHARMACEUTICAL_DRUG     — Chapter II exemption
 *   3. WHOLESALE_PACKAGE       — Rule 6(7)
 *   4. FAST_FOOD_RESTAURANT    — Rule 11(2)
 *   5. AGRICULTURAL_PRODUCE_OVER_50KG — Rule 11(1)(a)
 */
export function isExempt(labelData: LabelData, field: DeclarationType): { exempt: boolean; reason?: ExemptionReason; ruleCited?: string } {
  // ── 1. Small packages under 10g or 10ml — Rule 26 ───────────────────
  const nqDecl = labelData.declarations['NET_QUANTITY'];
  if (nqDecl && nqDecl.present) {
    const text = nqDecl.rawText.toLowerCase();

    // Check for small packages (≤10g or ≤10ml)
    const isSmall = (text.includes('g') && !text.includes('kg') && parseInt(text) <= 10) ||
                    (text.includes('ml') && parseInt(text) <= 10);

    if (isSmall) {
      // Small packages are exempt from all declarations EXCEPT generic name and MRP
      if (field !== 'GENERIC_NAME' && field !== 'MRP') {
        return {
          exempt: true,
          reason: ExemptionReason.SMALL_PACKAGE_SUB_10,
          ruleCited: 'Rule 26'
        };
      }
    }
  }

  // ── 2. Pharmaceutical drugs — Chapter II exemption ──────────────────
  if (labelData.productCategory === 'PHARMACEUTICAL') {
    return {
      exempt: true,
      reason: ExemptionReason.PHARMACEUTICAL_DRUG,
      ruleCited: 'Chapter II, Exemption'
    };
  }

  // ── 3. Wholesale packages — Rule 6(7) ──────────────────────────────
  // If label contains "not for retail sale" or "wholesale only"
  const allRawTexts: string[] = [];
  for (const key of Object.keys(labelData.declarations)) {
    const decl = labelData.declarations[key];
    if (decl?.rawText) {
      allRawTexts.push(decl.rawText);
    }
  }
  const combinedText = allRawTexts.join(' ').toLowerCase();

  if (combinedText.includes('not for retail') || combinedText.includes('wholesale only')) {
    return {
      exempt: true,
      reason: ExemptionReason.WHOLESALE_PACKAGE,
      ruleCited: 'Rule 6(7)'
    };
  }

  // ── 4. Fast food / restaurant packages — Rule 11(2) ────────────────
  // Label contains "not for sale" + restaurant/hotel/cafe keywords
  if (combinedText.includes('not for sale') &&
      (combinedText.includes('restaurant') || combinedText.includes('hotel') ||
       combinedText.includes('cafe') || combinedText.includes('canteen'))) {
    return {
      exempt: true,
      reason: ExemptionReason.FAST_FOOD_RESTAURANT,
      ruleCited: 'Rule 11(2)'
    };
  }

  // ── 5. Agricultural produce over 50kg — Rule 11(1)(a) ──────────────
  if (nqDecl?.parsedValue && nqDecl.parsedValue > 50000) { // value stored in grams
    if (labelData.productCategory === 'FOOD_GENERAL' ||
        labelData.productCategory === 'EDIBLE_OIL') {
      return {
        exempt: true,
        reason: ExemptionReason.AGRICULTURAL_PRODUCE_OVER_50KG,
        ruleCited: 'Rule 11(1)(a)'
      };
    }
  }

  return { exempt: false };
}
