import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';

enum RingSize { sm, md, lg }

class ComplianceScoreRing extends StatefulWidget {
  final int score;
  final int passedChecks;
  final int totalChecks;
  final RingSize size;

  const ComplianceScoreRing({
    Key? key,
    required this.score,
    required this.passedChecks,
    required this.totalChecks,
    this.size = RingSize.md,
  }) : super(key: key);

  @override
  State<ComplianceScoreRing> createState() => _ComplianceScoreRingState();
}

class _ComplianceScoreRingState extends State<ComplianceScoreRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Approximate cubic-bezier(0.34, 1.56, 0.64, 1) using elastic out or custom curve
    final curvedAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _animation = Tween<double>(begin: 0, end: widget.score / 100.0).animate(curvedAnimation);
    
    _controller.forward();
  }

  @override
  void didUpdateWidget(ComplianceScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      final curvedAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
      _animation = Tween<double>(begin: _animation.value, end: widget.score / 100.0).animate(curvedAnimation);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color ringColor = LabelLensColors.statusFail;
    if (widget.score >= 90) ringColor = LabelLensColors.statusPass;
    else if (widget.score >= 70) ringColor = LabelLensColors.statusWarn;

    double diameter;
    double strokeWidth;
    double fontSize;

    switch (widget.size) {
      case RingSize.sm:
        diameter = 80.0;
        strokeWidth = 6.0;
        fontSize = 16.0;
        break;
      case RingSize.md:
        diameter = 140.0;
        strokeWidth = 10.0;
        fontSize = 28.0;
        break;
      case RingSize.lg:
        diameter = 200.0;
        strokeWidth = 14.0;
        fontSize = 40.0;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: strokeWidth,
                color: LabelLensColors.surface3,
              ),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _animation.value,
                    strokeWidth: strokeWidth,
                    color: ringColor,
                    strokeCap: StrokeCap.round,
                  );
                },
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.score}%',
                      style: TextStyle(
                        fontFamily: LabelLensTypography.primaryFont,
                        fontSize: fontSize,
                        fontWeight: LabelLensTypography.bold,
                        color: LabelLensColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    if (widget.size != RingSize.sm)
                      Text(
                        'Score',
                        style: TextStyle(
                          fontFamily: LabelLensTypography.primaryFont,
                          fontSize: LabelLensTypography.caption,
                          color: LabelLensColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.size != RingSize.sm) ...[
          const SizedBox(height: 8),
          Text(
            '${widget.passedChecks}/${widget.totalChecks} checks passed',
            style: const TextStyle(
              fontFamily: LabelLensTypography.primaryFont,
              fontSize: LabelLensTypography.body2,
              color: LabelLensColors.textSecondary,
            ),
          ),
        ]
      ],
    );
  }
}
