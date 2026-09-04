import React, { useState } from 'react';
import { CaretDown, CaretUp } from '@phosphor-icons/react';
import { VerdictBadge, VerdictType } from './VerdictBadge';
import { colors } from '../tokens/colors';
import { spacing } from '../tokens/spacing';
import { typography } from '../tokens/typography';
import { radius } from '../tokens/radius';

export interface CheckRowProps {
  verdict: VerdictType;
  ruleCitation: string;
  shortDescription: string;
  foundValue?: string;
  requiredValue?: string;
  confidence: number;
  evidenceImageUrl?: string;
  isConfirmed?: boolean;
  isDisputed?: boolean;
}

export const CheckRow: React.FC<CheckRowProps> = ({
  verdict,
  ruleCitation,
  shortDescription,
  foundValue,
  requiredValue,
  confidence,
  evidenceImageUrl,
  isConfirmed,
  isDisputed,
}) => {
  const [isExpanded, setIsExpanded] = useState(false);

  let leftBorderColor = 'transparent';
  if (isConfirmed) leftBorderColor = colors.brand.primary;
  if (isDisputed) leftBorderColor = colors.surface['3'];

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        borderBottom: `1px solid ${colors.surface['3']}`,
        borderLeft: `4px solid ${leftBorderColor}`,
        backgroundColor: colors.surface['0'],
      }}
    >
      <div
        role="button"
        aria-expanded={isExpanded}
        onClick={() => setIsExpanded(!isExpanded)}
        style={{
          display: 'flex',
          alignItems: 'center',
          padding: spacing[4],
          cursor: 'pointer',
          gap: spacing[3],
        }}
      >
        <VerdictBadge verdict={verdict} size="sm" />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
          <span
            style={{
              fontFamily: typography.fontFamily.primary,
              fontSize: typography.sizes.body2,
              fontWeight: typography.weights.medium,
              color: colors.text.primary,
              textDecoration: isDisputed ? 'line-through' : 'none',
            }}
          >
            <span style={{ fontFamily: typography.fontFamily.mono, marginRight: spacing[2] }}>
              {ruleCitation}
            </span>
            {shortDescription}
          </span>
        </div>
        {isExpanded ? <CaretUp size={20} color={colors.text.secondary} /> : <CaretDown size={20} color={colors.text.secondary} />}
      </div>

      {isExpanded && (
        <div
          style={{
            padding: `0 ${spacing[4]} ${spacing[4]}`,
            display: 'flex',
            flexDirection: 'column',
            gap: spacing[2],
            fontFamily: typography.fontFamily.primary,
            fontSize: typography.sizes.body2,
            color: colors.text.secondary,
            marginLeft: '44px', // align with text
          }}
        >
          {foundValue && (
            <div>
              <strong>Found:</strong> {foundValue}
            </div>
          )}
          {requiredValue && (
            <div>
              <strong>Required:</strong> {requiredValue}
            </div>
          )}
          <div style={{ display: 'flex', alignItems: 'center', gap: spacing[2] }}>
            <strong>Confidence:</strong>
            <div style={{ width: '100px', height: '6px', backgroundColor: colors.surface['3'], borderRadius: radius.sm }}>
              <div
                style={{
                  width: `${confidence}%`,
                  height: '100%',
                  backgroundColor: confidence >= 85 ? colors.brand.secondary : confidence >= 60 ? colors.status.warn : colors.status.fail,
                  borderRadius: radius.sm,
                }}
              />
            </div>
            <span>{confidence}%</span>
          </div>
          {evidenceImageUrl && (
            <div style={{ marginTop: spacing[2] }}>
              <strong>Evidence:</strong>
              <img
                src={evidenceImageUrl}
                alt="Evidence crop"
                style={{
                  display: 'block',
                  marginTop: spacing[1],
                  maxHeight: '100px',
                  borderRadius: radius.sm,
                  border: `1px solid ${colors.surface['4']}`,
                }}
              />
            </div>
          )}
        </div>
      )}
    </div>
  );
};
