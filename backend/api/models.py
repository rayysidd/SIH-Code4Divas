import uuid
from sqlalchemy import Column, String, Float, Boolean, DateTime, ForeignKey, Enum as SQLEnum, JSON, Integer
from sqlalchemy.sql import func
from .database import Base

class ScanSession(Base):
    __tablename__ = "scan_sessions"

    scan_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=True) # UUID FK
    scan_timestamp = Column(DateTime(timezone=True), server_default=func.now())
    product_gtin = Column(String(14), nullable=True)
    product_name = Column(String, nullable=True)
    package_shape = Column(String) # RECTANGULAR, CYLINDRICAL, IRREGULAR, FLAT_SHEET, UNKNOWN
    pdp_area_cm2 = Column(Float, nullable=True)
    pdp_area_confidence = Column(Float, nullable=True)
    overall_verdict = Column(String) # PASS, FAIL, INCONCLUSIVE
    overall_confidence = Column(Float)
    rule_version = Column(String, nullable=False, default="2024.01")
    scan_mode = Column(String) # INSPECTOR, QA_MANAGER, API, CITIZEN
    input_image_url = Column(String, nullable=False)
    annotated_image_url = Column(String, nullable=True)
    pdf_report_url = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Violation(Base):
    __tablename__ = "violations"

    violation_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    scan_id = Column(String, ForeignKey("scan_sessions.scan_id"))
    violation_code = Column(String, nullable=False)
    check_id = Column(String, nullable=False)
    rule_cited = Column(String, nullable=False)
    amendment_basis = Column(String, nullable=True)
    severity = Column(String) # CRITICAL, HIGH, MEDIUM
    field_name = Column(String, nullable=True)
    description = Column(String, nullable=False)
    measured_value = Column(String, nullable=True)
    required_value = Column(String, nullable=True)
    margin = Column(String, nullable=True)
    confidence = Column(Float, nullable=False)
    bounding_box = Column(JSON, nullable=True) # JSONB in PG
    crop_url = Column(String, nullable=True)
    remediation = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class User(Base):
    __tablename__ = "users"
    user_id      = Column(String, primary_key=True)
    username     = Column(String, unique=True, nullable=False, index=True)
    full_name    = Column(String, nullable=False)
    email        = Column(String, unique=True, nullable=False)
    password_hash= Column(String, nullable=False)
    role         = Column(String, nullable=False, default="CITIZEN")
    district     = Column(String, nullable=True)
    is_active    = Column(Boolean, nullable=False, default=True)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())

class InviteCode(Base):
    __tablename__ = "invite_codes"
    code         = Column(String, primary_key=True)
    role         = Column(String, nullable=False)
    district     = Column(String, nullable=True)
    issued_by    = Column(String, ForeignKey("users.user_id"), nullable=False)
    issued_at    = Column(DateTime(timezone=True), server_default=func.now())
    expires_at   = Column(DateTime(timezone=True), nullable=False)
    used         = Column(Boolean, nullable=False, default=False)
    used_by      = Column(String, ForeignKey("users.user_id"), nullable=True)

class AuditLog(Base):
    __tablename__ = "audit_log"
    id             = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    action         = Column(String, nullable=False)
    actor_user_id  = Column(String, ForeignKey("users.user_id"), nullable=True)
    actor_username = Column(String, nullable=False)
    target         = Column(String, nullable=True)
    details        = Column(String, nullable=True)
    timestamp      = Column(DateTime(timezone=True), server_default=func.now())

class CitizenReport(Base):
    __tablename__ = "citizen_reports"
    tracking_id  = Column(String, primary_key=True)
    problem_type = Column(String, nullable=False)
    description  = Column(String, nullable=True)
    latitude     = Column(Float, nullable=True)
    longitude    = Column(Float, nullable=True)
    image_url    = Column(String, nullable=True)
    status       = Column(String, nullable=False, default="SUBMITTED")
    submitted_at = Column(DateTime(timezone=True), server_default=func.now())
    reviewed_by  = Column(String, ForeignKey("users.user_id"), nullable=True)
    reviewed_at  = Column(DateTime(timezone=True), nullable=True)

class BatchJob(Base):
    __tablename__ = "batch_jobs"
    batch_id        = Column(String, primary_key=True)
    submitted_by    = Column(String, ForeignKey("users.user_id"), nullable=False)
    total_urls      = Column(Integer, nullable=False)
    processed_urls  = Column(Integer, nullable=False, default=0)
    status          = Column(String, nullable=False, default="QUEUED")
    webhook_url     = Column(String, nullable=True)
    report_email    = Column(String, nullable=True)
    created_at      = Column(DateTime(timezone=True), server_default=func.now())
    completed_at    = Column(DateTime(timezone=True), nullable=True)

class ScanTask(Base):
    __tablename__ = "scan_tasks"
    scan_id     = Column(String, ForeignKey("scan_sessions.scan_id"), primary_key=True)
    status      = Column(String, nullable=False, default="PROCESSING")
    error       = Column(String, nullable=True)
    started_at  = Column(DateTime(timezone=True), server_default=func.now())
    completed_at= Column(DateTime(timezone=True), nullable=True)
