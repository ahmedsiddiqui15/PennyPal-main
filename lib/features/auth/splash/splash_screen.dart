import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_loading_bar.dart';
import '../../../core/widgets/app_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: palette.isDark
                ? const [Color(0xFF111827), Color(0xFF1F2937)]
                : const [Color(0xFFFFFBEB), Color(0xFFFAFAF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(size: 112, showWordmark: false)
                        .animate()
                        .scale(
                          duration: 900.ms,
                          curve: Curves.easeOutBack,
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1, 1),
                        )
                        .fadeIn(duration: 600.ms),
                    const SizedBox(height: AppConstants.spaceLg),
                    Text(
                      AppConstants.appName,
                      style: AppTextStyles.display
                          .copyWith(color: palette.textPrimary),
                    ).animate().fadeIn(delay: 350.ms, duration: 600.ms).slideY(
                          begin: 0.3,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 6),
                    Text(
                      AppConstants.tagline,
                      style: AppTextStyles.body
                          .copyWith(color: palette.textSecondary),
                    ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: AppConstants.spaceXl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLoadingBar()
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 500.ms),
                    const SizedBox(height: AppConstants.spaceSm),
                    Text(
                      'Loading',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: palette.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ).animate().fadeIn(delay: 850.ms, duration: 500.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
