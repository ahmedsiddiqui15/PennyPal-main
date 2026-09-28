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
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/subscription_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinanceState> finance = ref.watch(financeProvider);
    final String symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSheet(context, ref, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: finance.when(
        loading: () => const LoadingView(label: 'Loading subscriptions…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(financeProvider.notifier).load(),
        ),
        data: (FinanceState data) {
          final List<SubscriptionModel> active =
              data.subscriptions.where((s) => s.active).toList()
                ..sort((a, b) => a.daysUntilBilling.compareTo(b.daysUntilBilling));
          final List<SubscriptionModel> paused =
              data.subscriptions.where((s) => !s.active).toList();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly subscription cost',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.money(data.monthlySubscriptionCost,
                          symbol: symbol),
                      style: AppTextStyles.display.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatters.money(data.monthlySubscriptionCost * 12, symbol: symbol)} '
                      'per year',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spaceLg),
              const SectionHeader(
                title: 'Active',
                subtitle: 'Sorted by next billing date',
              ),
              if (active.isEmpty)
                const AppCard(
                  child: EmptyState(
                    compact: true,
                    emoji: '💳',
                    title: 'No active subscriptions',
                    message: 'Add Netflix, Spotify or ChatGPT Plus to track them.',
                  ),
                )
              else
                ...active.asMap().entries.map(
                      (MapEntry<int, SubscriptionModel> e) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppConstants.spaceSm),
                        child: _SubscriptionTile(
                          subscription: e.value,
                          symbol: symbol,
                        ).staggerIn(e.key),
                      ),
                    ),

              if (paused.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spaceLg),
                const SectionHeader(title: 'Paused'),
                ...paused.map(
                  (SubscriptionModel s) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppConstants.spaceSm),
                    child: _SubscriptionTile(
                      subscription: s,
                      symbol: symbol,
                    ),
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

class _SubscriptionTile extends ConsumerWidget {
  const _SubscriptionTile({required this.subscription, required this.symbol});

  final SubscriptionModel subscription;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final Color color = Color(subscription.colorValue);

    return AppCard(
      onTap: () => _showSheet(context, ref, subscription),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      radius: AppConstants.radiusMd,
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(subscription.emoji,
                style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.name,
                  style: AppTextStyles.subtitle.copyWith(
                    color: subscription.active
                        ? palette.textPrimary
                        : palette.textSecondary,
                  ),
                ),
                Text(
                  subscription.active
                      ? 'Next in ${subscription.daysUntilBilling} days • '
                          '${subscription.cycle.label}'
                      : 'Paused',
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.money(subscription.amount, symbol: symbol),
                style: AppTextStyles.subtitle.copyWith(
                  color: subscription.active
                      ? palette.textPrimary
                      : palette.textSecondary,
                ),
              ),
              Text(
                '${Formatters.money(subscription.monthlyCost, symbol: symbol)}/mo',
                style: AppTextStyles.caption.copyWith(
                  color: palette.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Switch(
            value: subscription.active,
            onChanged: (_) => ref
                .read(financeProvider.notifier)
                .toggleSubscription(subscription),
          ),
        ],
      ),
    );
  }
}

Future<void> _showSheet(
  BuildContext context,
  WidgetRef ref,
  SubscriptionModel? existing,
) {
  return AppDialog.sheet<void>(
    context,
    child: _SubscriptionSheet(existing: existing),
  );
}

class _SubscriptionSheet extends ConsumerStatefulWidget {
  const _SubscriptionSheet({this.existing});

  final SubscriptionModel? existing;

