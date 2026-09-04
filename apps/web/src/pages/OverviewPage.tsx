import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, Cell, PieChart, Pie, Legend } from 'recharts';
import { ArrowUp, ArrowDown, Camera,  ArrowClockwise, ChartLine, Users, } from '@phosphor-icons/react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import { apiGet } from '../lib/apiClient';

const barColors = ['#1A3C6B', '#2E7D9E', '#4AADE0', '#7FC8E8', '#B5DFF0'];
const PIE_COLORS = ['#1A3C6B', '#2E7D9E', '#F4A500', '#7F8C8D'];

/* ── Skeleton Loader Components ──────────────────────────────────────── */

const SkeletonCard: React.FC = () => (
  <div className="card">
    <div className="skeleton skeleton-text short" />
    <div className="skeleton skeleton-heading" style={{ marginTop: 8 }} />
    <div className="skeleton skeleton-text short" style={{ marginTop: 4 }} />
  </div>
);

const SkeletonChart: React.FC = () => (
  <div className="card">
    <div className="skeleton skeleton-text medium" />
    <div className="skeleton skeleton-chart" style={{ marginTop: 16 }} />
  </div>
);

/* ── Error State ─────────────────────────────────────────────────────── */

const ErrorState: React.FC<{ message: string; onRetry: () => void }> = ({ message, onRetry }) => (
  <div className="error-state">
    <div className="error-state-icon">⚠️</div>
    <h3>Something went wrong</h3>
    <p>{message}</p>
    <button className="btn btn-primary" onClick={onRetry}>
      <ArrowClockwise size={16} /> Try Again
    </button>
  </div>
);

/* ── Page Component ──────────────────────────────────────────────────── */

