import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, DownloadSimple, Flag, Export, ArrowClockwise, CheckCircle, XCircle, WarningCircle, Question } from '@phosphor-icons/react';
import { apiGet } from '../lib/apiClient';

interface ViolationDetail {
  violation_id: string;
  violation_code: string;
  check_id: string;
  rule_cited: string;
  amendment_basis?: string;
  severity: string;
  field_name?: string;
  description: string;
  measured_value?: string;
  required_value?: string;
  confidence: number;
  bounding_box?: { x: number; y: number; width: number; height: number };
  crop_url?: string;
  remediation?: string;
}

interface ScanReport {
  scan_id: string;
  status: string;
  overall_verdict: string;
  overall_confidence: number;
  violation_count: { critical: number; high: number; medium: number; inconclusive: number };
  violations: ViolationDetail[];
  generated_at?: string;
  rule_version?: string;
}

const verdictConfig: Record<string, { class: string; icon: React.ElementType; label: string }> = {
  PASS: { class: 'pass', icon: CheckCircle, label: 'PASS' },
  FAIL: { class: 'fail', icon: XCircle, label: 'FAIL' },
  WARN: { class: 'warn', icon: WarningCircle, label: 'WARN' },
  INCONCLUSIVE: { class: 'inconclusive', icon: Question, label: 'INCONCLUSIVE' },
};

