import { checkNetQuantity } from '../src/checks/net-quantity-check';
import { LabelData } from '../src/types';

describe('Net Quantity Check - Rule 6(1)(c)', () => {
  it('should pass for compliant net quantity', () => {
    const data: LabelData = {
      scanId: 'nq-001',
      packageShape: 'RECTANGULAR',
      isImported: false,
      productCategory: 'FOOD_GENERAL',
      declarations: {
        'NET_QUANTITY': {
          fieldType: 'NET_QUANTITY',
          present: true,
          rawText: '500 g',
          parsedValue: 500,
          confidence: 0.95,
        }
      }
    };

    const result = checkNetQuantity(data);
    expect(result.verdict).toBe('PASS');
    expect(result.checkId).toBe('PASS-NQ');
  });

  it('should fail if net quantity is absent', () => {
    const data: LabelData = {
      scanId: 'nq-002',
      packageShape: 'RECTANGULAR',
      isImported: false,
      productCategory: 'FOOD_GENERAL',
      declarations: {}
    };

    const result = checkNetQuantity(data);
    expect(result.verdict).toBe('FAIL');
    expect(result.severity).toBe('CRITICAL');
    expect(result.checkId).toBe('VIO-MISS-005');
  });

  it('should fail for edible oil with volume-only declaration', () => {
    const data: LabelData = {
      scanId: 'nq-003',
      packageShape: 'RECTANGULAR',
      isImported: false,
      productCategory: 'EDIBLE_OIL',
      declarations: {
        'NET_QUANTITY': {
          fieldType: 'NET_QUANTITY',
          present: true,
          rawText: '1000 ml',
          parsedValue: 1000,
          confidence: 0.90,
        }
      }
    };

    const result = checkNetQuantity(data);
    expect(result.verdict).toBe('FAIL');
    expect(result.severity).toBe('HIGH');
    expect(result.checkId).toBe('VIO-OIL-001');
    expect(result.description).toContain('weight declaration required');
  });

  it('should pass for edible oil with dual declaration (volume + weight)', () => {
    const data: LabelData = {
      scanId: 'nq-004',
      packageShape: 'CYLINDRICAL',
      isImported: false,
      productCategory: 'EDIBLE_OIL',
      declarations: {
        'NET_QUANTITY': {
          fieldType: 'NET_QUANTITY',
          present: true,
          rawText: '1000 ml (920 g)',
          parsedValue: 1000,
          confidence: 0.92,
        }
      }
    };

    const result = checkNetQuantity(data);
    expect(result.verdict).toBe('PASS');
  });
});
