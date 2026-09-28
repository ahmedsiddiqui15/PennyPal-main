import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/user_model.dart';
import '../../../providers/admin_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AdminState> admin = ref.watch(adminProvider);
    final UserModel? me = ref.watch(currentUserProvider);
    final String symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Overview'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final bool confirmed = await AppDialog.confirm(
                context,
                title: 'Log out?',
                message: 'You will leave the admin panel.',
                confirmLabel: 'Log Out',
                destructive: true,
              );
              if (confirmed) {
                await ref.read(authProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
      body: admin.when(
        loading: () => const LoadingView(label: 'Loading platform metrics…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(adminProvider.notifier).load(),
        ),
        data: (AdminState state) => _body(context, ref, state, me, symbol),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AdminState state,
    UserModel? me,
    String symbol,
  ) {
    final AppPalette palette = context.palette;
    final AdminMetrics metrics = state.metrics;
    final List<UserModel> recent = [...state.users]
      ..sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));

    
    
    final snapshot = ref.watch(snapshotProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceMd,
        AppConstants.spaceSm,
        AppConstants.spaceMd,
        AppConstants.spaceXxl,
      ),
      children: [
        AppCard(
          gradient: AppColors.amberGradient,
          padding: const EdgeInsets.all(AppConstants.spaceLg),
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 34),
              const SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${me?.firstName ?? 'Admin'}',
                      style: AppTextStyles.title.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Platform health at a glance',
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

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Users',
                value: '${metrics.totalUsers}',
                icon: Icons.people_rounded,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: _MetricCard(
                label: 'Active Users',
                value: '${metrics.activeUsers}',
                icon: Icons.online_prediction_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spaceMd),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Monthly Expenses',
                value: Formatters.money(metrics.totalExpenses, symbol: symbol),
                icon: Icons.north_east_rounded,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: _MetricCard(
                label: 'Total Savings',
                value: Formatters.money(metrics.totalSavings, symbol: symbol),
                icon: Icons.savings_rounded,
                color: AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spaceLg),

        
        const SectionHeader(
          title: 'User Growth',
          subtitle: 'Signups over the last 6 months',
        ),
        AppCard(
          padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
          child: SizedBox(
            height: 200,
            child: _GrowthChart(series: metrics.userGrowth),
          ),
        ),

        const SizedBox(height: AppConstants.spaceLg),

        
        const SectionHeader(
          title: 'Platform Activity',
          subtitle: 'Your live session figures',
        ),
        AppCard(
          child: Column(
            children: [
              _ActivityRow(
                label: 'Transactions in ledger',
                value: '${snapshot.transactions.length}',
              ),
              Divider(color: palette.divider),
              _ActivityRow(
                label: 'Expenses this month',
                value: Formatters.money(snapshot.monthExpense, symbol: symbol),
              ),
              Divider(color: palette.divider),
              _ActivityRow(
                label: 'Open support queries',
                value: '${metrics.openQueries}',
              ),
              Divider(color: palette.divider),
              _ActivityRow(
                label: 'Learning articles',
                value: '${metrics.articles}',
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.spaceLg),

        const SectionHeader(title: 'Recent Signups'),
        ...recent.take(5).toList().asMap().entries.map(
              (MapEntry<int, UserModel> e) => Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
                child: AppCard(
                  padding: const EdgeInsets.all(AppConstants.spaceMd),
                  radius: AppConstants.radiusMd,
                  child: Row(
                    children: [
                      AppAvatar(
                        name: e.value.name,
                        imageUrl: e.value.photoUrl,
                        size: 42,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.name,
                                style: AppTextStyles.subtitle
                                    .copyWith(color: palette.textPrimary)),
                            Text(e.value.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption
                                    .copyWith(color: palette.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        e.value.createdAt == null
                            ? '—'
                            : Formatters.relativeDate(e.value.createdAt!),
                        style: AppTextStyles.caption
                            .copyWith(color: palette.textSecondary),
                      ),
                    ],
                  ),
                ).staggerIn(e.key),
              ),
            ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 12),
          FittedBox(
            child: Text(value,
                style:
                    AppTextStyles.title.copyWith(color: palette.textPrimary)),
          ),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: palette.textSecondary)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    AppTextStyles.body.copyWith(color: palette.textSecondary)),
          ),
          Text(value,
              style:
                  AppTextStyles.subtitle.copyWith(color: palette.textPrimary)),
        ],
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.series});

  final List<Map<String, dynamic>> series;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double maxY = series.isEmpty
        ? 10
        : series
                .map((m) => (m['users'] as num).toDouble())
                .reduce((a, b) => a > b ? a : b) *
            1.4;

    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 10 : maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxY / 4,
              getTitlesWidget: (double value, TitleMeta meta) => Text(
                value.toInt().toString(),
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
              reservedSize: 24,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= series.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    series[index]['label'] as String,
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
              '${rod.toY.toInt()} users',
              AppTextStyles.caption.copyWith(color: Colors.white),
            ),
          ),
        ),
        barGroups: series.asMap().entries.map(
          (MapEntry<int, Map<String, dynamic>> e) => BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (e.value['users'] as num).toDouble(),
                width: 22,
                gradient: AppColors.amberGradient,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ).toList(),
      ),
    );
  }
}
