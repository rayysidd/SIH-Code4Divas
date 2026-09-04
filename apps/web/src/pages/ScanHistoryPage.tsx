import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ClockCounterClockwise, MagnifyingGlass, ArrowClockwise } from '@phosphor-icons/react';
import { useQuery } from '@tanstack/react-query';
import { } from '../lib/apiClient';

export const ScanHistoryPage: React.FC = () => {
  const [filter, setFilter] = useState('All');
  const [search, setSearch] = useState('');
  const navigate = useNavigate();

  const historyQuery = useQuery({
    queryKey: ['scan-history'],
    queryFn: async () => {
      // Simulated scan history — in production from GET /v1/scans
      return [
        { scan_id: 'a1b2c3', product: 'Sunflower Oil 1L', verdict: 'FAIL', time: '14:32', date: 'Today, 26 Aug 2026', location: 'Sadar Bazaar', checks: '18/28' },
        { scan_id: 'd4e5f6', product: 'Wheat Biscuits 250g', verdict: 'PASS', time: '14:45', date: 'Today, 26 Aug 2026', location: 'Sadar Bazaar', checks: '28/28' },
        { scan_id: 'g7h8i9', product: 'Soap Bar 100g', verdict: 'WARN', time: '11:20', date: 'Yesterday, 25 Aug 2026', location: 'Lajpat Nagar', checks: '26/28' },
        { scan_id: 'j0k1l2', product: 'LED Bulb 9W', verdict: 'PASS', time: '16:05', date: 'Yesterday, 25 Aug 2026', location: 'Nehru Place', checks: '27/28' },
        { scan_id: 'm3n4o5', product: 'Face Cream 50ml', verdict: 'FAIL', time: '10:12', date: '24 Aug 2026', location: 'Connaught Place', checks: '16/28' },
      ];
    },
  });

  const scans = historyQuery.data ?? [];
  const filtered = scans.filter(s => {
    const matchesFilter = filter === 'All' || s.verdict === filter.toUpperCase();
    const matchesSearch = !search || s.product.toLowerCase().includes(search.toLowerCase()) || s.scan_id.includes(search);
    return matchesFilter && matchesSearch;
  });

  // Group by date
  const grouped = filtered.reduce<Record<string, typeof filtered>>((acc, s) => {
    (acc[s.date] = acc[s.date] || []).push(s);
    return acc;
  }, {});

  return (
    <>
      <div style={{ marginBottom: 'var(--space-6)' }}>
        <h2>Scan History</h2>
        <p style={{ color: 'var(--color-text-secondary)', marginTop: 'var(--space-1)', fontSize: '0.875rem' }}>
          Browse and search past scans
        </p>
      </div>

      {/* Filters */}
      <div className="card" style={{ marginBottom: 'var(--space-6)', padding: 'var(--space-4)' }}>
        <div style={{ display: 'flex', gap: 'var(--space-4)', alignItems: 'center', flexWrap: 'wrap' }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 'var(--space-2)',
            background: 'var(--color-surface-2)', borderRadius: 'var(--radius-md)',
            padding: '8px 12px', flex: 1, maxWidth: '300px',
          }}>
            <MagnifyingGlass size={16} color="var(--color-text-tertiary)" />
            <input type="text" placeholder="Search by product or scan ID…" value={search} onChange={e => setSearch(e.target.value)} style={{
              border: 'none', background: 'transparent', outline: 'none',
              fontFamily: 'inherit', fontSize: '0.875rem', width: '100%',
              color: 'var(--color-text-primary)',
            }} />
          </div>
          <div className="filter-chips">
            {['All', 'FAIL', 'PASS', 'WARN'].map(f => (
              <button key={f} className={`filter-chip ${filter === f ? 'active' : ''}`} onClick={() => setFilter(f)}>
                {f}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Loading */}
      {historyQuery.isLoading && (
        <div className="card">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="skeleton skeleton-row" style={{ marginBottom: 'var(--space-2)' }} />
          ))}
        </div>
      )}

      {/* Error */}
      {historyQuery.isError && (
        <div className="error-state">
          <div className="error-state-icon">⚠️</div>
          <h3>Failed to load scan history</h3>
          <button className="btn btn-primary" onClick={() => historyQuery.refetch()}>
            <ArrowClockwise size={16} /> Retry
          </button>
        </div>
      )}

      {/* Data */}
      {historyQuery.isSuccess && (
        Object.keys(grouped).length > 0 ? (
          Object.entries(grouped).map(([date, items]) => (
            <div key={date} style={{ marginBottom: 'var(--space-6)' }}>
              <div style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--color-text-tertiary)', marginBottom: 'var(--space-2)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                {date}
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-2)' }}>
                {items.map(s => (
                  <div
                    key={s.scan_id}
                    className="card fade-in-up"
                    style={{ padding: 'var(--space-4)', cursor: 'pointer' }}
                    onClick={() => navigate(`/dashboard/scan/${s.scan_id}`)}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
                      <div style={{
                        width: 48, height: 48, borderRadius: 'var(--radius-md)',
                        background: 'var(--color-surface-2)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        color: 'var(--color-text-tertiary)', flexShrink: 0,
                      }}>
                        📦
                      </div>
                      <div style={{ flex: 1 }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span style={{ fontWeight: 600 }}>{s.product}</span>
                          <span className={`badge badge-${s.verdict.toLowerCase()}`}>{s.verdict}</span>
                        </div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)', marginTop: 2 }}>
                          {s.time} · {s.location} · {s.checks} ✓
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))
        ) : (
          <div className="card">
            <div className="empty-state">
              <div className="empty-state-icon"><ClockCounterClockwise size={48} /></div>
              <h3>No scans found</h3>
              <p>{search || filter !== 'All' ? 'Try adjusting your filters' : 'Start your first scan to build history'}</p>
              <button className="btn btn-primary" onClick={() => navigate('/dashboard/scan/new')}>New Scan</button>
            </div>
          </div>
        )
      )}
    </>
  );
};
