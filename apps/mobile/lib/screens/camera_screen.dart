import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:design_system/tokens/colors.dart';
import '../providers/scan_provider.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _permissionDenied = false;
  bool _flashOn = false;
  int _selectedCameraIndex = 0;
  // Cylinder mode: in a future iteration this triggers multi-frame capture
  bool _cylinderMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(_cameras[_selectedCameraIndex]);
    }
  }

  Future<void> _initCamera() async {
    // 1. Request permission
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() => _permissionDenied = true);
      return;
    }

    // 2. Get available cameras
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _permissionDenied = true);
        return;
      }
      await _initCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() => _permissionDenied = true);
    }
  }

  Future<void> _initCameraController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high, // high = ~1080p, good for OCR
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      // Lock focus and exposure for better label scanning
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _isInitialized = false);
    await _controller?.dispose();
    await _initCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    try {
      _flashOn = !_flashOn;
      await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (_) {}
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      // Haptic feedback on shutter
      HapticFeedback.mediumImpact();

      // Turn off torch before capture to avoid overexposure
      if (_flashOn) await controller.setFlashMode(FlashMode.off);

      final xFile = await controller.takePicture();
      final imageFile = File(xFile.path);

      // Store in scan provider and navigate to processing
      ref.read(scanProvider.notifier).setCapturedImage(imageFile);

      if (mounted) {
        // Start upload immediately in background
        ref.read(scanProvider.notifier).uploadAndProcess(imageFile);
        context.go('/processing');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture failed: ${e.toString()}'),
            backgroundColor: LabelLensColors.statusFail,
          ),
        );
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (xFile == null) return;

    final imageFile = File(xFile.path);
    ref.read(scanProvider.notifier).setCapturedImage(imageFile);
    ref.read(scanProvider.notifier).uploadAndProcess(imageFile);
    if (mounted) context.go('/processing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _permissionDenied
          ? _buildPermissionDeniedUI()
          : _buildCameraUI(),
    );
  }

  Widget _buildPermissionDeniedUI() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 72, color: Colors.white38),
            const SizedBox(height: 24),
            const Text(
              'Camera Access Required',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'LabelLens needs camera access to photograph product labels for compliance checking.',
              style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await openAppSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LabelLensColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Back', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraUI() {
    return Stack(
      children: [
        // ── Camera Preview ──────────────────────────────────────────────────
        if (_isInitialized && _controller != null)
          Positioned.fill(
            child: CameraPreview(_controller!),
          )
        else
          const Center(
            child: CircularProgressIndicator(color: Colors.white54),
          ),

        // ── Scanning overlay: animated corner brackets ─────────────────────
        if (_isInitialized)
          Center(
            child: _ScanOverlay(cylinderMode: _cylinderMode),
          ),

        // ── Top bar ─────────────────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back
                _TopBarButton(
                  icon: Icons.arrow_back,
                  onTap: () => context.go('/'),
                ),
                // Mode toggle pill
                GestureDetector(
                  onTap: () => setState(() => _cylinderMode = !_cylinderMode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _cylinderMode
                          ? LabelLensColors.brandAccent
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _cylinderMode ? Icons.radio_button_checked : Icons.crop_landscape,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _cylinderMode ? 'CYLINDER' : 'FLAT LABEL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Flash toggle
                _TopBarButton(
                  icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                  onTap: _toggleFlash,
                  active: _flashOn,
                ),
              ],
            ),
          ),
        ),

        // ── Coaching text ────────────────────────────────────────────────────
        if (_isInitialized)
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _cylinderMode
                        ? 'Rotate product slowly after tapping shutter'
                        : 'Align the full label within the frame',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

        // ── Bottom controls ──────────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gallery picker
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white38),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.white, size: 24),
                  ),
                ),

                // Shutter button
                GestureDetector(
                  onTap: _isCapturing ? null : _capturePhoto,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: _isCapturing ? 64 : 72,
                    height: _isCapturing ? 64 : 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isCapturing ? Colors.white54 : Colors.transparent,
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: _isCapturing ? 44 : 56,
                        height: _isCapturing ? 44 : 56,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(
                                  color: LabelLensColors.brandPrimary,
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // Flip camera
                GestureDetector(
                  onTap: _cameras.length > 1 ? _flipCamera : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38),
                    ),
                    child: Icon(
                      Icons.flip_camera_ios,
                      color: _cameras.length > 1 ? Colors.white : Colors.white24,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────────

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? LabelLensColors.brandAccent.withOpacity(0.8)
              : Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ScanOverlay extends StatefulWidget {
  final bool cylinderMode;
  const _ScanOverlay({required this.cylinderMode});

  @override
  State<_ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<_ScanOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLineCtrl;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cylinder mode: taller, narrower overlay
    final overlayW = widget.cylinderMode ? 220.0 : 300.0;
    final overlayH = widget.cylinderMode ? 360.0 : 210.0;
    final bracketColor = LabelLensColors.brandAccent;
    const bracketLen = 24.0;
    const bracketThick = 3.0;

    return SizedBox(
      width: overlayW,
      height: overlayH,
      child: Stack(
        children: [
          // Dark background scrim outside the frame
          CustomPaint(
            size: Size(overlayW, overlayH),
            painter: _FramePainter(bracketColor, bracketLen, bracketThick),
          ),

          // Animated horizontal scan line
          AnimatedBuilder(
            animation: _scanLineCtrl,
            builder: (context, _) {
              return Positioned(
                top: _scanLineCtrl.value * (overlayH - 4),
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        bracketColor.withOpacity(0),
                        bracketColor.withOpacity(0.8),
                        bracketColor.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final Color color;
  final double bracketLen;
  final double thick;

  _FramePainter(this.color, this.bracketLen, this.thick);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(Offset(0, bracketLen), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(bracketLen, 0), paint);
    // Top-right
    canvas.drawLine(Offset(w - bracketLen, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, bracketLen), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, h - bracketLen), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(bracketLen, h), paint);
    // Bottom-right
    canvas.drawLine(Offset(w - bracketLen, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - bracketLen), paint);
  }

  @override
  bool shouldRepaint(_FramePainter old) => false;
}
