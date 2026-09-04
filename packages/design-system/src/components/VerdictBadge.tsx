import React from 'react';
import { CheckCircle, XCircle, Warning, Question } from '@phosphor-icons/react';
import { colors } from '../tokens/colors';
import { typography } from '../tokens/typography';
import { radius } from '../tokens/radius';
import { spacing } from '../tokens/spacing';

export type VerdictType = 'PASS' | 'FAIL' | 'WARN' | 'INCONCLUSIVE';
export type BadgeSize = 'sm' | 'md' | 'lg';

export interface VerdictBadgeProps {
  verdict: VerdictType;
  size?: BadgeSize;
}

const config = {
  PASS: {
    text: 'PASS',
    Icon: CheckCircle,
    bgColor: colors.status.pass,
    textColor: colors.text.inverse,
  },
  FAIL: {
    text: 'FAIL',
    Icon: XCircle,
    bgColor: colors.status.fail,
    textColor: colors.text.inverse,
  },
  WARN: {
    text: 'WARN',
    Icon: Warning,
    bgColor: colors.status.warn, // Using standard warn bg as per spec, though text is inverse
    textColor: colors.text.inverse,
  },
  INCONCLUSIVE: {
    text: 'INCONCLUSIVE',
    Icon: Question,
    bgColor: colors.status.inconclusive,
    textColor: colors.text.inverse,
  },
};

const sizeConfig = {
  sm: {
    height: '20px',
    padding: `0 ${spacing[2]}`, // 10px approx with spacing
    fontSize: '11px',
    iconSize: 12,
  },
  md: {
    height: '28px',
    padding: `0 14px`,
    fontSize: typography.sizes.label,
    iconSize: 16,
  },
  lg: {
    height: '40px',
    padding: `0 ${spacing[5]}`,
    fontSize: typography.sizes.heading3,
    iconSize: 20,
  },
};

export const VerdictBadge: React.FC<VerdictBadgeProps> = ({ verdict, size = 'md' }) => {
  const { text, Icon, bgColor, textColor } = config[verdict];
  const sz = sizeConfig[size];

  return (
    <div
      role="status"
      aria-label={`Compliance result: ${text}`}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        height: sz.height,
        padding: sz.padding,
        backgroundColor: bgColor,
        color: textColor,
        borderRadius: radius.full,
        fontFamily: typography.fontFamily.primary,
        fontSize: sz.fontSize,
        fontWeight: typography.weights.bold,
        gap: spacing[1],
        textTransform: 'uppercase',
      }}
    >
      <Icon size={sz.iconSize} weight="fill" />
      <span>{text}</span>
    </div>
  );
};
