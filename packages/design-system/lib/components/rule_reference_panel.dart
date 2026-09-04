import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';

class RuleReferencePanel extends StatelessWidget {
  final String ruleText;
  final String source;

  const RuleReferencePanel({Key? key, required this.ruleText, required this.source}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LabelLensSpacing.s4),
      decoration: BoxDecoration(
        color: LabelLensColors.surface1,
        border: Border.all(color: LabelLensColors.surface3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Rule Reference',
            style: TextStyle(fontFamily: LabelLensTypography.primaryFont, fontSize: LabelLensTypography.heading3, fontWeight: LabelLensTypography.bold),
          ),
          const SizedBox(height: LabelLensSpacing.s2),
          Text(
            ruleText,
            style: const TextStyle(fontFamily: LabelLensTypography.monoFont, fontSize: LabelLensTypography.body2),
          ),
          const SizedBox(height: LabelLensSpacing.s2),
          Text(
            'Source: $source',
            style: const TextStyle(fontFamily: LabelLensTypography.primaryFont, fontSize: LabelLensTypography.caption, color: LabelLensColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
