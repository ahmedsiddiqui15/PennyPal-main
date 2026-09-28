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
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_success.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/income_model.dart';
import '../../../models/expense_model.dart' show EntrySource;
import '../../../providers/auth_providers.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _description = TextEditingController();

  IncomeCategory _category = IncomeCategory.allowance;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
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

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final String symbol = ref.read(currencySymbolProvider);
    final double amount = double.parse(_amount.text.trim());

    final IncomeModel income = IncomeModel(
      id: '',
      userId: ref.read(currentUserIdProvider),
      amount: amount,
      category: _category,
      description: _description.text.trim().isEmpty
          ? _category.label
          : _description.text.trim(),
      date: _date,
      source: EntrySource.manual,
    );

    final String? error =
        await ref.read(financeProvider.notifier).addIncome(income);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }

    await showSuccessOverlay(
      context,
      title: 'Income added!',
      message: '${Formatters.money(amount, symbol: symbol)} from '
          '${_category.label}.',
      buttonLabel: 'Nice',
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Income')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.spaceMd),
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppConstants.spaceLg),
                color: AppColors.success.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount',
                        style: AppTextStyles.caption
                            .copyWith(color: palette.textSecondary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amount,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.amount,
                      style: AppTextStyles.display
                          .copyWith(color: palette.textPrimary),
                      cursorColor: AppColors.success,
                      decoration: InputDecoration(
                        prefixText: '$symbol ',
                        prefixStyle: AppTextStyles.display
                            .copyWith(color: AppColors.success),
                        hintText: '0',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceLg),
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
              const SizedBox(height: AppConstants.spaceMd),
              AppTextField(
                label: 'Description',
                hint: 'e.g. Monthly allowance from home',
                controller: _description,
                icon: Icons.notes_rounded,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
              const SizedBox(height: AppConstants.spaceXl),
              PrimaryButton(
                label: 'Save Income',
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _save,
                gradient: AppColors.successGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