export const OverviewPage: React.FC = () => {
  const user = useAuthStore((s) => s.user);
  const role = user?.role ?? 'INSPECTOR';
  const navigate = useNavigate();

  const overviewQuery = useQuery({
    queryKey: ['analytics', 'overview'],
    queryFn: () => apiGet<{ total_scans: number; pass_rate: number; open_violations: number; avg_scan_time_seconds: number }>('/v1/analytics/overview'),
    retry: 1,
  });

  const trendQuery = useQuery({
    queryKey: ['analytics', 'compliance-trend'],
    queryFn: () => apiGet<{ period_days: number; data: { date: string; compliance_rate: number }[] }>('/v1/analytics/compliance-trend?days=30'),
  });

  const topViolationsQuery = useQuery({
    queryKey: ['analytics', 'top-violations'],
    queryFn: () => apiGet<{ rule: string; description: string; count: number; percentage: number }[]>('/v1/analytics/top-violations'),
  });

  const categoryQuery = useQuery({
    queryKey: ['analytics', 'by-category'],
    queryFn: () => apiGet<{ category: string; percentage: number; count: number }[]>('/v1/analytics/by-category'),
    enabled: role === 'QA_MANAGER' || role === 'ADMIN',
  });

  const greeting = (() => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  })();

  const firstName = user?.full_name?.split(' ')[0] ?? 'User';

  return (
    <>
      {/* Greeting */}
      <div style={{ marginBottom: 'var(--space-8)' }}>
        <h2>{greeting}, {firstName}.</h2>
        <p style={{ color: 'var(--color-text-secondary)', marginTop: '4px' }}>
          {role === 'ADMIN' && 'System-wide compliance overview'}
          {role === 'QA_MANAGER' && 'Batch compliance and trend analytics'}
          {role === 'INSPECTOR' && 'Your field inspection dashboard'}
          {!['ADMIN', 'QA_MANAGER', 'INSPECTOR'].includes(role) && 'Welcome to LabelLens'}
        </p>
      </div>

      {/* KPI Cards */}
      <div className="kpi-grid">
        {overviewQuery.isLoading ? (
          <>
            <SkeletonCard />
            <SkeletonCard />
            <SkeletonCard />
            <SkeletonCard />
          </>
        ) : overviewQuery.isError ? (
          <div style={{ gridColumn: '1 / -1' }}>
            <ErrorState message="Failed to load dashboard data" onRetry={() => overviewQuery.refetch()} />
          </div>
        ) : overviewQuery.data ? (
          <>
            <div className="card fade-in-up stagger-1">
              <div className="card-title">
                {role === 'QA_MANAGER' ? 'Batches Scanned' : role === 'ADMIN' ? 'Total Scans' : 'Scanned'}
              </div>
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
              <div className="card-trend">need review</div>
            </div>
            <div className="card fade-in-up stagger-4">
              <div className="card-title">Avg Scan Time</div>
              <div className="card-value">{overviewQuery.data.avg_scan_time_seconds}s</div>
              <div className="card-trend down"><ArrowDown size={12} weight="bold" /> faster</div>
            </div>
          </>
        ) : null}
      </div>

      {/* Role-specific CTA */}
      {role === 'INSPECTOR' && (
        <div className="card fade-in-up" style={{ marginBottom: 'var(--space-8)', display: 'flex', alignItems: 'center', gap: 'var(--space-6)' }}>
          <div style={{ flex: 1 }}>
            <h3>Start a new scan</h3>
            <p style={{ color: 'var(--color-text-secondary)', fontSize: '0.875rem', marginTop: 'var(--space-1)' }}>
              Upload a product label image for instant compliance verification
            </p>
          </div>
          <button className="btn btn-primary" onClick={() => navigate('/dashboard/scan/new')} style={{ padding: 'var(--space-3) var(--space-6)' }}>
            <Camera size={18} /> New Scan
          </button>
        </div>
      )}

      {role === 'ADMIN' && (
        <div className="card fade-in-up" style={{ marginBottom: 'var(--space-8)', display: 'flex', alignItems: 'center', gap: 'var(--space-6)', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', gap: 'var(--space-4)' }}>
            <button className="btn btn-secondary" onClick={() => navigate('/dashboard/citizen-reports')}>
              <Users size={16} /> Citizen Reports
            </button>
            <button className="btn btn-secondary" onClick={() => navigate('/dashboard/batch')}>
              <ChartLine size={16} /> Batch Audit
            </button>
          </div>
          <div className="mono" style={{ color: 'var(--color-text-tertiary)', fontSize: '0.75rem' }}>
            Rules Engine v2024.01
          </div>
        </div>
      )}

      {/* Charts Row */}
      <div className="charts-grid">
        {/* Compliance Trend Line Chart */}
        {trendQuery.isLoading ? (
          <SkeletonChart />
        ) : trendQuery.isError ? (
          <div className="card">
            <ErrorState message="Failed to load trend data" onRetry={() => trendQuery.refetch()} />
          </div>
        ) : (
          <div className="card fade-in-up">
            <h4 style={{ marginBottom: 'var(--space-4)' }}>Compliance Rate — Last 30 Days</h4>
            {trendQuery.data?.data && trendQuery.data.data.length > 0 ? (
              <ResponsiveContainer width="100%" height={220}>
                <LineChart data={trendQuery.data.data}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--color-surface-3)" />
                  <XAxis dataKey="date" tick={{ fontSize: 12, fill: 'var(--color-text-tertiary)' }} />
                  <YAxis domain={[60, 100]} tick={{ fontSize: 12, fill: 'var(--color-text-tertiary)' }} />
                  <Tooltip />
                  <Line type="monotone" dataKey="compliance_rate" name="Rate" stroke="#2E7D9E" strokeWidth={2} dot={{ r: 3, fill: '#2E7D9E' }} />
                </LineChart>
              </ResponsiveContainer>
            ) : (
              <div className="empty-state" style={{ height: 220 }}>
                <p>No trend data available yet</p>
              </div>
            )}
          </div>
        )}

        {/* Top Violated Rules Bar Chart */}
        {topViolationsQuery.isLoading ? (
          <SkeletonChart />
        ) : topViolationsQuery.isError ? (
          <div className="card">
            <ErrorState message="Failed to load violations" onRetry={() => topViolationsQuery.refetch()} />
          </div>
        ) : (
          <div className="card fade-in-up">
            <h4 style={{ marginBottom: 'var(--space-4)' }}>Top 5 Violated Rules</h4>
            {topViolationsQuery.data && topViolationsQuery.data.length > 0 ? (
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={topViolationsQuery.data} layout="vertical" margin={{ left: 120 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--color-surface-3)" />
                  <XAxis type="number" domain={[0, 50]} tick={{ fontSize: 12, fill: 'var(--color-text-tertiary)' }} />
                  <YAxis dataKey="rule" type="category" tick={{ fontSize: 11, fill: 'var(--color-text-secondary)' }} width={120} />
                  <Tooltip />
                  <Bar dataKey="percentage" name="%" radius={[0, 4, 4, 0]}>
                    {topViolationsQuery.data.map((_: any, index: number) => (
                      <Cell key={index} fill={barColors[index % barColors.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="empty-state" style={{ height: 220 }}>
                <p>No violation data available yet</p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Category Breakdown (QA_MANAGER and ADMIN) */}
      {(role === 'QA_MANAGER' || role === 'ADMIN') && (
        <div className="charts-grid">
          {categoryQuery.isLoading ? (
            <SkeletonChart />
          ) : categoryQuery.data && categoryQuery.data.length > 0 ? (
            <div className="card fade-in-up">
              <h4 style={{ marginBottom: 'var(--space-4)' }}>Violations by Category</h4>
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
          ) : null}
        </div>
      )}
    </>
  );
};
