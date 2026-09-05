import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MagnifyingGlass, Export, Warning, ArrowClockwise } from '@phosphor-icons/react';
import { useQuery } from '@tanstack/react-query';
import { apiGet } from '../lib/apiClient';

interface ViolationItem {
  violation_id: string;
  scan_id: string;
  violation_code: string;
  rule_cited: string;
  severity: string;
  description: string;
  confidence: number;
  measured_value?: string;
  required_value?: string;
}

export const ViolationsPage: React.FC = () => {
  const [filterSeverity, setFilterSeverity] = useState('ALL');
  const [search, setSearch] = useState('');
  const navigate = useNavigate();

  const violationsQuery = useQuery({
    queryKey: ['violations'],
    queryFn: () => apiGet<ViolationItem[]>('/v1/check/violations'),
  });

  const violations = violationsQuery.data ?? [];
  const filtered = violations.filter(v => {
    const matchesSeverity = filterSeverity === 'ALL' || v.severity === filterSeverity;
    const matchesSearch = !search || v.rule_cited.toLowerCase().includes(search.toLowerCase()) || v.description.toLowerCase().includes(search.toLowerCase());
    return matchesSeverity && matchesSearch;
  });

  const severityBadge = (s: string) => {
    if (s === 'CRITICAL') return 'badge-fail';
    if (s === 'HIGH') return 'badge-warn';
    return 'badge-inconclusive';
  };

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-6)' }}>
        <h2>Violations</h2>
        <button className="btn btn-secondary"><Export size={16} /> Export All</button>
      </div>

      <div className="card" style={{ marginBottom: 'var(--space-6)', padding: 'var(--space-4)' }}>
        <div style={{ display: 'flex', gap: 'var(--space-4)', alignItems: 'center', flexWrap: 'wrap' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 'var(--space-2)',
            background: 'var(--color-surface-2)', borderRadius: 'var(--radius-md)',
            padding: '8px 12px', flex: 1, maxWidth: '300px',
          }}>
            <MagnifyingGlass size={16} color="var(--color-text-tertiary)" />
            <input type="text" placeholder="Search violations…" value={search} onChange={e => setSearch(e.target.value)} style={{
              border: 'none', background: 'transparent', outline: 'none',
              fontFamily: 'inherit', fontSize: '0.875rem', width: '100%',
              color: 'var(--color-text-primary)',
            }} />
          </div>
          <div className="filter-chips">
            {['ALL', 'CRITICAL', 'HIGH', 'MEDIUM'].map(s => (
              <button key={s} className={`filter-chip ${filterSeverity === s ? 'active' : ''}`} onClick={() => setFilterSeverity(s)}>
                {s === 'ALL' ? 'All' : s}
              </button>
            ))}
          </div>
          <span style={{ color: 'var(--color-text-tertiary)', fontSize: '0.75rem' }}>
            {filtered.length} violations
          </span>
        </div>
      </div>

      {violationsQuery.isLoading && (
        <div className="card" style={{ padding: 0 }}>
          {[1, 2, 3, 4].map(i => (
            <div key={i} style={{ padding: 'var(--space-3) var(--space-4)', borderBottom: '1px solid var(--color-surface-3)' }}>
              <div className="skeleton skeleton-row" />
            </div>
          ))}
        </div>
      )}

      {violationsQuery.isError && (
        <div className="error-state">
          <div className="error-state-icon">⚠️</div>
          <h3>Failed to load violations</h3>
          <p>Could not retrieve violation data.</p>
          <button className="btn btn-primary" onClick={() => violationsQuery.refetch()}>
            <ArrowClockwise size={16} /> Retry
          </button>
        </div>
      )}

      {violationsQuery.isSuccess && (
        <div className="card fade-in-up" style={{ padding: 0, overflow: 'hidden' }}>
          {filtered.length > 0 ? (
            <table className="data-table data-table-responsive">
              <thead>
                <tr>
                  <th style={{ width: 40 }}><input type="checkbox" aria-label="Select all" /></th>
                  <th>Rule</th>
                  <th>Severity</th>
                  <th>Description</th>
                  <th>Confidence</th>
                  <th>Scan</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(v => (
                  <tr key={v.violation_id} style={{ cursor: 'pointer' }} onClick={() => navigate(`/dashboard/scan/${v.scan_id}`)}>
                    <td data-label="" onClick={e => e.stopPropagation()}><input type="checkbox" aria-label={`Select ${v.violation_code}`} /></td>
                    <td data-label="Rule">
                      <div>
                        <span className="mono" style={{ fontWeight: 600 }}>{v.rule_cited}</span>
                        <div style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)' }}>{v.violation_code}</div>
                      </div>
                    </td>
                    <td data-label="Severity"><span className={`badge ${severityBadge(v.severity)}`}>{v.severity}</span></td>
                    <td data-label="Description" style={{ maxWidth: 300 }}>{v.description}</td>
                    <td data-label="Confidence" style={{ color: 'var(--color-text-tertiary)', fontSize: '0.75rem' }}>{(v.confidence * 100).toFixed(0)}%</td>
                    <td data-label="Scan" className="mono" style={{ fontSize: '0.75rem' }}>{v.scan_id.substring(0, 8)}…</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="empty-state">
              <div className="empty-state-icon"><Warning size={48} /></div>
              <h3>No violations found</h3>
              <p>{search || filterSeverity !== 'ALL' ? 'Try adjusting your filters' : 'All products are currently compliant'}</p>
            </div>
          )}
        </div>
      )}
    </>
  );
};
