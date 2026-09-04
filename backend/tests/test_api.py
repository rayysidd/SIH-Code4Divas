from fastapi.testclient import TestClient
from api.main import app
import uuid

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "version": "1.0.0", "rules_version": "LMPC-2026-GSR128E"}

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "LabelLens API" in response.json()["service"]


# ── Registration Role Determination Tests ────────────────────────────────────

def test_register_no_code_non_platform_email_gets_citizen():
    """No invite code + non-platform email → CITIZEN"""
    uid = str(uuid.uuid4())[:8]
    response = client.post("/v1/auth/register", json={
        "username": f"test_citizen_{uid}",
        "password": "pass123",
        "full_name": "Test Citizen",
        "email": f"test_{uid}@gmail.com",
    })
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "CITIZEN"
    assert "access_token" in data
    assert "Citizen" in data["message"]


def test_register_admin_role_in_body_but_no_code_gets_citizen():
    """Even if role=ADMIN in body, without invite code → CITIZEN"""
    uid = str(uuid.uuid4())[:8]
    response = client.post("/v1/auth/register", json={
        "username": f"test_admin_wannabe_{uid}",
        "password": "pass123",
        "full_name": "Wannabe Admin",
        "email": f"admin_{uid}@personal.com",
        "role": "ADMIN",
    })
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "CITIZEN"


def test_register_platform_email_gets_ecom_lead():
    """Email from trusted platform domain → ECOM_LEAD"""
    uid = str(uuid.uuid4())[:8]
    response = client.post("/v1/auth/register", json={
        "username": f"test_ecom_{uid}",
        "password": "pass123",
        "full_name": "Platform Lead",
        "email": f"seller_{uid}@amazon.in",
    })
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "ECOM_LEAD"
    assert "Platform Lead" in data["message"]


def test_register_valid_inspector_invite_code():
    """Valid INSPECTOR invite code → INSPECTOR with district from invite"""
    uid = str(uuid.uuid4())[:8]
    
    # Create an invite code as admin
    token = _get_admin_token()
    gen_res = client.post(
        "/v1/auth/invite-codes",
        json={"role": "INSPECTOR", "district": "Mumbai North"},
        headers={"Authorization": f"Bearer {token}"},
    )
    code = gen_res.json()["invite_code"]

    response = client.post("/v1/auth/register", json={
        "username": f"test_inspector_{uid}",
        "password": "pass123",
        "full_name": "New Inspector",
        "email": f"inspector_{uid}@gov.in",
        "invite_code": code,
    })
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "INSPECTOR"
    assert data["district"] == "Mumbai North"
    assert "access_token" in data
    
    # Test that it can't be reused
    uid2 = str(uuid.uuid4())[:8]
    response2 = client.post("/v1/auth/register", json={
        "username": f"test_inspector_{uid2}",
        "password": "pass123",
        "full_name": "Another Inspector",
        "email": f"inspector2_{uid2}@gov.in",
        "invite_code": code,
    })
    assert response2.status_code == 400
    assert "already been used" in response2.json()["detail"]


def test_register_invalid_invite_code_rejected():
    """Non-existent invite code → 400"""
    uid = str(uuid.uuid4())[:8]
    response = client.post("/v1/auth/register", json={
        "username": f"test_bad_code_{uid}",
        "password": "pass123",
        "full_name": "Bad Code User",
        "email": f"bad_{uid}@example.com",
        "invite_code": "FAKE-CODE-12345",
    })
    assert response.status_code == 400
    assert "Invalid invite code" in response.json()["detail"]


