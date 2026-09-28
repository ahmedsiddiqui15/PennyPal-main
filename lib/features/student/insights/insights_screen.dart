import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stagger.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/ai_message_model.dart';
import '../../../models/financial_snapshot.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinanceState> finance = ref.watch(financeProvider);
    final String symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Insights')),
      body: finance.when(
        loading: () => const LoadingView(label: 'Analysing your habits…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(financeProvider.notifier).load(),
        ),
        data: (FinanceState data) {
          final FinancialSnapshot snapshot = data.snapshot;
          final List<InsightModel> insights = ref.watch(insightsProvider);

          return ListView(
            padding: const EdgeInsets.all(AppConstants.spaceMd),
            children: [
              
              AppCard(
                padding: const EdgeInsets.all(AppConstants.spaceLg),
                child: Row(
                  children: [
                    PercentageRing(
                      progress: snapshot.healthScore / 100,
                      size: 118,
                      label: snapshot.healthLabel,
                      color: snapshot.healthScore >= 80
                          ? AppColors.success
                          : snapshot.healthScore >= 60
                              ? AppColors.warning
                              : AppColors.danger,
                    ),
                    const SizedBox(width: AppConstants.spaceLg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Financial Health',
                            style: AppTextStyles.title
                                .copyWith(color: context.palette.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'A blend of your savings rate, budget discipline '
                            'and spending stability.',
                            style: AppTextStyles.caption.copyWith(
                              color: context.palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spaceLg),
              const SectionHeader(title: 'Score breakdown'),
              AppCard(
                child: Column(
                  children: [
                    _BreakdownRow(
                      label: 'Savings rate',
                      value: snapshot.savingsRate.clamp(0, 1).toDouble(),
                      detail: Formatters.percent(
                        snapshot.savingsRate.clamp(0, 1),
                      ),
                      color: AppColors.success,
                    ),
                    const SizedBox(height: AppConstants.spaceMd),
                    _BreakdownRow(
                      label: 'Budget adherence',
                      value: snapshot.budgetProgress,
                      detail: snapshot.totalBudget > 0
                          ? Formatters.percent(snapshot.budgetProgress)
                          : 'No budget set',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppConstants.spaceMd),
                    _BreakdownRow(
                      label: 'Spending stability',
                      value: (1 - (snapshot.monthExpense /
                              (snapshot.monthIncome <= 0
                                  ? 1
                                  : snapshot.monthIncome))
                          .clamp(0, 1))
                          .toDouble(),
                      detail: '${Formatters.money(snapshot.monthExpense, symbol: symbol)} spent',
                      color: AppColors.info,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spaceLg),
              const SectionHeader(
                title: 'Prediction',
                subtitle: 'Expected next month',
              ),
              AppCard(
                gradient: AppColors.amberGradient,
                child: Row(
                  children: [
                    const Icon(Icons.auto_graph_rounded,
                        color: Colors.white, size: 30),
                    const SizedBox(width: AppConstants.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.money(
                              snapshot.predictedNextMonth,
                              symbol: symbol,
                            ),
                            style:
                                AppTextStyles.title.copyWith(color: Colors.white),
                          ),
                          Text(
                            'Based on your '
                            '${Formatters.money(snapshot.dailyAverage, symbol: symbol)} '
                            'daily average',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spaceLg),
              SectionHeader(
                title: 'All insights',
                subtitle: '${insights.length} generated for you',
              ),
              ...insights.asMap().entries.map(
                    (MapEntry<int, InsightModel> e) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.spaceSm),
                      child: _InsightCard(insight: e.value).staggerIn(e.key),
                    ),
                  ),

              const SizedBox(height: AppConstants.spaceLg),
              const SectionHeader(title: 'Spending mix'),
              AppCard(
                child: Column(
                  children: snapshot.topCategories.isEmpty
                      ? [
                          Text(
                            'No spending recorded this month yet.',
                            style: AppTextStyles.body.copyWith(
                              color: context.palette.textSecondary,
                            ),
                          ),
                        ]
                      : snapshot.topCategories.map((entry) {
                          final double share = snapshot.monthExpense <= 0
                              ? 0
                              : entry.value / snapshot.monthExpense;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppConstants.spaceMd,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(entry.key.label,
                                          style: AppTextStyles.subtitle
                                              .copyWith(
                                            color:
                                                context.palette.textPrimary,
                                          )),
                                    ),
                                    Text(
                                      Formatters.money(entry.value,
                                          symbol: symbol),
                                      style: AppTextStyles.subtitle.copyWith(
                                        color: context.palette.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                BudgetProgressBar(
                                  progress: share,
                                  color: entry.key.color,
                                  height: 8,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final double value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.subtitle
                      .copyWith(color: palette.textPrimary)),
            ),
            Text(detail,
                style:
                    AppTextStyles.caption.copyWith(color: palette.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        BudgetProgressBar(progress: value, color: color, height: 8),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final InsightModel insight;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      radius: AppConstants.radiusMd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(insight.icon, color: insight.color, size: 21),
          ),
          const SizedBox(width: AppConstants.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: AppTextStyles.subtitle
                        .copyWith(color: palette.textPrimary)),
                const SizedBox(height: 3),
                Text(insight.detail,
                    style: AppTextStyles.caption
                        .copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
