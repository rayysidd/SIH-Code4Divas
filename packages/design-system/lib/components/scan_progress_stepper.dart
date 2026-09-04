import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';

enum StepStatus { done, active, pending, failed }

class ScanStep {
  final String label;
  final StepStatus status;

  ScanStep({required this.label, required this.status});
}

class ScanProgressStepper extends StatefulWidget {
  final List<ScanStep> steps;

  const ScanProgressStepper({Key? key, required this.steps}) : super(key: key);

  @override
  State<ScanProgressStepper> createState() => _ScanProgressStepperState();
}

class _ScanProgressStepperState extends State<ScanProgressStepper> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.steps.asMap().entries.map((entry) {
        final int index = entry.key;
        final ScanStep step = entry.value;
        final bool isLast = index == widget.steps.length - 1;

        Color nodeColor = LabelLensColors.surface3;
        Color textColor = LabelLensColors.textTertiary;
        
        if (step.status == StepStatus.done) {
          nodeColor = LabelLensColors.statusPass;
          textColor = LabelLensColors.textPrimary;
        } else if (step.status == StepStatus.active) {
          nodeColor = LabelLensColors.brandPrimary;
          textColor = LabelLensColors.textPrimary;
        } else if (step.status == StepStatus.failed) {
          nodeColor = LabelLensColors.statusFail;
          textColor = LabelLensColors.statusFail;
        }

        Widget node = Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: step.status == StepStatus.done ? nodeColor : LabelLensColors.surface0,
            border: Border.all(color: nodeColor, width: 2),
          ),
          child: step.status == StepStatus.done
              ? const Icon(Icons.check, size: 16, color: LabelLensColors.textInverse)
              : step.status == StepStatus.failed
                  ? const Icon(Icons.close, size: 16, color: LabelLensColors.statusFail)
                  : null,
        );

        if (step.status == StepStatus.active) {
          node = AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: node,
          );
        }

        return Expanded(
          flex: isLast ? 0 : 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  node,
                  const SizedBox(height: 4),
                  Text(
                    step.label,
                    style: TextStyle(
                      fontFamily: LabelLensTypography.primaryFont,
                      fontSize: LabelLensTypography.caption,
                      color: textColor,
                      fontWeight: step.status == StepStatus.active ? LabelLensTypography.bold : LabelLensTypography.regular,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(top: 11),
                    color: step.status == StepStatus.done ? LabelLensColors.statusPass : LabelLensColors.surface3,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
