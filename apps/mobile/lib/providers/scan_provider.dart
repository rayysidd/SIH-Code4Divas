import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

enum ScanStatus { idle, capturing, uploading, processing, done, error }

class ScanState {
  final ScanStatus status;
  final File? capturedImage;
  final String? taskId;
  final Map<String, dynamic>? result;
  final String? error;
  final int currentStep; // 0-5 for processing steps

  const ScanState({
    this.status = ScanStatus.idle,
    this.capturedImage,
    this.taskId,
    this.result,
    this.error,
    this.currentStep = 0,
  });

  ScanState copyWith({
    ScanStatus? status,
    File? capturedImage,
    String? taskId,
    Map<String, dynamic>? result,
    String? error,
    int? currentStep,
  }) {
    return ScanState(
      status: status ?? this.status,
      capturedImage: capturedImage ?? this.capturedImage,
      taskId: taskId ?? this.taskId,
      result: result ?? this.result,
      error: error ?? this.error,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class ScanNotifier extends StateNotifier<ScanState> {
  ScanNotifier() : super(const ScanState());

  void setCapturedImage(File image) {
    state = state.copyWith(
      capturedImage: image,
      status: ScanStatus.capturing,
    );
  }

  Future<void> uploadAndProcess(File imageFile) async {
    state = state.copyWith(status: ScanStatus.uploading, currentStep: 0);
    try {
      // Step 1: Upload image → get task_id
      final uploadResult = await ApiService.submitScan(imageFile);
      final taskId = uploadResult['scan_id']?.toString() ?? '';

      state = state.copyWith(
        taskId: taskId,
        status: ScanStatus.processing,
        currentStep: 1,
      );

      // Step 2: Poll for result with step updates
      await _pollForResult(taskId);
    } catch (e) {
      state = state.copyWith(
        status: ScanStatus.error,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> _pollForResult(String taskId) async {
    const maxAttempts = 30;
    const pollInterval = Duration(seconds: 2);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(pollInterval);

      try {
        final status = await ApiService.pollScanStatus(taskId);
        // Simulate progress if still processing
        int nextStep = state.currentStep;
        if (status['status'] == 'PROCESSING' && nextStep < 4) {
          nextStep++;
        }

        state = state.copyWith(currentStep: nextStep.clamp(0, 5));

        if (status['status'] == 'COMPLETED') {
          final result = await ApiService.getLabelScanResult(taskId);
          state = state.copyWith(
            status: ScanStatus.done,
            result: result,
            currentStep: 5,
          );
          return;
        }

        if (status['status'] == 'FAILED' || status['status'] == 'error') {
          throw Exception(status['error_message'] ?? status['error'] ?? 'Processing failed');
        }
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          throw Exception('Timeout: Backend did not respond after ${maxAttempts * 2}s');
        }
        // If it's an explicit error from our throw Exception above, rethrow it immediately
        if (e is Exception && !e.toString().contains('SocketException') && !e.toString().contains('Connection')) {
           rethrow;
        }
      }
    }
  }

  void reset() {
    state = const ScanState();
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier();
});
