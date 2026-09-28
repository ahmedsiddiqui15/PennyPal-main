import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_success.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/badge_model.dart';
import '../../../models/challenge_model.dart';
import '../../../providers/finance_providers.dart';

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinanceState> finance = ref.watch(financeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: finance.when(
        loading: () => const LoadingView(label: 'Loading your rewards…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(financeProvider.notifier).load(),
        ),
        data: (FinanceState data) {
          final int unlocked = data.unlockedBadgeCount;
          final int points = unlocked * 250 +
              data.challenges.fold(0, (s, c) => s + c.progressDays * 10);
          final int level = (points / 500).floor() + 1;
          final double levelProgress = (points % 500) / 500;

          return ListView(
            padding: const EdgeInsets.all(AppConstants.spaceMd),
            children: [
              
              AppCard(
                gradient: AppColors.amberGradient,
                padding: const EdgeInsets.all(AppConstants.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$level',
                            style: AppTextStyles.heading
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spaceMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Level $level Saver',
                                  style: AppTextStyles.title
                                      .copyWith(color: Colors.white)),
                              Text('$points points earned',
                                  style: AppTextStyles.caption.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.9),
                                  )),
                            ],
                          ),
                        ),
                        const Text('🏅', style: TextStyle(fontSize: 32)),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spaceMd),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusPill),
                      child: LinearProgressIndicator(
                        value: levelProgress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${500 - (points % 500)} points to level ${level + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spaceLg),

              
              SectionHeader(
                title: 'Badges',
                subtitle: '$unlocked of ${data.badges.length} unlocked',
              ),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppConstants.spaceSm,
                crossAxisSpacing: AppConstants.spaceSm,
                childAspectRatio: 0.82,
                children: data.badges
                    .asMap()
                    .entries
                    .map(
                      (MapEntry<int, BadgeModel> e) => _BadgeTile(badge: e.value)
                          .staggerIn(e.key),
                    )
                    .toList(),
              ),

              const SizedBox(height: AppConstants.spaceLg),

              
              const SectionHeader(
                title: 'Challenges',
                subtitle: 'Join and build better habits',
              ),
              ...data.challenges.asMap().entries.map(
                    (MapEntry<int, ChallengeModel> e) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.spaceMd),
                      child: _ChallengeCard(challenge: e.value)
                          .staggerIn(e.key),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final BadgeModel badge;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color color = Color(badge.colorValue);

    return GestureDetector(
      onTap: () => _showBadge(context, badge),
      child: AnimatedContainer(
        duration: AppConstants.durationNormal,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: badge.unlocked
              ? color.withValues(alpha: 0.12)
              : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: badge.unlocked
                ? color.withValues(alpha: 0.4)
                : palette.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: badge.unlocked ? 1 : 0.35,
              child: Text(badge.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 6),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: badge.unlocked ? palette.textPrimary : palette.textSecondary,
                fontSize: 10.5,
              ),
            ),
            if (!badge.unlocked)
              Icon(Icons.lock_rounded, size: 12, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showBadge(BuildContext context, BadgeModel badge) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Text(badge.emoji, style: const TextStyle(fontSize: 40)),
        title: Text(badge.title, textAlign: TextAlign.center),
        content: Text(badge.description, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(badge.unlocked ? 'Awesome' : 'Got it'),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge});

  final ChallengeModel challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(challenge.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.title,
                        style: AppTextStyles.subtitle
                            .copyWith(color: palette.textPrimary)),
                    Text('Reward: ${challenge.reward}',
                        style: AppTextStyles.caption
                            .copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              if (challenge.completed)
                const Icon(Icons.verified_rounded,
                    color: AppColors.success, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(challenge.description,
              style: AppTextStyles.caption
                  .copyWith(color: palette.textSecondary)),
          if (challenge.joined) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${challenge.progressDays} / ${challenge.targetDays} days',
                    style: AppTextStyles.caption
                        .copyWith(color: palette.textPrimary),
                  ),
                ),
                Text('${challenge.percent}%',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primaryDark)),
              ],
            ),
            const SizedBox(height: 8),
            BudgetProgressBar(progress: challenge.progress, height: 9),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final String? error = await ref
                          .read(financeProvider.notifier)
                          .toggleChallenge(challenge);
                      if (!context.mounted) return;
                      if (error != null) {
                        AppSnackbar.error(context, error);
                      } else {
                        AppSnackbar.info(context, 'You left the challenge.');
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Leave'),
                  ),
                ),
                const SizedBox(width: AppConstants.spaceMd),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: challenge.completed
                        ? null
                        : () async {
                            await ref
                                .read(financeProvider.notifier)
                                .progressChallenge(challenge, 1);
                            if (!context.mounted) return;
                            final ChallengeModel? updated = ref
                                .read(financeProvider)
                                .valueOrNull
                                ?.challenges
                                .firstWhere(
                                  (c) => c.id == challenge.id,
                                  orElse: () => challenge,
                                );
                            if (updated != null && updated.completed) {
                              await showSuccessOverlay(
                                context,
                                title: 'Challenge complete! 🏆',
                                message:
                                    'You finished ${challenge.title}. Reward unlocked.',
                                buttonLabel: 'Claim',
                              );
                            } else {
                              AppSnackbar.success(context, 'Progress logged.');
                            }
                          },
                    icon: const Icon(Icons.add_task_rounded, size: 16),
                    label: Text(challenge.completed ? 'Completed' : 'Log day'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppConstants.spaceMd),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final String? error = await ref
                      .read(financeProvider.notifier)
                      .toggleChallenge(challenge);
                  if (!context.mounted) return;
                  if (error != null) {
                    AppSnackbar.error(context, error);
                  } else {
                    AppSnackbar.success(context, 'Challenge joined! 💪');
                  }
                },
                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                label: const Text('Join Challenge'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
