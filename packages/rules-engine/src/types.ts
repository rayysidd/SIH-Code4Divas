export type Verdict = 'PASS' | 'FAIL' | 'WARN' | 'INCONCLUSIVE' | 'EXEMPT';

export type Severity = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';

export type PackageShape = 'RECTANGULAR' | 'CYLINDRICAL' | 'IRREGULAR' | 'FLAT_SHEET' | 'UNKNOWN';

export type DeclarationType = 
  | 'MANUFACTURER_NAME'
  | 'MANUFACTURER_ADDRESS'
  | 'GENERIC_NAME'
  | 'NET_QUANTITY'
  | 'MFG_DATE'
  | 'MRP'
  | 'BEST_BEFORE_DATE'
  | 'COUNTRY_OF_ORIGIN'
  | 'CUSTOMER_CARE'
  | 'VEG_NONVEG_SYMBOL'
  | 'UNIT_SALE_PRICE';

export interface BoundingBox {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface DeclarationData {
  fieldType: DeclarationType;
  rawText: string;
  parsedValue?: any;
  boundingBox?: BoundingBox;
  confidence: number;
  present: boolean;
  fontHeightMm?: number;
  fontRenderingType?: 'PRINTED' | 'EMBOSSED' | 'UNKNOWN';
}

export interface LabelData {
  scanId: string;
  packageShape: PackageShape;
  dimensionsCm?: {
    height?: number;
    width?: number;
    circumference?: number;
  };
  pdpAreaCm2?: number;
  declarations: Record<string, DeclarationData>;
  isImported: boolean;
  productCategory: string; // e.g., 'FOOD', 'COSMETICS'
  ecommerceListingUrl?: string;
}

export interface CheckResult {
  checkId: string;
  ruleCited: string;
  verdict: Verdict;
  severity?: Severity;
  description: string;
  foundValue?: string;
  requiredValue?: string;
  confidence: number;
  evidenceBox?: BoundingBox;
}

export interface EngineResult {
  scanId: string;
  overallVerdict: Verdict;
  overallConfidence: number;
  score: {
    passed: number;
    total: number;
  };
  results: CheckResult[];
}

export interface RuleDefinition {
  id: string;
  rule_citation: string;
  description: string;
  severity: Severity;
}
