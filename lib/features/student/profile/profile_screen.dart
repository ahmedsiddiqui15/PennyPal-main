import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinanceState> finance = ref.watch(financeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: finance.when(
        loading: () => const LoadingView(),
        error: (Object e, StackTrace s) => ErrorView(message: e.toString()),
        data: (FinanceState data) {
          final UserModel? user = ref.watch(currentUserProvider);
          if (user == null) {
            return const LoadingView(label: 'Loading profile…');
          }
          final String symbol = ref.watch(currencySymbolProvider);
          final int unlockedBadges = data.unlockedBadgeCount;

          return ListView(
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
                    AppAvatar(
                      name: user.name,
                      imageUrl: user.photoUrl,
                      size: 88,
                      showEditBadge: true,
                      onTap: () => context.push(AppRoutes.editProfile),
                    ),
                    const SizedBox(height: AppConstants.spaceMd),
                    Text(
                      user.name,
                      style: AppTextStyles.title
                          .copyWith(color: context.palette.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppTextStyles.caption
                          .copyWith(color: context.palette.textSecondary),
                    ),
                    const SizedBox(height: AppConstants.spaceSm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusPill),
                      ),
                      child: Text(
                        user.role.label,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spaceLg),

              
              Row(
                children: [
                  Expanded(
                    child: _StatPill(
                      label: 'Balance',
                      value: Formatters.money(data.snapshot.balance,
                          symbol: symbol),
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceMd),
                  Expanded(
                    child: _StatPill(
                      label: 'Health',
                      value: '${data.snapshot.healthScore}/100',
                      icon: Icons.favorite_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: _StatPill(
                      label: 'Goals',
                      value: '${data.goals.length}',
                      icon: Icons.flag_rounded,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceMd),
                  Expanded(
                    child: _StatPill(
                      label: 'Badges',
                      value: '$unlockedBadges',
                      icon: Icons.military_tech_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spaceLg),
              const SectionHeader(title: 'Account'),
              _MenuTile(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                subtitle: 'Name, phone, photo, currency',
                onTap: () => context.push(AppRoutes.editProfile),
              ),
              _MenuTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                subtitle: 'Theme, currency, notifications',
                onTap: () => context.push(AppRoutes.settings),
              ),
              _MenuTile(
                icon: Icons.subscriptions_outlined,
                label: 'Subscriptions',
                subtitle: 'Track recurring payments',
                onTap: () => context.push(AppRoutes.subscriptions),
              ),

              const SizedBox(height: AppConstants.spaceLg),
              const SectionHeader(title: 'Money Tools'),
              _MenuTile(
                icon: Icons.receipt_long_outlined,
                label: 'Transactions',
                subtitle: 'Search, filter and sort history',
                onTap: () => context.push(AppRoutes.transactions),
              ),
              _MenuTile(
                icon: Icons.bar_chart_rounded,
                label: 'Reports & Analytics',
                subtitle: 'Charts and PDF export',
                onTap: () => context.push(AppRoutes.reports),
              ),
              _MenuTile(
                icon: Icons.insights_rounded,
                label: 'Smart Insights',
                subtitle: 'Personalised money observations',
                onTap: () => context.push(AppRoutes.insights),
              ),
              _MenuTile(
                icon: Icons.support_agent_outlined,
                label: 'Penny AI Assistant',
                subtitle: 'Ask anything about your money',
                onTap: () => context.push(AppRoutes.aiAssistant),
              ),

              const SizedBox(height: AppConstants.spaceLg),
              const SectionHeader(title: 'Grow'),
              _MenuTile(
                icon: Icons.military_tech_outlined,
                label: 'Rewards & Challenges',
                subtitle: 'Badges, streaks and points',
                onTap: () => context.push(AppRoutes.gamification),
              ),
              _MenuTile(
                icon: Icons.school_outlined,
                label: 'Learn',
                subtitle: 'Financial skills library',
                onTap: () => context.push(AppRoutes.learning),
              ),
              _MenuTile(
                icon: Icons.support_agent_rounded,
                label: 'Support',
                subtitle: 'Feedback and help',
                onTap: () => context.push(AppRoutes.support),
              ),
              _MenuTile(
                icon: Icons.info_outline_rounded,
                label: 'About PennyPal',
                subtitle: 'Purpose, features and disclaimer',
                onTap: () => context.push(AppRoutes.about),
              ),

              const SizedBox(height: AppConstants.spaceLg),
              _MenuTile(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                danger: true,
                onTap: () async {
                  final bool confirmed = await AppDialog.confirm(
                    context,
                    title: 'Log out?',
                    message: 'You can sign back in any time.',
                    confirmLabel: 'Log Out',
                    destructive: true,
                  );
                  if (!confirmed || !context.mounted) return;
                  await ref.read(authProvider.notifier).signOut();
                },
              ),

              const SizedBox(height: AppConstants.spaceLg),
              Center(
                child: Text(
                  '${AppConstants.appName} v${AppConfig.appVersion} • '
                  '${AppConstants.tagline}',
                  style: AppTextStyles.caption.copyWith(
                    color: context.palette.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      radius: AppConstants.radiusMd,
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Text(value,
                      style: AppTextStyles.subtitle
                          .copyWith(color: palette.textPrimary)),
                ),
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: palette.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color color = danger ? AppColors.danger : palette.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd,
          vertical: 12,
        ),
        radius: AppConstants.radiusMd,
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: (danger ? AppColors.danger : AppColors.primary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: danger ? AppColors.danger : AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.subtitle.copyWith(color: color)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: AppTextStyles.caption
                            .copyWith(color: palette.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
          ],
        ),
      ).staggerIn(0),
    );
  }
}
