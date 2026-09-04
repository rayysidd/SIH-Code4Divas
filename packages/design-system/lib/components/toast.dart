import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/radius.dart';
import '../tokens/shadows.dart';

enum ToastType { success, error, info, warning }

class LabelLensToast {
  static void show(BuildContext context, {required String message, ToastType type = ToastType.info}) {
    Color borderColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        borderColor = LabelLensColors.statusPass;
        icon = Icons.check;
        break;
      case ToastType.error:
        borderColor = LabelLensColors.statusFail;
        icon = Icons.close;
        break;
      case ToastType.info:
        borderColor = LabelLensColors.brandPrimary;
        icon = Icons.info;
        break;
      case ToastType.warning:
        borderColor = LabelLensColors.statusWarn;
        icon = Icons.warning;
        break;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50.0,
        left: 16.0,
        right: 16.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: LabelLensColors.surface0,
              borderRadius: BorderRadius.circular(LabelLensRadius.md),
              boxShadow: LabelLensShadows.elev2,
              border: Border(left: BorderSide(color: borderColor, width: 4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, color: borderColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            fontFamily: LabelLensTypography.primaryFont,
                            fontSize: LabelLensTypography.body2,
                            color: LabelLensColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => overlayEntry.remove(),
                  child: const Icon(Icons.close, color: LabelLensColors.textTertiary, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
