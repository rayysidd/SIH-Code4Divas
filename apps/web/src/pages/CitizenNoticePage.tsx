import React from 'react';
import { DeviceMobile, ShieldCheck, QrCode } from '@phosphor-icons/react';

export const CitizenNoticePage: React.FC = () => {
  return (
    <div className="fade-in-up" style={{ maxWidth: 680, margin: '40px auto', textAlign: 'center' }}>
      <div className="card" style={{ padding: 'var(--space-8)' }}>
        <div style={{
          width: 72,
          height: 72,
          borderRadius: '50%',
          background: 'rgba(37, 99, 235, 0.1)',
          color: 'var(--color-brand)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '0 auto var(--space-4)',
        }}>
          <DeviceMobile size={40} weight="duotone" />
        </div>

        <h2 style={{ marginBottom: 'var(--space-2)' }}>Citizen Reporting via Mobile App</h2>
        <p style={{ color: 'var(--color-text-secondary)', fontSize: '1rem', lineHeight: 1.6, marginBottom: 'var(--space-6)' }}>
          To submit real-time product label violation reports with GPS tagging and camera capture, please use the official <strong>LabelLens Mobile Application</strong> for Android and iOS.
        </p>

        <div style={{
          background: 'var(--color-surface-2)',
          padding: 'var(--space-4)',
          borderRadius: 'var(--radius-lg)',
          marginBottom: 'var(--space-6)',
          textAlign: 'left',
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--space-3)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
            <ShieldCheck size={20} color="var(--color-pass)" />
            <span style={{ fontSize: '0.875rem', fontWeight: 500 }}>
              Confidential reporting under Legal Metrology Act, 2009
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-3)' }}>
            <QrCode size={20} color="var(--color-brand)" />
            <span style={{ fontSize: '0.875rem', fontWeight: 500 }}>
              Instant on-device OCR and offline verification capabilities
            </span>
          </div>
        </div>

        <p style={{ fontSize: '0.8125rem', color: 'var(--color-text-tertiary)' }}>
          Dept. of Consumer Affairs • Government of India
        </p>
      </div>
    </div>
  );
};
