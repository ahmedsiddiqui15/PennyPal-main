import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/learning_model.dart';
import '../../../providers/content_providers.dart';

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({super.key, required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LearningModel>> learning = ref.watch(learningProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lesson')),
      body: learning.when(
        loading: () => const LoadingView(),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(learningProvider.notifier).load(),
        ),
        data: (List<LearningModel> articles) {
          LearningModel? article;
          for (final LearningModel a in articles) {
            if (a.id == articleId) article = a;
          }

          if (article == null) {
            return const EmptyState(
              emoji: '📕',
              title: 'Lesson not found',
              message: 'This article may have been removed.',
            );
          }

          return _ArticleBody(article: article);
        },
      ),
    );
  }
}

class _ArticleBody extends ConsumerWidget {
  const _ArticleBody({required this.article});

  final LearningModel article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      children: [
        AppCard(
          gradient: AppColors.amberGradient,
          padding: const EdgeInsets.all(AppConstants.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: AppConstants.spaceMd),
              Text(
                article.title,
                style: AppTextStyles.heading.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${article.category} • ${article.readMinutes} min read',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spaceLg),
        Text(
          article.summary,
          style: AppTextStyles.subtitle.copyWith(
            color: palette.textPrimary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppConstants.spaceMd),
        Divider(color: palette.divider),
        const SizedBox(height: AppConstants.spaceMd),
        Text(
          article.content,
          style: AppTextStyles.body.copyWith(
            color: palette.textPrimary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: AppConstants.spaceXl),
        AppCard(
          color: AppColors.primary.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primaryDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Finished? Ask Penny AI to apply this to your own numbers.',
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spaceLg),
        PrimaryButton(
          label: 'Mark as read',
          icon: Icons.check_circle_outline_rounded,
          onPressed: () {
            AppSnackbar.success(context, 'Nice work! Lesson completed.');
            Navigator.of(context).maybePop();
          },
        ),
        const SizedBox(height: AppConstants.spaceMd),
        Text(
          'By ${article.author} • Updated ${Formatters.date(article.createdAt ?? DateTime.now())}',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}
