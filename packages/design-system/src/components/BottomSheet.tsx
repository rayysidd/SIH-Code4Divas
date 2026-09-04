import React from 'react';
import { colors } from '../tokens/colors';
import { radius } from '../tokens/radius';

export interface BottomSheetProps {
  isOpen: boolean;
  onClose: () => void;
  children: React.ReactNode;
}

export const BottomSheet: React.FC<BottomSheetProps> = ({ isOpen, onClose, children }) => {
  if (!isOpen) return null;

  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 1000, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
      <div onClick={onClose} style={{ position: 'absolute', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)' }} />
      <div style={{
        position: 'relative',
        backgroundColor: colors.surface['0'],
        borderTopLeftRadius: radius.xl,
        borderTopRightRadius: radius.xl,
        padding: '24px',
        maxHeight: '90vh',
        overflowY: 'auto'
      }}>
        <div style={{ width: '40px', height: '4px', backgroundColor: colors.surface['3'], borderRadius: radius.full, margin: '0 auto 16px' }} />
        {children}
      </div>
    </div>
  );
};
