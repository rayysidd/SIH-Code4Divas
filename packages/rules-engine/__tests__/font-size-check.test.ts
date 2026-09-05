import { checkFontSize } from '../src/checks/font-size-check';
import { LabelData } from '../src/types';

describe('Font Size Check - Rule 7(4)', () => {
  // ── Table I (weight/volume) tests ──────────────────────────────────

  it('should pass for compliant font size (Table I, weight/volume)', () => {
    const data: LabelData = {
      scanId: 'fs-001',
      packageShape: 'RECTANGULAR',
      pdpAreaCm2: 200,
      isImported: false,
      productCategory: 'FOOD_GENERAL',
      declarations: {
        'NET_QUANTITY': {
          fieldType: 'NET_QUANTITY',
          present: true,
          rawText: '500 g',
          fontHeightMm: 3.0, // Requirement for 100-500cm² table_I is 2.5mm printed
          confidence: 0.90,
        }
      }
    };

    const result = checkFontSize(data, 'NET_QUANTITY');
    expect(result.verdict).toBe('PASS');
    expect(result.checkId).toBe('PASS-FONT-NET_QUANTITY');
  });

  it('should fail for undersized font (Table I, weight/volume)', () => {
    const data: LabelData = {
      scanId: 'fs-002',
      packageShape: 'RECTANGULAR',
      pdpAreaCm2: 200,
      isImported: false,
      productCategory: 'FOOD_GENERAL',
      declarations: {
        'NET_QUANTITY': {
          fieldType: 'NET_QUANTITY',
          present: true,
          rawText: '500 g',
          fontHeightMm: 1.5, // Below 2.5mm minimum for 100-500cm² tier
          confidence: 0.88,
        }
      }
    };

    const result = checkFontSize(data, 'NET_QUANTITY');
    expect(result.verdict).toBe('FAIL');
    expect(result.checkId).toBe('VIO-FONT-001');
    expect(result.severity).toBe('CRITICAL');
    expect(result.description).toContain('2.5mm');
  });

  // ── Table II (length/area/number) tests ────────────────────────────

  it('should use Table II for products with piece-count units', () => {
    const data: LabelData = {
      scanId: 'fs-003',
      packageShape: 'RECTANGULAR',
      pdpAreaCm2: 200,
      isImported: false,
      productCategory: 'GENERAL',
      declarations: {
        'NET_QUANTITY': {
          fieldType: 'NET_QUANTITY',
          present: true,
          rawText: '10 pcs',
          fontHeightMm: 2.5, // Table II for 100-500cm² requires 2.0mm
          confidence: 0.90,
        }
      }
    };

    const result = checkFontSize(data, 'NET_QUANTITY');
    expect(result.verdict).toBe('PASS');
    expect(result.description).toContain('table_II');
  });

  it('should fail for undersized font using Table II (number units)', () => {
    const data: LabelData = {
      scanId: 'fs-004',
      packageShape: 'RECTANGULAR',
      pdpAreaCm2: 200,
      isImported: false,
      productCategory: 'GENERAL',
      declarations: {
        'NET_QUANTITY': {
          fieldType: 'NET_QUANTITY',
          present: true,
          rawText: '50 tablets',
          fontHeightMm: 1.5, // Table II 100-500cm² requires 2.0mm
          confidence: 0.85,
        }
      }
    };

    const result = checkFontSize(data, 'NET_QUANTITY');
    expect(result.verdict).toBe('FAIL');
    expect(result.checkId).toBe('VIO-FONT-001');
    expect(result.description).toContain('2mm');
    expect(result.description).toContain('table_II');
  });

  it('should use Table II for products with cm units', () => {
    const data: LabelData = {
      scanId: 'fs-005',
      packageShape: 'RECTANGULAR',
      pdpAreaCm2: 80,
      isImported: false,
      productCategory: 'GENERAL',
      declarations: {
        'NET_QUANTITY': {
          fieldType: 'NET_QUANTITY',
          present: true,
          rawText: '100 cm',
          fontHeightMm: 1.2, // Table II for <100cm² requires 1.0mm — should pass
          confidence: 0.88,
        }
      }
    };

    const result = checkFontSize(data, 'NET_QUANTITY');
    expect(result.verdict).toBe('PASS');
  });

  // ── MRP font check ────────────────────────────────────────────────

  it('should check MRP font size using Table I for weight/volume product', () => {
    const data: LabelData = {
      scanId: 'fs-006',
      packageShape: 'RECTANGULAR',
      pdpAreaCm2: 30,
      isImported: false,
      productCategory: 'FOOD_GENERAL',
      declarations: {
        'NET_QUANTITY': {
          fieldType: 'NET_QUANTITY',
          present: true,
          rawText: '100 g',
          confidence: 0.90,
        },
        'MRP': {
          fieldType: 'MRP',
          present: true,
          rawText: 'MRP ₹45.00',
          fontHeightMm: 0.8, // Below 1.0mm for <50cm² tier
          confidence: 0.90,
        }
      }
    };

    const result = checkFontSize(data, 'MRP');
    expect(result.verdict).toBe('FAIL');
    expect(result.checkId).toBe('VIO-FONT-002');
  });

  // ── Inconclusive case ─────────────────────────────────────────────

  it('should return INCONCLUSIVE when font height is not available', () => {
    const data: LabelData = {
      scanId: 'fs-007',
      packageShape: 'RECTANGULAR',
      pdpAreaCm2: 200,
      isImported: false,
      productCategory: 'FOOD_GENERAL',
      declarations: {
        'NET_QUANTITY': {
          fieldType: 'NET_QUANTITY',
          present: true,
          rawText: '500 g',
          confidence: 0.90,
          // No fontHeightMm
        }
      }
    };

    const result = checkFontSize(data, 'NET_QUANTITY');
    expect(result.verdict).toBe('INCONCLUSIVE');
  });
});
