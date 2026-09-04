import React from 'react';
import { colors } from '../tokens/colors';
import { typography } from '../tokens/typography';

export interface RuleReferencePanelProps {
  ruleText: string;
  source: string;
}

export const RuleReferencePanel: React.FC<RuleReferencePanelProps> = ({ ruleText, source }) => {
  return (
    <div style={{ padding: '16px', backgroundColor: colors.surface['1'], border: `1px solid ${colors.surface['3']}` }}>
      <h3 style={{ margin: '0 0 8px 0', fontFamily: typography.fontFamily.primary }}>Rule Reference</h3>
      <p style={{ fontFamily: typography.fontFamily.mono, fontSize: typography.sizes.body2 }}>{ruleText}</p>
      <small style={{ color: colors.text.secondary, fontFamily: typography.fontFamily.primary }}>Source: {source}</small>
    </div>
  );
};
