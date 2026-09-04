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
 */
export function isExempt(labelData: LabelData, field: DeclarationType): { exempt: boolean; reason?: ExemptionReason; ruleCited?: string } {
  // Check Rule 26 exemptions (Small packages under 10g or 10ml)
  const nqDecl = labelData.declarations['NET_QUANTITY'];
  if (nqDecl && nqDecl.present) {
    const text = nqDecl.rawText.toLowerCase();
    
    // Simplistic check for demo - if it declares 5g, 8ml, etc.
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

  // Example: Drugs are completely exempt (governed by DPCO)
  if (labelData.productCategory === 'PHARMACEUTICAL') {
    return {
      exempt: true,
      reason: ExemptionReason.PHARMACEUTICAL_DRUG,
      ruleCited: 'Chapter II, Exemption'
    };
  }

  return { exempt: false };
}
