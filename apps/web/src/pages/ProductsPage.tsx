import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { MagnifyingGlass, Plus, UploadSimple, DotsThree, Package, ArrowClockwise } from '@phosphor-icons/react';
import { useQuery } from '@tanstack/react-query';
// import { apiGet } from '../lib/apiClient';

/* ── Page Component (Screen W-02) ─────────────────────────────────────── */

export const ProductsPage: React.FC = () => {
  const [search, setSearch] = useState('');
  const [filterVerdict, setFilterVerdict] = useState('ALL');
  const navigate = useNavigate();

  // Fetch scan data from backend — using as proxy for demo
  const scansQuery = useQuery({
    queryKey: ['products'],
    queryFn: async () => {
      // In production, this would be GET /v1/scans or similar
      // For now, return simulated data from analytics
      // await apiGet<{ total_scans: number; pass_rate: number }>('/v1/analytics/');
      // Build simulated product list from stats
      return [
        { id: '1', name: 'Sunflower Oil 1L', gtin: '8901234567890', category: 'Food', verdict: 'FAIL', score: 64, checks: '18/28' },
        { id: '2', name: 'Wheat Biscuits 250g', gtin: '8901234567891', category: 'Food', verdict: 'PASS', score: 100, checks: '28/28' },
        { id: '3', name: 'Face Cream 50ml', gtin: '8901234567892', category: 'Cosmetics', verdict: 'WARN', score: 85, checks: '24/28' },
        { id: '4', name: 'LED Bulb 9W', gtin: '8901234567893', category: 'Electronics', verdict: 'PASS', score: 96, checks: '27/28' },
        { id: '5', name: 'Soap Bar 100g', gtin: '8901234567894', category: 'Cosmetics', verdict: 'FAIL', score: 58, checks: '16/28' },
      ];
    },
  });

  const products = scansQuery.data ?? [];
  const filtered = products.filter(p => {
    const matchesSearch = !search || p.name.toLowerCase().includes(search.toLowerCase()) || p.gtin.includes(search);
    const matchesVerdict = filterVerdict === 'ALL' || p.verdict === filterVerdict;
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
                  <th>Product</th>
                  <th>GTIN</th>
                  <th>Category</th>
                  <th>Verdict</th>
                  <th>Score</th>
                  <th style={{ width: 50 }}>Action</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(p => (
                  <tr key={p.id} style={{ cursor: 'pointer' }} onClick={() => navigate(`/dashboard/scan/${p.id}`)}>
                    <td data-label="" onClick={e => e.stopPropagation()}><input type="checkbox" aria-label={`Select ${p.name}`} /></td>
                    <td data-label="Product" style={{ fontWeight: 500 }}>{p.name}</td>
                    <td data-label="GTIN" className="mono">{p.gtin}</td>
                    <td data-label="Category">{p.category}</td>
                    <td data-label="Verdict">
                      <span className={`badge badge-${p.verdict.toLowerCase()}`}>{p.verdict}</span>
                    </td>
                    <td data-label="Score">
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <div style={{ width: 60, height: 6, background: 'var(--color-surface-3)', borderRadius: 'var(--radius-sm)' }}>
                          <div style={{
                            width: `${p.score}%`, height: '100%', borderRadius: 'var(--radius-sm)',
                            background: p.score >= 90 ? 'var(--color-pass)' : p.score >= 70 ? 'var(--color-warn)' : 'var(--color-fail)',
                          }} />
                        </div>
                        <span style={{ fontSize: '0.75rem', color: 'var(--color-text-secondary)' }}>{p.checks}</span>
                      </div>
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
