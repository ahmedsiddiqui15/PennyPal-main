import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import 'app_loading_bar.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.enabled = true,
    this.outlined = false,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool enabled;
  final bool outlined;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isInteractive = enabled && !isLoading && onPressed != null;

    final Widget child = isLoading
        ? const AppLoadingBar(
            width: 56,
            height: 3,
            color: Colors.white,
            trackColor: Colors.white24,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
              ],
              Text(label, style: AppTextStyles.button),
            ],
          );

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: isInteractive ? onPressed : null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: palette.border),
            foregroundColor: palette.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
              ],
              Text(label,
                  style: AppTextStyles.button
                      .copyWith(color: palette.textPrimary)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.amberGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          boxShadow: isInteractive ? AppShadows.amber : null,
        ),
        child: FilledButton(
          onPressed: isInteractive ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
          ),
          child: isLoading
              ? child
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(label, style: AppTextStyles.button),
                  ],
                ),
        ),
      ),
    );
  }
}
