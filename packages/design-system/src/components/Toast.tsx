import React from 'react';
import { colors } from '../tokens/colors';
import { typography } from '../tokens/typography';
import { radius } from '../tokens/radius';
import { shadows } from '../tokens/shadows';

export type ToastType = 'success' | 'error' | 'info' | 'warning';

export interface ToastProps {
  message: string;
  type?: ToastType;
  onClose: () => void;
}

export const Toast: React.FC<ToastProps> = ({ message, type = 'info', onClose }) => {
  const config = {
    success: { border: colors.status.pass, icon: '✓' },
    error: { border: colors.status.fail, icon: '✗' },
    info: { border: colors.brand.primary, icon: 'i' },
    warning: { border: colors.status.warn, icon: '⚠' },
  };

  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      backgroundColor: colors.surface['0'],
      borderLeft: `4px solid ${config[type].border}`,
      boxShadow: shadows.elev2,
      borderRadius: radius.md,
      padding: '12px 16px',
      gap: '12px',
      fontFamily: typography.fontFamily.primary,
      fontSize: typography.sizes.body2
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        <span style={{ color: config[type].border, fontWeight: 'bold' }}>{config[type].icon}</span>
        <span>{message}</span>
      </div>
      <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: colors.text.tertiary }}>
        ✕
      </button>
    </div>
  );
};
