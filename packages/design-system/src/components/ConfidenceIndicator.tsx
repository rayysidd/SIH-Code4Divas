import React from 'react';
import { Gauge, Warning } from '@phosphor-icons/react';
import { colors } from '../tokens/colors';
import { typography } from '../tokens/typography';
import { radius } from '../tokens/radius';

export interface ConfidenceIndicatorProps {
  confidence: number; // 0 to 100
}

export const ConfidenceIndicator: React.FC<ConfidenceIndicatorProps> = ({ confidence }) => {
  let level = 'LOW';
  let color = colors.status.fail;
  let icon = <Warning size={16} color={color} weight="fill" />;

  if (confidence >= 85) {
    level = 'HIGH';
    color = colors.brand.secondary;
    icon = <Gauge size={16} color={color} weight="fill" />;
  } else if (confidence >= 60) {
    level = 'MEDIUM';
    color = colors.status.warn;
    icon = <Gauge size={16} color={color} weight="fill" />;
  }

  // 12 blocks total for the gauge
  const totalBlocks = 12;
  const filledBlocks = Math.round((confidence / 100) * totalBlocks);

  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: '8px' }}>
      {icon}
      <div style={{ display: 'flex', gap: '2px' }}>
        {Array.from({ length: totalBlocks }).map((_, i) => (
          <div
            key={i}
            style={{
              width: '6px',
              height: '12px',
              backgroundColor: i < filledBlocks ? color : colors.surface['3'],
              borderRadius: radius.sm,
            }}
          />
        ))}
      </div>
      <span
        style={{
          fontFamily: typography.fontFamily.primary,
          fontSize: typography.sizes.body2,
          fontWeight: typography.weights.medium,
          color: colors.text.primary,
        }}
      >
        {confidence}%
      </span>
    </div>
  );
};
