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
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/income_model.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinanceState> finance = ref.watch(financeProvider);
    final String symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Income')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addIncome),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Income'),
      ),
      body: finance.when(
        loading: () => const LoadingView(label: 'Loading income…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(financeProvider.notifier).load(),
        ),
        data: (FinanceState data) {
          final List<IncomeModel> incomes = [...data.incomes]
            ..sort((a, b) => b.date.compareTo(a.date));
          final double monthTotal = data.snapshot.monthIncome;
          final Map<IncomeCategory, double> bySource = {};
          for (final IncomeModel i in data.monthIncomes) {
            bySource.update(i.category, (v) => v + i.amount,
                ifAbsent: () => i.amount);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceMd,
              AppConstants.spaceSm,
              AppConstants.spaceMd,
              AppConstants.spaceXxl * 2,
            ),
            children: [
              AppCard(
                gradient: AppColors.successGradient,
                padding: const EdgeInsets.all(AppConstants.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income this month',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.money(monthTotal, symbol: symbol),
                      style: AppTextStyles.display.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.monthIncomes.length} entries logged',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              if (bySource.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spaceLg),
                const SectionHeader(
                  title: 'By source',
                  subtitle: 'Where your money comes from',
                ),
                AppCard(
                  child: Column(
                    children: bySource.entries
                        .map(
                          (MapEntry<IncomeCategory, double> e) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppConstants.spaceMd),
                            child: Row(
                              children: [
                                CategoryAvatar(
                                  incomeCategory: e.key,
                                  size: 40,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(e.key.label,
                                          style: AppTextStyles.subtitle.copyWith(
                                            color: context.palette.textPrimary,
                                          )),
                                      const SizedBox(height: 6),
                                      BudgetProgressBar(
                                        progress: monthTotal <= 0
                                            ? 0
                                            : e.value / monthTotal,
                                        color: e.key.color,
                                        height: 7,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  Formatters.money(e.value, symbol: symbol),
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: context.palette.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],

              const SizedBox(height: AppConstants.spaceLg),
              const SectionHeader(title: 'History'),
              if (incomes.isEmpty)
                const AppCard(
                  child: EmptyState(
                    compact: true,
                    emoji: '💼',
                    title: 'No income logged',
                    message: 'Add your allowance, job or scholarship income.',
                  ),
                )
              else
                ...incomes.asMap().entries.map(
                      (MapEntry<int, IncomeModel> e) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppConstants.spaceSm),
                        child: _IncomeTile(
                          income: e.value,
                          symbol: symbol,
                        ).staggerIn(e.key),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _IncomeTile extends ConsumerWidget {
  const _IncomeTile({required this.income, required this.symbol});

  final IncomeModel income;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceMd,
        vertical: AppConstants.spaceSm,
      ),
      radius: AppConstants.radiusMd,
      child: Row(
        children: [
          CategoryAvatar(incomeCategory: income.category, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income.description.isEmpty
                      ? income.category.label
                      : income.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle
                      .copyWith(color: palette.textPrimary),
                ),
                Text(
                  '${income.category.label} • ${Formatters.relativeDate(income.date)}',
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '+${Formatters.money(income.amount, symbol: symbol)}',
            style: AppTextStyles.subtitle.copyWith(color: AppColors.success),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: palette.textSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            onSelected: (String value) {
              if (value == 'edit') {
                _showEditSheet(context, ref);
              } else {
                _delete(context, ref);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete income?',
      message: 'This entry will be removed permanently.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final String? error =
        await ref.read(financeProvider.notifier).deleteIncome(income.id);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.success(context, 'Income deleted.');
    }
  }

  Future<void> _showEditSheet(BuildContext context, WidgetRef ref) async {
    await AppDialog.sheet<void>(
      context,
      child: _EditIncomeSheet(income: income),
    );
  }
}

class _EditIncomeSheet extends ConsumerStatefulWidget {
  const _EditIncomeSheet({required this.income});

  final IncomeModel income;

  @override
  ConsumerState<_EditIncomeSheet> createState() => _EditIncomeSheetState();
}

class _EditIncomeSheetState extends ConsumerState<_EditIncomeSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount =
      TextEditingController(text: widget.income.amount.toStringAsFixed(0));
  late final TextEditingController _description =
      TextEditingController(text: widget.income.description);
  late IncomeCategory _category = widget.income.category;
  late final DateTime _date = widget.income.date;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final IncomeModel updated = widget.income.copyWith(
      amount: double.parse(_amount.text.trim()),
      category: _category,
      description: _description.text.trim(),
      date: _date,
    );

    final String? error =
        await ref.read(financeProvider.notifier).updateIncome(updated);

    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.success(context, 'Income updated.');
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
            const SheetHeader(title: 'Edit income'),
            const SizedBox(height: AppConstants.spaceLg),
            AppTextField(
              label: 'Amount',
              controller: _amount,
              icon: Icons.payments_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
            ),
            const SizedBox(height: AppConstants.spaceMd),
            Text('Source',
                style: AppTextStyles.subtitle
                    .copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppConstants.spaceSm),
            Wrap(
              spacing: AppConstants.spaceSm,
              runSpacing: AppConstants.spaceSm,
              children: IncomeCategory.values
                  .map(
                    (IncomeCategory c) => AppChip(
                      label: c.label,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                      icon: c.icon,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            AppTextField(
              label: 'Description',
              controller: _description,
              icon: Icons.notes_rounded,
            ),
            const SizedBox(height: AppConstants.spaceLg),
            PrimaryButton(
              label: 'Save Changes',
              isLoading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
