import React from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  BarChart, Bar, PieChart, Pie, Cell, Legend,
} from 'recharts';
import { ArrowUp, ArrowDown, ArrowClockwise } from '@phosphor-icons/react';
import { apiGet } from '../lib/apiClient';

const PIE_COLORS = ['#1A3C6B', '#2E7D9E', '#F4A500', '#7F8C8D'];
const BAR_COLOR = '#2E7D9E';

/* ── Shared Components ───────────────────────────────────────────────── */

const SkeletonChart = () => (
  <div className="card">
    <div className="skeleton skeleton-text medium" />
    <div className="skeleton skeleton-chart" style={{ marginTop: 16 }} />
  </div>
);

const SkeletonCard = () => (
  <div className="card">
    <div className="skeleton skeleton-text short" />
    <div className="skeleton skeleton-heading" style={{ marginTop: 8 }} />
    <div className="skeleton skeleton-text short" style={{ marginTop: 4 }} />
  </div>
);

/* ── Page Component (Screen W-07) ─────────────────────────────────────── */

export const AnalyticsPage: React.FC = () => {
  const overviewQuery = useQuery({
    queryKey: ['analytics', 'overview'],
    queryFn: () => apiGet<{ total_scans: number; pass_rate: number; open_violations: number; avg_scan_time_seconds: number }>('/v1/analytics/overview'),
  });

  const trendQuery = useQuery({
    queryKey: ['analytics', 'compliance-trend'],
    queryFn: () => apiGet<{ period_days: number; data: { date: string; compliance_rate: number }[] }>('/v1/analytics/compliance-trend?days=30'),
  });

  const topRulesQuery = useQuery({
    queryKey: ['analytics', 'top-violations'],
    queryFn: () => apiGet<{ rule: string; description: string; count: number; percentage: number }[]>('/v1/analytics/top-violations'),
  });

  const categoryQuery = useQuery({
    queryKey: ['analytics', 'by-category'],
    queryFn: () => apiGet<{ category: string; percentage: number; count: number }[]>('/v1/analytics/by-category'),
  });

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-6)' }}>
        <h2>Analytics</h2>
        <div style={{ display: 'flex', gap: 'var(--space-3)' }}>
          <select style={{
            padding: '8px 12px', borderRadius: 'var(--radius-md)',
            border: '1px solid var(--color-surface-4)', fontFamily: 'inherit', fontSize: '0.875rem',
            background: 'var(--color-surface-0)', color: 'var(--color-text-primary)',
          }}>
            <option>August 2026</option>
            <option>July 2026</option>
          </select>
          <button className="btn btn-secondary">Export</button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="kpi-grid">
        {overviewQuery.isLoading ? (
          <><SkeletonCard /><SkeletonCard /><SkeletonCard /><SkeletonCard /></>
        ) : overviewQuery.isError ? (
          <div style={{ gridColumn: '1 / -1' }}>
            <div className="error-state">
              <div className="error-state-icon">⚠️</div>
              <h3>Failed to load analytics</h3>
              <p>Could not connect to the analytics service.</p>
              <button className="btn btn-primary" onClick={() => overviewQuery.refetch()}>
                <ArrowClockwise size={16} /> Retry
              </button>
            </div>
          </div>
        ) : overviewQuery.data ? (
          <>
            <div className="card fade-in-up stagger-1">
              <div className="card-title">Products Scanned</div>
              <div className="card-value">{overviewQuery.data.total_scans}</div>
              <div className="card-trend">this month</div>
            </div>
            <div className="card fade-in-up stagger-2">
              <div className="card-title">Pass Rate</div>
              <div className="card-value">{overviewQuery.data.pass_rate}%</div>
              <div className="card-trend up"><ArrowUp size={12} weight="bold" /> trending up</div>
            </div>
            <div className="card fade-in-up stagger-3">
              <div className="card-title">Open Violations</div>
              <div className="card-value">{overviewQuery.data.open_violations}</div>
              <div className="card-trend down"><ArrowDown size={12} weight="bold" /> from last month</div>
            </div>
            <div className="card fade-in-up stagger-4">
              <div className="card-title">Avg Scan Time</div>
              <div className="card-value">{overviewQuery.data.avg_scan_time_seconds}s</div>
              <div className="card-trend up"><ArrowUp size={12} weight="bold" /> faster</div>
            </div>
          </>
        ) : null}
      </div>

      {/* Charts Row 1 */}
      <div className="charts-grid">
        {trendQuery.isLoading ? <SkeletonChart /> : trendQuery.isError ? (
          <div className="card">
            <div className="error-state">
              <h3>Trend data unavailable</h3>
              <button className="btn btn-secondary" onClick={() => trendQuery.refetch()}><ArrowClockwise size={14} /> Retry</button>
            </div>
          </div>
        ) : (
          <div className="card fade-in-up">
            <h4 style={{ marginBottom: 'var(--space-4)' }}>Compliance Trend — 30 Days</h4>
            {trendQuery.data?.data && trendQuery.data.data.length > 0 ? (
              <ResponsiveContainer width="100%" height={250}>
                <LineChart data={trendQuery.data.data}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--color-surface-3)" />
                  <XAxis dataKey="date" tick={{ fontSize: 12, fill: 'var(--color-text-tertiary)' }} />
                  <YAxis domain={[60, 100]} tick={{ fontSize: 12, fill: 'var(--color-text-tertiary)' }} />
                  <Tooltip />
                  <Line type="monotone" dataKey="compliance_rate" name="Rate" stroke="#2E7D9E" strokeWidth={2} dot={{ r: 3 }} />
                </LineChart>
              </ResponsiveContainer>
            ) : (
              <div className="empty-state" style={{ height: 250 }}><p>No trend data available</p></div>
            )}
          </div>
        )}

        {topRulesQuery.isLoading ? <SkeletonChart /> : topRulesQuery.isError ? (
          <div className="card">
            <div className="error-state">
              <h3>Violation data unavailable</h3>
              <button className="btn btn-secondary" onClick={() => topRulesQuery.refetch()}><ArrowClockwise size={14} /> Retry</button>
            </div>
          </div>
        ) : (
          <div className="card fade-in-up">
            <h4 style={{ marginBottom: 'var(--space-4)' }}>Top Violated Rules</h4>
            {topRulesQuery.data && topRulesQuery.data.length > 0 ? (
              <ResponsiveContainer width="100%" height={250}>
                <BarChart data={topRulesQuery.data} layout="vertical" margin={{ left: 100 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--color-surface-3)" />
                  <XAxis type="number" tick={{ fontSize: 12, fill: 'var(--color-text-tertiary)' }} />
                  <YAxis dataKey="rule" type="category" tick={{ fontSize: 10, fill: 'var(--color-text-secondary)' }} width={100} />
                  <Tooltip />
                  <Bar dataKey="count" fill={BAR_COLOR} radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="empty-state" style={{ height: 250 }}><p>No violation data available</p></div>
            )}
          </div>
        )}
      </div>

      {/* Charts Row 2 */}
      <div className="charts-grid">
        {categoryQuery.isLoading ? <SkeletonChart /> : categoryQuery.data && categoryQuery.data.length > 0 ? (
          <div className="card fade-in-up">
            <h4 style={{ marginBottom: 'var(--space-4)' }}>By Category</h4>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie data={categoryQuery.data.map(c => ({ name: c.category, value: c.count }))} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={90} label>
                  {categoryQuery.data.map((_: any, i: number) => (
                    <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        ) : (
          <div className="card">
            <h4 style={{ marginBottom: 'var(--space-4)' }}>By Category</h4>
            <div className="empty-state" style={{ height: 250 }}><p>No category data available</p></div>
          </div>
        )}
      </div>
    </>
  );
};
