import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Users, ArrowClockwise } from '@phosphor-icons/react';
import { apiGet } from '../lib/apiClient';

interface CitizenReport {
  tracking_id: string;
  problem_type: string;
  description?: string;
  latitude?: number;
  longitude?: number;
  submitted_at: string;
  status: string;
}

export const CitizenReportsPage: React.FC = () => {
  const reportsQuery = useQuery({
    queryKey: ['citizen-reports'],
    queryFn: () => apiGet<CitizenReport[]>('/v1/citizens/reports'),
  });

  const reports = reportsQuery.data ?? [];

  const statusColor = (s: string) => {
    if (s === 'SUBMITTED') return 'var(--color-brand-accent)';
    if (s === 'IN_REVIEW') return 'var(--color-brand-secondary)';
    if (s === 'RESOLVED') return 'var(--color-pass)';
    return 'var(--color-text-tertiary)';
  };

  return (
    <>
      <div style={{ marginBottom: 'var(--space-6)' }}>
        <h2>Citizen Reports</h2>
        <p style={{ color: 'var(--color-text-secondary)', marginTop: 'var(--space-1)', fontSize: '0.875rem' }}>
          Violation reports submitted by consumers
        </p>
      </div>

      {reportsQuery.isLoading && (
        <div className="card">
          {[1, 2, 3].map(i => (
            <div key={i} className="skeleton skeleton-row" style={{ marginBottom: 'var(--space-2)' }} />
          ))}
        </div>
      )}

      {reportsQuery.isError && (
        <div className="error-state">
          <div className="error-state-icon">⚠️</div>
          <h3>Failed to load reports</h3>
          <button className="btn btn-primary" onClick={() => reportsQuery.refetch()}>
            <ArrowClockwise size={16} /> Retry
          </button>
        </div>
      )}

      {reportsQuery.isSuccess && (
        reports.length > 0 ? (
          <div className="card fade-in-up" style={{ padding: 0, overflow: 'hidden' }}>
            <table className="data-table data-table-responsive">
              <thead>
                <tr>
                  <th>Tracking ID</th>
                  <th>Problem Type</th>
                  <th>Description</th>
                  <th>Submitted</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {reports.map(r => (
                  <tr key={r.tracking_id}>
                    <td data-label="Tracking ID" className="mono" style={{ fontWeight: 600 }}>{r.tracking_id}</td>
                    <td data-label="Problem">{r.problem_type}</td>
                    <td data-label="Description" style={{ fontSize: '0.8125rem', color: 'var(--color-text-secondary)' }}>
                      {r.description || '—'}
                    </td>
                    <td data-label="Submitted" style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)' }}>
                      {new Date(r.submitted_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
                    </td>
                    <td data-label="Status">
                      <span style={{ fontSize: '0.75rem', fontWeight: 600, color: statusColor(r.status) }}>
                        {r.status.replace('_', ' ')}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="card">
            <div className="empty-state">
              <div className="empty-state-icon"><Users size={48} /></div>
              <h3>No citizen reports</h3>
              <p>No violation reports have been submitted by consumers yet.</p>
            </div>
          </div>
        )
      )}
    </>
  );
};
