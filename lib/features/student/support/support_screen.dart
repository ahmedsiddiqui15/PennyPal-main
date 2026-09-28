import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_success.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/support_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/content_providers.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key, this.initialTab = 0});

  
  
  final int initialTab;

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 1),
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<SupportModel>> support = ref.watch(supportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Feedback'),
            Tab(text: 'Contact Support'),
          ],
        ),
      ),
      body: support.when(
        loading: () => const LoadingView(),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(supportProvider.notifier).load(),
        ),
        data: (List<SupportModel> items) => TabBarView(
          controller: _tabs,
          children: [
            _FeedbackTab(tickets: items),
            _ContactTab(tickets: items),
          ],
        ),
      ),
    );
  }
}

class _FeedbackTab extends ConsumerStatefulWidget {
  const _FeedbackTab({required this.tickets});

  final List<SupportModel> tickets;

  @override
  ConsumerState<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends ConsumerState<_FeedbackTab> {
  final TextEditingController _comment = TextEditingController();
  int _rating = 0;
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      AppSnackbar.warning(context, 'Please choose a rating first.');
      return;
    }
    setState(() => _sending = true);

    final user = ref.read(currentUserProvider);
    final SupportModel feedback = SupportModel(
      id: '',
      userId: user?.id ?? '',
      userName: user?.name ?? 'Student',
      userEmail: user?.email ?? '',
      subject: 'App feedback',
      message: _comment.text.trim(),
      rating: _rating,
      isFeedback: true,
      createdAt: DateTime.now(),
    );

    final String? error =
        await ref.read(supportProvider.notifier).submit(feedback);

    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    _comment.clear();
    setState(() => _rating = 0);
    await showSuccessOverlay(
      context,
      title: 'Thank you! 🌟',
      message: 'Your feedback helps us make PennyPal better.',
      buttonLabel: 'Close',
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final List<SupportModel> feedback =
        widget.tickets.where((t) => t.isFeedback).toList();

    return ListView(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppConstants.spaceLg),
          child: Column(
            children: [
              Text('Rate PennyPal',
                  style: AppTextStyles.title.copyWith(color: palette.textPrimary)),
              const SizedBox(height: 6),
              Text('How is your experience so far?',
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary)),
              const SizedBox(height: AppConstants.spaceLg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (int i) {
                  final int star = i + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = star),
                    iconSize: 38,
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: star <= _rating
                          ? AppColors.primary
                          : palette.textSecondary,
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppConstants.spaceSm),
              AppTextField(
                label: 'Tell us more (optional)',
                hint: 'What do you love? What should we fix?',
                controller: _comment,
                icon: Icons.rate_review_outlined,
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: AppConstants.spaceLg),
              PrimaryButton(
                label: 'Submit Feedback',
                icon: Icons.send_rounded,
                isLoading: _sending,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        if (feedback.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spaceLg),
          const SectionHeader(title: 'Your feedback'),
          ...feedback.asMap().entries.map(
                (MapEntry<int, SupportModel> e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
                  child: _HistoryCard(ticket: e.value).staggerIn(e.key),
                ),
              ),
        ],
      ],
    );
  }
}

class _ContactTab extends ConsumerStatefulWidget {
  const _ContactTab({required this.tickets});

  final List<SupportModel> tickets;

  @override
  ConsumerState<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends ConsumerState<_ContactTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final user = ref.read(currentUserProvider);
    final SupportModel query = SupportModel(
      id: '',
      userId: user?.id ?? '',
      userName: user?.name ?? 'Student',
      userEmail: user?.email ?? '',
      subject: _subject.text.trim(),
      message: _message.text.trim(),
      createdAt: DateTime.now(),
    );

    final String? error =
        await ref.read(supportProvider.notifier).submit(query);

    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    _subject.clear();
    _message.clear();
    AppSnackbar.success(context, 'Query sent — we will reply within 24 hours.');
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final List<SupportModel> queries =
        widget.tickets.where((t) => !t.isFeedback).toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppConstants.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.support_agent_rounded,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('We are here to help',
                              style: AppTextStyles.title
                                  .copyWith(color: palette.textPrimary)),
                          Text('Typical reply time: under 24 hours',
                              style: AppTextStyles.caption
                                  .copyWith(color: palette.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spaceLg),
                AppTextField(
                  label: 'Subject',
                  hint: 'e.g. Receipt scanner issue',
                  controller: _subject,
                  icon: Icons.subject_rounded,
                  validator: (v) => Validators.notEmpty(v, 'Subject'),
                ),
                const SizedBox(height: AppConstants.spaceMd),
                AppTextField(
                  label: 'Message',
                  hint: 'Describe your issue in detail…',
                  controller: _message,
                  icon: Icons.message_outlined,
                  maxLines: 5,
                  minLines: 4,
                  validator: (v) => Validators.notEmpty(v, 'Message'),
                ),
                const SizedBox(height: AppConstants.spaceLg),
                PrimaryButton(
                  label: 'Send Query',
                  icon: Icons.send_rounded,
                  isLoading: _sending,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
          if (queries.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spaceLg),
            const SectionHeader(title: 'Your queries'),
            ...queries.asMap().entries.map(
                  (MapEntry<int, SupportModel> e) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppConstants.spaceSm),
                    child: _HistoryCard(ticket: e.value).staggerIn(e.key),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.ticket});

  final SupportModel ticket;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color statusColor = ticket.status.color;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      radius: AppConstants.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: AppTextStyles.subtitle
                      .copyWith(color: palette.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                ),
                child: Text(
                  ticket.status.label,
                  style: AppTextStyles.caption.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          if (ticket.rating > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: List.generate(
                5,
                (int i) => Icon(
                  i < ticket.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(ticket.message,
              style:
                  AppTextStyles.caption.copyWith(color: palette.textSecondary)),
          if (ticket.response.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PennyPal Support',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.success)),
                  const SizedBox(height: 2),
                  Text(ticket.response,
                      style: AppTextStyles.caption
                          .copyWith(color: palette.textSecondary)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            Formatters.relativeDate(ticket.createdAt ?? DateTime.now()),
            style: AppTextStyles.caption.copyWith(
              color: palette.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
