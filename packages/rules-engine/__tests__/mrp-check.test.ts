import { checkMRP } from '../src/checks/mrp-check';
import { LabelData } from '../src/types';

describe('MRP Check - Rule 6(1)(e)', () => {
  it('should pass for compliant MRP', () => {
    const data: LabelData = {
      scanId: '123',
      packageShape: 'RECTANGULAR',
      isImported: false,
      productCategory: 'FOOD',
      declarations: {
        'MRP': {
          fieldType: 'MRP',
          present: true,
          rawText: 'MRP ₹45.00 (Incl. of all taxes)',
          confidence: 0.95,
        }
      }
    };
    
    const result = checkMRP(data);
    expect(result.verdict).toBe('PASS');
    expect(result.checkId).toBe('PASS-MRP');
  });

  it('should fail if tax suffix is missing', () => {
    const data: LabelData = {
      scanId: '123',
      packageShape: 'RECTANGULAR',
      isImported: false,
      productCategory: 'FOOD',
      declarations: {
        'MRP': {
          fieldType: 'MRP',
          present: true,
          rawText: 'MRP ₹45.00',
          confidence: 0.95,
        }
      }
    };
    
    const result = checkMRP(data);
    expect(result.verdict).toBe('FAIL');
    expect(result.severity).toBe('HIGH');
    expect(result.checkId).toBe('VIO-FORMAT-001');
  });

  it('should fail if missing entirely', () => {
    const data: LabelData = {
      scanId: '123',
      packageShape: 'RECTANGULAR',
      isImported: false,
      productCategory: 'FOOD',
      declarations: {}
    };
    
    const result = checkMRP(data);
    expect(result.verdict).toBe('FAIL');
    expect(result.severity).toBe('CRITICAL');
    expect(result.checkId).toBe('VIO-MISS-007');
  });
});
