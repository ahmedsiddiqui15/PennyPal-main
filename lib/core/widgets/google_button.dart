import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.label = 'Continue with Google',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.googleIcon,
              height: 22,
              width: 22,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stack) {
                return const Icon(
                  Icons.g_mobiledata_rounded,
                  size: 22,
                  color: Color(0xFF4285F4),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.button.copyWith(color: palette.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
