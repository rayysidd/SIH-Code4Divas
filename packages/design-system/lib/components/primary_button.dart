import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';
import '../tokens/radius.dart';
import '../tokens/shadows.dart';

enum ButtonSize { sm, md, lg }

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonSize size;
  final bool isLoading;
  final bool fullWidth;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.size = ButtonSize.md,
    this.isLoading = false,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double height;
    EdgeInsets padding;
    double fontSize;

    switch (size) {
      case ButtonSize.sm:
        height = 32.0;
        padding = const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s4);
        fontSize = LabelLensTypography.heading3;
        break;
      case ButtonSize.md:
        height = 44.0;
        padding = const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s6);
        fontSize = LabelLensTypography.body1;
        break;
      case ButtonSize.lg:
        height = 52.0;
        padding = const EdgeInsets.symmetric(horizontal: LabelLensSpacing.s8);
        fontSize = 18.0;
        break;
    }

    final bool isDisabled = onPressed == null || isLoading;

    Widget child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(LabelLensColors.textTertiary),
            ),
          )
        : Text(
            text,
            style: TextStyle(
              fontFamily: LabelLensTypography.primaryFont,
              fontSize: fontSize,
              fontWeight: LabelLensTypography.semiBold,
              color: isDisabled ? LabelLensColors.textTertiary : LabelLensColors.textInverse,
            ),
          );

    return Container(
      width: fullWidth ? double.infinity : null,
      height: height,
      decoration: BoxDecoration(
        color: isDisabled ? LabelLensColors.surface3 : LabelLensColors.brandPrimary,
        borderRadius: BorderRadius.circular(LabelLensRadius.md),
        boxShadow: isDisabled ? LabelLensShadows.elev0 : LabelLensShadows.elev1,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(LabelLensRadius.md),
          child: Padding(
            padding: padding,
            child: Center(
              widthFactor: fullWidth ? null : 1.0,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
