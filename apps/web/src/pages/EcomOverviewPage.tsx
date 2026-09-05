import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { CheckCircle, XCircle, Warning, Globe, ArrowRight, CircleNotch } from '@phosphor-icons/react';
import { apiGet } from '../lib/apiClient';

interface EcomOverviewResponse {
  total_listings_checked: number;
  pass_rate: number;
  recent_failures: Array<{
    id: string;
    batch_id: string | null;
    listing_url: string;
    verdict: string;
    missing_fields: string[];
    checked_at: string;
  }>;
  recent_failure_count: number;
}

export const EcomOverviewPage: React.FC = () => {
  const { data, isLoading, error, refetch } = useQuery<EcomOverviewResponse>({
    queryKey: ['ecom-overview'],
    queryFn: () => apiGet<EcomOverviewResponse>('/v1/analytics/ecom-overview'),
  });

  if (isLoading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircleNotch size={32} className="spin" color="var(--color-brand)" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="error-state">
        <Warning size={48} color="var(--color-fail)" />
        <h3>Failed to load E-Commerce Overview</h3>
        <p>{(error as Error).message}</p>
        <button className="btn btn-primary" onClick={() => refetch()}>Retry</button>
      </div>
    );
  }

  const overview = data || {
    total_listings_checked: 0,
    pass_rate: 0,
    recent_failures: [],
    recent_failure_count: 0,
  };

  return (
    <div className="fade-in-up">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-6)' }}>
        <div>
          <h2>E-Commerce Compliance Hub</h2>
          <p style={{ color: 'var(--color-text-secondary)', marginTop: 'var(--space-1)' }}>
            Marketplace compliance metrics and LMPC Rule 6(10) audit activity
          </p>
        </div>
        <Link to="/dashboard/ecommerce" className="btn btn-primary" style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
          <Globe size={18} />
          <span>Check Listing</span>
        </Link>
      </div>

      {/* KPI Cards */}
      <div className="grid-2" style={{ marginBottom: 'var(--space-6)' }}>
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <p style={{ fontSize: '0.8125rem', color: 'var(--color-text-secondary)', fontWeight: 500 }}>
                Total Listings Checked
              </p>
              <h1 style={{ marginTop: 'var(--space-2)', fontSize: '2.25rem', fontWeight: 800 }}>
                {overview.total_listings_checked}
              </h1>
            </div>
            <div style={{
              background: 'var(--color-brand-alpha-10, rgba(37, 99, 235, 0.1))',
              padding: 'var(--space-3)',
              borderRadius: 'var(--radius-md)',
              color: 'var(--color-brand)',
            }}>
              <Globe size={24} />
            </div>
          </div>
          <p style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)', marginTop: 'var(--space-3)' }}>
            Scoped to your platform checks
          </p>
        </div>

        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <p style={{ fontSize: '0.8125rem', color: 'var(--color-text-secondary)', fontWeight: 500 }}>
                LMPC Compliance Pass Rate
              </p>
              <h1 style={{ marginTop: 'var(--space-2)', fontSize: '2.25rem', fontWeight: 800, color: overview.pass_rate >= 80 ? 'var(--color-pass)' : 'var(--color-warn)' }}>
                {overview.pass_rate.toFixed(1)}%
              </h1>
            </div>
            <div style={{
              background: 'rgba(34, 197, 94, 0.1)',
              padding: 'var(--space-3)',
              borderRadius: 'var(--radius-md)',
              color: 'var(--color-pass)',
            }}>
              <CheckCircle size={24} />
            </div>
          </div>
          <p style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)', marginTop: 'var(--space-3)' }}>
            Mandatory declaration adherence
          </p>
        </div>
      </div>

      {/* Quick Launch Card */}
      <div className="card" style={{ marginBottom: 'var(--space-6)', background: 'linear-gradient(135deg, rgba(13, 148, 136, 0.05), rgba(15, 118, 110, 0.1))', border: '1px solid rgba(13, 148, 136, 0.2)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h4 style={{ color: 'var(--color-text-primary)' }}>Verify Any Marketplace Listing</h4>
            <p style={{ fontSize: '0.875rem', color: 'var(--color-text-secondary)', marginTop: 'var(--space-1)' }}>
              Check single Amazon, Flipkart, or Meesho URLs in real time for missing declarations.
            </p>
          </div>
          <Link to="/dashboard/ecommerce" className="btn btn-secondary" style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
            <span>Go to Listing Checker</span>
            <ArrowRight size={16} />
          </Link>
        </div>
      </div>

      {/* Recent Failures Table */}
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-4)' }}>
          <div>
            <h4>Recent Non-Compliant Listings</h4>
            <p style={{ fontSize: '0.75rem', color: 'var(--color-text-secondary)', marginTop: 2 }}>
              Listings missing mandatory declarations under Rule 6(10)
            </p>
          </div>
          <span style={{
            fontSize: '0.75rem',
            padding: '2px 8px',
            borderRadius: 'var(--radius-full, 9999px)',
            background: 'rgba(239, 68, 68, 0.1)',
            color: 'var(--color-fail)',
            fontWeight: 600,
          }}>
            {overview.recent_failures.length} Recorded
          </span>
        </div>

        {overview.recent_failures.length === 0 ? (
          <div style={{ padding: 'var(--space-6)', textAlign: 'center', color: 'var(--color-text-secondary)' }}>
            <p>No non-compliant listings logged yet.</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Listing URL</th>
                  <th>Verdict</th>
                  <th>Missing Declarations</th>
                  <th>Audited At</th>
                </tr>
              </thead>
              <tbody>
                {overview.recent_failures.map((item) => (
                  <tr key={item.id}>
                    <td style={{ maxWidth: 280, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      <a href={item.listing_url} target="_blank" rel="noopener noreferrer" style={{ color: 'var(--color-brand)', textDecoration: 'underline' }}>
                        {item.listing_url}
                      </a>
                    </td>
                    <td>
                      <span style={{
                        padding: '2px 8px',
                        borderRadius: 'var(--radius-sm, 4px)',
                        fontSize: '0.75rem',
                        fontWeight: 700,
                        background: 'rgba(239, 68, 68, 0.1)',
                        color: 'var(--color-fail)',
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: 4,
                      }}>
                        <XCircle size={14} />
                        {item.verdict}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                        {(item.missing_fields || []).map((f) => (
                          <span
                            key={f}
                            style={{
                              fontSize: '0.6875rem',
                              padding: '2px 6px',
                              borderRadius: 4,
                              background: 'rgba(239, 68, 68, 0.08)',
                              color: 'var(--color-fail)',
                              fontWeight: 500,
                            }}
                          >
                            {f}
                          </span>
                        ))}
                      </div>
                    </td>
                    <td style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)', whiteSpace: 'nowrap' }}>
                      {item.checked_at ? new Date(item.checked_at).toLocaleDateString() : '—'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};
