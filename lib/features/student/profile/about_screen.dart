import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/section_header.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const List<(IconData, String, String)> _features = [
    (
      Icons.receipt_long_rounded,
      'Track money',
      'Log income and expenses, scan receipts and see where your money goes.',
    ),
    (
      Icons.donut_large_rounded,
      'Budget smartly',
      'Set a monthly budget and category limits with instant overspending alerts.',
    ),
    (
      Icons.savings_rounded,
      'Grow savings',
      'Create goals with a monthly contribution and watch your progress climb.',
    ),
    (
      Icons.support_agent_rounded,
      'Learn & improve',
      'Financial literacy articles, smart insights and an AI budgeting assistant.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('About PennyPal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spaceMd,
          AppConstants.spaceSm,
          AppConstants.spaceMd,
          AppConstants.spaceXxl,
        ),
        children: [
          
          AppCard(
            padding: const EdgeInsets.all(AppConstants.spaceLg),
            child: Column(
              children: [
                const AppLogo(size: 76, showWordmark: false),
                const SizedBox(height: AppConstants.spaceMd),
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.heading
                      .copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  AppConstants.tagline,
                  style: AppTextStyles.subtitle
                      .copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppConstants.spaceSm),
                Text(
                  'Version ${AppConfig.appVersion}',
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spaceLg),

          
          const SectionHeader(title: 'Our purpose'),
          AppCard(
            child: Text(
              'PennyPal is a personal finance learning and expense-management '
              'app built for students. It helps you record everyday spending, '
              'plan a budget, build savings habits and understand your money '
              'through simple, beginner-friendly guidance — so the allowance, '
              'scholarship or part-time income you receive lasts longer and '
              'goes further.',
              style: AppTextStyles.body.copyWith(color: palette.textSecondary),
            ),
          ),

          const SizedBox(height: AppConstants.spaceLg),

          
          const SectionHeader(title: 'What you can do'),
          AppCard(
            child: Column(
              children: _features
                  .asMap()
                  .entries
                  .map(
                    (MapEntry<int, (IconData, String, String)> e) => Column(
                      children: [
                        _FeatureRow(
                          icon: e.value.$1,
                          title: e.value.$2,
                          detail: e.value.$3,
                        ),
                        if (e.key != _features.length - 1)
                          Divider(color: palette.divider),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: AppConstants.spaceLg),

          
          const SectionHeader(title: 'Important'),
          AppCard(
            color: AppColors.warning.withValues(alpha: 0.10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 20, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text('Guidance only',
                        style: AppTextStyles.subtitle
                            .copyWith(color: palette.textPrimary)),
                  ],
                ),
                const SizedBox(height: AppConstants.spaceSm),
                Text(
                  'PennyPal is not a bank, digital wallet, payment gateway, '
                  'investment platform or professional financial adviser. It '
                  'does not connect to real bank accounts, move money or store '
                  'card details. Every tip, insight and AI reply is educational '
                  'guidance and should not be treated as financial advice.',
                  style:
                      AppTextStyles.caption.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spaceLg),

          
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 20, color: AppColors.primaryDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your data stays yours',
                          style: AppTextStyles.subtitle
                              .copyWith(color: palette.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        'Financial records are stored securely against your '
                        'account and are never shared with other students.',
                        style: AppTextStyles.caption
                            .copyWith(color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spaceLg),
          Center(
            child: Text(
              'Made with Flutter • Powered by Firebase',
              style: AppTextStyles.caption.copyWith(
                color: palette.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.subtitle
                        .copyWith(color: palette.textPrimary)),
                const SizedBox(height: 2),
                Text(detail,
                    style: AppTextStyles.caption
                        .copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
