import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../providers/settings_providers.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.accent,
  });

  final String title;
  final String description;
  final String imageAsset;
  final Color accent;
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Track Your Money Easily',
      description:
          'Record your income and expenses in a simple and smart way.',
      imageAsset: AppAssets.onboarding1,
      accent: AppColors.primary,
    ),
    _OnboardingPage(
      title: 'Create Smart Budgets',
      description: 'Manage spending and savings goals with clear limits.',
      imageAsset: AppAssets.onboarding2,
      accent: Color(0xFF3B82F6),
    ),
    _OnboardingPage(
      title: 'Learn Financial Skills',
      description:
          'Improve your financial habits with guidance and AI coaching.',
      imageAsset: AppAssets.onboarding3,
      accent: Color(0xFF8B5CF6),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).markOnboardingSeen();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 8),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.subtitle
                        .copyWith(color: palette.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (int i) => setState(() => _index = i),
                itemBuilder: (BuildContext context, int i) {
                  final _OnboardingPage page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spaceLg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: _OnboardingArt(
                              asset: page.imageAsset,
                              accent: page.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.spaceLg),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading
                              .copyWith(color: palette.textPrimary),
                        ),
                        const SizedBox(height: AppConstants.spaceSm),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body
                                .copyWith(color: palette.textSecondary),
                          ),
                        ),
                        const SizedBox(height: AppConstants.spaceLg),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (int i) => AnimatedContainer(
                  duration: AppConstants.durationNormal,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _index == i ? 28 : 8,
                  decoration: BoxDecoration(
                    color: _index == i ? AppColors.primary : palette.border,
                    borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spaceLg),
              child: PrimaryButton(
                label: isLast ? 'Get Started' : 'Next',
                icon: isLast ? Icons.arrow_forward_rounded : null,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingArt extends StatelessWidget {
  const _OnboardingArt({
    required this.asset,
    required this.accent,
  });

  final String asset;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      constraints: const BoxConstraints(maxWidth: 340, maxHeight: 340),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: palette.isDark ? 0.72 : 0.88),
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
            return ColoredBox(
              color: accent.withValues(alpha: 0.08),
              child: Icon(
                Icons.image_outlined,
                size: 64,
                color: accent.withValues(alpha: 0.55),
              ),
            );
          },
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 420.ms)
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }
}
