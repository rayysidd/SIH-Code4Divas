import React, { ButtonHTMLAttributes } from 'react';
import { colors } from '../tokens/colors';
import { typography } from '../tokens/typography';
import { radius } from '../tokens/radius';
import { spacing } from '../tokens/spacing';
import { shadows } from '../tokens/shadows';
import { motion } from '../tokens/motion';

export type ButtonSize = 'sm' | 'md' | 'lg';

export interface PrimaryButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  size?: ButtonSize;
  isLoading?: boolean;
  fullWidth?: boolean;
}

export const PrimaryButton: React.FC<PrimaryButtonProps> = ({
  size = 'md',
  isLoading = false,
  fullWidth = false,
  children,
  disabled,
  style,
  ...props
}) => {
  const sizeStyles = {
    sm: { height: '32px', padding: `0 ${spacing[4]}`, fontSize: typography.sizes.heading3 },
    md: { height: '44px', padding: `0 ${spacing[6]}`, fontSize: typography.sizes.body1 },
    lg: { height: '52px', padding: `0 ${spacing[8]}`, fontSize: '18px' },
  };

  const currentSize = sizeStyles[size];
  const isDisabled = disabled || isLoading;

  return (
    <button
      disabled={isDisabled}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        height: currentSize.height,
        padding: currentSize.padding,
        fontSize: currentSize.fontSize,
        fontFamily: typography.fontFamily.primary,
        fontWeight: typography.weights.semiBold,
        width: fullWidth ? '100%' : 'auto',
        backgroundColor: isDisabled ? colors.surface['3'] : colors.brand.primary,
        color: isDisabled ? colors.text.tertiary : colors.text.inverse,
        borderRadius: radius.md,
        border: 'none',
        boxShadow: isDisabled ? shadows.elev0 : shadows.elev1,
        cursor: isDisabled ? 'not-allowed' : 'pointer',
        transition: `all ${motion.durations.fast} ${motion.easings.fast}`,
        ...style,
      }}
      {...props}
    >
      {isLoading ? (
        <span className="spinner" style={{ animation: 'spin 1s linear infinite' }}>
          ↻
        </span>
      ) : (
        children
      )}
    </button>
  );
};
