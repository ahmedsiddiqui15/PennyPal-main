import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/learning_model.dart';
import '../../../providers/content_providers.dart';

class AdminContentScreen extends ConsumerWidget {
  const AdminContentScreen({super.key});

  static const List<String> _categories = [
    'Budgeting',
    'Saving',
    'Needs vs Wants',
    'Income Management',
    'Investing',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<LearningModel>> learning = ref.watch(learningProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Content')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Article'),
      ),
      body: learning.when(
        loading: () => const LoadingView(label: 'Loading content…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(learningProvider.notifier).load(),
        ),
        data: (List<LearningModel> articles) {
          final int published = articles.where((a) => a.published).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceMd,
              AppConstants.spaceSm,
              AppConstants.spaceMd,
              AppConstants.spaceXxl * 2,
            ),
            children: [
              AppCard(
                gradient: AppColors.amberGradient,
                padding: const EdgeInsets.all(AppConstants.spaceLg),
                child: Row(
                  children: [
                    const Icon(Icons.article_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(width: AppConstants.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${articles.length} articles',
                              style: AppTextStyles.title
                                  .copyWith(color: Colors.white)),
                          Text('$published published • '
                              '${articles.length - published} drafts',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              const SectionHeader(
                title: 'Financial Articles',
                subtitle: 'Create, edit, publish or delete',
              ),
              if (articles.isEmpty)
                AppCard(
                  child: EmptyState(
                    compact: true,
                    emoji: '📝',
                    title: 'No articles yet',
                    message: 'Create your first lesson for students.',
                    actionLabel: 'New Article',
                    onAction: () => _openEditor(context, ref, null),
                  ),
                )
              else
                ...articles.asMap().entries.map(
                      (MapEntry<int, LearningModel> e) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppConstants.spaceSm),
                        child: _ArticleAdminTile(article: e.value)
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

class _ArticleAdminTile extends ConsumerWidget {
  const _ArticleAdminTile({required this.article});

  final LearningModel article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      radius: AppConstants.radiusMd,
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(article.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle
                            .copyWith(color: palette.textPrimary)),
                    Text('${article.category} • ${article.readMinutes} min',
                        style: AppTextStyles.caption
                            .copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (article.published
                          ? AppColors.success
                          : AppColors.warning)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                ),
                child: Text(
                  article.published ? 'Published' : 'Draft',
                  style: AppTextStyles.caption.copyWith(
                    color:
                        article.published ? AppColors.success : AppColors.warning,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(article.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.caption.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final String? error = await ref
                        .read(learningProvider.notifier)
                        .togglePublished(article);
                    if (!context.mounted) return;
                    if (error != null) {
                      AppSnackbar.error(context, error);
                    } else {
                      AppSnackbar.success(
                        context,
                        article.published ? 'Moved to drafts.' : 'Published.',
                      );
                    }
                  },
                  icon: Icon(
                    article.published
                        ? Icons.unpublished_rounded
                        : Icons.publish_rounded,
                    size: 16,
                  ),
                  label: Text(article.published ? 'Unpublish' : 'Publish'),
                ),
              ),
              const SizedBox(width: AppConstants.spaceSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditor(context, ref, article),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppConstants.spaceSm),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, ref, article),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    LearningModel article,
  ) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete article?',
      message: '"${article.title}" will be removed permanently.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final String? error =
        await ref.read(learningProvider.notifier).delete(article.id);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.success(context, 'Article deleted.');
    }
  }
}

void _openEditor(BuildContext context, WidgetRef ref, LearningModel? article) {
  AppDialog.sheet<void>(
    context,
    child: _ArticleEditor(article: article),
  );
}

class _ArticleEditor extends ConsumerStatefulWidget {
  const _ArticleEditor({this.article});

  final LearningModel? article;

  @override
  ConsumerState<_ArticleEditor> createState() => _ArticleEditorState();
}

class _ArticleEditorState extends ConsumerState<_ArticleEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.article?.title ?? '');
  late final TextEditingController _summary =
      TextEditingController(text: widget.article?.summary ?? '');
  late final TextEditingController _content =
      TextEditingController(text: widget.article?.content ?? '');
  late final TextEditingController _minutes = TextEditingController(
    text: (widget.article?.readMinutes ?? 4).toString(),
  );
  late String _category =
      widget.article?.category ?? AdminContentScreen._categories.first;
  late String _emoji = widget.article?.emoji ?? '📘';
  late bool _published = widget.article?.published ?? false;
  bool _saving = false;

  static const List<String> _emojis = [
    '📘', '💰', '🐖', '⚖️', '💼', '📈', '🧾', '🎯', '🧠', '💡',
  ];

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _content.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final LearningModel model = widget.article == null
        ? LearningModel(
            id: '',
            title: _title.text.trim(),
            category: _category,
            summary: _summary.text.trim(),
            content: _content.text.trim(),
            readMinutes: int.tryParse(_minutes.text.trim()) ?? 4,
            emoji: _emoji,
            published: _published,
          )
        : widget.article!.copyWith(
            title: _title.text.trim(),
            category: _category,
            summary: _summary.text.trim(),
            content: _content.text.trim(),
            readMinutes: int.tryParse(_minutes.text.trim()) ?? 4,
            emoji: _emoji,
            published: _published,
          );

    final String? error =
        await ref.read(learningProvider.notifier).save(model);

    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.success(context, 'Article saved.');
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: widget.article == null ? 'New article' : 'Edit article',
            ),
            const SizedBox(height: AppConstants.spaceLg),
            AppTextField(
              label: 'Title',
              controller: _title,
              icon: Icons.title_rounded,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => Validators.notEmpty(v, 'Title'),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            Text('Category',
                style: AppTextStyles.subtitle
                    .copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppConstants.spaceSm),
            Wrap(
              spacing: AppConstants.spaceSm,
              runSpacing: AppConstants.spaceSm,
              children: AdminContentScreen._categories
                  .map(
                    (String c) => AppChip(
                      label: c,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            Text('Cover emoji',
                style: AppTextStyles.subtitle
                    .copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppConstants.spaceSm),
            Wrap(
              spacing: AppConstants.spaceSm,
              runSpacing: AppConstants.spaceSm,
              children: _emojis
                  .map(
                    (String e) => GestureDetector(
                      onTap: () => setState(() => _emoji = e),
                      child: Container(
                        height: 44,
                        width: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _emoji == e
                              ? AppColors.primary.withValues(alpha: 0.16)
                              : palette.surfaceMuted,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMd),
                          border: Border.all(
                            color: _emoji == e
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            AppTextField(
              label: 'Summary',
              hint: 'One-line description shown in the list',
              controller: _summary,
              icon: Icons.short_text_rounded,
              maxLines: 2,
              minLines: 2,
              validator: (v) => Validators.notEmpty(v, 'Summary'),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            AppTextField(
              label: 'Content',
              hint: 'Write the lesson body…',
              controller: _content,
              icon: Icons.article_outlined,
              maxLines: 10,
              minLines: 6,
              validator: (v) => Validators.notEmpty(v, 'Content'),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            AppTextField(
              label: 'Read minutes',
              controller: _minutes,
              icon: Icons.schedule_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppConstants.spaceSm),
            SwitchListTile(
              value: _published,
              onChanged: (bool v) => setState(() => _published = v),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: Text('Publish immediately',
                  style: AppTextStyles.subtitle
                      .copyWith(color: palette.textPrimary)),
              subtitle: Text('Unpublished articles stay as drafts',
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary)),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            PrimaryButton(
              label: 'Save Article',
              icon: Icons.check_rounded,
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
