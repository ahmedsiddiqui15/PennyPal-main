import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/expense_model.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _description = TextEditingController();

  ExpenseModel? _expense;
  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final AsyncValue<FinanceState> finance = ref.read(financeProvider);
    FinanceState? data = finance.valueOrNull;
    data ??= await ref.read(financeProvider.notifier).load().then(
          (_) => ref.read(financeProvider).valueOrNull,
        );

    ExpenseModel? found;
    for (final ExpenseModel e in data?.expenses ?? const <ExpenseModel>[]) {
      if (e.id == widget.expenseId) found = e;
    }

    if (!mounted) return;
    setState(() {
      _expense = found;
      _loading = false;
      if (found != null) {
        _amount.text = found.amount.toStringAsFixed(0);
        _description.text = found.description;
        _category = found.category;
        _date = found.date;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ExpenseModel? expense = _expense;
    if (expense == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final ExpenseModel updated = expense.copyWith(
      amount: double.parse(_amount.text.trim()),
      category: _category,
      description: _description.text.trim(),
      date: _date,
    );

    final String? error =
        await ref.read(financeProvider.notifier).updateExpense(updated);

    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    AppSnackbar.success(context, 'Expense updated.');
    context.pop();
  }

  Future<void> _delete() async {
    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete expense?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final String? error =
        await ref.read(financeProvider.notifier).deleteExpense(widget.expenseId);
    if (!mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    AppSnackbar.success(context, 'Expense deleted.');
    context.pop();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String symbol = ref.watch(currencySymbolProvider);

    if (_loading) {
      return const Scaffold(body: LoadingView(label: 'Loading expense…'));
    }

    final ExpenseModel? expense = _expense;
    if (expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense')),
        body: EmptyState(
          emoji: '🕵️',
          title: 'Expense not found',
          message: 'It may have been deleted already.',
          actionLabel: 'Go back',
          onAction: () => context.pop(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger),
            onPressed: _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.spaceMd),
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppConstants.spaceLg),
                gradient: AppColors.amberGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.category.label,
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.money(expense.amount, symbol: symbol),
                      style: AppTextStyles.display.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.date(expense.date)} • ${expense.source.label}',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              AppTextField(
                label: 'Amount',
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                icon: Icons.payments_outlined,
                validator: Validators.amount,
              ),
              const SizedBox(height: AppConstants.spaceMd),
              AppTextField(
                label: 'Description',
                controller: _description,
                icon: Icons.notes_rounded,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppConstants.spaceLg),
              Text('Category',
                  style: AppTextStyles.subtitle
                      .copyWith(color: palette.textPrimary)),
              const SizedBox(height: AppConstants.spaceSm),
              Wrap(
                spacing: AppConstants.spaceSm,
                runSpacing: AppConstants.spaceSm,
                children: ExpenseCategory.values
                    .map(
                      (ExpenseCategory c) => GestureDetector(
                        onTap: () => setState(() => _category = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _category == c
                                ? c.color.withValues(alpha: 0.14)
                                : palette.card,
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusMd),
                            border: Border.all(
                              color: _category == c ? c.color : palette.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(c.icon,
                                  size: 16,
                                  color: _category == c
                                      ? c.color
                                      : palette.textSecondary),
                              const SizedBox(width: 6),
                              Text(c.label,
                                  style: AppTextStyles.caption.copyWith(
                                    color: _category == c
                                        ? c.color
                                        : palette.textPrimary,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              AppCard(
                onTap: _pickDate,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceMd,
                  vertical: 14,
                ),
                radius: AppConstants.radiusMd,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        Formatters.date(_date),
                        style: AppTextStyles.body
                            .copyWith(color: palette.textPrimary),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: palette.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceXl),
              PrimaryButton(
                label: 'Save Changes',
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
