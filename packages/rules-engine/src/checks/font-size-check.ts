import { LabelData, CheckResult, Verdict, Severity } from '../types';
import rulesDb from '../../rules-db.json';

/**
 * Checks compliance for Font Size - Rule 7(4) Table I & II
 *
 * Dynamically selects the correct font size table based on the product's
 * net quantity unit type:
 *   - Table I  for weight/volume (g, kg, ml, L)
 *   - Table II for length/area/number (m, cm, pcs, nos, tablets, pieces)
 */
export function checkFontSize(labelData: LabelData, declaration: 'NET_QUANTITY' | 'MRP'): CheckResult {
  const decl = labelData.declarations[declaration];

  if (!decl || !decl.present || !decl.fontHeightMm) {
    return {
      checkId: 'PASS-NO-FONT-DATA',
      ruleCited: '7(4)',
      verdict: 'INCONCLUSIVE',
      description: `Could not measure font size for ${declaration}.`,
      confidence: 0,
    };
  }

  // Determine which table to use based on net quantity unit type
  const nqDecl = labelData.declarations['NET_QUANTITY'];
  const unitText = (nqDecl?.rawText || '').toLowerCase();
  const isLengthAreaNumber =
    unitText.includes('pcs') || unitText.includes('piece') ||
    unitText.includes('nos') || unitText.includes('unit') ||
    unitText.includes('tablet') || unitText.includes(' m ') ||
    unitText.includes('cm');

  const tableKey = isLengthAreaNumber ? 'table_II' : 'table_I';
  const table = (rulesDb.font_size_rules as any)[tableKey];

  if (!table || !table.tiers) {
    return {
      checkId: 'ERR-NO-TABLE',
      ruleCited: '7(4)',
      verdict: 'INCONCLUSIVE',
      description: `Font size table "${tableKey}" not found in rules database.`,
      confidence: 0,
    };
  }

  // Find applicable tier based on PDP area
  const pdpArea = labelData.pdpAreaCm2 || 0;
  const tier = table.tiers.find((t: any) => pdpArea > t.min_area && pdpArea <= t.max_area);

  if (!tier) {
    return {
      checkId: 'ERR-NO-TIER',
      ruleCited: '7(4)',
      verdict: 'INCONCLUSIVE',
      description: `PDP Area (${pdpArea}cm²) does not match any known tier in ${tableKey}.`,
      confidence: 0,
    };
  }

  const isEmbossed = decl.fontRenderingType === 'EMBOSSED';
  const requiredMinMm = isEmbossed ? tier.embossed_min_mm : tier.printed_min_mm;

  if (decl.fontHeightMm < requiredMinMm) {
    const isCritical = declaration === 'NET_QUANTITY' || declaration === 'MRP';
    const checkId = declaration === 'NET_QUANTITY' ? 'VIO-FONT-001' : 'VIO-FONT-002';

    return {
      checkId,
      ruleCited: '7(4)',
      verdict: 'FAIL',
      severity: isCritical ? 'CRITICAL' : 'HIGH',
      description: `Numeral height ${decl.fontHeightMm}mm is below the minimum required ${requiredMinMm}mm (${tableKey}).`,
      foundValue: `${decl.fontHeightMm}mm`,
      requiredValue: `≥ ${requiredMinMm}mm (PDP: ${pdpArea}cm², ${isEmbossed ? 'Embossed' : 'Printed'}, ${tableKey})`,
      confidence: decl.confidence,
      evidenceBox: decl.boundingBox,
    };
  }

  return {
    checkId: `PASS-FONT-${declaration}`,
    ruleCited: '7(4)',
    verdict: 'PASS',
    description: `Font size (${decl.fontHeightMm}mm) meets the requirement (≥ ${requiredMinMm}mm, ${tableKey}).`,
    foundValue: `${decl.fontHeightMm}mm`,
    confidence: decl.confidence,
    evidenceBox: decl.boundingBox,
  };
}
