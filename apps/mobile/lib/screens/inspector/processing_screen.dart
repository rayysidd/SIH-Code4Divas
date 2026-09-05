import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/components/scan_progress_stepper.dart';
import '../../providers/scan_provider.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  final List<String> _stepLabels = [
    'Uploaded',
    'OCR',
    'Classify',
    'Measure',
    'Rules',
    'Result',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);

    // Navigate when done or errored
    ref.listen<ScanState>(scanProvider, (previous, next) {
      if (next.status == ScanStatus.done && mounted) {
        context.go('/verdict');
      }
      if (next.status == ScanStatus.error && mounted) {
        _showErrorAndGoBack(next.error ?? 'Unknown error');
      }
    });

    final currentStep = scanState.currentStep.clamp(0, _stepLabels.length - 1);

    final steps = _stepLabels.asMap().entries.map((e) {
      StepStatus status;
      if (e.key < currentStep) {
        status = StepStatus.done;
      } else if (e.key == currentStep) {
        status = StepStatus.active;
      } else {
        status = StepStatus.pending;
      }
      return ScanStep(label: e.value, status: status);
    }).toList();

    return Scaffold(
      backgroundColor: LabelLensColors.brandPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing logo
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80 + (_pulseCtrl.value * 40),
                        height: 80 + (_pulseCtrl.value * 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withOpacity(0.1 * (1 - _pulseCtrl.value)),
                        ),
                      ),
                      const Icon(Icons.document_scanner,
                          color: Colors.white, size: 56),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),

              const Text(
                'Analyzing Label...',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStatusMessage(scanState.status),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 48),

              ScanProgressStepper(steps: steps),

              const SizedBox(height: 32),

              Text(
                currentStep < _stepLabels.length
                    ? _stepLabels[currentStep]
                    : 'Complete!',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusMessage(ScanStatus status) {
    switch (status) {
      case ScanStatus.uploading:
        return 'Uploading image to server...';
      case ScanStatus.processing:
        return 'Running compliance checks...';
      case ScanStatus.done:
        return 'Analysis complete!';
      case ScanStatus.error:
        return 'Something went wrong';
      default:
        return 'Please wait...';
    }
  }

  void _showErrorAndGoBack(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Processing Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(scanProvider.notifier).reset();
              context.go('/');
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
