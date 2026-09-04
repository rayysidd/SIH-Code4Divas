import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ArrowClockwise, Users, PencilSimple, CheckCircle, XCircle } from '@phosphor-icons/react';
import { apiGet, apiPatch } from '../../lib/apiClient';

interface User {
  user_id: string;
  username: string;
  full_name: string;
  role: string;
  district: string | null;
  is_active: boolean;
}

export const UserManagementPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [roleInput, setRoleInput] = useState('');
  const [districtInput, setDistrictInput] = useState('');

  const usersQuery = useQuery({
    queryKey: ['users'],
    queryFn: () => apiGet<User[]>('/v1/auth/users'),
  });

  const statusMutation = useMutation({
    mutationFn: ({ userId, isActive }: { userId: string, isActive: boolean }) =>
      apiPatch(`/v1/auth/users/${userId}/status`, { is_active: isActive }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
    onError: (err: any) => {
      alert(err.message || 'Failed to update status');
    }
  });

  const roleMutation = useMutation({
    mutationFn: ({ userId, role, district }: { userId: string, role: string, district: string | null }) =>
      apiPatch(`/v1/auth/users/${userId}/role`, { role, district }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setEditingUser(null);
    },
    onError: (err: any) => {
      alert(err.message || 'Failed to update role');
    }
  });

  const handleToggleStatus = (user: User) => {
    if (user.is_active) {
      if (!window.confirm(`Are you sure you want to deactivate ${user.username}?`)) return;
    }
    statusMutation.mutate({ userId: user.user_id, isActive: !user.is_active });
  };

  const handleEditClick = (user: User) => {
    setEditingUser(user);
    setRoleInput(user.role);
    setDistrictInput(user.district || '');
  };

  const handleSaveRole = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingUser) return;
    roleMutation.mutate({
      userId: editingUser.user_id,
      role: roleInput,
      district: districtInput.trim() || null,
    });
  };

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-6)' }}>
        <div>
          <h1 className="page-title">User Management</h1>
          <p className="page-description">Manage user roles, districts, and system access</p>
        </div>
      </div>

      {usersQuery.isLoading && (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {[1, 2, 3, 4].map(i => (
            <div key={i} style={{ padding: 'var(--space-3) var(--space-4)', borderBottom: '1px solid var(--color-surface-3)' }}>
              <div className="skeleton skeleton-row" />
            </div>
          ))}
        </div>
      )}

      {usersQuery.isError && (
        <div className="error-state">
          <div className="error-state-icon">⚠️</div>
          <h3>Failed to load users</h3>
          <button className="btn btn-primary" onClick={() => usersQuery.refetch()}>
            <ArrowClockwise size={16} /> Retry
          </button>
        </div>
      )}

      {usersQuery.isSuccess && (
        <div className="card fade-in-up" style={{ padding: 0, overflow: 'hidden' }}>
          {usersQuery.data.length > 0 ? (
            <table className="data-table data-table-responsive">
              <thead>
                <tr>
                  <th>Username</th>
                  <th>Full Name</th>
                  <th>Role</th>
                  <th>District</th>
                  <th>Status</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {usersQuery.data.map(user => (
                  <tr key={user.user_id} style={{ opacity: user.is_active ? 1 : 0.6 }}>
                    <td data-label="Username" style={{ fontWeight: 600 }}>{user.username}</td>
                    <td data-label="Full Name">{user.full_name}</td>
                    <td data-label="Role">
                      <span className="badge badge-info">{user.role}</span>
                    </td>
                    <td data-label="District">{user.district || '—'}</td>
                    <td data-label="Status">
                      {user.is_active ? (
                        <span className="badge" style={{ backgroundColor: '#10b981', color: '#fff' }}><CheckCircle size={14} /> Active</span>
                      ) : (
                        <span className="badge" style={{ backgroundColor: '#ef4444', color: '#fff' }}><XCircle size={14} /> Inactive</span>
                      )}
                    </td>
                    <td data-label="Actions" style={{ textAlign: 'right' }}>
                      <button className="btn btn-outline" style={{ padding: '4px 8px', marginRight: '8px' }} onClick={() => handleEditClick(user)}>
                        <PencilSimple size={16} />
                      </button>
                      <button 
                        className="btn"
                        style={{ padding: '4px 8px', backgroundColor: user.is_active ? '#fee2e2' : '#d1fae5', color: user.is_active ? '#991b1b' : '#065f46' }}
                        onClick={() => handleToggleStatus(user)}
                        disabled={statusMutation.isPending}
                      >
                        {user.is_active ? 'Deactivate' : 'Reactivate'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="empty-state">
              <div className="empty-state-icon"><Users size={48} /></div>
              <h3>No users found</h3>
            </div>
          )}
        </div>
      )}

      {/* Edit Role Modal */}
      {editingUser && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 }}>
          <div className="card fade-in-up" style={{ width: '100%', maxWidth: '400px' }}>
            <h2 className="card-title">Edit Role: {editingUser.username}</h2>
            <form onSubmit={handleSaveRole} style={{ marginTop: 'var(--space-4)' }}>
              <div className="form-group">
                <label className="form-label">Role</label>
                <select className="form-input" value={roleInput} onChange={(e) => setRoleInput(e.target.value)} required>
                  <option value="CITIZEN">CITIZEN</option>
                  <option value="INSPECTOR">INSPECTOR</option>
                  <option value="QA_MANAGER">QA_MANAGER</option>
                  <option value="ECOM_LEAD">ECOM_LEAD</option>
                  <option value="ADMIN">ADMIN</option>
                </select>
              </div>
              <div className="form-group" style={{ marginTop: 'var(--space-4)' }}>
                <label className="form-label">District (Optional)</label>
                <input className="form-input" type="text" value={districtInput} onChange={(e) => setDistrictInput(e.target.value)} placeholder="e.g. Mumbai North" />
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--space-2)', marginTop: 'var(--space-6)' }}>
                <button type="button" className="btn btn-outline" onClick={() => setEditingUser(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary" disabled={roleMutation.isPending}>Save Changes</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
};
