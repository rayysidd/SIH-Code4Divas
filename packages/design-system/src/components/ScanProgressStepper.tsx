import React from 'react';
import { colors } from '../tokens/colors';
import { typography } from '../tokens/typography';

export type StepStatus = 'done' | 'active' | 'pending' | 'failed';

export interface ScanStep {
  label: string;
  status: StepStatus;
}

export interface ScanProgressStepperProps {
  steps: ScanStep[];
}

export const ScanProgressStepper: React.FC<ScanProgressStepperProps> = ({ steps }) => {
  return (
    <div style={{ display: 'flex', alignItems: 'center', width: '100%', justifyContent: 'space-between' }}>
      {steps.map((step, index) => {
        const isLast = index === steps.length - 1;

        let nodeColor = colors.surface['3'];
        let textColor = colors.text.tertiary;
        
        if (step.status === 'done') {
          nodeColor = colors.status.pass;
          textColor = colors.text.primary;
        } else if (step.status === 'active') {
          nodeColor = colors.brand.primary;
          textColor = colors.text.primary;
        } else if (step.status === 'failed') {
          nodeColor = colors.status.fail;
          textColor = colors.status.fail;
        }

        return (
          <React.Fragment key={index}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '4px', zIndex: 1 }}>
              <div
                style={{
                  width: '24px',
                  height: '24px',
                  borderRadius: '50%',
                  backgroundColor: step.status === 'done' ? nodeColor : colors.surface['0'],
                  border: `2px solid ${nodeColor}`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: step.status === 'done' ? colors.text.inverse : 'transparent',
                  fontSize: '12px',
                  transition: 'all 0.3s ease',
                  ...(step.status === 'active' ? { animation: 'pulse 1.5s ease-in-out infinite' } : {})
                }}
              >
                {step.status === 'done' ? '✓' : (step.status === 'failed' ? '✗' : '')}
              </div>
              <span style={{
                fontFamily: typography.fontFamily.primary,
                fontSize: typography.sizes.caption,
                color: textColor,
                fontWeight: step.status === 'active' ? typography.weights.bold : typography.weights.regular,
                whiteSpace: 'nowrap'
              }}>
                {step.label}
              </span>
            </div>
            {!isLast && (
              <div style={{ flex: 1, height: '2px', backgroundColor: step.status === 'done' ? colors.status.pass : colors.surface['3'], margin: '0 -10px', marginBottom: '16px', zIndex: 0 }} />
            )}
          </React.Fragment>
        );
      })}
    </div>
  );
};