export const ScanDetailPage: React.FC = () => {
  const { scanId } = useParams<{ scanId: string }>();
  const navigate = useNavigate();
  const [filterVerdict, setFilterVerdict] = useState('ALL');

  const reportQuery = useQuery({
    queryKey: ['report', scanId],
    queryFn: () => apiGet<ScanReport>(`/v1/report/${scanId}`),
    enabled: !!scanId,
  });

  const report = reportQuery.data;
  const vc = report ? verdictConfig[report.overall_verdict] || verdictConfig.INCONCLUSIVE : null;

  const violations = report?.violations ?? [];
  const filteredViolations = violations.filter(v => {
    if (filterVerdict === 'ALL') return true;
    if (filterVerdict === 'FAIL') return v.severity === 'CRITICAL' || v.severity === 'HIGH';
    if (filterVerdict === 'WARN') return v.severity === 'MEDIUM';
    return true;
  });

  const totalChecks = violations.length || 28;
  const passedChecks = totalChecks - (report?.violation_count?.critical ?? 0) - (report?.violation_count?.high ?? 0) - (report?.violation_count?.medium ?? 0);
  const scorePercent = Math.round((passedChecks / totalChecks) * 100);

  const handleDownloadPdf = () => {
    window.open(`${import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'}/v1/report/${scanId}/pdf`, '_blank');
  };

  return (
    <>
      {/* Back navigation */}
      <button
        className="btn btn-secondary"
        onClick={() => navigate(-1)}
        style={{ marginBottom: 'var(--space-4)', fontSize: '0.8125rem' }}
      >
        <ArrowLeft size={16} /> Back
      </button>

      {/* Loading */}
      {reportQuery.isLoading && (
        <div className="card">
          <div className="skeleton skeleton-heading" />
          <div className="skeleton skeleton-chart" style={{ marginTop: 16 }} />
          {[1, 2, 3].map(i => (
            <div key={i} className="skeleton skeleton-row" style={{ marginTop: 12 }} />
          ))}
        </div>
      )}

      {/* Error */}
      {reportQuery.isError && (
        <div className="error-state">
          <div className="error-state-icon">⚠️</div>
          <h3>Failed to load scan report</h3>
          <p>Scan ID: <code className="mono">{scanId}</code></p>
          <button className="btn btn-primary" onClick={() => reportQuery.refetch()}>
            <ArrowClockwise size={16} /> Retry
          </button>
        </div>
      )}

      {/* Report */}
      {report && vc && (
        <>
          {/* Hero Verdict Card */}
          <div className="card fade-in-up" style={{ marginBottom: 'var(--space-6)' }}>
            <div className="verdict-hero">
              <div className={`verdict-badge-lg ${vc.class}`}>
                <vc.icon size={28} weight="fill" />
                {vc.label}
              </div>
              <div style={{ fontSize: '0.875rem', color: 'var(--color-text-secondary)', marginBottom: 'var(--space-3)' }}>
                Compliance Score
              </div>
              <div style={{ fontSize: '3rem', fontWeight: 700, color: 'var(--color-text-primary)', lineHeight: 1 }}>
                {scorePercent}%
              </div>
              <div style={{ fontSize: '0.8125rem', color: 'var(--color-text-tertiary)', marginTop: 'var(--space-1)' }}>
                {passedChecks}/{totalChecks} checks passed • Confidence: {(report.overall_confidence * 100).toFixed(0)}%
              </div>
            </div>

            {/* Violation Count Summary */}
            <div style={{ display: 'flex', justifyContent: 'center', gap: 'var(--space-6)', paddingTop: 'var(--space-4)', borderTop: '1px solid var(--color-surface-3)' }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--color-fail)' }}>{report.violation_count.critical}</div>
                <div style={{ fontSize: '0.6875rem', color: 'var(--color-text-tertiary)', textTransform: 'uppercase' }}>Critical</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--color-warn)' }}>{report.violation_count.high}</div>
                <div style={{ fontSize: '0.6875rem', color: 'var(--color-text-tertiary)', textTransform: 'uppercase' }}>High</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--color-brand-secondary)' }}>{report.violation_count.medium}</div>
                <div style={{ fontSize: '0.6875rem', color: 'var(--color-text-tertiary)', textTransform: 'uppercase' }}>Medium</div>
              </div>
            </div>
          </div>

          {/* Action Bar */}
          <div style={{ display: 'flex', gap: 'var(--space-3)', marginBottom: 'var(--space-6)', flexWrap: 'wrap' }}>
            <button className="btn btn-primary" onClick={handleDownloadPdf}>
              <DownloadSimple size={16} /> Download PDF Report
            </button>
            <button className="btn btn-secondary">
              <Export size={16} /> Export JSON
            </button>
            <button className="btn btn-secondary">
              <Flag size={16} /> Flag for Review
            </button>
          </div>

          {/* Filter Tabs */}
          <div className="card" style={{ marginBottom: 'var(--space-4)', padding: 'var(--space-3)' }}>
            <div className="filter-chips">
              {[
                { key: 'ALL', label: `All (${violations.length})` },
                { key: 'FAIL', label: `FAIL (${(report.violation_count.critical || 0) + (report.violation_count.high || 0)})` },
                { key: 'WARN', label: `WARN (${report.violation_count.medium || 0})` },
              ].map(f => (
                <button key={f.key} className={`filter-chip ${filterVerdict === f.key ? 'active' : ''}`} onClick={() => setFilterVerdict(f.key)}>
                  {f.label}
                </button>
              ))}
            </div>
          </div>

          {/* Violation Details */}
          {filteredViolations.length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-3)' }}>
              {filteredViolations.map((v) => (
                <div key={v.violation_id} className="card fade-in-up" style={{ padding: 'var(--space-4)' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 'var(--space-2)' }}>
                    <div>
                      <span className={`badge ${v.severity === 'CRITICAL' ? 'badge-fail' : v.severity === 'HIGH' ? 'badge-warn' : 'badge-inconclusive'}`}>
                        {v.severity}
                      </span>
                      <span className="mono" style={{ marginLeft: 'var(--space-2)', fontWeight: 600 }}>{v.rule_cited}</span>
                    </div>
                    <span style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)' }}>
                      Confidence: {(v.confidence * 100).toFixed(0)}%
                    </span>
                  </div>
                  <p style={{ fontWeight: 500, marginBottom: 'var(--space-2)' }}>{v.description}</p>
                  {(v.measured_value || v.required_value) && (
                    <div style={{ display: 'flex', gap: 'var(--space-6)', fontSize: '0.8125rem', color: 'var(--color-text-secondary)' }}>
                      {v.measured_value && <div><strong>Found:</strong> {v.measured_value}</div>}
                      {v.required_value && <div><strong>Required:</strong> {v.required_value}</div>}
                    </div>
                  )}
                  {v.remediation && (
                    <div style={{
                      marginTop: 'var(--space-3)', padding: 'var(--space-3)',
                      background: 'var(--color-surface-2)', borderRadius: 'var(--radius-md)',
                      fontSize: '0.8125rem', color: 'var(--color-text-secondary)',
                    }}>
                      💡 <strong>Fix:</strong> {v.remediation}
                    </div>
                  )}
                </div>
              ))}
            </div>
          ) : (
            <div className="card">
              <div className="empty-state">
                <CheckCircle size={48} color="var(--color-pass)" />
                <h3>All checks passed</h3>
                <p>No violations found for this filter</p>
              </div>
            </div>
          )}

          {/* Metadata */}
          <div className="card" style={{ marginTop: 'var(--space-6)', background: 'var(--color-surface-2)' }}>
            <div className="mono" style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)', display: 'flex', gap: 'var(--space-6)', flexWrap: 'wrap' }}>
              <span>Scan ID: {report.scan_id}</span>
              <span>Rules: v{report.rule_version || '2024.01'}</span>
              {report.generated_at && <span>Generated: {report.generated_at}</span>}
            </div>
          </div>
        </>
      )}
    </>
  );
};
