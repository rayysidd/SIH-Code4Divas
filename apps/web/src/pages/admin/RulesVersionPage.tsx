import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { FileText, UploadSimple } from '@phosphor-icons/react';
import { apiGet } from '../../lib/apiClient';
import { ResponsiveContainer, BarChart, CartesianGrid, XAxis, YAxis, Tooltip, Bar } from 'recharts';

interface RulesVersion {
  version: string;
  effective_date: string;
  amendment_basis: string;
  scan_counts: { version: string; count: number }[];
}

export const RulesVersionPage: React.FC = () => {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['rules-version'],
    queryFn: () => apiGet<RulesVersion>('/v1/rules/version'),
  });

  return (
    <div className="page-container">
      <header className="page-header">
        <div>
          <h1 className="page-title">Rules Version</h1>
          <p className="page-description">Compliance engine version control</p>
        </div>
        <div className="tooltip-container" title="Coming soon — rules updates require a review workflow">
          <button className="btn btn-primary" disabled style={{ opacity: 0.5, cursor: 'not-allowed' }}>
            <UploadSimple size={20} />
            Upload new rules version
          </button>
        </div>
      </header>

      {isLoading && <div className="skeleton" style={{ height: '200px' }} />}
      
      {isError && (
        <div className="error-state">
          <div className="error-state-icon">⚠️</div>
          <h3>Failed to load rules version</h3>
        </div>
      )}

      {data && (
        <div className="dashboard-grid">
          <div className="card" style={{ gridColumn: 'span 12' }}>
            <h2 className="card-title">
              <FileText size={20} /> Current Active Version
            </h2>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 'var(--space-4)', marginTop: 'var(--space-4)' }}>
              <div>
                <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem' }}>Version ID</p>
                <p style={{ fontSize: '1.25rem', fontWeight: 600 }}>{data.version}</p>
              </div>
              <div>
                <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem' }}>Effective Date</p>
                <p style={{ fontSize: '1.25rem', fontWeight: 600 }}>{data.effective_date}</p>
              </div>
              <div>
                <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem' }}>Amendment Basis</p>
                <p style={{ fontSize: '1.25rem', fontWeight: 600 }}>{data.amendment_basis}</p>
              </div>
            </div>
          </div>

          <div className="card" style={{ gridColumn: 'span 12' }}>
            <h2 className="card-title">Scan Breakdown by Rules Version</h2>
            <p className="card-description">Number of scans processed using each rules database version</p>
            <div style={{ height: 300, marginTop: 'var(--space-4)' }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={data.scan_counts} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--color-surface-3)" />
                  <XAxis dataKey="version" stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="var(--text-muted)" fontSize={12} tickLine={false} axisLine={false} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'var(--color-surface-2)',
                      border: '1px solid var(--color-surface-3)',
                      borderRadius: 'var(--radius-md)',
                      color: 'var(--text-primary)',
                    }}
                  />
                  <Bar dataKey="count" fill="var(--color-brand-primary)" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
