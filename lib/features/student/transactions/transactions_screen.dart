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
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../core/widgets/transaction_tile.dart';
import '../../../models/transaction_model.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/repository.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
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
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Clear filters',
            icon: const Icon(Icons.filter_alt_off_outlined),
            onPressed: () {
              _search.clear();
              ref.read(financeProvider.notifier).clearFilter();
            },
          ),
        ],
      ),
      body: finance.when(
        loading: () => const LoadingView(label: 'Loading transactions…'),
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
    final TransactionFilter filter = data.filter;
    final List<TransactionModel> results = filter.apply(data.transactions);

    final double income = results
        .where((t) => t.isIncome)
        .fold(0, (s, t) => s + t.amount);
    final double expense = results
        .where((t) => t.isExpense)
        .fold(0, (s, t) => s + t.amount);

    
    final Map<String, List<TransactionModel>> grouped = {};
    for (final TransactionModel tx in results) {
      final String key = Formatters.date(
        DateTime(tx.date.year, tx.date.month, tx.date.day),
      );
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceMd,
        AppConstants.spaceSm,
        AppConstants.spaceMd,
        AppConstants.spaceXxl,
      ),
      children: [
        TextField(
          controller: _search,
          onChanged: (String v) => ref
              .read(financeProvider.notifier)
              .updateFilter(filter.copyWith(query: v)),
          decoration: InputDecoration(
            hintText: 'Search by description or category…',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: filter.query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _search.clear();
                      ref
                          .read(financeProvider.notifier)
                          .updateFilter(filter.copyWith(query: ''));
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
              _chip(
                'All types',
                filter.type == null,
                () => ref.read(financeProvider.notifier).updateFilter(
                      filter.copyWith(clearType: true),
                    ),
              ),
              _chip(
                'Income',
                filter.type == TransactionType.income,
                () => ref.read(financeProvider.notifier).updateFilter(
                      filter.copyWith(type: TransactionType.income),
                    ),
                icon: Icons.south_west_rounded,
              ),
              _chip(
                'Expenses',
                filter.type == TransactionType.expense,
                () => ref.read(financeProvider.notifier).updateFilter(
                      filter.copyWith(type: TransactionType.expense),
                    ),
                icon: Icons.north_east_rounded,
              ),
              _chip(
                'This month',
                filter.from != null &&
                    filter.from!.month == DateTime.now().month,
                () {
                  final DateTime now = DateTime.now();
                  ref.read(financeProvider.notifier).updateFilter(
                        filter.copyWith(
                          from: DateTime(now.year, now.month, 1),
                          to: now,
                        ),
                      );
                },
              ),
              _chip(
                'Last 30 days',
                false,
                () {
                  final DateTime now = DateTime.now();
                  ref.read(financeProvider.notifier).updateFilter(
                        filter.copyWith(
                          from: now.subtract(const Duration(days: 30)),
                          to: now,
                        ),
                      );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spaceSm),

        
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip(
                'All categories',
                filter.categories.isEmpty,
                () => ref.read(financeProvider.notifier).updateFilter(
                      filter.copyWith(categories: <String>{}),
                    ),
              ),
              ...ExpenseCategory.values.map(
                (ExpenseCategory c) => _chip(
                  c.label,
                  filter.categories.contains(c.name),
                  () {
                    final Set<String> next = {...filter.categories};
                    if (!next.remove(c.name)) next.add(c.name);
                    ref.read(financeProvider.notifier).updateFilter(
                          filter.copyWith(categories: next),
                        );
                  },
                  icon: c.icon,
                ),
              ),
              ...IncomeCategory.values.map(
                (IncomeCategory c) => _chip(
                  c.label,
                  filter.categories.contains(c.name),
                  () {
                    final Set<String> next = {...filter.categories};
                    if (!next.remove(c.name)) next.add(c.name);
                    ref.read(financeProvider.notifier).updateFilter(
                          filter.copyWith(categories: next),
                        );
                  },
                  icon: c.icon,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spaceMd),

        
        AppCard(
          padding: const EdgeInsets.all(AppConstants.spaceMd),
          radius: AppConstants.radiusMd,
          child: Row(
            children: [
              Expanded(
                child: _SummaryColumn(
                  label: 'Income',
                  value: Formatters.money(income, symbol: symbol),
                  color: AppColors.success,
                ),
              ),
              Container(height: 36, width: 1, color: palette.divider),
              Expanded(
                child: _SummaryColumn(
                  label: 'Expenses',
                  value: Formatters.money(expense, symbol: symbol),
                  color: AppColors.danger,
                ),
              ),
              Container(height: 36, width: 1, color: palette.divider),
              Expanded(
                child: _SummaryColumn(
                  label: 'Net',
                  value: Formatters.money(income - expense, symbol: symbol),
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spaceMd),

        Row(
          children: [
            Text('${results.length} results',
                style: AppTextStyles.caption
                    .copyWith(color: palette.textSecondary)),
            const Spacer(),
            PopupMenuButton<TransactionSort>(
              initialValue: filter.sort,
              onSelected: (TransactionSort s) => ref
                  .read(financeProvider.notifier)
                  .updateFilter(filter.copyWith(sort: s)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: TransactionSort.newest, child: Text('Newest first')),
                PopupMenuItem(value: TransactionSort.oldest, child: Text('Oldest first')),
                PopupMenuItem(value: TransactionSort.highest, child: Text('Highest amount')),
                PopupMenuItem(value: TransactionSort.lowest, child: Text('Lowest amount')),
              ],
              child: Row(
                children: [
                  Icon(Icons.swap_vert_rounded,
                      size: 18, color: palette.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _sortLabel(filter.sort),
                    style: AppTextStyles.caption
                        .copyWith(color: palette.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spaceSm),

        if (results.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppConstants.spaceXl),
            child: EmptyState(
              emoji: '🔎',
              title: 'Nothing matches',
              message: 'Try a different search, date range or category.',
            ),
          )
        else
          ...grouped.entries.toList().asMap().entries.expand(
                (MapEntry<int, MapEntry<String, List<TransactionModel>>> day) {
                  final List<TransactionModel> dayItems = day.value.value;
                  final double dayTotal = dayItems.fold(
                    0,
                    (s, t) => s + t.signedAmount,
                  );
                  return [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppConstants.spaceMd,
                        bottom: AppConstants.spaceSm,
                      ),
                      child: Row(
                        children: [
                          Text(
                            day.value.key,
                            style: AppTextStyles.caption.copyWith(
                              color: palette.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            Formatters.money(dayTotal, symbol: symbol),
                            style: AppTextStyles.caption.copyWith(
                              color: dayTotal >= 0
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppCard(
                      margin: const EdgeInsets.only(bottom: AppConstants.spaceSm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spaceMd,
                        vertical: AppConstants.spaceSm,
                      ),
                      radius: AppConstants.radiusMd,
                      child: Column(
                        children: dayItems
                            .asMap()
                            .entries
                            .map(
                              (MapEntry<int, TransactionModel> e) => Column(
                                children: [
                                  TransactionTile(
                                    transaction: e.value,
                                    symbol: symbol,
                                    showDate: false,
                                    onTap: () => e.value.isExpense
                                        ? context.push(
                                            AppRoutes.expenseDetailPath(e.value.id),
                                          )
                                        : null,
                                  ),
                                  if (e.key != dayItems.length - 1)
                                    Divider(
                                      height: 1,
                                      color: palette.divider,
                                    ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ).staggerIn(day.key),
                  ];
                },
              ),
      ],
    );
  }

  Widget _chip(
    String label,
    bool selected,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppConstants.spaceSm),
      child: AppChip(
        label: label,
        selected: selected,
        onTap: onTap,
        icon: icon,
      ),
    );
  }

  String _sortLabel(TransactionSort sort) => switch (sort) {
        TransactionSort.newest => 'Newest first',
        TransactionSort.oldest => 'Oldest first',
        TransactionSort.highest => 'Highest amount',
        TransactionSort.lowest => 'Lowest amount',
      };
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: context.palette.textSecondary)),
        const SizedBox(height: 2),
        FittedBox(
          child: Text(value,
              style: AppTextStyles.subtitle.copyWith(color: color)),
        ),
      ],
    );
  }
}
