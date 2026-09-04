import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MagnifyingGlass, Export, Warning, ArrowClockwise } from '@phosphor-icons/react';
import { useQuery } from '@tanstack/react-query';
import { } from '../lib/apiClient';

export const ViolationsPage: React.FC = () => {
  const [filterSeverity, setFilterSeverity] = useState('ALL');
  const [search, setSearch] = useState('');
  const navigate = useNavigate();

  const violationsQuery = useQuery({
    queryKey: ['violations'],
    queryFn: async () => {
      // Simulated violations — in production, from GET /v1/violations
      return [
        { id: 'v1', product: 'Sunflower Oil 1L', rule: 'Rule 6(1)(e)', desc: 'MRP — "Inclusive of all taxes" missing', severity: 'CRITICAL', category: 'Food', status: 'Open', date: '26 Aug 2026', scanId: '1' },
        { id: 'v2', product: 'Sunflower Oil 1L', rule: 'Rule 7(4)', desc: 'Numeral height 1.8mm < 2.5mm required', severity: 'HIGH', category: 'Food', status: 'Open', date: '26 Aug 2026', scanId: '1' },
        { id: 'v3', product: 'Sunflower Oil 1L', rule: 'Rule 6(1)(h)', desc: 'Customer care details absent', severity: 'CRITICAL', category: 'Food', status: 'Open', date: '26 Aug 2026', scanId: '1' },
        { id: 'v4', product: 'Soap Bar 100g', rule: 'Rule 6(11)', desc: 'Unit sale price not declared', severity: 'HIGH', category: 'Cosmetics', status: 'In Review', date: '25 Aug 2026', scanId: '5' },
        { id: 'v5', product: 'Face Cream 50ml', rule: 'Rule 6(1)(e)', desc: 'MRP format incorrect', severity: 'MEDIUM', category: 'Cosmetics', status: 'Resolved', date: '24 Aug 2026', scanId: '3' },
      ];
    },
  });

  const violations = violationsQuery.data ?? [];
  const filtered = violations.filter(v => {
    const matchesSeverity = filterSeverity === 'ALL' || v.severity === filterSeverity;
    const matchesSearch = !search || v.product.toLowerCase().includes(search.toLowerCase()) || v.rule.toLowerCase().includes(search.toLowerCase());
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
                  <th>Product</th>
                  <th>Rule</th>
                  <th>Severity</th>
                  <th>Category</th>
                  <th>Status</th>
                  <th>Detected</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(v => (
                  <tr key={v.id} style={{ cursor: 'pointer' }} onClick={() => navigate(`/dashboard/scan/${v.scanId}`)}>
                    <td data-label="" onClick={e => e.stopPropagation()}><input type="checkbox" aria-label={`Select ${v.product}`} /></td>
                    <td data-label="Product" style={{ fontWeight: 500 }}>{v.product}</td>
                    <td data-label="Rule">
                      <div>
                        <span className="mono" style={{ fontWeight: 600 }}>{v.rule}</span>
                        <div style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)' }}>{v.desc}</div>
                      </div>
                    </td>
                    <td data-label="Severity"><span className={`badge ${severityBadge(v.severity)}`}>{v.severity}</span></td>
                    <td data-label="Category">{v.category}</td>
                    <td data-label="Status">
                      <span style={{
                        fontSize: '0.75rem', fontWeight: 500,
                        color: v.status === 'Open' ? 'var(--color-warn)' : v.status === 'Resolved' ? 'var(--color-pass)' : 'var(--color-brand-secondary)'
                      }}>
                        {v.status}
                      </span>
                    </td>
                    <td data-label="Detected" style={{ color: 'var(--color-text-tertiary)', fontSize: '0.75rem' }}>{v.date}</td>
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
