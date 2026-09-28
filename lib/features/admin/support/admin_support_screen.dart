import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
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
import '../../../models/support_model.dart';
import '../../../providers/content_providers.dart';

class AdminSupportScreen extends ConsumerWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SupportModel>> support = ref.watch(supportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(supportProvider.notifier).load(),
          ),
        ],
      ),
      body: support.when(
        loading: () => const LoadingView(label: 'Loading queries…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(supportProvider.notifier).load(),
        ),
        data: (List<SupportModel> all) {
          final List<SupportModel> items = [...all]
            ..sort((a, b) => (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)));

          final int pending =
              items.where((i) => i.status == SupportStatus.pending).length;
          final int inProgress =
              items.where((i) => i.status == SupportStatus.inProgress).length;
          final int resolved =
              items.where((i) => i.status == SupportStatus.resolved).length;
          final double resolutionRate =
              items.isEmpty ? 0 : resolved / items.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceMd,
              AppConstants.spaceSm,
              AppConstants.spaceMd,
              AppConstants.spaceXxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatusStat(
                      label: 'Pending',
                      value: pending,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceSm),
                  Expanded(
                    child: _StatusStat(
                      label: 'In progress',
                      value: inProgress,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceSm),
                  Expanded(
                    child: _StatusStat(
                      label: 'Resolved',
                      value: resolved,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceLg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Resolution rate',
                            style: AppTextStyles.subtitle.copyWith(
                              color: context.palette.textPrimary,
                            )),
                        const Spacer(),
                        Text(Formatters.percent(resolutionRate),
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.success,
                            )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BudgetProgressBar(
                      progress: resolutionRate,
                      color: AppColors.success,
                      height: 9,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              SectionHeader(
                title: 'All Queries',
                subtitle: '${items.length} total',
              ),
              if (items.isEmpty)
                const AppCard(
                  child: EmptyState(
                    compact: true,
                    emoji: '📬',
                    title: 'No queries yet',
                    message: 'Student questions and feedback appear here.',
                  ),
                )
              else
                ...items.asMap().entries.map(
                      (MapEntry<int, SupportModel> e) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppConstants.spaceSm),
                        child: _QueryTile(query: e.value).staggerIn(e.key),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusStat extends StatelessWidget {
  const _StatusStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      radius: AppConstants.radiusMd,
      child: Column(
        children: [
          Text('$value',
              style: AppTextStyles.title.copyWith(color: color)),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption
                  .copyWith(color: palette.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _QueryTile extends ConsumerWidget {
  const _QueryTile({required this.query});

  final SupportModel query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final Color statusColor = query.status.color;

    return AppCard(
      onTap: () => _openDetail(context, ref, query),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      radius: AppConstants.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  query.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle
                      .copyWith(color: palette.textPrimary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                ),
                child: Text(
                  query.status.label,
                  style: AppTextStyles.caption
                      .copyWith(color: statusColor, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${query.userName} • ${Formatters.relativeDate(query.createdAt ?? DateTime.now())}',
            style:
                AppTextStyles.caption.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            query.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statusButton(
                context,
                ref,
                SupportStatus.pending,
                statusColor,
              ),
              const SizedBox(width: 6),
              _statusButton(
                context,
                ref,
                SupportStatus.inProgress,
                AppColors.info,
              ),
              const SizedBox(width: 6),
              _statusButton(
                context,
                ref,
                SupportStatus.resolved,
                AppColors.success,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _openDetail(context, ref, query),
                child: const Text('Reply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusButton(
    BuildContext context,
    WidgetRef ref,
    SupportStatus status,
    Color color,
  ) {
    final bool selected = query.status == status;
    return GestureDetector(
      onTap: () async {
        final String? error = await ref
            .read(supportProvider.notifier)
            .updateStatus(query, status);
        if (!context.mounted) return;
        if (error != null) {
          AppSnackbar.error(context, error);
        } else {
          AppSnackbar.success(context, 'Marked as ${status.label}.');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusPill),
          border: Border.all(
            color: selected ? color : context.palette.border,
          ),
        ),
        child: Text(
          status.label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? color : context.palette.textSecondary,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

void _openDetail(BuildContext context, WidgetRef ref, SupportModel query) {
  AppDialog.sheet<void>(
    context,
    child: _QueryDetail(query: query),
  );
}

class _QueryDetail extends ConsumerStatefulWidget {
  const _QueryDetail({required this.query});

  final SupportModel query;

  @override
  ConsumerState<_QueryDetail> createState() => _QueryDetailState();
}

class _QueryDetailState extends ConsumerState<_QueryDetail> {
  late final TextEditingController _response =
      TextEditingController(text: widget.query.response);
  late SupportStatus _status = widget.query.status;
  bool _sending = false;

  @override
  void dispose() {
    _response.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    final String? error = await ref
        .read(supportProvider.notifier)
        .updateStatus(widget.query, _status, response: _response.text.trim());

    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.success(context, 'Response sent.');
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final SupportModel query = widget.query;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader(title: 'Query detail'),
          const SizedBox(height: AppConstants.spaceLg),
          AppCard(
            color: palette.surfaceMuted,
            padding: const EdgeInsets.all(AppConstants.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(query.subject,
                    style: AppTextStyles.subtitle
                        .copyWith(color: palette.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  '${query.userName} • ${query.userEmail}',
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: 10),
                Text(query.message,
                    style: AppTextStyles.body
                        .copyWith(color: palette.textPrimary)),
                if (query.rating > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(
                      5,
                      (int i) => Icon(
                        i < query.rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceLg),
          Text('Status',
              style: AppTextStyles.subtitle
                  .copyWith(color: palette.textPrimary)),
          const SizedBox(height: AppConstants.spaceSm),
          Wrap(
            spacing: AppConstants.spaceSm,
            children: SupportStatus.values
                .map(
                  (SupportStatus s) => AppChip(
                    label: s.label,
                    selected: _status == s,
                    onTap: () => setState(() => _status = s),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppConstants.spaceLg),
          AppTextField(
            label: 'Response to student',
            hint: 'Type your reply…',
            controller: _response,
            icon: Icons.reply_rounded,
            maxLines: 4,
            minLines: 3,
          ),
          const SizedBox(height: AppConstants.spaceLg),
          PrimaryButton(
            label: 'Send Response',
            icon: Icons.send_rounded,
            isLoading: _sending,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
