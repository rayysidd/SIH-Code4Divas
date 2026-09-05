import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MagnifyingGlass, Plus, UploadSimple, DotsThree, Package, ArrowClockwise } from '@phosphor-icons/react';
import { useQuery } from '@tanstack/react-query';
import { apiGet } from '../lib/apiClient';

interface ScanProduct {
  scan_id: string;
  overall_verdict: string;
  overall_confidence: number;
  created_at: string;
  rule_version?: string;
}

/* ── Page Component (Screen W-02) ─────────────────────────────────────── */

export const ProductsPage: React.FC = () => {
  const [search, setSearch] = useState('');
  const [filterVerdict, setFilterVerdict] = useState('ALL');
  const navigate = useNavigate();

  const scansQuery = useQuery({
    queryKey: ['products'],
    queryFn: () => apiGet<ScanProduct[]>('/v1/check/scans'),
  });

  const products = scansQuery.data ?? [];
  const filtered = products.filter(p => {
    const matchesSearch = !search || p.scan_id.toLowerCase().includes(search.toLowerCase());
    const matchesVerdict = filterVerdict === 'ALL' || p.overall_verdict === filterVerdict;
    return matchesSearch && matchesVerdict;
  });

  return (
    <>
      {/* Page Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-6)' }}>
        <h2>Products</h2>
        <div style={{ display: 'flex', gap: 'var(--space-3)' }}>
          <button className="btn btn-secondary" onClick={() => navigate('/dashboard/scan/new')}><Plus size={16} /> New Scan</button>
          <button className="btn btn-primary" onClick={() => navigate('/dashboard/batch')}><UploadSimple size={16} /> Bulk Upload</button>
        </div>
      </div>

      {/* Filters */}
      <div className="card" style={{ marginBottom: 'var(--space-6)', padding: 'var(--space-4)' }}>
        <div style={{ display: 'flex', gap: 'var(--space-4)', alignItems: 'center', flexWrap: 'wrap' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 'var(--space-2)',
            background: 'var(--color-surface-2)', borderRadius: 'var(--radius-md)',
            padding: '8px 12px', flex: 1, maxWidth: '400px',
          }}>
            <MagnifyingGlass size={16} color="var(--color-text-tertiary)" />
            <input
              type="text"
              placeholder="Search products by name or GTIN…"
              value={search}
              onChange={e => setSearch(e.target.value)}
              style={{
                border: 'none', background: 'transparent', outline: 'none',
                fontFamily: 'inherit', fontSize: '0.875rem', width: '100%',
                color: 'var(--color-text-primary)',
              }}
            />
          </div>
          <div className="filter-chips">
            {['ALL', 'PASS', 'FAIL', 'WARN', 'INCONCLUSIVE'].map(v => (
              <button key={v} className={`filter-chip ${filterVerdict === v ? 'active' : ''}`} onClick={() => setFilterVerdict(v)}>
                {v === 'ALL' ? 'All' : v}
              </button>
            ))}
          </div>
          <span style={{ color: 'var(--color-text-tertiary)', fontSize: '0.75rem' }}>
            {filtered.length} of {products.length} products
          </span>
        </div>
      </div>

      {/* Loading */}
      {scansQuery.isLoading && (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {[1, 2, 3, 4, 5].map(i => (
            <div key={i} style={{ padding: 'var(--space-3) var(--space-4)', borderBottom: '1px solid var(--color-surface-3)' }}>
              <div className="skeleton skeleton-row" />
            </div>
          ))}
        </div>
      )}

      {/* Error */}
      {scansQuery.isError && (
        <div className="error-state">
          <div className="error-state-icon">⚠️</div>
          <h3>Failed to load products</h3>
          <p>Could not fetch product data from the server.</p>
          <button className="btn btn-primary" onClick={() => scansQuery.refetch()}>
            <ArrowClockwise size={16} /> Retry
          </button>
        </div>
      )}

      {/* Data */}
      {scansQuery.isSuccess && (
        <div className="card fade-in-up" style={{ padding: 0, overflow: 'hidden' }}>
          {filtered.length > 0 ? (
            <table className="data-table data-table-responsive">
              <thead>
                <tr>
                  <th style={{ width: 40 }}><input type="checkbox" aria-label="Select all" /></th>
                  <th>Scan ID</th>
                  <th>Verdict</th>
                  <th>Confidence</th>
                  <th>Scanned</th>
                  <th style={{ width: 50 }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(p => (
                  <tr key={p.scan_id} style={{ cursor: 'pointer' }} onClick={() => navigate(`/dashboard/scan/${p.scan_id}`)}>
                    <td data-label="" onClick={e => e.stopPropagation()}><input type="checkbox" aria-label={`Select ${p.scan_id}`} /></td>
                    <td data-label="Scan ID" className="mono" style={{ fontWeight: 500 }}>{p.scan_id.substring(0, 12)}…</td>
                    <td data-label="Verdict">
                      <span className={`badge badge-${p.overall_verdict.toLowerCase()}`}>{p.overall_verdict}</span>
                    </td>
                    <td data-label="Confidence">
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <div style={{ width: 60, height: 6, background: 'var(--color-surface-3)', borderRadius: 'var(--radius-sm)' }}>
                          <div style={{
                            width: `${(p.overall_confidence * 100)}%`, height: '100%', borderRadius: 'var(--radius-sm)',
                            background: p.overall_confidence >= 0.9 ? 'var(--color-pass)' : p.overall_confidence >= 0.7 ? 'var(--color-warn)' : 'var(--color-fail)',
                          }} />
                        </div>
                        <span style={{ fontSize: '0.75rem', color: 'var(--color-text-secondary)' }}>{(p.overall_confidence * 100).toFixed(0)}%</span>
                      </div>
                    </td>
                    <td data-label="Scanned" style={{ color: 'var(--color-text-tertiary)', fontSize: '0.75rem' }}>
                      {p.created_at ? new Date(p.created_at).toLocaleDateString('en-IN') : '—'}
                    </td>
                    <td data-label="Action" onClick={e => e.stopPropagation()}>
                      <button style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-text-tertiary)' }}>
                        <DotsThree size={20} weight="bold" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="empty-state">
              <div className="empty-state-icon"><Package size={48} /></div>
              <h3>No products found</h3>
              <p>{search ? 'Try adjusting your search or filters' : 'Start your first scan to see products here'}</p>
              {!search && (
                <button className="btn btn-primary" onClick={() => navigate('/dashboard/scan/new')}>
                  <Plus size={16} /> New Scan
                </button>
              )}
            </div>
          )}
        </div>
      )}
    </>
  );
};
