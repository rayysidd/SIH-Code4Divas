"""
/v1/analytics/* — Analytics and dashboard data endpoints.
Implements dashboard KPIs, violation trends, category breakdowns.
"""

from typing import List
from fastapi import APIRouter, Depends

from ..schemas import AnalyticsOverview, TopViolatedRule
from ..auth import get_current_user, require_role, TokenData

router = APIRouter(prefix="/analytics", tags=["Analytics"])

@router.get("/admin-overview", summary="Admin cross-district dashboard KPI overview", dependencies=[Depends(require_role("ADMIN"))])
async def get_admin_overview():
    """
    Return dashboard KPIs aggregated across all districts for the ADMIN.
    """
    from .scans import _scan_store
    from .auth_router import _users_by_id
    
    # Generate mock seed data if empty, so the UI has something to show for demo purposes
    if not _scan_store:
        # Mock some aggregates
        return {
            "pass_rate_trend": [
                {"district": "Mumbai North", "data": [{"date": "2026-08-01", "rate": 78}, {"date": "2026-08-15", "rate": 81}]},
                {"district": "Pune Central", "data": [{"date": "2026-08-01", "rate": 82}, {"date": "2026-08-15", "rate": 85}]}
            ],
            "inspector_workload": [
                {"inspector": "rajan", "district": "Mumbai North", "scans": 142},
                {"inspector": "amit", "district": "Pune Central", "scans": 105}
            ],
            "top_violations_by_district": [
                {"district": "Mumbai North", "violations": [{"rule": "6(1)(a)", "count": 45}, {"rule": "6(1)(e)", "count": 32}]},
                {"district": "Pune Central", "violations": [{"rule": "6(1)(e)", "count": 38}, {"rule": "6(1)(h)", "count": 19}]}
            ]
        }

    # Real aggregation logic over _scan_store
    district_pass_counts = {}
    district_total_counts = {}
    inspector_scans = {}
    district_violations = {}

    for session in _scan_store.values():
        user = _users_by_id.get(session.get("user_id"))
        if not user:
            continue
            
        district = user.get("district") or "Unknown"
        username = user.get("username", "Unknown")
        
        # Pass rates
        district_total_counts[district] = district_total_counts.get(district, 0) + 1
        resp = session.get("response")
        if resp and resp.overall_verdict == "PASS":
            district_pass_counts[district] = district_pass_counts.get(district, 0) + 1
            
        # Workload
        if username not in inspector_scans:
            inspector_scans[username] = {"district": district, "scans": 0}
        inspector_scans[username]["scans"] += 1
        
        # Violations
        if district not in district_violations:
            district_violations[district] = {}
            
        if resp:
            for v in resp.violations:
                rule = v.rule_cited
                district_violations[district][rule] = district_violations[district].get(rule, 0) + 1

    # Format response
    # 1. Pass rate trend (just returning a single point for "now" for the demo since we lack historical data)
    pass_rate_trend = []
    for d in district_total_counts:
        rate = round((district_pass_counts.get(d, 0) / district_total_counts[d]) * 100, 1) if district_total_counts[d] > 0 else 0
        pass_rate_trend.append({"district": d, "data": [{"date": "Now", "rate": rate}]})

    # 2. Inspector workload
    inspector_workload = [{"inspector": k, "district": v["district"], "scans": v["scans"]} for k, v in inspector_scans.items()]
    
    # 3. Top violations by district
    top_violations_by_district = []
    for d, rules in district_violations.items():
        sorted_rules = sorted([{"rule": r, "count": c} for r, c in rules.items()], key=lambda x: x["count"], reverse=True)
        top_violations_by_district.append({"district": d, "violations": sorted_rules[:5]})
        
    return {
        "pass_rate_trend": pass_rate_trend,
        "inspector_workload": inspector_workload,
        "top_violations_by_district": top_violations_by_district
    }


@router.get("/overview", response_model=AnalyticsOverview, summary="Dashboard KPI overview")
async def get_overview(
    current_user: TokenData = Depends(require_role("INSPECTOR")),
):
    """
    Return dashboard KPIs: total scans, pass rate, open violations, avg scan time.
    Screen W-01 data source.
    """
    return AnalyticsOverview(
        total_scans=247,
        pass_rate=78.5,
        open_violations=53,
        avg_scan_time_seconds=4.2,
    )


@router.get("/top-violations", response_model=List[TopViolatedRule], summary="Top violated rules")
async def get_top_violations(
    current_user: TokenData = Depends(require_role("INSPECTOR")),
):
    """
    Return top 5 most violated rules. Screen W-01 bar chart data.
    """
    return [
        TopViolatedRule(rule="Rule 7(4)", description="Font Size", count=94, percentage=38),
        TopViolatedRule(rule="Rule 6(1)(e)", description="MRP format", count=69, percentage=28),
        TopViolatedRule(rule="Rule 6(1)(h)", description="Consumer care", count=47, percentage=19),
        TopViolatedRule(rule="Rule 6(11)", description="USP missing", count=30, percentage=12),
        TopViolatedRule(rule="Rule 6(10)", description="E-com listing", count=22, percentage=9),
    ]


@router.get("/compliance-trend", summary="Compliance rate over time")
async def get_compliance_trend(
    days: int = 30,
    current_user: TokenData = Depends(require_role("INSPECTOR")),
):
    """
    Return daily compliance rate for the last N days.
    Screen W-07 line chart data.
    """
    # Simulated trend data
    import random
    random.seed(42)
    return {
        "period_days": days,
        "data": [
            {"date": f"2026-08-{str(i).zfill(2)}", "compliance_rate": round(70 + random.random() * 20, 1)}
            for i in range(1, min(days + 1, 27))
        ]
    }


@router.get("/by-category", summary="Violations by product category")
async def get_violations_by_category(
    current_user: TokenData = Depends(require_role("QA_MANAGER")),
):
    """
    Return violations grouped by product category.
    Screen W-07 pie chart data.
    """
    return [
        {"category": "Food", "percentage": 45, "count": 111},
        {"category": "Cosmetics", "percentage": 30, "count": 74},
        {"category": "Electronics", "percentage": 15, "count": 37},
        {"category": "General", "percentage": 10, "count": 25},
    ]
