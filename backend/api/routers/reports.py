"""
/v1/report/* — Report generation and retrieval endpoints.
Implements: GET /report/{scan_id}, GET /report/{scan_id}/pdf
"""

import os
import tempfile
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from ..schemas import ScanResponse, ViolationCountSummary, ViolationResponse, SeverityEnum, VerdictEnum
from ..auth import get_current_user, TokenData
from ..database import get_db
from ..models import ScanSession, Violation, ScanTask
from .scans import _scan_store

router = APIRouter(prefix="/report", tags=["Reports"])

@router.get("/{scan_id}", summary="Get full scan report as JSON")
async def get_report(
    scan_id: str,
    current_user: TokenData = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retrieve full scan report as JSON.
    SRS Appendix A — GET /report/{scan_id}
    """
    if scan_id in _scan_store and "response" in _scan_store[scan_id]:
        return _scan_store[scan_id]["response"]

    session = db.query(ScanSession).filter(ScanSession.scan_id == scan_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Scan not found")
        
    task = db.query(ScanTask).filter(ScanTask.scan_id == scan_id).first()
    db_violations = db.query(Violation).filter(Violation.scan_id == scan_id).all()
    
    violations_resp = []
    for v in db_violations:
        violations_resp.append({
            "violation_id": v.violation_id,
            "violation_code": v.violation_code,
            "check_id": v.check_id,
            "rule_cited": v.rule_cited,
            "severity": v.severity,
            "description": v.description,
            "confidence": v.confidence,
            "measured_value": v.get("measured_value") if hasattr(v, "get") else getattr(v, "measured_value", None),
            "required_value": v.get("required_value") if hasattr(v, "get") else getattr(v, "required_value", None),
        })
        
    critical = sum(1 for v in db_violations if v.severity == "CRITICAL")
    high = sum(1 for v in db_violations if v.severity == "HIGH")
    medium = sum(1 for v in db_violations if v.severity == "MEDIUM")
    
    return {
        "scan_id": scan_id,
        "status": task.status if task else "COMPLETED",
        "overall_verdict": session.overall_verdict,
        "overall_confidence": session.overall_confidence,
        "violation_count": {"critical": critical, "high": high, "medium": medium, "inconclusive": 0},
        "violations": violations_resp,
        "declarations": {},
        "generated_at": session.created_at.isoformat() if session.created_at else None,
        "rule_version": session.rule_version,
    }


@router.get("/{scan_id}/pdf", summary="Download PDF report")
async def get_report_pdf(
    scan_id: str,
    current_user: TokenData = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Download PDF report.
    SRS Appendix A — GET /report/{scan_id}/pdf
    """
    report_data = None
    if scan_id in _scan_store and "response" in _scan_store[scan_id]:
        resp = _scan_store[scan_id]["response"]
        if hasattr(resp, 'model_dump'):
            report_data = resp.model_dump()
        else:
            report_data = resp.dict()
            
    if not report_data:
        session = db.query(ScanSession).filter(ScanSession.scan_id == scan_id).first()
        if not session:
            raise HTTPException(status_code=404, detail="Scan not found")
        
        db_violations = db.query(Violation).filter(Violation.scan_id == scan_id).all()
        critical = sum(1 for v in db_violations if v.severity == "CRITICAL")
        high = sum(1 for v in db_violations if v.severity == "HIGH")
        medium = sum(1 for v in db_violations if v.severity == "MEDIUM")
        
        violations_resp = []
        for v in db_violations:
            violations_resp.append({
                "violation_code": v.violation_code,
                "rule_cited": v.rule_cited,
                "severity": v.severity,
                "description": v.description,
                "measured_value": getattr(v, "measured_value", None),
                "required_value": getattr(v, "required_value", None),
                "remediation": getattr(v, "remediation", None)
            })
            
        report_data = {
            "scan_id": scan_id,
            "overall_verdict": session.overall_verdict,
            "overall_confidence": session.overall_confidence,
            "violation_count": {"critical": critical, "high": high, "medium": medium, "inconclusive": 0},
            "violations": violations_resp,
            "generated_at": session.created_at.strftime("%Y-%m-%d %H:%M:%S") if session.created_at else "Unknown"
        }
    else:
        report_data["generated_at"] = _scan_store[scan_id].get("timestamp", "Unknown")
        
    try:
        from reportlab.lib.pagesizes import letter
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib import colors
        
        tmp_dir = os.path.join(tempfile.gettempdir(), "labellens_reports")
        os.makedirs(tmp_dir, exist_ok=True)
        pdf_path = os.path.join(tmp_dir, f"labellens_report_{scan_id}.pdf")
        
        doc = SimpleDocTemplate(pdf_path, pagesize=letter)
        styles = getSampleStyleSheet()
        elements = []
        
        elements.append(Paragraph("LabelLens Compliance Report", styles['Title']))
        elements.append(Spacer(1, 12))
        elements.append(Paragraph(f"Scan ID: {scan_id}", styles['Normal']))
        elements.append(Paragraph(f"Generated At: {report_data.get('generated_at', '')}", styles['Normal']))
        elements.append(Spacer(1, 24))
        
        verdict = report_data.get('overall_verdict', 'UNKNOWN')
        if isinstance(verdict, Enum):
            verdict = verdict.value
            
        v_color = colors.red if verdict == 'FAIL' else colors.green if verdict == 'PASS' else colors.orange
        verdict_style = ParagraphStyle('Verdict', parent=styles['Heading2'], textColor=v_color)
        elements.append(Paragraph(f"Overall Verdict: {verdict}", verdict_style))
        elements.append(Paragraph(f"Confidence: {report_data.get('overall_confidence', 0)*100:.1f}%", styles['Normal']))
        
        vc = report_data.get('violation_count', {})
        elements.append(Paragraph(f"Violations - Critical: {vc.get('critical', 0)}, High: {vc.get('high', 0)}, Medium: {vc.get('medium', 0)}", styles['Normal']))
        elements.append(Spacer(1, 24))
        
        elements.append(Paragraph("Violations Details", styles['Heading3']))
        elements.append(Spacer(1, 12))
        
        data = [['Rule Cited', 'Severity', 'Description', 'Measured', 'Required']]
        for v in report_data.get('violations', []):
            if isinstance(v, dict):
                sev = v.get('severity', '')
                if isinstance(sev, Enum): sev = sev.value
                data.append([
                    v.get('rule_cited', ''),
                    sev,
                    Paragraph(v.get('description', ''), styles['Normal']),
                    v.get('measured_value', 'N/A') or 'N/A',
                    v.get('required_value', 'N/A') or 'N/A'
                ])
            else:
                sev = getattr(v, 'severity', '')
                if isinstance(sev, Enum): sev = sev.value
                data.append([
                    getattr(v, 'rule_cited', ''),
                    sev,
                    Paragraph(getattr(v, 'description', ''), styles['Normal']),
                    getattr(v, 'measured_value', 'N/A') or 'N/A',
                    getattr(v, 'required_value', 'N/A') or 'N/A'
                ])
                
        if len(data) > 1:
            t = Table(data, colWidths=[100, 60, 200, 80, 80])
            t.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0, 0), (-1, -1), 1, colors.black)
            ]))
            elements.append(t)
        else:
            elements.append(Paragraph("No violations found.", styles['Normal']))
            
        elements.append(Spacer(1, 48))
        elements.append(Paragraph("Generated by LabelLens SIH26034 — Legal Metrology Compliance Tool", styles['Italic']))
        
        doc.build(elements)
        
        return FileResponse(
            path=pdf_path,
            filename=f"labellens_report_{scan_id}.pdf",
            media_type="application/pdf"
        )
    except ImportError:
        raise HTTPException(status_code=500, detail="PDF generation library (reportlab) not installed.")
    except Exception as e:
        print(f"Error generating PDF: {e}")
        raise HTTPException(status_code=500, detail="Error generating PDF report")
