import React, { useEffect, useState } from 'react';
import { colors } from '../tokens/colors';
import { typography } from '../tokens/typography';

export interface ComplianceScoreRingProps {
  score: number; // 0 to 100
  passedChecks: number;
  totalChecks: number;
  size?: 'sm' | 'md' | 'lg';
}

export const ComplianceScoreRing: React.FC<ComplianceScoreRingProps> = ({
  score,
  passedChecks,
  totalChecks,
  size = 'md',
}) => {
  const [animatedScore, setAnimatedScore] = useState(0);

  useEffect(() => {
    // Simple animation on mount
    const timer = setTimeout(() => {
      setAnimatedScore(score);
    }, 100);
    return () => clearTimeout(timer);
  }, [score]);

  let ringColor = colors.status.fail;
  if (score >= 90) ringColor = colors.status.pass;
  else if (score >= 70) ringColor = colors.status.warn;

  const sizeConfig = {
    sm: { diameter: 80, stroke: 6, fontSize: '16px' },
    md: { diameter: 140, stroke: 10, fontSize: '28px' },
    lg: { diameter: 200, stroke: 14, fontSize: '40px' },
  };

  const { diameter, stroke, fontSize } = sizeConfig[size];
  const radius = (diameter - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference - (animatedScore / 100) * circumference;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '8px' }}>
      <div style={{ position: 'relative', width: diameter, height: diameter }}>
        <svg width={diameter} height={diameter} style={{ transform: 'rotate(-90deg)' }}>
          {/* Background Ring */}
          <circle
            cx={diameter / 2}
            cy={diameter / 2}
            r={radius}
            fill="transparent"
            stroke={colors.surface['3']}
            strokeWidth={stroke}
          />
          {/* Progress Ring */}
          <circle
            cx={diameter / 2}
            cy={diameter / 2}
            r={radius}
            fill="transparent"
            stroke={ringColor}
            strokeWidth={stroke}
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            strokeLinecap="round"
            style={{
              transition: 'stroke-dashoffset 600ms cubic-bezier(0.34, 1.56, 0.64, 1)',
            }}
          />
        </svg>
        {/* Center Text */}
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            fontFamily: typography.fontFamily.primary,
          }}
        >
          <span style={{ fontSize, fontWeight: typography.weights.bold, color: colors.text.primary, lineHeight: 1 }}>
            {score}%
          </span>
          {size !== 'sm' && (
            <span style={{ fontSize: typography.sizes.caption, color: colors.text.secondary }}>
              Score
            </span>
          )}
        </div>
      </div>
      {size !== 'sm' && (
        <div style={{ fontFamily: typography.fontFamily.primary, fontSize: typography.sizes.body2, color: colors.text.secondary }}>
          {passedChecks}/{totalChecks} checks passed
        </div>
      )}
    </div>
  );
};
