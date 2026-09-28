import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../core/widgets/transaction_tile.dart';
import '../../../models/financial_snapshot.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/repository.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<FinanceState> finance = ref.watch(financeProvider);
    final String symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            tooltip: 'Transaction history',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push(AppRoutes.transactions),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addExpense),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: finance.when(
        loading: () => const LoadingView(label: 'Loading expenses…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(financeProvider.notifier).load(),
        ),
        data: (FinanceState data) => _body(context, data, symbol),
      ),
    );
  }

  Widget _body(BuildContext context, FinanceState data, String symbol) {
    final AppPalette palette = context.palette;
    final FinancialSnapshot snapshot = data.snapshot;

    
    final TransactionFilter filter = data.filter.copyWith(type: TransactionType.expense);
    final List<TransactionModel> filtered =
        filter.apply(data.transactions);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spaceMd,
            AppConstants.spaceSm,
            AppConstants.spaceMd,
            AppConstants.spaceXxl,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: "Today's spending",
                      value: Formatters.money(snapshot.todayExpense, symbol: symbol),
                      icon: Icons.today_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceMd),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Last 7 days',
                      value: Formatters.money(snapshot.weekExpense, symbol: symbol),
                      icon: Icons.date_range_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceMd),

              
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This month',
                            style: AppTextStyles.caption
                                .copyWith(color: palette.textSecondary),
                          ),
                          Text(
                            Formatters.money(snapshot.monthExpense, symbol: symbol),
                            style: AppTextStyles.title
                                .copyWith(color: palette.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: palette.divider,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppConstants.spaceMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last month',
                              style: AppTextStyles.caption
                                  .copyWith(color: palette.textSecondary),
                            ),
                            Text(
                              Formatters.money(snapshot.prevMonthExpense,
                                  symbol: symbol),
                              style: AppTextStyles.title
                                  .copyWith(color: palette.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _DeltaPill(
                      current: snapshot.monthExpense,
                      previous: snapshot.prevMonthExpense,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spaceLg),

              
              if (snapshot.topCategories.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Where it goes',
                  subtitle: 'This month by category',
                ),
                AppCard(
                  child: Column(
                    children: snapshot.topCategories
                        .take(5)
                        .map(
                          (MapEntry<ExpenseCategory, double> entry) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppConstants.spaceMd,
                            ),
                            child: _CategoryRow(
                              category: entry.key,
                              amount: entry.value,
                              total: snapshot.monthExpense,
                              symbol: symbol,
                              budget: _budgetFor(data, entry.key),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceLg),
              ],

              
              const SectionHeader(title: 'All Expenses'),
              TextField(
                controller: _search,
                onChanged: (v) => ref
                    .read(financeProvider.notifier)
                    .updateFilter(data.filter.copyWith(query: v)),
                decoration: InputDecoration(
                  hintText: 'Search expenses…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: data.filter.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _search.clear();
                            ref
                                .read(financeProvider.notifier)
                                .updateFilter(
                                  data.filter.copyWith(query: ''),
                                );
                          },
                        ),
                ),
              ),
              const SizedBox(height: AppConstants.spaceMd),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: data.filter.categories.isEmpty,
                      onTap: () => ref
                          .read(financeProvider.notifier)
                          .updateFilter(data.filter.copyWith(categories: {})),
                    ),
                    ...ExpenseCategory.values.map(
                      (ExpenseCategory c) => _CategoryChip(
                        label: c.label,
                        emoji: null,
                        icon: c.icon,
                        selected: data.filter.categories.contains(c.name),
                        onTap: () {
                          final Set<String> next =
                              {...data.filter.categories};
                          if (!next.remove(c.name)) next.add(c.name);
                          ref
                              .read(financeProvider.notifier)
                              .updateFilter(
                                data.filter.copyWith(categories: next),
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceMd),
              Row(
                children: [
                  Text(
                    '${filtered.length} ${filtered.length == 1 ? 'entry' : 'entries'}',
                    style: AppTextStyles.caption
                        .copyWith(color: palette.textSecondary),
                  ),
                  const Spacer(),
                  _SortButton(
                    sort: data.filter.sort,
                    onChanged: (TransactionSort sort) => ref
                        .read(financeProvider.notifier)
                        .updateFilter(data.filter.copyWith(sort: sort)),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceSm),
            ]),
          ),
        ),
        if (filtered.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(AppConstants.spaceLg),
              child: EmptyState(
                emoji: '🔍',
                title: 'No expenses found',
                message: 'Try clearing the filters or add a new expense.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (BuildContext context, int i) {
                final TransactionModel tx = filtered[i];
                return AppCard(
                  margin: const EdgeInsets.only(bottom: AppConstants.spaceSm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceMd,
                    vertical: 4,
                  ),
                  radius: AppConstants.radiusMd,
                  child: TransactionTile(
                    transaction: tx,
                    symbol: symbol,
                    onTap: () =>
                        context.push(AppRoutes.expenseDetailPath(tx.id)),
                  ),
                ).staggerIn(i);
              },
            ),
          ),
      ],
    );
  }

  double? _budgetFor(FinanceState data, ExpenseCategory category) {
    for (final budget in data.budgets) {
      if (budget.category == category.name) return budget.limit;
    }
    return null;
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.emoji,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.spaceSm),
      child: AppChip(
        label: label,
        selected: selected,
        onTap: onTap,
        icon: icon,
        emoji: emoji,
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onChanged});

  final TransactionSort sort;
  final ValueChanged<TransactionSort> onChanged;

  static const Map<TransactionSort, String> _labels = {
    TransactionSort.newest: 'Newest first',
    TransactionSort.oldest: 'Oldest first',
    TransactionSort.highest: 'Highest amount',
    TransactionSort.lowest: 'Lowest amount',
  };

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return PopupMenuButton<TransactionSort>(
      initialValue: sort,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      itemBuilder: (_) => _labels.entries
          .map(
            (MapEntry<TransactionSort, String> e) => PopupMenuItem<TransactionSort>(
              value: e.key,
              child: Text(e.value, style: AppTextStyles.body),
            ),
          )
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_vert_rounded, size: 18, color: palette.textSecondary),
          const SizedBox(width: 4),
          Text(
            _labels[sort]!,
            style: AppTextStyles.caption.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      radius: AppConstants.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.title.copyWith(color: palette.textPrimary),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.current, required this.previous});

  final double current;
  final double previous;

  @override
  Widget build(BuildContext context) {
    if (previous <= 0) return const SizedBox.shrink();
    final double change = (current - previous) / previous;
    final bool up = change >= 0;
    final Color color = up ? AppColors.danger : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${(change.abs() * 100).toStringAsFixed(0)}%',
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.symbol,
    this.budget,
  });

  final ExpenseCategory category;
  final double amount;
  final double total;
  final String symbol;
  final double? budget;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double share = total <= 0 ? 0 : amount / total;

    return Row(
      children: [
        CategoryAvatar(expenseCategory: category, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.label,
                      style: AppTextStyles.subtitle
                          .copyWith(color: palette.textPrimary),
                    ),
                  ),
                  Text(
                    Formatters.money(amount, symbol: symbol),
                    style: AppTextStyles.subtitle
                        .copyWith(color: palette.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              BudgetProgressBar(
                progress: budget != null && budget! > 0
                    ? amount / budget!
                    : share,
                color: category.color,
                height: 7,
              ),
              const SizedBox(height: 3),
              Text(
                budget != null
                    ? '${Formatters.percent(amount / budget!)} of ${Formatters.money(budget!, symbol: symbol)} budget'
                    : '${Formatters.percent(share)} of spending',
                style: AppTextStyles.caption
                    .copyWith(color: palette.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
