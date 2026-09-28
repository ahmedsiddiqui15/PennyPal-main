import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/financial_snapshot.dart';
import '../../../models/report_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/settings_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _exporting = false;

  Future<void> _export(Future<void> Function() action, String success) async {
    setState(() => _exporting = true);
    try {
      await action();
      if (!mounted) return;
      AppSnackbar.success(context, success);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<FinanceState> finance = ref.watch(financeProvider);
    final String symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: finance.when(
        loading: () => const LoadingView(label: 'Crunching your numbers…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(financeProvider.notifier).load(),
        ),
        data: (FinanceState data) => _body(context, data, symbol),
      ),
    );
  }

  Widget _body(BuildContext context, FinanceState data, String symbol) {
    final FinancialSnapshot snapshot = data.snapshot;
    final List<Map<String, dynamic>> series = snapshot.monthlySeries;

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
              child: _KpiCard(
                label: 'Income',
                value: Formatters.money(snapshot.monthIncome, symbol: symbol),
                color: AppColors.success,
                icon: Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: _KpiCard(
                label: 'Expenses',
                value: Formatters.money(snapshot.monthExpense, symbol: symbol),
                color: AppColors.danger,
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spaceMd),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Saved',
                value: Formatters.money(
                  snapshot.monthIncome - snapshot.monthExpense,
                  symbol: symbol,
                ),
                color: AppColors.primaryDark,
                icon: Icons.savings_rounded,
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: _KpiCard(
                label: 'Health score',
                value: '${snapshot.healthScore}/100',
                color: AppColors.info,
                icon: Icons.favorite_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spaceLg),

        
        const SectionHeader(
          title: 'Income vs Expenses',
          subtitle: 'Last 12 months',
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
          child: SizedBox(
            height: 220,
            child: _IncomeExpenseChart(series: series, symbol: symbol),
          ),
        ),

        const SizedBox(height: AppConstants.spaceLg),

        
        const SectionHeader(
          title: 'Monthly Savings',
          subtitle: 'Income minus expenses',
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
          child: SizedBox(
            height: 190,
            child: _SavingsBarChart(series: series, symbol: symbol),
          ),
        ),

        const SizedBox(height: AppConstants.spaceLg),

        
        const SectionHeader(
          title: 'Category Analysis',
          subtitle: 'This month',
        ),
        AppCard(
          child: snapshot.monthByCategory.isEmpty
              ? const SizedBox(
                  height: 160,
                  child: EmptyState(
                    compact: true,
                    emoji: '📊',
                    title: 'No spending yet',
                    message: 'Add expenses to see your category breakdown.',
                  ),
                )
              : Row(
                  children: [
                    SizedBox(
                      height: 168,
                      width: 168,
                      child: _CategoryPie(snapshot: snapshot),
                    ),
                    const SizedBox(width: AppConstants.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: snapshot.topCategories.take(6).map(
                          (MapEntry<ExpenseCategory, double> e) {
                            final double share = snapshot.monthExpense <= 0
                                ? 0
                                : e.value / snapshot.monthExpense;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    height: 10,
                                    width: 10,
                                    decoration: BoxDecoration(
                                      color: e.key.color,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      e.key.label,
                                      style: AppTextStyles.caption.copyWith(
                                        color: context.palette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Formatters.percent(share),
                                    style: AppTextStyles.caption.copyWith(
                                      color: context.palette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: AppConstants.spaceLg),

        
        AppCard(
          color: AppColors.primary.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_graph_rounded,
                      color: AppColors.primaryDark, size: 20),
                  const SizedBox(width: 8),
                  Text('Expense prediction',
                      style: AppTextStyles.subtitle
                          .copyWith(color: AppColors.primaryDark)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                Formatters.money(snapshot.predictedNextMonth, symbol: symbol),
                style: AppTextStyles.display.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Expected spending next month based on your current burn rate.',
                style: AppTextStyles.caption
                    .copyWith(color: context.palette.textSecondary),
              ),
              const SizedBox(height: 12),
              BudgetProgressBar(
                progress: snapshot.totalBudget <= 0
                    ? 0
                    : (snapshot.predictedNextMonth / snapshot.totalBudget)
                        .clamp(0.0, 1.0),
                height: 8,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.spaceLg),

        
        const SectionHeader(title: 'Export'),
        PrimaryButton(
          label: 'Export PDF Report',
          icon: Icons.picture_as_pdf_rounded,
          isLoading: _exporting,
          onPressed: () => _export(() async {
            final ReportModel report = ref
                .read(reportServiceProvider)
                .buildReport(snapshot, ref.read(currentUserIdProvider));
            await ref
                .read(reportServiceProvider)
                .sharePdf(report, symbol: symbol);
            await ref
                .read(repositoryProvider)
                .saveReport(report);
          }, 'Report exported.'),
        ),
        const SizedBox(height: AppConstants.spaceMd),
        PrimaryButton(
          label: 'Export CSV Ledger',
          icon: Icons.table_chart_outlined,
          outlined: true,
          isLoading: _exporting,
          onPressed: () async {
            
            
            final String csv = ref
                .read(reportServiceProvider)
                .buildCsv(data.transactions.toList());
            AppSnackbar.info(
              context,
              'CSV generated: ${csv.split('\n').length - 1} rows ready.',
            );
          },
        ),
      ],
    );
  }
}

class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({required this.series, required this.symbol});

  final List<Map<String, dynamic>> series;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final List<Map<String, dynamic>> data =
        series.where((m) => _hasData(m)).toList();
    final List<Map<String, dynamic>> points =
        data.isEmpty ? series.sublist(series.length - 6) : data;

    double maxY = 0;
    for (final Map<String, dynamic> m in points) {
      final double income = (m['income'] as num).toDouble();
      final double expense = (m['expense'] as num).toDouble();
      maxY = [maxY, income, expense].reduce((a, b) => a > b ? a : b);
    }
    maxY = maxY <= 0 ? 1000 : maxY * 1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: palette.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: maxY / 4,
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                Formatters.compact(value, symbol: ''),
                style: AppTextStyles.caption.copyWith(
                  color: palette.textSecondary,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[index]['label'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: palette.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> spots) => spots
                .map(
                  (LineBarSpot s) => LineTooltipItem(
                    Formatters.money(s.y, symbol: symbol),
                    AppTextStyles.caption.copyWith(color: Colors.white),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          _line(
            points: points,
            key: 'income',
            color: AppColors.success,
          ),
          _line(
            points: points,
            key: 'expense',
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }

  bool _hasData(Map<String, dynamic> m) =>
      (m['income'] as num) > 0 || (m['expense'] as num) > 0;

  LineChartBarData _line({
    required List<Map<String, dynamic>> points,
    required String key,
    required Color color,
  }) {
    return LineChartBarData(
      spots: points.asMap().entries
          .map(
            (MapEntry<int, Map<String, dynamic>> e) =>
                FlSpot(e.key.toDouble(), (e.value[key] as num).toDouble()),
          )
          .toList(),
      isCurved: true,
      curveSmoothness: 0.28,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.10),
      ),
    );
  }
}

class _SavingsBarChart extends StatelessWidget {
  const _SavingsBarChart({required this.series, required this.symbol});

  final List<Map<String, dynamic>> series;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final List<Map<String, dynamic>> points = series.sublist(
      series.length >= 6 ? series.length - 6 : 0,
    );

    final List<double> savings = points
        .map((m) =>
            ((m['income'] as num) - (m['expense'] as num)).toDouble())
        .toList();
    final double maxAbs = savings.isEmpty
        ? 1
        : savings.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxAbs <= 0 ? 1000 : maxAbs * 1.3,
        minY: savings.any((v) => v < 0) ? -maxAbs * 1.3 : 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxAbs <= 0 ? 500 : maxAbs / 2,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                Formatters.compact(value, symbol: ''),
                style: AppTextStyles.caption.copyWith(
                  color: palette.textSecondary,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[index]['label'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: palette.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (_, __, BarChartRodData rod, ___) =>
                BarTooltipItem(
              Formatters.money(rod.toY, symbol: symbol),
              AppTextStyles.caption.copyWith(color: Colors.white),
            ),
          ),
        ),
        barGroups: points.asMap().entries.map((MapEntry<int, Map<String, dynamic>> e) {
          final double net = savings[e.key];
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: net,
                width: 18,
                color: net >= 0 ? AppColors.success : AppColors.danger,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryPie extends StatelessWidget {
  const _CategoryPie({required this.snapshot});

  final FinancialSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<ExpenseCategory, double>> categories =
        snapshot.topCategories.take(6).toList();
    final double total = categories.fold(0, (s, e) => s + e.value);

    if (total <= 0) return const SizedBox.shrink();

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 42,
        sections: categories
            .map(
              (MapEntry<ExpenseCategory, double> e) => PieChartSectionData(
                value: e.value,
                color: e.key.color,
                radius: 34,
                title: e.value / total >= 0.12
                    ? '${((e.value / total) * 100).round()}%'
                    : '',
                titleStyle: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      radius: AppConstants.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: AppTextStyles.title.copyWith(color: palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
