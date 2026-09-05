import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ClockCounterClockwise, MagnifyingGlass, ArrowClockwise } from '@phosphor-icons/react';
import { useQuery } from '@tanstack/react-query';
import { apiGet } from '../lib/apiClient';

interface ScanHistoryItem {
  scan_id: string;
  overall_verdict: string;
  overall_confidence: number;
  created_at: string;
  rule_version?: string;
}

export const ScanHistoryPage: React.FC = () => {
  const [filter, setFilter] = useState('All');
  const [search, setSearch] = useState('');
  const navigate = useNavigate();

  const historyQuery = useQuery({
    queryKey: ['scan-history'],
    queryFn: () => apiGet<ScanHistoryItem[]>('/v1/check/scans'),
  });

  const scans = historyQuery.data ?? [];
  const filtered = scans.filter(s => {
    const matchesFilter = filter === 'All' || s.overall_verdict === filter.toUpperCase();
    const matchesSearch = !search || s.scan_id.toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  // Group by date
  const grouped = filtered.reduce<Record<string, typeof filtered>>((acc, s) => {
    const dateKey = s.created_at ? new Date(s.created_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) : 'Unknown';
    (acc[dateKey] = acc[dateKey] || []).push(s);
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
                          <span className="mono" style={{ fontWeight: 600 }}>{s.scan_id.substring(0, 8)}…</span>
                          <span className={`badge badge-${s.overall_verdict.toLowerCase()}`}>{s.overall_verdict}</span>
                        </div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)', marginTop: 2 }}>
                          Confidence: {s.overall_confidence ? `${(s.overall_confidence * 100).toFixed(0)}%` : '—'} · Rules: v{s.rule_version || '2024.01'}
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
