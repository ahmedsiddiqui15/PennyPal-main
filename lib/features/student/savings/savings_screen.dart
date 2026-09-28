import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_success.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/saving_goal_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinanceState> finance = ref.watch(financeProvider);
    final String symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Savings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGoalSheet(context, ref, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal'),
      ),
      body: finance.when(
        loading: () => const LoadingView(label: 'Loading your goals…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(financeProvider.notifier).load(),
        ),
        data: (FinanceState data) {
          final List<SavingGoalModel> goals = data.goals;
          final double saved = data.snapshot.totalSaved;
          final double target = data.snapshot.totalGoalTarget;
          final double progress = target <= 0 ? 0 : (saved / target).clamp(0, 1);
          final List<SavingGoalModel> active =
              goals.where((SavingGoalModel g) => !g.completed).toList();
          final List<SavingGoalModel> completed =
              goals.where((SavingGoalModel g) => g.completed).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceMd,
              AppConstants.spaceSm,
              AppConstants.spaceMd,
              AppConstants.spaceXxl * 2,
            ),
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppConstants.spaceLg),
                child: Row(
                  children: [
                    PercentageRing(
                      progress: progress,
                      size: 112,
                      label: 'Saved',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppConstants.spaceLg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total saved',
                              style: AppTextStyles.caption.copyWith(
                                color: context.palette.textSecondary,
                              )),
                          Text(
                            Formatters.money(saved, symbol: symbol),
                            style: AppTextStyles.title.copyWith(
                              color: context.palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'of ${Formatters.money(target, symbol: symbol)} target',
                            style: AppTextStyles.caption.copyWith(
                              color: context.palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${goals.where((g) => g.completed).length} of '
                            '${goals.length} goals completed',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              const SectionHeader(
                title: 'Active Goals',
                subtitle: 'Tap a goal to add money',
              ),
              if (active.isEmpty)
                const AppCard(
                  child: EmptyState(
                    compact: true,
                    emoji: '🐖',
                    title: 'No active saving goals',
                    message: 'Create a goal like "New Laptop" and start saving.',
                  ),
                )
              else
                ...active.asMap().entries.map(
                      (MapEntry<int, SavingGoalModel> e) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppConstants.spaceMd),
                        child: _GoalCard(
                          goal: e.value,
                          symbol: symbol,
                        ).staggerIn(e.key),
                      ),
                    ),

              
              if (completed.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spaceSm),
                SectionHeader(
                  title: 'Goal History',
                  subtitle: '${completed.length} archived '
                      '${completed.length == 1 ? 'goal' : 'goals'}',
                ),
                ...completed.asMap().entries.map(
                      (MapEntry<int, SavingGoalModel> e) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppConstants.spaceMd),
                        child: _GoalCard(
                          goal: e.value,
                          symbol: symbol,
                          archived: true,
                        ).staggerIn(e.key),
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({
    required this.goal,
    required this.symbol,
    this.archived = false,
  });

  final SavingGoalModel goal;
  final String symbol;

  
  final bool archived;

  
  
  String get _timeline {
    if (goal.completed) return 'Goal reached 🎉';
    final DateTime? eta = goal.estimatedCompletion;
    if (eta != null) {
      final int months = goal.monthsToComplete!;
      return '≈ $months ${months == 1 ? 'month' : 'months'} left · '
          'by ${Formatters.date(eta)}';
    }
    if (goal.deadline != null) return '${goal.daysLeft} days left';
    return 'No timeline set';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final Color color = Color(goal.colorValue);
    final bool locked = archived || goal.completed;

    return AppCard(
      onTap: locked ? null : () => _showAddFundsSheet(context, ref, goal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(goal.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle
                          .copyWith(color: palette.textPrimary),
                    ),
                    Text(
                      _timeline,
                      style: AppTextStyles.caption
                          .copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              if (goal.completed) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.14),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('Done',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.success)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
              ],
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: palette.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMd),
                ),
                onSelected: (String value) {
                  if (value == 'edit') {
                    _showGoalSheet(context, ref, goal);
                  } else {
                    _delete(context, ref);
                  }
                },
                itemBuilder: (_) => [
                  if (!goal.completed)
                    const PopupMenuItem<String>(
                        value: 'edit', child: Text('Edit')),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceMd),
          Row(
            children: [
              Expanded(
                child: Text(
                  Formatters.money(goal.currentAmount, symbol: symbol),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title.copyWith(color: color),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'of ${Formatters.money(goal.targetAmount, symbol: symbol)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BudgetProgressBar(progress: goal.progress, color: color, height: 10),
          const SizedBox(height: 12),
          Row(
            children: [
              ..._milestones(goal, palette),
              const Spacer(),
              Text(
                '${goal.percent}%',
                style: AppTextStyles.subtitle.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _milestones(SavingGoalModel goal, AppPalette palette) {
    return [25, 50, 75, 100].map((int m) {
      final bool reached = goal.percent >= m;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: reached
                ? Color(goal.colorValue).withValues(alpha: 0.16)
                : palette.surfaceMuted,
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reached)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(Icons.check_rounded,
                      size: 11, color: Color(goal.colorValue)),
                ),
              Text(
                '$m%',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: reached
                      ? Color(goal.colorValue)
                      : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete goal?',
      message: 'Your saved progress will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final String? error =
        await ref.read(financeProvider.notifier).deleteGoal(goal.id);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.success(context, 'Goal deleted.');
    }
  }
}

Future<void> _showAddFundsSheet(
  BuildContext context,
  WidgetRef ref,
  SavingGoalModel goal,
) {
  return AppDialog.sheet<void>(
    context,
    child: _AddFundsSheet(goal: goal),
  );
}

class _AddFundsSheet extends ConsumerStatefulWidget {
  const _AddFundsSheet({required this.goal});

  final SavingGoalModel goal;

  @override
  ConsumerState<_AddFundsSheet> createState() => _AddFundsSheetState();
}

class _AddFundsSheetState extends ConsumerState<_AddFundsSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final double value = double.parse(_amount.text.trim());
    final bool wasComplete = widget.goal.completed;
    final String symbol = ref.read(currencySymbolProvider);

    final String? error = await ref
        .read(financeProvider.notifier)
        .addToGoal(widget.goal.id, value);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }

    Navigator.of(context).pop();

    final bool nowComplete = ref
            .read(financeProvider)
            .valueOrNull
            ?.goals
            .firstWhere(
              (g) => g.id == widget.goal.id,
              orElse: () => widget.goal,
            )
            .completed ??
        false;

    if (!wasComplete && nowComplete) {
      await showSuccessOverlay(
        context,
        title: 'Goal completed! 🎉',
        message: 'You reached ${widget.goal.title}. Incredible discipline.',
        buttonLabel: 'Celebrate',
      );
    } else {
      AppSnackbar.success(
        context,
        '${Formatters.money(value, symbol: symbol)} added to '
        '${widget.goal.title}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String symbol = ref.watch(currencySymbolProvider);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: 'Add to ${widget.goal.title}',
              subtitle:
                  '${Formatters.money(widget.goal.remaining, symbol: symbol)} to go',
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Row(
              children: [250, 500, 1000, 2000]
                  .map(
                    (int amount) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: OutlinedButton(
                          onPressed: () {
                            final double current =
                                double.tryParse(_amount.text) ?? 0;
                            _amount.text = (current + amount).toStringAsFixed(0);
                            setState(() {});
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text('+$amount',
                              style: AppTextStyles.caption
                                  .copyWith(color: palette.textPrimary)),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            AppTextField(
              label: 'Amount to add',
              hint: 'e.g. 1000',
              controller: _amount,
              icon: Icons.savings_outlined,
              prefixText: '$symbol ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
            ),
            const SizedBox(height: AppConstants.spaceLg),
            PrimaryButton(
              label: 'Add Funds',
              icon: Icons.add_rounded,
              isLoading: _saving,
              onPressed: _submit,
              gradient: AppColors.successGradient,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showGoalSheet(
  BuildContext context,
  WidgetRef ref,
  SavingGoalModel? existing,
) {
  return AppDialog.sheet<void>(
    context,
    child: _GoalSheet(existing: existing),
  );
}

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet({this.existing});

  final SavingGoalModel? existing;

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  static const List<String> _emojis = [
    '💻', '🏔️', '🛟', '📱', '🎧', '🚲', '📚', '🎮', '✈️', '🎯',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _target = TextEditingController(
    text: widget.existing == null
        ? ''
        : widget.existing!.targetAmount.toStringAsFixed(0),
  );
  late final TextEditingController _current = TextEditingController(
    text: widget.existing == null
        ? '0'
        : widget.existing!.currentAmount.toStringAsFixed(0),
  );
  late final TextEditingController _monthly = TextEditingController(
    text: (widget.existing?.monthlyContribution ?? 0) > 0
        ? widget.existing!.monthlyContribution.toStringAsFixed(0)
        : '',
  );
  late String _emoji = widget.existing?.emoji ?? '🎯';
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _deadline = widget.existing?.deadline;
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _current.dispose();
    _monthly.dispose();
    super.dispose();
  }

  
  String? _etaPreview() {
    final double target = double.tryParse(_target.text.trim()) ?? 0;
    final double current = double.tryParse(_current.text.trim()) ?? 0;
    final double monthly = double.tryParse(_monthly.text.trim()) ?? 0;
    if (target <= 0 || monthly <= 0) return null;
    final double remaining = (target - current).clamp(0, double.infinity);
    if (remaining <= 0) return 'You have already reached this goal. 🎉';
    final int months = (remaining / monthly).ceil();
    final DateTime now = DateTime.now();
    final DateTime eta = DateTime(now.year, now.month + months, now.day);
    return 'Estimated completion: $months '
        '${months == 1 ? 'month' : 'months'} (by ${Formatters.date(eta)}).';
  }

  Future<void> _pickDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final String userId = ref.read(currentUserIdProvider);
    final double target = double.parse(_target.text.trim());
    final double current = double.tryParse(_current.text.trim()) ?? 0;
    final double monthly = double.tryParse(_monthly.text.trim()) ?? 0;

    final SavingGoalModel goal = widget.existing == null
        ? SavingGoalModel(
            id: '',
            userId: userId,
            title: _title.text.trim(),
            targetAmount: target,
            currentAmount: current,
            monthlyContribution: monthly,
            deadline: _deadline,
            emoji: _emoji,
            completed: current >= target,
          )
        : widget.existing!.copyWith(
            title: _title.text.trim(),
            targetAmount: target,
            currentAmount: current,
            monthlyContribution: monthly,
            deadline: _deadline,
            emoji: _emoji,
            completed: current >= target,
          );

    final String? error =
        await ref.read(financeProvider.notifier).saveGoal(goal);
    if (!mounted) return;

    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.success(context, 'Goal saved.');
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String symbol = ref.watch(currencySymbolProvider);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: widget.existing == null ? 'New saving goal' : 'Edit goal',
            ),
            const SizedBox(height: AppConstants.spaceLg),
            AppTextField(
              label: 'Goal name',
              hint: 'e.g. New Laptop',
              controller: _title,
              icon: Icons.flag_outlined,
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.notEmpty(v, 'Goal name'),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            Text('Icon',
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
              label: 'Target amount',
              hint: 'e.g. 100000',
              controller: _target,
              icon: Icons.flag_circle_outlined,
              prefixText: '$symbol ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            AppTextField(
              label: 'Already saved',
              hint: '0',
              controller: _current,
              icon: Icons.savings_outlined,
              prefixText: '$symbol ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            AppTextField(
              label: 'Monthly contribution (optional)',
              hint: 'e.g. 5000',
              controller: _monthly,
              icon: Icons.event_repeat_rounded,
              prefixText: '$symbol ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            if (_etaPreview() != null) ...[
              const SizedBox(height: AppConstants.spaceSm),
              Row(
                children: [
                  const Icon(Icons.auto_graph_rounded,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _etaPreview()!,
                      style: AppTextStyles.caption
                          .copyWith(color: palette.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppConstants.spaceMd),
            AppCard(
              onTap: _pickDeadline,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceMd,
                vertical: 14,
              ),
              radius: AppConstants.radiusMd,
              child: Row(
                children: [
                  const Icon(Icons.event_rounded,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _deadline == null
                          ? 'Set a deadline (optional)'
                          : Formatters.date(_deadline!),
                      style: AppTextStyles.body
                          .copyWith(color: palette.textPrimary),
                    ),
                  ),
                  if (_deadline != null)
                    GestureDetector(
                      onTap: () => setState(() => _deadline = null),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: palette.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            PrimaryButton(
              label: 'Save Goal',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