def test_register_expired_invite_code_rejected():
    """Expired invite code → 400"""
    from datetime import datetime, timedelta
    from sqlalchemy.orm import Session
    from api.database import SessionLocal
    from api.models import InviteCode, User

    db = SessionLocal()
    admin_user = db.query(User).filter(User.username == "admin").first()
    code = "EXPIRED-CODE-" + str(uuid.uuid4())[:4]
    
    expired = InviteCode(
        code=code,
        role="INSPECTOR",
        issued_by=admin_user.user_id,
        expires_at=datetime.utcnow() - timedelta(days=1)
    )
    db.add(expired)
    db.commit()

    uid = str(uuid.uuid4())[:8]
    response = client.post("/v1/auth/register", json={
        "username": f"test_expired_{uid}",
        "password": "pass123",
        "full_name": "Expired Code User",
        "email": f"expired_{uid}@example.com",
        "invite_code": code,
    })
    assert response.status_code == 400
    assert "expired" in response.json()["detail"]


def test_register_duplicate_username_rejected():
    """Duplicate username → 400"""
    uid = str(uuid.uuid4())[:8]
    email = f"dup_{uid}@example.com"
    response = client.post("/v1/auth/register", json={
        "username": "admin",  # already exists
        "password": "pass123",
        "full_name": "Duplicate Admin",
        "email": email,
    })
    assert response.status_code == 400
    assert "already exists" in response.json()["detail"]


# ── Invite Code Generation Tests ────────────────────────────────────────────

def _get_admin_token():
    """Helper to login as admin and get access token."""
    res = client.post("/v1/auth/login", json={
        "username": "admin",
        "password": "admin123",
    })
    return res.json()["access_token"]


