import { LabelData, EngineResult, CheckResult, Verdict } from './types';
import { checkMRP } from './checks/mrp-check';
import { checkNetQuantity } from './checks/net-quantity-check';
import { checkFontSize } from './checks/font-size-check';
import { determineProductCategory } from './category-router';
import { isExempt } from './exemption-engine';

/**
 * Main Rules Engine Orchestrator
 */
export function runComplianceEngine(labelData: LabelData): EngineResult {
  const results: CheckResult[] = [];

  // Determine actual product category (overrides or infers)
  const category = determineProductCategory(labelData);
  labelData.productCategory = category;

  // 1. Mandatory Declarations Check
  
  // Check MRP (Rule 6(1)(e))
  const mrpExempt = isExempt(labelData, 'MRP');
  if (mrpExempt.exempt) {
    results.push({
      checkId: 'EXEMPT-MRP',
      ruleCited: mrpExempt.ruleCited || 'Exemption',
      verdict: 'EXEMPT',
      description: `MRP is exempt: ${mrpExempt.reason}`,
      confidence: 1.0
    });
  } else {
    results.push(checkMRP(labelData));
  }

  // Check Net Quantity (Rule 6(1)(c))
  const nqExempt = isExempt(labelData, 'NET_QUANTITY');
  if (nqExempt.exempt) {
    results.push({
      checkId: 'EXEMPT-NQ',
      ruleCited: nqExempt.ruleCited || 'Exemption',
      verdict: 'EXEMPT',
      description: `Net Quantity is exempt: ${nqExempt.reason}`,
      confidence: 1.0
    });
  } else {
    results.push(checkNetQuantity(labelData));
  }

  // 2. Font Size Checks
  if (labelData.declarations['NET_QUANTITY']?.present) {
    results.push(checkFontSize(labelData, 'NET_QUANTITY'));
  }
  if (labelData.declarations['MRP']?.present) {
    results.push(checkFontSize(labelData, 'MRP'));
  }

  // 3. (Add other checks here: Placement, E-commerce, etc.)

  // 4. Compute Overall Verdict & Score
  let overallVerdict: Verdict = 'PASS';
  let overallConfidence = 1.0;
  let passedCount = 0;
  let totalCount = results.length;

  let hasCriticalFailure = false;
  let hasHighFailure = false;
  let hasInconclusive = false;

  for (const r of results) {
    overallConfidence = Math.min(overallConfidence, r.confidence);
    
    if (r.verdict === 'PASS') {
      passedCount++;
    } else if (r.verdict === 'FAIL') {
      if (r.severity === 'CRITICAL') hasCriticalFailure = true;
      if (r.severity === 'HIGH') hasHighFailure = true;
    } else if (r.verdict === 'INCONCLUSIVE') {
      hasInconclusive = true;
    }
  }

  if (hasCriticalFailure) {
    overallVerdict = 'FAIL';
  } else if (hasHighFailure && overallConfidence > 0.6) {
    overallVerdict = 'FAIL';
  } else if (hasInconclusive) {
    overallVerdict = 'INCONCLUSIVE';
  }

  return {
    scanId: labelData.scanId,
    overallVerdict,
    overallConfidence: overallConfidence * 100,
    score: {
      passed: passedCount,
      total: totalCount,
    },
    results,
  };
}
