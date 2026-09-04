import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ArrowClockwise, ClipboardText, Funnel } from '@phosphor-icons/react';
import { apiGet } from '../../lib/apiClient';

interface AuditLog {
  id: string;
  action: string;
  actor_user_id: string;
  actor_username: string;
  target: string | null;
  details: string | null;
  timestamp: string;
}

export const AuditLogPage: React.FC = () => {
  const [actionFilter, setActionFilter] = useState('');
  const [dateSince, setDateSince] = useState('');

  const auditQuery = useQuery({
    queryKey: ['audit-log', actionFilter, dateSince],
    queryFn: () => {
      const params = new URLSearchParams();
      if (actionFilter) params.append('action', actionFilter);
      if (dateSince) {
        const d = new Date(dateSince);
        if (!isNaN(d.getTime())) params.append('since', d.toISOString());
      }
      const qs = params.toString();
      return apiGet<AuditLog[]>(`/v1/auth/audit-log${qs ? `?${qs}` : ''}`);
    },
  });

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-6)' }}>
        <div>
          <h1 className="page-title">Audit Log</h1>
          <p className="page-description">System-wide record of administrative actions</p>
        </div>
      </div>

      <div className="card" style={{ marginBottom: 'var(--space-6)', display: 'flex', gap: 'var(--space-4)', alignItems: 'center' }}>
        <Funnel size={20} color="var(--text-muted)" />
        <div className="form-group" style={{ flex: 1, margin: 0 }}>
          <select className="form-input" value={actionFilter} onChange={(e) => setActionFilter(e.target.value)}>
            <option value="">All Actions</option>
            <option value="LOGIN">LOGIN</option>
            <option value="REGISTER">REGISTER</option>
            <option value="USER_DEACTIVATED">USER_DEACTIVATED</option>
            <option value="USER_REACTIVATED">USER_REACTIVATED</option>
            <option value="ROLE_CHANGED">ROLE_CHANGED</option>
            <option value="INVITE_CODE_ISSUED">INVITE_CODE_ISSUED</option>
            <option value="INVITE_CODE_REVOKED">INVITE_CODE_REVOKED</option>
          </select>
        </div>
        <div className="form-group" style={{ flex: 1, margin: 0 }}>
          <input 
            type="date" 
            className="form-input" 
            value={dateSince} 
            onChange={(e) => setDateSince(e.target.value)} 
            placeholder="Since Date" 
          />
        </div>
        <button className="btn btn-outline" onClick={() => { setActionFilter(''); setDateSince(''); }}>Clear Filters</button>
      </div>

      {auditQuery.isLoading && (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {[1, 2, 3, 4, 5].map(i => (
            <div key={i} style={{ padding: 'var(--space-3) var(--space-4)', borderBottom: '1px solid var(--color-surface-3)' }}>
              <div className="skeleton skeleton-row" />
            </div>
          ))}
        </div>
      )}

      {auditQuery.isError && (
        <div className="error-state">
          <div className="error-state-icon">⚠️</div>
          <h3>Failed to load audit log</h3>
          <button className="btn btn-primary" onClick={() => auditQuery.refetch()}>
            <ArrowClockwise size={16} /> Retry
          </button>
        </div>
      )}

      {auditQuery.isSuccess && (
        <div className="card fade-in-up" style={{ padding: 0, overflow: 'hidden' }}>
          {auditQuery.data.length > 0 ? (
            <table className="data-table data-table-responsive">
              <thead>
                <tr>
                  <th>Timestamp</th>
                  <th>Action</th>
                  <th>Actor</th>
                  <th>Target</th>
                  <th>Details</th>
                </tr>
              </thead>
              <tbody>
                {auditQuery.data.map((log) => (
                  <tr key={log.id}>
                    <td data-label="Timestamp" className="mono" style={{ fontSize: '0.85rem' }}>
                      {new Date(log.timestamp).toLocaleString()}
                    </td>
                    <td data-label="Action" style={{ fontWeight: 600 }}>{log.action}</td>
                    <td data-label="Actor" style={{ fontSize: '0.875rem' }}>
                      {log.actor_username}<br/>
                      <span className="mono" style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{log.actor_user_id.split('-')[0]}...</span>
                    </td>
                    <td data-label="Target" className="mono" style={{ fontSize: '0.875rem' }}>{log.target || '—'}</td>
                    <td data-label="Details" style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>{log.details || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="empty-state">
              <div className="empty-state-icon"><ClipboardText size={48} /></div>
              <h3>No audit events match filters</h3>
            </div>
          )}
        </div>
      )}
    </>
  );
};