def test_generate_invite_code_as_admin():
    """ADMIN can generate invite codes."""
    token = _get_admin_token()
    response = client.post(
        "/v1/auth/invite-codes",
        json={"role": "INSPECTOR", "district": "Delhi South"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "INSPECTOR"
    assert data["district"] == "Delhi South"
    assert "invite_code" in data


def test_generate_invite_code_as_non_admin_rejected():
    """Non-ADMIN cannot generate invite codes → 403"""
    # Create an inspector user first
    uid = str(uuid.uuid4())[:8]
    token_admin = _get_admin_token()
    gen_res = client.post(
        "/v1/auth/invite-codes",
        json={"role": "INSPECTOR", "district": "Delhi South"},
        headers={"Authorization": f"Bearer {token_admin}"},
    )
    code = gen_res.json()["invite_code"]
    
    reg_res = client.post("/v1/auth/register", json={
        "username": f"rajan_{uid}",
        "password": "inspector123",
        "full_name": "Rajan",
        "email": f"rajan_{uid}@gov.in",
        "invite_code": code,
    })
    token = reg_res.json()["access_token"]

    response = client.post(
        "/v1/auth/invite-codes",
        json={"role": "INSPECTOR"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 403


def test_list_invite_codes_as_admin():
    """ADMIN can list all invite codes."""
    token = _get_admin_token()
    response = client.get(
        "/v1/auth/invite-codes",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 0


def test_delete_invite_code_as_admin():
    """ADMIN can revoke an unused invite code."""
    token = _get_admin_token()
    
    # Generate a code first
    gen_res = client.post(
        "/v1/auth/invite-codes",
        json={"role": "QA_MANAGER", "district": "Test District"},
        headers={"Authorization": f"Bearer {token}"},
    )
    code = gen_res.json()["invite_code"]

    # Delete the code
    del_res = client.delete(
        f"/v1/auth/invite-codes/{code}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert del_res.status_code == 200

    # Try to register with it (should fail)
    uid = str(uuid.uuid4())[:8]
    reg_res = client.post("/v1/auth/register", json={
        "username": f"test_revoked_{uid}",
        "password": "pass123",
        "full_name": "Revoked Code User",
        "email": f"revoked_{uid}@example.com",
        "invite_code": code,
    })
    assert reg_res.status_code == 400


def test_delete_used_invite_code_rejected():
    """Revoking an already used invite code should fail."""
    token = _get_admin_token()
    
    gen_res = client.post(
        "/v1/auth/invite-codes",
        json={"role": "INSPECTOR", "district": "Test District"},
        headers={"Authorization": f"Bearer {token}"},
    )
    code = gen_res.json()["invite_code"]
    
    uid = str(uuid.uuid4())[:8]
    client.post("/v1/auth/register", json={
        "username": f"test_inspector_{uid}",
        "password": "pass123",
        "full_name": "New Inspector",
        "email": f"inspector_{uid}@gov.in",
        "invite_code": code,
    })
    
    del_res = client.delete(
        f"/v1/auth/invite-codes/{code}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert del_res.status_code == 400
    assert "already used" in del_res.json()["detail"].lower()


def test_registered_user_can_fetch_profile():
    """Newly registered user can call /me with the returned token."""
    uid = str(uuid.uuid4())[:8]
    reg_res = client.post("/v1/auth/register", json={
        "username": f"test_profile_check_{uid}",
        "password": "pass123",
        "full_name": "Profile Checker",
        "email": f"profile_{uid}@test.com",
    })
    token = reg_res.json()["access_token"]

    me_res = client.get(
        "/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert me_res.status_code == 200
    data = me_res.json()
    assert data["username"] == f"test_profile_check_{uid}"
    assert data["role"] == "CITIZEN"


def test_get_users_as_admin():
    """ADMIN can fetch user list."""
    token = _get_admin_token()
    res = client.get("/v1/auth/users", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    users = res.json()
    assert isinstance(users, list)
    assert len(users) >= 1
    assert "password_hash" not in users[0]
    assert "username" in users[0]


def test_get_audit_log_as_admin():
    """ADMIN can fetch audit log."""
    token = _get_admin_token()
    res = client.get("/v1/auth/audit-log", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    logs = res.json()
    assert isinstance(logs, list)
    assert len(logs) >= 1
    assert "action" in logs[0]

# ── ML Pipeline & Rules Engine Tests ─────────────────────────────────────────

def test_mrp_detection():
    """Test that MRP is detected and format is validated"""
    from ml.rules_engine import evaluate_compliance
    
    # Mock data simulating a successful MRP OCR extraction
    declarations = {
        "MRP": {
            "present": True,
            "raw_text": "MRP Rs. 99.00",
            "physical_size_mm": 2.5,
            "taxes_included_suffix": True
        }
    }
    
    result = evaluate_compliance(declarations, pdp_area_cm2=75.0)
    
    # V001/V002 shouldn't trigger if present and has suffix
    violations = [v["violation_id"] for v in result["violations"]]
    assert "V001" not in violations
    assert "V002" not in violations

def test_font_size_table_i():
    """Test Table I tier selection based on PDP area"""
    from ml.rules_engine import get_min_font_height_mm
    
    # < 50cm2 -> 1.0mm
    assert get_min_font_height_mm(40.0) == 1.0
    # 50 - 100cm2 -> 2.0mm
    assert get_min_font_height_mm(75.0) == 2.0
    # 100 - 500cm2 -> 4.0mm
    assert get_min_font_height_mm(250.0) == 4.0
    # > 500cm2 -> 6.0mm
    assert get_min_font_height_mm(600.0) == 6.0

def test_rule_6_10_ecommerce():
    """Test e-commerce mandatory declaration check (GSR 128(E))"""
    from ml.rules_engine import evaluate_compliance
    
    declarations = {
        "COUNTRY_OF_ORIGIN": {"present": True}
    }
    
    # Imported, no filter -> should fail
    result_fail = evaluate_compliance(
        declarations, 
        is_imported=True, 
        ecommerce_has_coo_filter=False
    )
    violations = [v["violation_id"] for v in result_fail["violations"]]
    assert "V008" in violations
    
    # Imported, has filter -> should pass
    result_pass = evaluate_compliance(
        declarations, 
        is_imported=True, 
        ecommerce_has_coo_filter=True
    )
    violations = [v["violation_id"] for v in result_pass["violations"]]
    assert "V008" not in violations
