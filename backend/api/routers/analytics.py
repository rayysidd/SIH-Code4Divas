"""
/v1/analytics/* — Analytics and dashboard data endpoints.
Implements dashboard KPIs, violation trends, category breakdowns.

All endpoints now use real SQLAlchemy queries against the database
instead of returning hardcoded/random data.
"""

from typing import List
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, case, cast, Date

from ..schemas import AnalyticsOverview, TopViolatedRule
from ..auth import get_current_user, require_role, TokenData
from ..database import get_db
from ..models import ScanSession, Violation, BatchListingResult

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/admin-overview", summary="Admin cross-district dashboard KPI overview", dependencies=[Depends(require_role("ADMIN"))])
async def get_admin_overview(db: Session = Depends(get_db)):
    """
    Return dashboard KPIs aggregated across all districts for the ADMIN.
    """
    from ..models import User

    # Real aggregation: join scans to users for district info
    rows = (
        db.query(
            User.district,
            func.count(ScanSession.scan_id).label("total"),
            func.sum(case((ScanSession.overall_verdict == "PASS", 1), else_=0)).label("passed"),
        )
        .join(User, ScanSession.user_id == User.user_id)
        .group_by(User.district)
        .all()
    )

    if not rows:
        return {
            "pass_rate_trend": [],
            "inspector_workload": [],
            "top_violations_by_district": [],
        }

    # 1. Pass rate trend by district
    pass_rate_trend = []
    for row in rows:
        district = row.district or "Unknown"
        rate = round((row.passed / row.total * 100), 1) if row.total > 0 else 0
        pass_rate_trend.append({
            "district": district,
            "data": [{"date": datetime.utcnow().strftime("%Y-%m-%d"), "rate": rate}],
        })

    # 2. Inspector workload
    inspector_rows = (
        db.query(
            User.username,
            User.district,
            func.count(ScanSession.scan_id).label("scans"),
        )
        .join(User, ScanSession.user_id == User.user_id)
        .group_by(User.username, User.district)
        .order_by(func.count(ScanSession.scan_id).desc())
        .all()
    )
    inspector_workload = [
        {"inspector": r.username, "district": r.district or "Unknown", "scans": r.scans}
        for r in inspector_rows
    ]

    # 3. Top violations by district
    vio_rows = (
        db.query(
            User.district,
            Violation.rule_cited,
            func.count(Violation.violation_id).label("cnt"),
        )
        .join(ScanSession, Violation.scan_id == ScanSession.scan_id)
        .join(User, ScanSession.user_id == User.user_id)
        .group_by(User.district, Violation.rule_cited)
        .order_by(func.count(Violation.violation_id).desc())
        .all()
    )

    district_violations = {}
    for r in vio_rows:
        d = r.district or "Unknown"
        if d not in district_violations:
            district_violations[d] = []
        if len(district_violations[d]) < 5:
            district_violations[d].append({"rule": r.rule_cited, "count": r.cnt})

    top_violations_by_district = [
        {"district": d, "violations": v}
        for d, v in district_violations.items()
    ]

    return {
        "pass_rate_trend": pass_rate_trend,
        "inspector_workload": inspector_workload,
        "top_violations_by_district": top_violations_by_district,
    }


@router.get("/ecom-overview", summary="E-commerce compliance overview for Ecom Lead")
async def get_ecom_overview(
    current_user: TokenData = Depends(require_role("ECOM_LEAD")),
    db: Session = Depends(get_db),
):
    """
    Aggregate from BatchListingResult (both standalone and batch-linked rows)
    scoped to current_user.user_id: total listings checked, pass rate,
    count of recent failures with their missing_fields.
    """
    user_results = db.query(BatchListingResult).filter(
        BatchListingResult.checked_by == current_user.user_id
    )
    total_checked = user_results.count()
    passed_count = user_results.filter(BatchListingResult.verdict == "PASS").count()
    failed_count = user_results.filter(BatchListingResult.verdict == "FAIL").count()
    pass_rate = round((passed_count / total_checked * 100), 1) if total_checked > 0 else 0.0

    recent_failures = (
        user_results.filter(BatchListingResult.verdict == "FAIL")
        .order_by(BatchListingResult.checked_at.desc())
        .limit(10)
        .all()
    )

    return {
        "total_checked": total_checked,
        "total_listings_checked": total_checked,
        "passed_count": passed_count,
        "failed_count": failed_count,
        "pass_rate": pass_rate,
        "recent_failures": [
            {
                "id": r.id,
                "listing_url": r.listing_url,
                "verdict": r.verdict,
                "missing_fields": r.missing_fields or [],
                "checked_at": r.checked_at.isoformat() + "Z" if r.checked_at else None,
            }
            for r in recent_failures
        ],
    }


