import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

class ConfidenceIndicator extends StatelessWidget {
  final int confidence; // 0 to 100

  const ConfidenceIndicator({Key? key, required this.confidence}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color = LabelLensColors.statusFail;
    IconData icon = Icons.warning;

    if (confidence >= 85) {
      color = LabelLensColors.brandSecondary;
      icon = Icons.speed; // Placeholder for gauge
    } else if (confidence >= 60) {
      color = LabelLensColors.statusWarn;
      icon = Icons.speed;
    }

    const int totalBlocks = 12;
    final int filledBlocks = ((confidence / 100.0) * totalBlocks).round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: LabelLensSpacing.s2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(totalBlocks, (index) {
            return Container(
              margin: const EdgeInsets.only(right: 2),
              width: 6,
              height: 12,
              decoration: BoxDecoration(
                color: index < filledBlocks ? color : LabelLensColors.surface3,
                borderRadius: BorderRadius.circular(LabelLensRadius.sm),
              ),
            );
          }),
        ),
        const SizedBox(width: LabelLensSpacing.s2),
        Text(
          '$confidence%',
          style: const TextStyle(
            fontFamily: LabelLensTypography.primaryFont,
            fontSize: LabelLensTypography.body2,
            fontWeight: LabelLensTypography.medium,
            color: LabelLensColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
