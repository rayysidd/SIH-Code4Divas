import 'package:flutter/material.dart';
import 'verdict_badge.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';


class CheckRow extends StatefulWidget {
  final VerdictType verdict;
  final String ruleCitation;
  final String shortDescription;
  final String? foundValue;
  final String? requiredValue;
  final int confidence;
  final String? evidenceImageUrl;
  final bool isConfirmed;
  final bool isDisputed;

  const CheckRow({
    Key? key,
    required this.verdict,
    required this.ruleCitation,
    required this.shortDescription,
    this.foundValue,
    this.requiredValue,
    required this.confidence,
    this.evidenceImageUrl,
    this.isConfirmed = false,
    this.isDisputed = false,
  }) : super(key: key);

  @override
  State<CheckRow> createState() => _CheckRowState();
}

class _CheckRowState extends State<CheckRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    Color leftBorderColor = Colors.transparent;
    if (widget.isConfirmed) leftBorderColor = LabelLensColors.brandPrimary;
    if (widget.isDisputed) leftBorderColor = LabelLensColors.surface3;

    return Container(
      decoration: BoxDecoration(
        color: LabelLensColors.surface0,
        border: Border(
          bottom: const BorderSide(color: LabelLensColors.surface3, width: 1),
          left: BorderSide(color: leftBorderColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(LabelLensSpacing.s4),
              child: Row(
                children: [
                  VerdictBadge(verdict: widget.verdict, size: BadgeSize.sm),
                  const SizedBox(width: LabelLensSpacing.s3),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: LabelLensTypography.primaryFont,
                          fontSize: LabelLensTypography.body2,
                          color: LabelLensColors.textPrimary,
                          decoration: widget.isDisputed ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                        children: [
                          TextSpan(
                            text: '${widget.ruleCitation} ',
                            style: const TextStyle(
                              fontFamily: LabelLensTypography.monoFont,
                              fontWeight: LabelLensTypography.semiBold,
                            ),
                          ),
                          TextSpan(text: widget.shortDescription),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: LabelLensColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: 56.0, // Indent past badge (20 + 12 + 24 approx)
                right: LabelLensSpacing.s4,
                bottom: LabelLensSpacing.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.foundValue != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: LabelLensSpacing.s2),
                      child: Text('Found: ${widget.foundValue}', style: _detailStyle()),
                    ),
                  if (widget.requiredValue != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: LabelLensSpacing.s2),
                      child: Text('Required: ${widget.requiredValue}', style: _detailStyle()),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: LabelLensSpacing.s2),
                    child: Row(
                      children: [
                        Text('Confidence: ', style: _detailStyle()),
                        const SizedBox(width: LabelLensSpacing.s2),
                        Container(
                          width: 100,
                          height: 6,
                          decoration: BoxDecoration(
                            color: LabelLensColors.surface3,
                            borderRadius: BorderRadius.circular(LabelLensRadius.sm),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: widget.confidence / 100.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: widget.confidence >= 85
                                    ? LabelLensColors.brandSecondary
                                    : widget.confidence >= 60
                                        ? LabelLensColors.statusWarn
                                        : LabelLensColors.statusFail,
                                borderRadius: BorderRadius.circular(LabelLensRadius.sm),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: LabelLensSpacing.s2),
                        Text('${widget.confidence}%', style: _detailStyle()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _detailStyle() {
    return const TextStyle(
      fontFamily: LabelLensTypography.primaryFont,
      fontSize: LabelLensTypography.body2,
      color: LabelLensColors.textSecondary,
    );
  }
}