  @override
  ConsumerState<_SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends ConsumerState<_SubscriptionSheet> {
  static const List<({String name, String emoji, int color})> _presets = [
    (name: 'Netflix', emoji: '🎬', color: 0xFFEF4444),
    (name: 'Spotify', emoji: '🎧', color: 0xFF16A34A),
    (name: 'YouTube Premium', emoji: '▶️', color: 0xFFDC2626),
    (name: 'ChatGPT Plus', emoji: '🤖', color: 0xFF10A37F),
    (name: 'iCloud+', emoji: '☁️', color: 0xFF3B82F6),
    (name: 'Adobe CC', emoji: '🎨', color: 0xFF8B5CF6),
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : widget.existing!.amount.toStringAsFixed(0),
  );
  late BillingCycle _cycle = widget.existing?.cycle ?? BillingCycle.monthly;
  late String _emoji = widget.existing?.emoji ?? '🎬';
  late int _color = widget.existing?.colorValue ?? 0xFFEF4444;
  late DateTime _billingDate =
      widget.existing?.billingDate ?? DateTime.now();

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _billingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 400)),
    );
    if (picked != null) setState(() => _billingDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final String userId = ref.read(currentUserIdProvider);
    final SubscriptionModel subscription = widget.existing == null
        ? SubscriptionModel(
            id: '',
            userId: userId,
            name: _name.text.trim(),
            amount: double.parse(_amount.text.trim()),
            billingDate: _billingDate,
            cycle: _cycle,
            emoji: _emoji,
            colorValue: _color,
          )
        : widget.existing!.copyWith(
            name: _name.text.trim(),
            amount: double.parse(_amount.text.trim()),
            billingDate: _billingDate,
            cycle: _cycle,
            emoji: _emoji,
            colorValue: _color,
          );

    final String? error =
        await ref.read(financeProvider.notifier).saveSubscription(subscription);
    if (!mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.success(context, 'Subscription saved.');
  }

  Future<void> _delete() async {
    final SubscriptionModel? existing = widget.existing;
    if (existing == null) return;

    final bool confirmed = await AppDialog.confirm(
      context,
      title: 'Delete subscription?',
      message: '${existing.name} will be removed from your tracker.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final String? error = await ref
        .read(financeProvider.notifier)
        .deleteSubscription(existing.id);
    if (!mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.success(context, 'Subscription deleted.');
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
              title: widget.existing == null
                  ? 'Add subscription'
                  : 'Edit subscription',
              trailing: widget.existing == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.danger),
                      onPressed: _delete,
                    ),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            Text('Quick add',
                style: AppTextStyles.caption.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppConstants.spaceSm),
            Wrap(
              spacing: AppConstants.spaceSm,
              runSpacing: AppConstants.spaceSm,
              children: _presets
                  .map(
                    (({String name, String emoji, int color}) p) => AppChip(
                      label: p.name,
                      emoji: p.emoji,
                      selected: _name.text == p.name,
                      onTap: () => setState(() {
                        _name.text = p.name;
                        _emoji = p.emoji;
                        _color = p.color;
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            AppTextField(
              label: 'Service name',
              hint: 'e.g. Netflix',
              controller: _name,
              icon: Icons.subscriptions_outlined,
              validator: (v) => Validators.notEmpty(v, 'Name'),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            AppTextField(
              label: 'Amount',
              hint: 'e.g. 1100',
              controller: _amount,
              icon: Icons.payments_outlined,
              prefixText: '$symbol ',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
            ),
            const SizedBox(height: AppConstants.spaceMd),
            Text('Billing cycle',
                style: AppTextStyles.subtitle
                    .copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppConstants.spaceSm),
            Wrap(
              spacing: AppConstants.spaceSm,
              children: BillingCycle.values
                  .map(
                    (BillingCycle c) => AppChip(
                      label: c.label,
                      selected: _cycle == c,
                      onTap: () => setState(() => _cycle = c),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            AppCard(
              onTap: _pickDate,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceMd,
                vertical: 14,
              ),
              radius: AppConstants.radiusMd,
              child: Row(
                children: [
                  const Icon(Icons.event_repeat_rounded,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Next billing: ${Formatters.date(_billingDate)}',
                      style: AppTextStyles.body
                          .copyWith(color: palette.textPrimary),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: palette.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            PrimaryButton(
              label: 'Save Subscription',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
