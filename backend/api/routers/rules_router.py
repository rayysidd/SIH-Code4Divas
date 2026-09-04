"""
/v1/rules/* — Rules Engine and Compliance DB endpoints.
"""

import json
import os
from fastapi import APIRouter, Depends
from ..auth import require_role, TokenData

router = APIRouter(prefix="/rules", tags=["Rules Engine"])

@router.get(
    "/version",
    summary="Get rules engine version info (ADMIN only)",
    dependencies=[Depends(require_role("ADMIN"))],
)
async def get_rules_version():
    """
    Returns the current rules engine version info and usage stats.
    Reads directly from packages/rules-engine/rules-db.json.
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
        
    # In a real DB, we would query `SELECT rule_version, COUNT(*) FROM scans GROUP BY rule_version`
    # Mocking this for the admin dashboard demo
    scan_counts_by_version = []
    if version != "Unknown":
        scan_counts_by_version.append({"version": version, "count": 247})
    scan_counts_by_version.append({"version": "2023.02", "count": 12})
        
    return {
        "version": version,
        "effective_date": effective_date,
        "amendment_basis": amendment_basis,
        "scan_counts": scan_counts_by_version
    }
