import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 96,
    this.showWordmark = true,
    this.showTagline = false,
    this.compact = false,
  });

  final double size;
  final bool showWordmark;
  final bool showTagline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    final Widget mark = SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        AppAssets.logo,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          
          return Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(size * 0.28),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: size * 0.48,
              color: AppColors.primaryDark,
            ),
          );
        },
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        if (!compact) const SizedBox(width: 16),
        if (!compact)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style:
                    AppTextStyles.heading.copyWith(color: palette.textPrimary),
              ),
              if (showTagline)
                Text(
                  AppConstants.tagline,
                  style: AppTextStyles.body
                      .copyWith(color: palette.textSecondary),
                ),
            ],
          ),
      ],
    );
  }
}
