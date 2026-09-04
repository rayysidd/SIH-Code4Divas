import React, { useState, useCallback } from 'react';
import { ArrowsLeftRight, UploadSimple, CircleNotch, CheckCircle, XCircle } from '@phosphor-icons/react';
import { useMutation } from '@tanstack/react-query';
import { apiPost, } from '../lib/apiClient';

interface CrossChannelField {
  declaration: string;
  physical_label: string | null;
  ecom_listing: string | null;
  match_status: string;
}

interface CrossChannelResponse {
  scan_id: string;
  listing_url: string;
  overall_verdict: string;
  rule_basis: string;
  fields: CrossChannelField[];
}

export const EcommercePage: React.FC = () => {
  const [url, setUrl] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [dragOver, setDragOver] = useState(false);

  const listingMutation = useMutation({
    mutationFn: (listingUrl: string) =>
      apiPost<CrossChannelResponse>('/v1/check/listing', { listing_url: listingUrl }),
  });

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    const dropped = e.dataTransfer.files[0];
    if (dropped && dropped.type.startsWith('image/')) {
      setFile(dropped);
    }
  }, []);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files?.[0]) {
      setFile(e.target.files[0]);
    }
  };

  const handleCheck = () => {
    if (url.trim()) {
      listingMutation.mutate(url.trim());
    }
  };

  const statusIcon = (s: string) => {
    if (s === 'MATCH') return <span style={{ color: 'var(--color-pass)', display: 'flex', alignItems: 'center', gap: 4 }}><CheckCircle size={16} weight="fill" /> MATCH</span>;
    if (s === 'PARTIAL' || s === 'MISMATCH') return <span style={{ color: 'var(--color-warn)', display: 'flex', alignItems: 'center', gap: 4 }}><XCircle size={16} /> MISMATCH</span>;
    return <span style={{ color: 'var(--color-fail)', display: 'flex', alignItems: 'center', gap: 4 }}><XCircle size={16} weight="fill" /> MISSING</span>;
  };

  return (
    <>
      <h2 style={{ marginBottom: 'var(--space-6)' }}>E-Commerce Compliance Checker</h2>

      {/* Step 1: Physical Label */}
      <div className="card" style={{ marginBottom: 'var(--space-6)' }}>
        <h4 style={{ marginBottom: 'var(--space-4)' }}>Step 1: Physical Label</h4>
        <div style={{ display: 'flex', gap: 'var(--space-6)', flexWrap: 'wrap' }}>
          <div
            className={`upload-zone ${dragOver ? 'drag-over' : ''}`}
            style={{ flex: 1, minWidth: 200 }}
            onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
            onDragLeave={() => setDragOver(false)}
            onDrop={handleDrop}
            onClick={() => document.getElementById('ecom-file-input')?.click()}
          >
            <input
              id="ecom-file-input"
              type="file"
              accept="image/*"
              onChange={handleFileSelect}
              style={{ display: 'none' }}
            />
            {file ? (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 'var(--space-2)' }}>
                <CheckCircle size={32} weight="fill" color="var(--color-pass)" />
                <p style={{ fontWeight: 600, color: 'var(--color-text-primary)' }}>{file.name}</p>
                <p style={{ fontSize: '0.75rem' }}>Click to change</p>
              </div>
            ) : (
              <>
                <div className="upload-zone-icon"><UploadSimple size={32} /></div>
                <p>Drag & drop label image here, or click to upload</p>
              </>
            )}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', color: 'var(--color-text-tertiary)', fontWeight: 600 }}>OR</div>
          <div style={{
            flex: 1, minWidth: 200, border: '1px solid var(--color-surface-4)', borderRadius: 'var(--radius-lg)',
            padding: 'var(--space-6)', display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <select style={{
              padding: '8px 16px', borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-surface-4)', fontFamily: 'inherit',
              fontSize: '0.875rem', background: 'var(--color-surface-0)', color: 'var(--color-text-primary)',
            }}>
              <option>Select from existing scans…</option>
            </select>
          </div>
        </div>
      </div>

      {/* Step 2: E-Commerce URL */}
      <div className="card" style={{ marginBottom: 'var(--space-6)' }}>
        <h4 style={{ marginBottom: 'var(--space-4)' }}>Step 2: E-Commerce Listing URL</h4>
        <div style={{ display: 'flex', gap: 'var(--space-3)' }}>
          <input
            type="url"
            placeholder="https://www.amazon.in/dp/B09XXXX…"
            value={url}
            onChange={e => setUrl(e.target.value)}
            style={{
              flex: 1, padding: '10px 16px', borderRadius: 'var(--radius-md)',
              border: '1px solid var(--color-surface-4)', fontFamily: 'inherit',
              fontSize: '0.875rem', outline: 'none', background: 'var(--color-surface-0)',
              color: 'var(--color-text-primary)',
            }}
          />
          <button
            className="btn btn-primary"
            onClick={handleCheck}
            disabled={!url.trim() || listingMutation.isPending}
          >
            {listingMutation.isPending ? (
              <><CircleNotch size={16} className="spin" /> Checking…</>
            ) : (
              <><ArrowsLeftRight size={16} /> Check</>
            )}
          </button>
        </div>
      </div>

      {/* Error State */}
      {listingMutation.isError && (
        <div className="error-state" style={{ marginBottom: 'var(--space-6)' }}>
          <div className="error-state-icon">⚠️</div>
          <h3>Check failed</h3>
          <p>{(listingMutation.error as Error)?.message || 'Could not verify listing'}</p>
          <button className="btn btn-primary" onClick={handleCheck}>Retry</button>
        </div>
      )}

      {/* Result Table */}
      {listingMutation.isSuccess && listingMutation.data && (
        <div className="card fade-in-up">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--space-4)' }}>
            <div>
              <h4>Cross-Channel Reconciliation Report</h4>
              <p style={{
                fontSize: '0.75rem', fontWeight: 600, marginTop: 4,
                color: listingMutation.data.overall_verdict === 'PASS' ? 'var(--color-pass)' : 'var(--color-fail)',
              }}>
                Overall: {listingMutation.data.overall_verdict}
                {listingMutation.data.fields.filter(f => f.match_status !== 'MATCH').length > 0 &&
                  ` — ${listingMutation.data.fields.filter(f => f.match_status !== 'MATCH').length} declarations need attention`}
              </p>
              <p className="mono" style={{ fontSize: '0.6875rem', color: 'var(--color-text-tertiary)', marginTop: 2 }}>
                Rule basis: {listingMutation.data.rule_basis}
              </p>
            </div>
            <button className="btn btn-secondary" style={{ fontSize: '0.75rem' }}>Export Report</button>
          </div>
          <table className="data-table data-table-responsive">
            <thead>
              <tr>
                <th>Declaration</th>
                <th>Physical Label</th>
                <th>E-com Listing</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {listingMutation.data.fields.map((f, i) => (
                <tr key={i}>
                  <td data-label="Declaration" style={{ fontWeight: 500 }}>{f.declaration}</td>
                  <td data-label="Physical Label">{f.physical_label || '—'}</td>
                  <td data-label="E-com Listing">{f.ecom_listing || '—'}</td>
                  <td data-label="Status">{statusIcon(f.match_status)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
};
