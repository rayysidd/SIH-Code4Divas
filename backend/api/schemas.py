from pydantic import BaseModel
from typing import Optional, List
from enum import Enum


class PackageShapeEnum(str, Enum):
    RECTANGULAR = "RECTANGULAR"
    CYLINDRICAL = "CYLINDRICAL"
    IRREGULAR = "IRREGULAR"
    FLAT_SHEET = "FLAT_SHEET"
    UNKNOWN = "UNKNOWN"


class VerdictEnum(str, Enum):
    PASS = "PASS"
    FAIL = "FAIL"
    INCONCLUSIVE = "INCONCLUSIVE"
    NEEDS_VERIFICATION = "NEEDS_VERIFICATION"
    NOT_A_LABEL = "NOT_A_LABEL"
    WARN = "WARN"
    EXEMPT = "EXEMPT"


class SeverityEnum(str, Enum):
    CRITICAL = "CRITICAL"
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"
    INCONCLUSIVE = "INCONCLUSIVE"


class ScanModeEnum(str, Enum):
    INSPECTOR = "INSPECTOR"
    QA_MANAGER = "QA_MANAGER"
    API = "API"
    CITIZEN = "CITIZEN"


# ── Request Schemas ──────────────────────────────────────────────────────────


class ScanRequest(BaseModel):
    package_shape_hint: Optional[PackageShapeEnum] = None
    product_gtin: Optional[str] = None
    listing_url: Optional[str] = None
    rule_version: Optional[str] = "2024.01"


class ListingCheckRequest(BaseModel):
    listing_url: str
    physical_label_scan_id: Optional[str] = None


class CrossChannelRequest(BaseModel):
    listing_url: str
    scan_id: str


class BatchListingsRequest(BaseModel):
    listing_urls: List[str]
    webhook_url: Optional[str] = None
    report_email: Optional[str] = None


class CitizenReportRequest(BaseModel):
    problem_type: str
    description: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


# ── Response Schemas ─────────────────────────────────────────────────────────


class BoundingBoxSchema(BaseModel):
    x: float
    y: float
    width: float
    height: float


class ViolationResponse(BaseModel):
    violation_id: str
    violation_code: str
    check_id: str
    rule_cited: str
    amendment_basis: Optional[str] = None
    severity: SeverityEnum
    field_name: Optional[str] = None
    description: str
    measured_value: Optional[str] = None
    required_value: Optional[str] = None
    confidence: float
    bounding_box: Optional[BoundingBoxSchema] = None
    crop_url: Optional[str] = None
    remediation: Optional[str] = None


class ViolationCountSummary(BaseModel):
    critical: int = 0
    high: int = 0
    medium: int = 0
    inconclusive: int = 0


class ScanResponse(BaseModel):
    scan_id: str
    status: str = "COMPLETED"
    overall_verdict: VerdictEnum
    overall_confidence: float
    violation_count: ViolationCountSummary
    violations: List[ViolationResponse] = []
    pdf_report_url: Optional[str] = None
    annotated_image_url: Optional[str] = None
    ocr_preview: Optional[str] = None
    pdp_area_cm2: Optional[float] = None
    pdp_area_method: Optional[str] = None


class ScanAsyncResponse(BaseModel):
    scan_id: str
    status: str = "PROCESSING"
    poll_url: str
    estimated_completion_seconds: int = 15


class ScanStatusResponse(BaseModel):
    scan_id: str
    status: str
    overall_verdict: Optional[VerdictEnum] = None
    overall_confidence: Optional[float] = None
    violation_count: Optional[ViolationCountSummary] = None
    pdf_report_url: Optional[str] = None
    error_message: Optional[str] = None


class CrossChannelField(BaseModel):
    declaration: str
    physical_label: Optional[str] = None
    ecom_listing: Optional[str] = None
    match_status: str  # MATCH, MISMATCH, LABEL_ONLY, LISTING_ONLY


class CrossChannelResponse(BaseModel):
    scan_id: str
    listing_url: str
    overall_verdict: VerdictEnum
    rule_basis: str = "Rule 6(10), LMPC Rules 2011"
    fields: List[CrossChannelField] = []


class CitizenReportResponse(BaseModel):
    tracking_id: str
    status: str = "SUBMITTED"
    message: str = "Your report has been submitted. We'll update you when reviewed."


class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"
    rules_version: str = "2024.01"


class AnalyticsOverview(BaseModel):
    total_scans: int = 0
    pass_rate: float = 0.0
    open_violations: int = 0
    avg_scan_time_seconds: float = 0.0


class TopViolatedRule(BaseModel):
    rule: str
    description: str
    count: int
    percentage: float
