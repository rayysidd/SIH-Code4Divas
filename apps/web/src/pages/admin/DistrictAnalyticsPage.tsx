import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { ChartLine, Users, Warning } from '@phosphor-icons/react';
import { apiGet } from '../../lib/apiClient';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
} from 'recharts';

interface AdminOverview {
  pass_rate_trend: { district: string; data: { date: string; rate: number }[] }[];
  inspector_workload: { inspector: string; district: string; scans: number }[];
  top_violations_by_district: { district: string; violations: { rule: string; count: number }[] }[];
}

export const DistrictAnalyticsPage: React.FC = () => {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['admin-overview'],
    queryFn: () => apiGet<AdminOverview>('/v1/analytics/admin-overview'),
  });

  return (
    <div className="page-container">
      <header className="page-header">
        <div>
          <h1 className="page-title">District Analytics</h1>
          <p className="page-description">Cross-district oversight and performance metrics</p>
        </div>
      </header>

      {isLoading && <div className="skeleton" style={{ height: '400px' }} />}

      {isError && (
        <div className="error-state">
          <div className="error-state-icon">⚠️</div>
          <h3>Failed to load analytics</h3>
        </div>
      )}

      {data && (
        <div className="dashboard-grid">
          {/* Pass Rate by District */}
          <div className="card" style={{ gridColumn: 'span 12' }}>
            <h2 className="card-title">
              <ChartLine size={20} /> Pass Rate by District
            </h2>
            <div style={{ height: 300, marginTop: 'var(--space-4)' }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={data.pass_rate_trend.map(d => ({
                    district: d.district,
                    rate: d.data.length > 0 ? d.data[d.data.length - 1].rate : 0
                  }))}
                  margin={{ top: 20, right: 30, left: 20, bottom: 5 }}
                >
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--color-surface-3)" />
                  <XAxis dataKey="district" stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'var(--color-surface-2)',
                      border: '1px solid var(--color-surface-3)',
                      borderRadius: 'var(--radius-md)',
                      color: 'var(--text-primary)',
                    }}
                    formatter={(value: any) => [`${value}%`, 'Pass Rate']}
                  />
                  <Bar dataKey="rate" fill="#10b981" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Inspector Workload */}
          <div className="card" style={{ gridColumn: 'span 6' }}>
            <h2 className="card-title">
              <Users size={20} /> Inspector Workload
            </h2>
            <div style={{ height: 300, marginTop: 'var(--space-4)' }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={data.inspector_workload} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--color-surface-3)" />
                  <XAxis dataKey="inspector" stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'var(--color-surface-2)',
                      border: '1px solid var(--color-surface-3)',
                      borderRadius: 'var(--radius-md)',
                      color: 'var(--text-primary)',
                    }}
                  />
                  <Bar dataKey="scans" name="Total Scans" fill="var(--color-brand-primary)" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Top Violations by District */}
          <div className="card" style={{ gridColumn: 'span 6' }}>
            <h2 className="card-title">
              <Warning size={20} /> Top Violations by District
            </h2>
            <div style={{ marginTop: 'var(--space-4)', overflowY: 'auto', maxHeight: '300px' }}>
              {data.top_violations_by_district.map((d, i) => (
                <div key={i} style={{ marginBottom: 'var(--space-4)' }}>
                  <h3 style={{ fontSize: '1rem', fontWeight: 600, marginBottom: 'var(--space-2)' }}>{d.district}</h3>
                  <table className="data-table" style={{ fontSize: '0.875rem' }}>
                    <thead>
                      <tr>
                        <th>Rule Cited</th>
                        <th style={{ textAlign: 'right' }}>Occurrences</th>
                      </tr>
                    </thead>
                    <tbody>
                      {d.violations.length === 0 ? (
                        <tr><td colSpan={2} style={{ textAlign: 'center' }}>No violations</td></tr>
                      ) : (
                        d.violations.map((v, j) => (
                          <tr key={j}>
                            <td>{v.rule}</td>
                            <td style={{ textAlign: 'right' }}>{v.count}</td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
