import React, { useState } from 'react';
import { Stack, CircleNotch, CheckCircle, } from '@phosphor-icons/react';
import { useMutation, useQuery } from '@tanstack/react-query';
import { apiPost, apiGet } from '../lib/apiClient';

interface BatchResponse {
  batch_id: string;
  status: string;
  total_urls: number;
  estimated_completion: string;
  message: string;
}

interface BatchStatus {
  batch_id: string;
  status: string;
  processed: number;
  total: number;
  pass_count: number;
  fail_count: number;
  pending: number;
  eta_minutes: number;
}

export const BatchPage: React.FC = () => {
  const [urls, setUrls] = useState('');
  const [webhookUrl, setWebhookUrl] = useState('');
  const [reportEmail, setReportEmail] = useState('');
  const [submittedBatchId, setSubmittedBatchId] = useState<string | null>(null);

  const submitMutation = useMutation({
    mutationFn: async () => {
      const urlList = urls.split('\n').map(u => u.trim()).filter(u => u.length > 0);
      return apiPost<BatchResponse>('/v1/batch/listings', {
        listing_urls: urlList,
        webhook_url: webhookUrl || undefined,
        report_email: reportEmail || undefined,
      });
    },
    onSuccess: (data) => {
      setSubmittedBatchId(data.batch_id);
    },
  });

  const statusQuery = useQuery({
    queryKey: ['batch-status', submittedBatchId],
    queryFn: () => apiGet<BatchStatus>(`/v1/batch/listings/${submittedBatchId}`),
    enabled: !!submittedBatchId,
    refetchInterval: 10000, // Poll every 10s
  });

  const urlCount = urls.split('\n').filter(u => u.trim().length > 0).length;

  return (
    <>
      <div style={{ marginBottom: 'var(--space-6)' }}>
        <h2>Batch Audit</h2>
        <p style={{ color: 'var(--color-text-secondary)', marginTop: 'var(--space-1)', fontSize: '0.875rem' }}>
          Submit bulk e-commerce listing URLs for overnight compliance audit
        </p>
      </div>

      {!submittedBatchId ? (
        <>
          {/* URL Input */}
          <div className="card" style={{ marginBottom: 'var(--space-6)' }}>
            <h4 style={{ marginBottom: 'var(--space-3)' }}>Listing URLs</h4>
            <p style={{ fontSize: '0.8125rem', color: 'var(--color-text-tertiary)', marginBottom: 'var(--space-3)' }}>
              Enter one URL per line (max 10,000)
            </p>
            <textarea
              className="form-textarea"
              value={urls}
              onChange={e => setUrls(e.target.value)}
              placeholder="https://www.amazon.in/dp/B09XXXX&#10;https://www.flipkart.com/product/YYYY&#10;https://www.myntra.com/..."
              rows={8}
            />
            <div style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)', marginTop: 'var(--space-2)' }}>
              {urlCount} URL{urlCount !== 1 ? 's' : ''} entered
            </div>
          </div>

          {/* Optional Fields */}
          <div className="card" style={{ marginBottom: 'var(--space-6)' }}>
            <h4 style={{ marginBottom: 'var(--space-3)' }}>Notification (optional)</h4>
            <div style={{ display: 'flex', gap: 'var(--space-4)', flexWrap: 'wrap' }}>
              <div style={{ flex: 1, minWidth: 200 }}>
                <label style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--color-text-secondary)', display: 'block', marginBottom: 'var(--space-1)' }}>
                  Webhook URL
                </label>
                <input
                  type="url"
                  placeholder="https://hooks.example.com/…"
                  value={webhookUrl}
                  onChange={e => setWebhookUrl(e.target.value)}
                  style={{
                    width: '100%', padding: '8px 12px', borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--color-surface-4)', fontFamily: 'inherit',
                    fontSize: '0.875rem', outline: 'none', background: 'var(--color-surface-0)',
                    color: 'var(--color-text-primary)',
                  }}
                />
              </div>
              <div style={{ flex: 1, minWidth: 200 }}>
                <label style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--color-text-secondary)', display: 'block', marginBottom: 'var(--space-1)' }}>
                  Report Email
                </label>
                <input
                  type="email"
                  placeholder="qa-team@company.com"
                  value={reportEmail}
                  onChange={e => setReportEmail(e.target.value)}
                  style={{
                    width: '100%', padding: '8px 12px', borderRadius: 'var(--radius-md)',
                    border: '1px solid var(--color-surface-4)', fontFamily: 'inherit',
                    fontSize: '0.875rem', outline: 'none', background: 'var(--color-surface-0)',
                    color: 'var(--color-text-primary)',
                  }}
                />
              </div>
            </div>
          </div>

          {/* Submit Error */}
          {submitMutation.isError && (
            <div className="login-error" style={{ marginBottom: 'var(--space-4)' }}>
              {(submitMutation.error as Error)?.message || 'Batch submission failed'}
            </div>
          )}

          {/* Submit */}
          <button
            className="btn btn-primary"
            onClick={() => submitMutation.mutate()}
            disabled={urlCount === 0 || submitMutation.isPending}
            style={{ padding: 'var(--space-3) var(--space-6)' }}
          >
            {submitMutation.isPending ? (
              <><CircleNotch size={16} className="spin" /> Submitting…</>
            ) : (
              <><Stack size={16} /> Submit Batch ({urlCount} URLs)</>
            )}
          </button>
        </>
      ) : (
        /* Batch Status */
        <div className="card fade-in-up">
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)', marginBottom: 'var(--space-6)' }}>
            <CheckCircle size={24} weight="fill" color="var(--color-pass)" />
            <div>
              <h3>Batch Submitted</h3>
              <p className="mono" style={{ fontSize: '0.8125rem', color: 'var(--color-text-tertiary)' }}>
                {submittedBatchId}
              </p>
            </div>
          </div>

          {statusQuery.isLoading && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)', color: 'var(--color-text-tertiary)' }}>
              <CircleNotch size={16} className="spin" /> Loading status…
            </div>
          )}

          {statusQuery.data && (
            <>
              <div style={{ marginBottom: 'var(--space-4)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 'var(--space-2)' }}>
                  <span style={{ fontSize: '0.8125rem', fontWeight: 600 }}>Progress</span>
                  <span style={{ fontSize: '0.8125rem', color: 'var(--color-text-secondary)' }}>
                    {statusQuery.data.processed}/{statusQuery.data.total}
                  </span>
                </div>
                <div className="progress-bar">
                  <div className="progress-bar-fill" style={{ width: `${(statusQuery.data.processed / statusQuery.data.total) * 100}%` }} />
                </div>
              </div>

              <div className="kpi-grid" style={{ gridTemplateColumns: 'repeat(3, 1fr)', marginBottom: 'var(--space-4)' }}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--color-pass)' }}>{statusQuery.data.pass_count}</div>
                  <div style={{ fontSize: '0.6875rem', color: 'var(--color-text-tertiary)', textTransform: 'uppercase' }}>Passed</div>
                </div>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--color-fail)' }}>{statusQuery.data.fail_count}</div>
                  <div style={{ fontSize: '0.6875rem', color: 'var(--color-text-tertiary)', textTransform: 'uppercase' }}>Failed</div>
                </div>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--color-text-tertiary)' }}>{statusQuery.data.pending}</div>
                  <div style={{ fontSize: '0.6875rem', color: 'var(--color-text-tertiary)', textTransform: 'uppercase' }}>Pending</div>
                </div>
              </div>

              <div className="mono" style={{ fontSize: '0.75rem', color: 'var(--color-text-tertiary)' }}>
                ETA: ~{statusQuery.data.eta_minutes} minutes · Status: {statusQuery.data.status}
              </div>
            </>
          )}

          <div style={{ marginTop: 'var(--space-6)' }}>
            <button className="btn btn-secondary" onClick={() => setSubmittedBatchId(null)}>
              Submit Another Batch
            </button>
          </div>
        </div>
      )}
    </>
  );
};
