import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/learning_model.dart';
import '../../../providers/content_providers.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<LearningModel>> learning = ref.watch(learningProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: learning.when(
        loading: () => const LoadingView(label: 'Loading lessons…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(learningProvider.notifier).load(),
        ),
        data: (List<LearningModel> articles) {
          final List<String> categories = [
            'All',
            ...ref.watch(learningCategoriesProvider),
          ];
          final List<LearningModel> filtered = _category == 'All'
              ? articles
              : articles.where((a) => a.category == _category).toList();
          final int totalMinutes =
              articles.fold(0, (sum, a) => sum + a.readMinutes);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceMd,
              AppConstants.spaceSm,
              AppConstants.spaceMd,
              AppConstants.spaceXxl,
            ),
            children: [
              AppCard(
                gradient: AppColors.amberGradient,
                padding: const EdgeInsets.all(AppConstants.spaceLg),
                child: Row(
                  children: [
                    const Text('📚', style: TextStyle(fontSize: 38)),
                    const SizedBox(width: AppConstants.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Financial Skills',
                              style: AppTextStyles.title
                                  .copyWith(color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(
                            '${articles.length} lessons • $totalMinutes min of reading',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: categories
                      .map(
                        (String c) => Padding(
                          padding: const EdgeInsets.only(
                            right: AppConstants.spaceSm,
                          ),
                          child: AppChip(
                            label: c,
                            selected: _category == c,
                            onTap: () => setState(() => _category = c),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              SectionHeader(
                title: _category == 'All' ? 'All lessons' : _category,
                subtitle: '${filtered.length} available',
              ),
              if (filtered.isEmpty)
                const AppCard(
                  child: EmptyState(
                    compact: true,
                    emoji: '📖',
                    title: 'Nothing here yet',
                    message: 'New lessons are added regularly.',
                  ),
                )
              else
                ...filtered.asMap().entries.map(
                      (MapEntry<int, LearningModel> e) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppConstants.spaceSm),
                        child: _ArticleCard(article: e.value).staggerIn(e.key),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final LearningModel article;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return AppCard(
      onTap: () => context.push(AppRoutes.articleDetailPath(article.id)),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      radius: AppConstants.radiusMd,
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(article.emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: AppConstants.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle
                      .copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusPill),
                      ),
                      child: Text(
                        article.category,
                        style: AppTextStyles.caption.copyWith(
                          color: palette.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.schedule_rounded,
                        size: 13, color: palette.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${article.readMinutes} min read',
                      style: AppTextStyles.caption.copyWith(
                        color: palette.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    if (!article.published) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Draft',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.warning, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
        ],
      ),
    );
  }
}

class ReadingProgress extends StatelessWidget {
  const ReadingProgress({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) =>
      BudgetProgressBar(progress: progress, height: 6);
}
