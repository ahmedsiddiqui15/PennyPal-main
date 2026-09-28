import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

class AppLoadingBar extends StatelessWidget {
  const AppLoadingBar({
    super.key,
    this.width = 128,
    this.height = 3.5,
    this.color,
    this.trackColor,
  });

  final double width;
  final double height;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final Color active = color ?? AppColors.primary;
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        child: LinearProgressIndicator(
          minHeight: height,
          backgroundColor:
              trackColor ?? active.withValues(alpha: 0.16),
          valueColor: AlwaysStoppedAnimation<Color>(active),
        ),
      ),
    );
  }
}
