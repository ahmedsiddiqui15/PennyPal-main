import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import 'primary_button.dart';

Future<void> showSuccessOverlay(
  BuildContext context, {
  required String title,
  String? message,
  String buttonLabel = 'Done',
  Duration autoClose = Duration.zero,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: AppConstants.durationNormal,
    pageBuilder: (_, __, ___) => _SuccessDialog(
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      autoClose: autoClose,
    ),
    transitionBuilder: (_, Animation<double> animation, __, Widget child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    },
  );
}

class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.autoClose,
  });

  final String title;
  final String? message;
  final String buttonLabel;
  final Duration autoClose;

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _confetti.play();
    if (widget.autoClose > Duration.zero) {
      Future<void>.delayed(widget.autoClose, () {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.04,
            numberOfParticles: 18,
            gravity: 0.25,
            colors: const [
              AppColors.primary,
              AppColors.primaryDark,
              AppColors.success,
              Color(0xFF3B82F6),
              Color(0xFFEC4899),
            ],
          ),
        ),
        Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceXl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusXl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 132,
                  width: 132,
                  child: Lottie.asset(
                    AppAssets.successAnimation,
                    repeat: false,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 64,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceMd),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(color: palette.textPrimary),
                ),
                if (widget.message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.message!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body
                        .copyWith(color: palette.textSecondary),
                  ),
                ],
                const SizedBox(height: AppConstants.spaceLg),
                PrimaryButton(
                  label: widget.buttonLabel,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
