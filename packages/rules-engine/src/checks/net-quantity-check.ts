import { LabelData, CheckResult } from '../types';

/**
 * Checks compliance for Net Quantity - Rule 6(1)(c)
 */
export function checkNetQuantity(labelData: LabelData): CheckResult {
  const nqDecl = labelData.declarations['NET_QUANTITY'];
  const ruleCited = '6(1)(c)';

  if (!nqDecl || !nqDecl.present) {
    return {
      checkId: 'VIO-MISS-005',
      ruleCited,
      verdict: 'FAIL',
      severity: 'CRITICAL',
      description: 'Net quantity declaration is absent from the label.',
      confidence: nqDecl?.confidence || 0.95,
    };
  }

  // Dual declaration check for edible oil (Fourth Schedule)
  if (labelData.productCategory === 'EDIBLE_OIL') {
    const text = nqDecl.rawText.toLowerCase();
    const hasVolume = text.includes('ml') || text.includes('l');
    const hasWeight = text.includes('g') || text.includes('kg');
    
    if (hasVolume && !hasWeight) {
      return {
        checkId: 'VIO-OIL-001',
        ruleCited: '4th Schedule',
        verdict: 'FAIL',
        severity: 'HIGH',
        description: 'Edible oil declared by volume only; weight declaration required.',
        foundValue: nqDecl.rawText,
        requiredValue: 'Volume and equivalent weight',
        confidence: nqDecl.confidence,
        evidenceBox: nqDecl.boundingBox,
      };
    }
  }

  // Basic check pass
  return {
    checkId: 'PASS-NQ',
    ruleCited,
    verdict: 'PASS',
    description: 'Net quantity declaration is present and compliant.',
    foundValue: nqDecl.rawText,
    confidence: nqDecl.confidence,
    evidenceBox: nqDecl.boundingBox,
  };
}
