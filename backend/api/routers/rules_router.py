"""
/v1/rules/* — Rules Engine and Compliance DB endpoints.
"""

import json
import os
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..auth import require_role, TokenData
from ..database import get_db

router = APIRouter(prefix="/rules", tags=["Rules Engine"])

@router.get(
    "/version",
    summary="Get rules engine version info (ADMIN only)",
    dependencies=[Depends(require_role("ADMIN"))],
)
async def get_rules_version(db: Session = Depends(get_db)):
    """
    Returns the current rules engine version info and usage stats.
    Reads directly from packages/rules-engine/rules-db.json.
    Scan counts are queried from the real database.
    """
    db_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "packages", "rules-engine", "rules-db.json")
    try:
        with open(db_path, "r") as f:
            db_data = json.load(f)
            
        version = db_data.get("version", "Unknown")
        effective_date = db_data.get("effective_date", "Unknown")
        amendment_basis = db_data.get("amendment_basis", "Unknown")
    except Exception:
        version = "Unknown"
        effective_date = "Unknown"
        amendment_basis = "Unknown"
        
    # Real DB query for scan counts by rule version
    from ..models import ScanSession
    from sqlalchemy import func

    rows = (
        db.query(
            ScanSession.rule_version,
            func.count(ScanSession.scan_id).label("cnt"),
        )
        .group_by(ScanSession.rule_version)
        .all()
    )
    scan_counts_by_version = [
        {"version": r.rule_version or "unknown", "count": r.cnt}
        for r in rows
    ]
        
    return {
        "version": version,
        "effective_date": effective_date,
        "amendment_basis": amendment_basis,
        "scan_counts": scan_counts_by_version,
    }
