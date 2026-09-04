import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radius.dart';

class LabelLensBottomSheet {
  static void show(BuildContext context, {required Widget child}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: LabelLensColors.surface0,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(LabelLensRadius.xl),
              topRight: Radius.circular(LabelLensRadius.xl),
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: LabelLensColors.surface3,
                  borderRadius: BorderRadius.circular(LabelLensRadius.full),
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        );
      },
    );
  }
}
