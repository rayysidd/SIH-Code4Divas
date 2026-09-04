import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';


enum VerdictType { pass, fail, warn, inconclusive }
enum BadgeSize { sm, md, lg }

class VerdictBadge extends StatelessWidget {
  final VerdictType verdict;
  final BadgeSize size;

  const VerdictBadge({
    Key? key,
    required this.verdict,
    this.size = BadgeSize.md,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String text;
    IconData iconData;
    Color bgColor;
    Color textColor = LabelLensColors.textInverse;

    switch (verdict) {
      case VerdictType.pass:
        text = 'PASS';
        iconData = Icons.check_circle; // Fallback to material if phosphor is absent
        bgColor = LabelLensColors.statusPass;
        break;
      case VerdictType.fail:
        text = 'FAIL';
        iconData = Icons.cancel;
        bgColor = LabelLensColors.statusFail;
        break;
      case VerdictType.warn:
        text = 'WARN';
        iconData = Icons.warning;
        bgColor = LabelLensColors.statusWarn;
        break;
      case VerdictType.inconclusive:
        text = 'INCONCLUSIVE';
        iconData = Icons.help;
        bgColor = LabelLensColors.statusInconclusive;
        break;
    }

    double height;
    EdgeInsets padding;
    double fontSize;
    double iconSize;

    switch (size) {
      case BadgeSize.sm:
        height = 20.0;
        padding = const EdgeInsets.symmetric(horizontal: 10.0);
        fontSize = 11.0;
        iconSize = 12.0;
        break;
      case BadgeSize.md:
        height = 28.0;
        padding = const EdgeInsets.symmetric(horizontal: 14.0);
        fontSize = LabelLensTypography.label;
        iconSize = 16.0;
        break;
      case BadgeSize.lg:
        height = 40.0;
        padding = const EdgeInsets.symmetric(horizontal: 20.0);
        fontSize = LabelLensTypography.heading3;
        iconSize = 20.0;
        break;
    }

    return Semantics(
      label: 'Compliance result: $text',
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(LabelLensRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: iconSize,
              color: textColor,
            ),
            const SizedBox(width: LabelLensSpacing.s1),
            Text(
              text,
              style: TextStyle(
                fontFamily: LabelLensTypography.primaryFont,
                fontSize: fontSize,
                fontWeight: LabelLensTypography.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
