import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, Trash, ArrowClockwise, Users, Copy, Check } from '@phosphor-icons/react';
import { apiGet, apiPost, apiDelete } from '../../lib/apiClient';

interface InviteCode {
  code: string;
  role: string;
  district: string | null;
  issued_by: string;
  issued_at: string;
  used: boolean;
  used_by: string | null;
  expires_at: string;
}

export const InviteCodesPage: React.FC = () => {
  const [role, setRole] = useState('INSPECTOR');
  const [district, setDistrict] = useState('');
  const [copiedCode, setCopiedCode] = useState<string | null>(null);
  const queryClient = useQueryClient();

  const codesQuery = useQuery({
    queryKey: ['invite-codes'],
    queryFn: () => apiGet<InviteCode[]>('/v1/auth/invite-codes'),
  });

  const generateMutation = useMutation({
    mutationFn: (data: { role: string; district?: string }) => 
      apiPost<{ invite_code: string }>('/v1/auth/invite-codes', data),
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['invite-codes'] });
      setRole('INSPECTOR');
      setDistrict('');
      handleCopy(data.invite_code);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (code: string) => apiDelete(`/v1/auth/invite-codes/${code}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['invite-codes'] });
    },
  });

  const handleCopy = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedCode(text);
    setTimeout(() => setCopiedCode(null), 2000);
  };

  const handleGenerate = (e: React.FormEvent) => {
    e.preventDefault();
    generateMutation.mutate({ 
      role, 
      district: district.trim() || undefined 
    });
  };

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-6)' }}>
        <h2>Manage Invites</h2>
      </div>

      {/* Generate Code Form */}
      <div className="card" style={{ marginBottom: 'var(--space-6)', padding: 'var(--space-4)' }}>
        <h3 style={{ marginBottom: 'var(--space-4)' }}>Generate New Invite Code</h3>
        <form onSubmit={handleGenerate} style={{ display: 'flex', gap: 'var(--space-4)', alignItems: 'flex-end', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-2)' }}>
            <label style={{ fontSize: '0.875rem', fontWeight: 500 }}>Role</label>
            <select 
              value={role} 
              onChange={(e) => setRole(e.target.value)}
              style={{
                padding: '10px 14px',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--color-surface-3)',
                background: 'var(--color-surface-1)',
                color: 'var(--color-text-primary)'
              }}
            >
              <option value="INSPECTOR">Inspector</option>
              <option value="QA_MANAGER">QA Manager</option>
              <option value="ADMIN">Admin</option>
            </select>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-2)', flex: 1, minWidth: '200px' }}>
            <label style={{ fontSize: '0.875rem', fontWeight: 500 }}>District (Optional)</label>
            <input 
              type="text" 
              placeholder="e.g. Mumbai North"
              value={district}
              onChange={(e) => setDistrict(e.target.value)}
              style={{
                padding: '10px 14px',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--color-surface-3)',
                background: 'var(--color-surface-1)',
                color: 'var(--color-text-primary)'
              }}
            />
          </div>
          <button 
            type="submit" 
            className="btn btn-primary" 
            disabled={generateMutation.isPending}
            style={{ height: '42px' }}
          >
            {generateMutation.isPending ? 'Generating...' : <><Plus size={16} /> Generate Code</>}
          </button>
        </form>
        {generateMutation.isError && (
          <div style={{ color: 'var(--color-fail)', marginTop: 'var(--space-3)', fontSize: '0.875rem' }}>
            Failed to generate invite code.
          </div>
        )}
      </div>

      {/* List */}
      {codesQuery.isLoading && (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {[1, 2, 3].map(i => (
            <div key={i} style={{ padding: 'var(--space-3) var(--space-4)', borderBottom: '1px solid var(--color-surface-3)' }}>
              <div className="skeleton skeleton-row" />
            </div>
          ))}
        </div>
      )}

      {codesQuery.isError && (
        <div className="error-state">
          <div className="error-state-icon">⚠️</div>
          <h3>Failed to load invite codes</h3>
          <button className="btn btn-primary" onClick={() => codesQuery.refetch()}>
            <ArrowClockwise size={16} /> Retry
          </button>
        </div>
      )}

      {codesQuery.isSuccess && (
        <div className="card fade-in-up" style={{ padding: 0, overflow: 'hidden' }}>
          {codesQuery.data.length > 0 ? (
            <table className="data-table data-table-responsive">
              <thead>
                <tr>
                  <th>Code</th>
                  <th>Role</th>
                  <th>District</th>
                  <th>Status</th>
                  <th>Issued By</th>
                  <th>Issued At</th>
                  <th>Expires At</th>
                  <th style={{ width: 100 }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {codesQuery.data.map(invite => {
                  const isExpired = new Date(invite.expires_at) < new Date();
                  const statusLabel = invite.used ? 'Used' : isExpired ? 'Expired' : 'Active';
                  const statusColor = invite.used ? 'var(--color-text-tertiary)' : isExpired ? 'var(--color-warn)' : 'var(--color-pass)';
                  
                  return (
                    <tr key={invite.code}>
                      <td data-label="Code" className="mono" style={{ fontWeight: 600 }}>
                        {invite.code}
                      </td>
                      <td data-label="Role">{invite.role}</td>
                      <td data-label="District">{invite.district || '—'}</td>
                      <td data-label="Status">
                        <span style={{ 
                          display: 'inline-flex', alignItems: 'center', gap: '6px',
                          padding: '4px 8px', borderRadius: '4px',
                          background: 'var(--color-surface-2)', color: statusColor,
                          fontSize: '0.75rem', fontWeight: 600
                        }}>
                          {statusLabel}
                        </span>
                        {invite.used_by && (
                          <div style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)', marginTop: '4px' }}>
                            By: {invite.used_by.substring(0,8)}...
                          </div>
                        )}
                      </td>
                      <td data-label="Issued By">{invite.issued_by}</td>
                      <td data-label="Issued At">
                        {new Date(invite.issued_at).toLocaleDateString()}
                      </td>
                      <td data-label="Expires At" style={{ color: isExpired ? 'var(--color-warn)' : 'inherit' }}>
                        {new Date(invite.expires_at).toLocaleDateString()}
                      </td>
                      <td data-label="Actions">
                        <div style={{ display: 'flex', gap: '8px' }}>
                          <button 
                            className="btn btn-icon" 
                            onClick={() => handleCopy(invite.code)}
                            title="Copy code"
                          >
                            {copiedCode === invite.code ? <Check size={18} color="var(--color-pass)" /> : <Copy size={18} />}
                          </button>
                          
                          {!invite.used && (
                            <button 
                              className="btn btn-icon" 
                              onClick={() => {
                                if (window.confirm('Are you sure you want to revoke this code?')) {
                                  deleteMutation.mutate(invite.code);
                                }
                              }}
                              disabled={deleteMutation.isPending}
                              title="Revoke code"
                              style={{ color: 'var(--color-fail)' }}
                            >
                              <Trash size={18} />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          ) : (
            <div className="empty-state">
              <div className="empty-state-icon"><Users size={48} /></div>
              <h3>No invite codes</h3>
              <p>Generate one above to get started.</p>
            </div>
          )}
        </div>
      )}
    </>
  );
};
