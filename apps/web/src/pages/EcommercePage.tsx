import React, { useState } from 'react';
import { ArrowsLeftRight, CircleNotch, CheckCircle, XCircle } from '@phosphor-icons/react';
import { useMutation } from '@tanstack/react-query';
import { apiPost } from '../lib/apiClient';

interface ListingCheckResponse {
  id?: string;
  verdict: 'PASS' | 'FAIL';
  missing_fields: string[];
  listing_url: string;
  checked_at?: string;
}

const MANDATORY_DECLARATIONS = [
  { key: 'MRP', label: 'Maximum Retail Price (MRP)' },
  { key: 'NET_QUANTITY', label: 'Net Quantity / Unit Sale Price' },
  { key: 'COUNTRY_OF_ORIGIN', label: 'Country of Origin' },
  { key: 'MANUFACTURER_PACKER', label: 'Manufacturer / Packer Details' },
  { key: 'CONSUMER_CARE', label: 'Consumer Care / Contact Information' },
];

export const EcommercePage: React.FC = () => {
  const [url, setUrl] = useState('');

  const listingMutation = useMutation({
    mutationFn: (listingUrl: string) =>
      apiPost<ListingCheckResponse>('/v1/batch/listings/check', { listing_url: listingUrl }),
  });

  const handleCheck = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (url.trim()) {
      listingMutation.mutate(url.trim());
    }
  };

  const isPass = listingMutation.data?.verdict === 'PASS';
  const missingFields = listingMutation.data?.missing_fields || [];

  return (
    <div className="fade-in-up">
      <h2 style={{ marginBottom: 'var(--space-2)' }}>E-Commerce Compliance Checker</h2>
      <p style={{ color: 'var(--color-text-secondary)', marginBottom: 'var(--space-6)' }}>
        Verify product listing URLs against LMPC Rule 6(10) mandatory e-commerce declarations.
      </p>

      {/* URL Input Form */}
      <div className="card" style={{ marginBottom: 'var(--space-6)' }}>
        <h4 style={{ marginBottom: 'var(--space-4)' }}>Product Listing URL</h4>
        <form onSubmit={handleCheck} style={{ display: 'flex', gap: 'var(--space-3)' }}>
          <input
            type="url"
            placeholder="https://www.amazon.in/dp/... or https://www.flipkart.com/..."
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            required
            style={{
              flex: 1,
              padding: '10px 16px',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-surface-4)',
              fontFamily: 'inherit',
              fontSize: '0.875rem',
              outline: 'none',
              background: 'var(--color-surface-0)',
              color: 'var(--color-text-primary)',
            }}
          />
          <button
            type="submit"
            className="btn btn-primary"
            disabled={!url.trim() || listingMutation.isPending}
            style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}
          >
            {listingMutation.isPending ? (
              <>
                <CircleNotch size={16} className="spin" />
                <span>Checking…</span>
              </>
            ) : (
              <>
                <ArrowsLeftRight size={16} />
                <span>Check Listing</span>
              </>
            )}
          </button>
        </form>
      </div>

      {/* Error State */}
      {listingMutation.isError && (
        <div className="error-state" style={{ marginBottom: 'var(--space-6)' }}>
          <div className="error-state-icon">⚠️</div>
          <h3>Check failed</h3>
          <p>{(listingMutation.error as Error)?.message || 'Could not verify listing'}</p>
          <button className="btn btn-primary" onClick={() => handleCheck()}>Retry</button>
        </div>
      )}

      {/* Result Card */}
      {listingMutation.isSuccess && listingMutation.data && (
        <div className="card fade-in-up">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-4)' }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-2)' }}>
                <span
                  style={{
                    padding: '4px 12px',
                    borderRadius: 'var(--radius-full, 9999px)',
                    fontWeight: 700,
                    fontSize: '0.8125rem',
                    background: isPass ? 'rgba(34, 197, 94, 0.15)' : 'rgba(239, 68, 68, 0.15)',
                    color: isPass ? 'var(--color-pass)' : 'var(--color-fail)',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: 6,
                  }}
                >
                  {isPass ? <CheckCircle size={16} weight="fill" /> : <XCircle size={16} weight="fill" />}
                  {isPass ? 'COMPLIANT' : 'NON-COMPLIANT'}
                </span>
                <span style={{ fontSize: '0.875rem', fontWeight: 600, color: 'var(--color-text-primary)' }}>
                  {isPass ? 'All declarations verified' : `${missingFields.length} Mandatory Declarations Missing`}
                </span>
              </div>
              <p className="mono" style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)', marginTop: 6 }}>
                Rule basis: Rule 6(10), Legal Metrology (Packaged Commodities) Rules 2011
              </p>
            </div>
          </div>

          <table className="data-table data-table-responsive">
            <thead>
              <tr>
                <th>Mandatory Declaration</th>
                <th>Status</th>
                <th>Requirement</th>
              </tr>
            </thead>
            <tbody>
              {MANDATORY_DECLARATIONS.map((decl) => {
                const missing = missingFields.includes(decl.key);
                return (
                  <tr key={decl.key}>
                    <td data-label="Declaration" style={{ fontWeight: 500 }}>{decl.label}</td>
                    <td data-label="Status">
                      {missing ? (
                        <span style={{ color: 'var(--color-fail)', display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
                          <XCircle size={16} weight="fill" /> Missing
                        </span>
                      ) : (
                        <span style={{ color: 'var(--color-pass)', display: 'flex', alignItems: 'center', gap: 6, fontWeight: 600 }}>
                          <CheckCircle size={16} weight="fill" /> Present
                        </span>
                      )}
                    </td>
                    <td data-label="Requirement" style={{ fontSize: '0.8125rem', color: 'var(--color-text-secondary)' }}>
                      Mandatory on all e-commerce product display pages
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};
