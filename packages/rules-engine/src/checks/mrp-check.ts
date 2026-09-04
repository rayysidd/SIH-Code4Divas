import { LabelData, CheckResult, Verdict } from '../types';

/**
 * Checks compliance for Maximum Retail Price (MRP) - Rule 6(1)(e)
 * Validates presence, prefix, decimal places, currency symbol, and tax suffix.
 */
export function checkMRP(labelData: LabelData): CheckResult {
  const mrpDecl = labelData.declarations['MRP'];
  const ruleCited = '6(1)(e)';

  if (!mrpDecl || !mrpDecl.present) {
    return {
      checkId: 'VIO-MISS-007',
      ruleCited,
      verdict: 'FAIL',
      severity: 'CRITICAL',
      description: 'MRP declaration is absent from the label.',
      confidence: mrpDecl?.confidence || 0.95,
    };
  }

  const rawText = mrpDecl.rawText.toLowerCase();
  let verdict: Verdict = 'PASS';
  let severity: 'HIGH' | 'MEDIUM' | undefined = undefined;
  let description = 'MRP declaration is compliant.';
  let checkId = 'PASS-MRP';

  const hasTaxSuffix = rawText.includes('incl. of all taxes') || rawText.includes('inclusive of all taxes') || rawText.includes('incl. all taxes');
  const hasCurrencySymbol = rawText.includes('₹') || rawText.includes('rs') || rawText.includes('rs.');
  
  if (!hasTaxSuffix) {
    verdict = 'FAIL';
    severity = 'HIGH';
    checkId = 'VIO-FORMAT-001';
    description = 'MRP missing "Inclusive of all taxes" suffix.';
  } else if (!hasCurrencySymbol) {
    verdict = 'FAIL';
    severity = 'MEDIUM';
    checkId = 'VIO-FORMAT-002';
    description = 'MRP missing currency symbol (₹ or Rs).';
  } else if (!/\d+\.\d{2}/.test(mrpDecl.rawText)) {
    // Check for two decimal places
    verdict = 'FAIL';
    severity = 'MEDIUM';
    checkId = 'VIO-FORMAT-003';
    description = 'MRP not in two decimal places.';
  }

  return {
    checkId,
    ruleCited,
    verdict,
    severity,
    description,
    foundValue: mrpDecl.rawText,
    requiredValue: 'e.g., MRP ₹XX.00 (Incl. of all taxes)',
    confidence: mrpDecl.confidence,
    evidenceBox: mrpDecl.boundingBox,
  };
}
