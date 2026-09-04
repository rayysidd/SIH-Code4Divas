import 'package:flutter/material.dart';

class LabelLensMotion {
  // Durations
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 100);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration page = Duration(milliseconds: 400);
  static const Duration scanPulse = Duration(milliseconds: 1500);
  static const Duration resultReveal = Duration(milliseconds: 500);

  // Curves (Easings)
  static const Curve fastCurve = Curves.easeOut;
  static const Curve normalCurve = Curves.easeInOut;
  static const Curve slowCurve = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve pageCurve = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve scanPulseCurve = Curves.easeInOut;
  static const Curve resultRevealCurve = Cubic(0.34, 1.56, 0.64, 1.0);
}
