import React from 'react';
import { colors } from '../tokens/colors';
import { typography } from '../tokens/typography';

export interface AnnotatedImageViewerProps {
  imageUrl: string;
  onClose: () => void;
}

export const AnnotatedImageViewer: React.FC<AnnotatedImageViewerProps> = ({ imageUrl, onClose }) => {
  return (
    <div style={{
      position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.9)', zIndex: 1000,
      display: 'flex', flexDirection: 'column', color: colors.text.inverse
    }}>
      <div style={{ padding: '16px', display: 'flex', justifyContent: 'space-between' }}>
        <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'white', cursor: 'pointer' }}>
          ✕ Close
        </button>
        <span>Annotated Label View</span>
      </div>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <img src={imageUrl} alt="Annotated" style={{ maxWidth: '100%', maxHeight: '100%', objectFit: 'contain' }} />
      </div>
    </div>
  );
};
