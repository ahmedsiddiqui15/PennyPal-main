import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/budget_model.dart';
import '../../../models/financial_snapshot.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinanceState> finance = ref.watch(financeProvider);
    final String symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            tooltip: 'Reports',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => context.push(AppRoutes.reports),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetSheet(context, ref, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Limit'),
      ),
      body: finance.when(
        loading: () => const LoadingView(label: 'Loading budget…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(financeProvider.notifier).load(),
        ),
        data: (FinanceState data) => _body(context, ref, data, symbol),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    FinanceState data,
    String symbol,
  ) {
    final AppPalette palette = context.palette;
    final FinancialSnapshot snapshot = data.snapshot;
    final BudgetModel? master = data.budgets.where((b) => b.isMaster).isEmpty
        ? null
        : data.budgets.firstWhere((b) => b.isMaster);
    final List<BudgetModel> categories =
        data.budgets.where((b) => !b.isMaster).toList();

    
    final List<BudgetModel> overspent = categories.where((b) {
      final double spent = snapshot.monthByCategory[b.category] ?? 0;
      return spent > b.limit;
    }).toList();

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
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.monthYear(DateTime.now()),
                          style: AppTextStyles.caption
                              .copyWith(color: palette.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total Budget',
                          style: AppTextStyles.title
                              .copyWith(color: palette.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        _MiniMetric(
                          label: 'Limit',
                          value: Formatters.money(
                            master?.limit ?? snapshot.totalBudget,
                            symbol: symbol,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _MiniMetric(
                          label: 'Used',
                          value: Formatters.money(snapshot.budgetUsed,
                              symbol: symbol),
                          color: AppColors.danger,
                        ),
                        const SizedBox(height: 6),
                        _MiniMetric(
                          label: 'Remaining',
                          value: Formatters.money(snapshot.budgetRemaining,
                              symbol: symbol),
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                  PercentageRing(
                    progress: snapshot.budgetProgress,
                    size: 116,
                    label: 'Used',
                    color: snapshot.budgetProgress >= 1
                        ? AppColors.danger
                        : snapshot.budgetProgress >= 0.8
                            ? AppColors.warning
                            : AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceMd),
              PrimaryButton(
                label: master == null ? 'Set Overall Budget' : 'Edit Overall Budget',
                icon: Icons.tune_rounded,
                outlined: true,
                onPressed: () => _showBudgetSheet(context, ref, master),
              ),
            ],
          ),
        ),

        if (overspent.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spaceLg),
          AppCard(
            color: AppColors.danger.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overspending alert',
                        style: AppTextStyles.subtitle
                            .copyWith(color: AppColors.danger),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${overspent.map((b) => b.categoryLabel).join(', ')} '
                        '${overspent.length == 1 ? 'is' : 'are'} over budget. '
                        'Consider adjusting your limits.',
                        style: AppTextStyles.caption
                            .copyWith(color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppConstants.spaceLg),
        const SectionHeader(
          title: 'Category Limits',
          subtitle: 'Tap a category to edit',
        ),
        if (categories.isEmpty)
          const AppCard(
            child: EmptyState(
              compact: true,
              emoji: '🎯',
              title: 'No category limits yet',
              message: 'Add a limit per category to control your spending.',
            ),
          )
        else
          ...categories.asMap().entries.map(
                (MapEntry<int, BudgetModel> e) {
                  final ExpenseCategory category =
                      ExpenseCategory.fromKey(e.value.category);
                  final double spent =
                      snapshot.monthByCategory[category.name] ?? 0;
                  final double progress =
                      e.value.limit <= 0 ? 0 : spent / e.value.limit;
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppConstants.spaceSm),
                    child: AppCard(
                      onTap: () => _showBudgetSheet(context, ref, e.value),
                      padding: const EdgeInsets.all(AppConstants.spaceMd),
                      radius: AppConstants.radiusMd,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CategoryAvatar(
                                expenseCategory: category,
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(category.label,
                                        style: AppTextStyles.subtitle.copyWith(
                                          color: palette.textPrimary,
                                        )),
                                    Text(
                                      '${Formatters.money(spent, symbol: symbol)} of '
                                      '${Formatters.money(e.value.limit, symbol: symbol)}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Formatters.percent(progress),
                                style: AppTextStyles.subtitle.copyWith(
                                  color: progress >= 1
                                      ? AppColors.danger
                                      : progress >= 0.8
                                          ? AppColors.warning
                                          : AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded,
                                  color: palette.textSecondary, size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          BudgetProgressBar(progress: progress, height: 8),
                        ],
                      ),
                    ).staggerIn(e.key),
                  );
                },
              ),

        const SizedBox(height: AppConstants.spaceLg),
        AppCard(
          gradient: AppColors.amberGradient,
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Icon(Icons.insights_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicted spending next month',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      Formatters.money(snapshot.predictedNextMonth,
                          symbol: symbol),
                      style: AppTextStyles.title.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(label,
              style:
                  AppTextStyles.caption.copyWith(color: palette.textSecondary)),
        ),
        Text(
          value,
          style: AppTextStyles.subtitle.copyWith(
            color: color ?? palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

Future<void> _showBudgetSheet(
  BuildContext context,
  WidgetRef ref,
  BudgetModel? existing,
) {
  return AppDialog.sheet<void>(
    context,
    child: _BudgetSheet(existing: existing),
  );
}

class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet({this.existing});

  final BudgetModel? existing;

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _limit = TextEditingController(
    text: widget.existing == null
        ? ''
        : widget.existing!.limit.toStringAsFixed(0),
  );

  
  String? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category;
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final DateTime month =
        DateTime(DateTime.now().year, DateTime.now().month, 1);
    final String userId = ref.read(currentUserIdProvider);

    final BudgetModel budget = widget.existing == null
        ? BudgetModel(
            id: '',
            userId: userId,
            limit: double.parse(_limit.text.trim()),
            category: _category,
            month: month,
          )
        : widget.existing!.copyWith(
            limit: double.parse(_limit.text.trim()),
            category: _category,
          );

    final String? error =
        await ref.read(financeProvider.notifier).saveBudget(budget);
    if (!mounted) return;

    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.success(context, 'Budget saved.');
  }

  Future<void> _delete() async {
    final BudgetModel? existing = widget.existing;
    if (existing == null) return;

    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete limit?',
      message: 'This budget limit will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final String? error =
        await ref.read(financeProvider.notifier).deleteBudget(existing.id);
    if (!mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.success(context, 'Budget deleted.');
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
              title: widget.existing == null ? 'Add budget limit' : 'Edit budget',
              subtitle: Formatters.monthYear(DateTime.now()),
              trailing: widget.existing == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.danger),
                      onPressed: _delete,
                    ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Text('Applies to',
                style: AppTextStyles.subtitle
                    .copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppConstants.spaceSm),
            Wrap(
              spacing: AppConstants.spaceSm,
              runSpacing: AppConstants.spaceSm,
              children: [
                AppChip(
                  label: 'Overall',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                ...ExpenseCategory.values.map(
                  (ExpenseCategory c) => AppChip(
                    label: c.label,
                    selected: _category == c.name,
                    onTap: () => setState(() => _category = c.name),
                    icon: c.icon,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceLg),
            AppTextField(
              label: 'Limit amount',
              hint: 'e.g. 9000',
              controller: _limit,
              icon: Icons.payments_outlined,
              prefixText: '$symbol ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
            ),
            const SizedBox(height: AppConstants.spaceLg),
            PrimaryButton(
              label: 'Save Budget',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
