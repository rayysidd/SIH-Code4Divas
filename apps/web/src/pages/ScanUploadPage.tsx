import React, { useState, useCallback, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { UploadSimple, Camera } from '@phosphor-icons/react';
import { useMutation, useQuery } from '@tanstack/react-query';
import { apiUpload, apiGet } from '../lib/apiClient';

interface ScanAsyncResponse {
  scan_id: string;
  status: string;
  poll_url: string;
}

interface ScanStatusResponse {
  scan_id: string;
  status: string;
  error_message?: string;
}

export const ScanUploadPage: React.FC = () => {
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [dragOver, setDragOver] = useState(false);
  const [scanId, setScanId] = useState<string | null>(null);
  const [timeoutReached, setTimeoutReached] = useState(false);
  
  const navigate = useNavigate();

  const scanMutation = useMutation({
    mutationFn: async (imageFile: File) => {
      const formData = new FormData();
      formData.append('images', imageFile);
      formData.append('rule_version', '2024.01');
      return apiUpload<ScanAsyncResponse>('/v1/check/label', formData);
    },
    onSuccess: (data) => {
      setScanId(data.scan_id);
      
      // Safety timeout of 60 seconds
      setTimeout(() => {
        setTimeoutReached(true);
      }, 60000);
    },
  });

  const { data: statusData, error: statusError } = useQuery({
    queryKey: ['scanStatus', scanId],
    queryFn: () => apiGet<ScanStatusResponse>(`/v1/check/label/status/${scanId}`),
    enabled: !!scanId && !timeoutReached,
    refetchInterval: (query) => {
      if (timeoutReached) return false;
      const status = query.state.data?.status;
      if (status === 'COMPLETED' || status === 'FAILED') return false;
      return 2000;
    },
  });

  useEffect(() => {
    if (statusData?.status === 'COMPLETED') {
      apiGet(`/v1/check/label/result/${scanId}`).then(() => {
        navigate(`/dashboard/scan/${scanId}`);
      }).catch(() => {
        navigate(`/dashboard/scan/${scanId}`);
      });
    }
  }, [statusData, navigate, scanId]);

  const handleFile = useCallback((f: File) => {
    setFile(f);
    const reader = new FileReader();
    reader.onload = (e) => setPreview(e.target?.result as string);
    reader.readAsDataURL(f);
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    const dropped = e.dataTransfer.files[0];
    if (dropped && dropped.type.startsWith('image/')) {
      handleFile(dropped);
    }
  }, [handleFile]);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files?.[0]) {
      handleFile(e.target.files[0]);
    }
  };

  const handleScan = () => {
    if (file) {
      setScanId(null);
      setTimeoutReached(false);
      scanMutation.mutate(file);
    }
  };
  
  const resetUpload = () => {
    setScanId(null);
    setTimeoutReached(false);
    scanMutation.reset();
  };

  const isProcessing = scanMutation.isPending || (scanId && statusData?.status === 'PROCESSING' && !timeoutReached) || (!statusData && scanId && !timeoutReached);
  const hasFailed = statusData?.status === 'FAILED' || statusError;

  if (isProcessing) {
    return (
      <div className="processing-overlay fade-in-up">
        <div className="processing-ring" />
        <h3>Analyzing Label…</h3>
        <p style={{ color: 'var(--color-text-secondary)', marginTop: 'var(--space-2)' }}>
          Running OCR pipeline and LMPC rules engine
        </p>
        <div className="mono" style={{ color: 'var(--color-text-tertiary)', marginTop: 'var(--space-4)', fontSize: '0.75rem' }}>
          This typically takes 5–15 seconds
        </div>
      </div>
    );
  }

  if (hasFailed || timeoutReached) {
    return (
      <div className="processing-overlay fade-in-up" style={{ backgroundColor: 'var(--color-surface-1)' }}>
        <h3 style={{ color: 'var(--color-status-fail)' }}>Scan Failed</h3>
        <p style={{ color: 'var(--color-text-secondary)', marginTop: 'var(--space-2)', marginBottom: 'var(--space-4)' }}>
          {timeoutReached 
            ? "This is taking longer than expected — please try again." 
            : statusData?.error_message || "An error occurred while processing the label."}
        </p>
        <button className="btn btn-primary" onClick={resetUpload}>
          Try Again
        </button>
      </div>
    );
  }

  return (
    <>
      <div style={{ marginBottom: 'var(--space-6)' }}>
        <h2>New Scan</h2>
        <p style={{ color: 'var(--color-text-secondary)', marginTop: 'var(--space-1)' }}>
          Upload a product label image for instant LMPC compliance verification
        </p>
      </div>

      {/* Upload Area */}
      <div className="card" style={{ marginBottom: 'var(--space-6)' }}>
        {!preview ? (
          <div
            className={`upload-zone ${dragOver ? 'drag-over' : ''}`}
            onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
            onDragLeave={() => setDragOver(false)}
            onDrop={handleDrop}
            onClick={() => document.getElementById('scan-file-input')?.click()}
          >
            <input
              id="scan-file-input"
              type="file"
              accept=".jpg,.jpeg,.png,.webp"
              onChange={handleFileSelect}
              style={{ display: 'none' }}
            />
            <div className="upload-zone-icon"><Camera size={48} /></div>
            <h3>Drop label image here</h3>
            <p>or click to browse • Supports JPG, PNG, WebP</p>
          </div>
        ) : (
          <div style={{ display: 'flex', gap: 'var(--space-6)', alignItems: 'flex-start', flexWrap: 'wrap' }}>
            <div style={{ flex: '0 0 280px', position: 'relative' }}>
              <img
                src={preview}
                alt="Selected label"
                style={{
                  width: '100%', borderRadius: 'var(--radius-lg)',
                  border: '2px solid var(--color-surface-3)',
                }}
              />
              <button
                className="btn btn-secondary"
                style={{ position: 'absolute', bottom: 8, right: 8, fontSize: '0.75rem', padding: '4px 10px' }}
                onClick={() => { setFile(null); setPreview(null); }}
              >
                Change
              </button>
            </div>
            <div style={{ flex: 1 }}>
              <h4 style={{ marginBottom: 'var(--space-2)' }}>Ready to scan</h4>
              <div style={{ fontSize: '0.875rem', color: 'var(--color-text-secondary)', marginBottom: 'var(--space-2)' }}>
                <strong>File:</strong> {file?.name}
              </div>
              <div style={{ fontSize: '0.875rem', color: 'var(--color-text-secondary)', marginBottom: 'var(--space-4)' }}>
                <strong>Size:</strong> {file ? (file.size / 1024).toFixed(1) : 0} KB
              </div>

              {scanMutation.isError && (
                <div className="login-error" style={{ marginBottom: 'var(--space-4)' }}>
                  {(scanMutation.error as Error)?.message || 'Upload failed — please try again'}
                </div>
              )}

              <button className="btn btn-primary" onClick={handleScan} style={{ padding: 'var(--space-3) var(--space-6)' }}>
                <UploadSimple size={18} /> Scan Label
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Tips */}
      <div className="card" style={{ background: 'var(--color-surface-2)' }}>
        <h4 style={{ marginBottom: 'var(--space-3)' }}>📋 Tips for best results</h4>
        <ul style={{ paddingLeft: 'var(--space-5)', fontSize: '0.875rem', color: 'var(--color-text-secondary)', lineHeight: 1.8 }}>
          <li>Capture the full label in a single shot — avoid cropping key information</li>
          <li>Ensure good lighting and minimal glare on reflective packaging</li>
          <li>Include the Principal Display Panel (front face) of the package</li>
          <li>For multi-panel labels, take separate photos of each panel</li>
        </ul>
      </div>
    </>
  );
};