@router.get("/overview", response_model=AnalyticsOverview, summary="Dashboard KPI overview")
async def get_overview(
    mine: bool = False,
    current_user: TokenData = Depends(require_role("INSPECTOR")),
    db: Session = Depends(get_db),
):
    """
    Return dashboard KPIs: total scans, pass rate, open violations, avg scan time.
    Screen W-01 data source. Scoped to current user if INSPECTOR or mine=True.
    """
    is_scoped = mine or (current_user.role == "INSPECTOR")

    scan_query = db.query(ScanSession)
    if is_scoped:
        scan_query = scan_query.filter(ScanSession.user_id == current_user.user_id)

    total = scan_query.count()
    passed = scan_query.filter(ScanSession.overall_verdict == "PASS").count()
    pass_rate = round((passed / total * 100), 1) if total > 0 else 0.0

    vio_query = db.query(Violation).filter(Violation.severity.in_(["CRITICAL", "HIGH"]))
    if is_scoped:
        vio_query = vio_query.join(ScanSession, Violation.scan_id == ScanSession.scan_id).filter(
            ScanSession.user_id == current_user.user_id
        )
    open_violations = vio_query.count()

    # Real avg scan time from ScanTask durations
    from ..models import ScanTask
    task_query = db.query(ScanTask).filter(ScanTask.status == "COMPLETED")
    if is_scoped:
        task_query = task_query.join(ScanSession, ScanTask.scan_id == ScanSession.scan_id).filter(
            ScanSession.user_id == current_user.user_id
        )
    completed_tasks = task_query.all()
    if completed_tasks:
        durations = [
            (t.completed_at - t.started_at).total_seconds()
            for t in completed_tasks
            if t.completed_at and t.started_at
        ]
        avg_time = round(sum(durations) / len(durations), 1) if durations else 0.0
    else:
        avg_time = 0.0

    return AnalyticsOverview(
        total_scans=total,
        pass_rate=pass_rate,
        open_violations=open_violations,
        avg_scan_time_seconds=avg_time,
    )


@router.get("/top-violations", response_model=List[TopViolatedRule], summary="Top violated rules")
async def get_top_violations(
    mine: bool = False,
    current_user: TokenData = Depends(require_role("INSPECTOR")),
    db: Session = Depends(get_db),
):
    """
    Return top 5 most violated rules. Screen W-01 bar chart data.
    Scoped to current user if INSPECTOR or mine=True.
    """
    is_scoped = mine or (current_user.role == "INSPECTOR")

    q = db.query(
        Violation.rule_cited,
        func.count(Violation.violation_id).label("cnt"),
    )
    if is_scoped:
        q = q.join(ScanSession, Violation.scan_id == ScanSession.scan_id).filter(
            ScanSession.user_id == current_user.user_id
        )

    rows = (
        q.group_by(Violation.rule_cited)
        .order_by(func.count(Violation.violation_id).desc())
        .limit(5)
        .all()
    )

    total = sum(r.cnt for r in rows) if rows else 1

    return [
        TopViolatedRule(
            rule=r.rule_cited,
            description=r.rule_cited,
            count=r.cnt,
            percentage=round(r.cnt / total * 100),
        )
        for r in rows
    ]


@router.get("/compliance-trend", summary="Compliance rate over time")
async def get_compliance_trend(
    days: int = 30,
    mine: bool = False,
    current_user: TokenData = Depends(require_role("INSPECTOR")),
    db: Session = Depends(get_db),
):
    """
    Return daily compliance rate for the last N days.
    Screen W-07 line chart data. Scoped if INSPECTOR or mine=True.
    """
    is_scoped = mine or (current_user.role == "INSPECTOR")
    cutoff = datetime.utcnow() - timedelta(days=days)

    q = db.query(
        cast(ScanSession.created_at, Date).label("day"),
        func.count().label("total"),
        func.sum(
            case((ScanSession.overall_verdict == "PASS", 1), else_=0)
        ).label("passed"),
    ).filter(ScanSession.created_at >= cutoff)

    if is_scoped:
        q = q.filter(ScanSession.user_id == current_user.user_id)

    rows = (
        q.group_by(cast(ScanSession.created_at, Date))
        .order_by(cast(ScanSession.created_at, Date))
        .all()
    )

    return {
        "period_days": days,
        "data": [
            {
                "date": str(r.day),
                "compliance_rate": round(r.passed / r.total * 100, 1) if r.total else 0,
            }
            for r in rows
        ],
    }


@router.get("/by-category", summary="Violations by product category")
async def get_violations_by_category(
    current_user: TokenData = Depends(require_role("QA_MANAGER")),
    db: Session = Depends(get_db),
):
    """
    Return violations grouped by product category.
    Screen W-07 pie chart data.

    Since product_category is not stored per-scan yet, we infer from
    violation codes: food-related rules → Food, cosmetics-related → Cosmetics, etc.
    """
    total_violations = db.query(Violation).count()
    if total_violations == 0:
        return []

    # Heuristic categorization based on rule citations
    food_count = (
        db.query(Violation)
        .filter(
            Violation.rule_cited.ilike("%FSSAI%")
            | Violation.rule_cited.ilike("%6(1)(f)%")
            | Violation.rule_cited.ilike("%6(1)(j)%")
        )
        .count()
    )
    cosmetics_count = (
        db.query(Violation)
        .filter(Violation.description.ilike("%cosmetic%"))
        .count()
    )
    other_count = total_violations - food_count - cosmetics_count

    results = []
    for category, count in [("Food", food_count), ("Cosmetics", cosmetics_count), ("General", other_count)]:
        if count > 0:
            results.append({
                "category": category,
                "percentage": round(count / total_violations * 100),
                "count": count,
            })

    return results
