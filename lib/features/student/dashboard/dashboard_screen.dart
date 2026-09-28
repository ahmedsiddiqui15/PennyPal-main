import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/balance_card.dart';
import '../../../core/widgets/budget_progress_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../core/widgets/transaction_tile.dart';
import '../../../models/ai_message_model.dart';
import '../../../models/financial_snapshot.dart';
import '../../../models/transaction_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/content_providers.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/settings_providers.dart';
import 'widgets/dashboard_header.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FinanceState> finance = ref.watch(financeProvider);
    final UserModel? user = ref.watch(currentUserProvider);
    final String symbol = ref.watch(currencySymbolProvider);

    if (user == null) {
      return const Scaffold(body: LoadingView(label: 'Preparing your data…'));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(financeProvider.notifier).refresh(),
          child: finance.when(
            loading: () => const LoadingView(label: 'Loading your finances…'),
            error: (Object error, StackTrace stack) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.read(financeProvider.notifier).load(),
            ),
            data: (FinanceState data) => _DashboardBody(
              data: data,
              user: user,
              symbol: symbol,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.data,
    required this.user,
    required this.symbol,
  });

  final FinanceState data;
  final UserModel user;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FinancialSnapshot snapshot = data.snapshot;
    final int unread = ref.watch(unreadNotificationCountProvider);
    final List<InsightModel> insights = ref.watch(insightsProvider);
    final List<TransactionModel> recent = snapshot.recentTransactions.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceMd,
        AppConstants.spaceSm,
        AppConstants.spaceMd,
        AppConstants.spaceXxl,
      ),
      children: [
        DashboardHeader(
          user: user,
          unreadCount: unread,
          onAvatarTap: () => context.push(AppRoutes.editProfile),
          onBellTap: () => context.push(AppRoutes.notifications),
        ),
        const SizedBox(height: AppConstants.spaceLg),

        
        BalanceCard(
          balance: snapshot.balance,
          income: snapshot.monthIncome,
          expense: snapshot.monthExpense,
          symbol: symbol,
          ownerName: user.firstName,
        ).animate().fadeIn(duration: 500.ms).slideY(
              begin: 0.12,
              end: 0,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: AppConstants.spaceLg),

        
        SectionHeader(
          title: 'Quick Actions',
          subtitle: 'Log money in seconds',
        ),
        _QuickActions(
          onAddExpense: () => context.push(AppRoutes.addExpense),
          onAddIncome: () => context.push(AppRoutes.addIncome),
          onScanReceipt: () =>
              context.push('${AppRoutes.addExpense}?mode=receipt'),
          onBudget: () => context.go(AppRoutes.budget),
          onHistory: () => context.push(AppRoutes.transactions),
          onLearning: () => context.push(AppRoutes.learning),
          onFeedback: () => context.push('${AppRoutes.support}?tab=feedback'),
          onSupport: () => context.push('${AppRoutes.support}?tab=contact'),
          onAssistant: () => context.push(AppRoutes.aiAssistant),
        ),

        const SizedBox(height: AppConstants.spaceLg),

        
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Monthly Income',
                value: snapshot.monthIncome,
                icon: Icons.south_west_rounded,
                color: AppColors.success,
                symbol: symbol,
                trend: snapshot.prevMonthIncome > 0
                    ? (snapshot.monthIncome - snapshot.prevMonthIncome) /
                        snapshot.prevMonthIncome
                    : null,
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: StatCard(
                label: 'Monthly Expenses',
                value: snapshot.monthExpense,
                icon: Icons.north_east_rounded,
                color: AppColors.danger,
                symbol: symbol,
                trend: snapshot.prevMonthExpense > 0
                    ? (snapshot.monthExpense - snapshot.prevMonthExpense) /
                        snapshot.prevMonthExpense
                    : null,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppConstants.spaceLg),

        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _BudgetCard(snapshot: snapshot, symbol: symbol)),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(child: _HealthCard(snapshot: snapshot)),
          ],
        ),

        const SizedBox(height: AppConstants.spaceLg),

        
        _PredictionCard(snapshot: snapshot, symbol: symbol),

        const SizedBox(height: AppConstants.spaceLg),

        
        SectionHeader(
          title: 'Smart Insights',
          subtitle: 'Powered by Penny AI',
          actionLabel: 'See all',
          onAction: () => context.push(AppRoutes.insights),
        ),
        ...insights.take(2).toList().asMap().entries.map(
              (MapEntry<int, InsightModel> e) => Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
                child: _InsightTile(insight: e.value).staggerIn(e.key),
              ),
            ),

        const SizedBox(height: AppConstants.spaceMd),

        
        SectionHeader(
          title: 'Recent Activity',
          actionLabel: 'See all',
          onAction: () => context.push(AppRoutes.transactions),
        ),
        if (recent.isEmpty)
          const AppCard(
            child: EmptyState(
              compact: true,
              emoji: '🧾',
              title: 'No transactions yet',
              message: 'Add your first expense to see it here.',
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceMd,
              vertical: AppConstants.spaceSm,
            ),
            child: Column(
              children: recent
                  .asMap()
                  .entries
                  .map(
                    (MapEntry<int, TransactionModel> e) => Column(
                      children: [
                        TransactionTile(
                          transaction: e.value,
                          symbol: symbol,
                          onTap: e.value.isExpense
                              ? () => context
                                  .push(AppRoutes.expenseDetailPath(e.value.id))
                              : () => context.push(AppRoutes.income),
                        ).staggerIn(e.key),
                        if (e.key != recent.length - 1)
                          Divider(color: context.palette.divider, height: 1),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onScanReceipt,
    required this.onBudget,
    required this.onHistory,
    required this.onLearning,
    required this.onFeedback,
    required this.onSupport,
    required this.onAssistant,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onScanReceipt;
  final VoidCallback onBudget;
  final VoidCallback onHistory;
  final VoidCallback onLearning;
  final VoidCallback onFeedback;
  final VoidCallback onSupport;
  final VoidCallback onAssistant;

  @override
  Widget build(BuildContext context) {
    final List<_QuickAction> actions = [
      _QuickAction('Add Expense', Icons.add_circle_outline_rounded,
          AppColors.danger, onAddExpense),
      _QuickAction('Add Income', Icons.savings_outlined, AppColors.success,
          onAddIncome),
      _QuickAction('Scan Receipt', Icons.document_scanner_outlined,
          const Color(0xFF3B82F6), onScanReceipt),
      _QuickAction('Budget', Icons.donut_large_rounded, AppColors.primary,
          onBudget),
      _QuickAction('History', Icons.receipt_long_rounded,
          const Color(0xFF8B5CF6), onHistory),
      _QuickAction('Learn', Icons.school_outlined, const Color(0xFF06B6D4),
          onLearning),
      _QuickAction('Feedback', Icons.star_outline_rounded, AppColors.warning,
          onFeedback),
      _QuickAction('Support', Icons.support_agent_rounded,
          const Color(0xFFEC4899), onSupport),
      _QuickAction('AI Assistant', Icons.support_agent_outlined, AppColors.primary,
          onAssistant),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppConstants.spaceSm,
      crossAxisSpacing: AppConstants.spaceSm,
      childAspectRatio: 0.95,
      children: actions
          .asMap()
          .entries
          .map(
            (MapEntry<int, _QuickAction> e) =>
                _QuickActionButton(action: e.value).staggerIn(e.key),
          )
          .toList(),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.color, this.onTap);

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return AppCard(
      onTap: action.onTap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      radius: AppConstants.radiusMd,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 78,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppTextStyles.caption.copyWith(
                  color: palette.textPrimary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.snapshot, required this.symbol});

  final FinancialSnapshot snapshot;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double progress = snapshot.budgetProgress;

    return AppCard(
      onTap: () => context.go(AppRoutes.budget),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget',
              style: AppTextStyles.caption.copyWith(color: palette.textSecondary)),
          const SizedBox(height: AppConstants.spaceMd),
          Center(
            child: PercentageRing(
              progress: progress,
              size: 104,
              label: 'Used',
              color: progress >= 1
                  ? AppColors.danger
                  : progress >= 0.8
                      ? AppColors.warning
                      : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppConstants.spaceMd),
          Text(
            snapshot.totalBudget > 0
                ? '${Formatters.money(snapshot.budgetRemaining, symbol: symbol)} left'
                : 'No budget set',
            style: AppTextStyles.caption.copyWith(color: palette.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.snapshot});

  final FinancialSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final int score = snapshot.healthScore;
    final Color color = score >= 80
        ? AppColors.success
        : score >= 60
            ? AppColors.warning
            : AppColors.danger;

    return AppCard(
      onTap: () => context.push(AppRoutes.insights),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Score',
              style: AppTextStyles.caption.copyWith(color: palette.textSecondary)),
          const SizedBox(height: AppConstants.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$score',
                  style: AppTextStyles.display.copyWith(color: color)),
              const SizedBox(width: 2),
              Text('/100',
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
            ),
            child: Text(
              snapshot.healthLabel,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ),
          const SizedBox(height: AppConstants.spaceMd),
          BudgetProgressBar(progress: score / 100, color: color, height: 8),
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.snapshot, required this.symbol});

  final FinancialSnapshot snapshot;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(AppRoutes.reports),
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
            child: const Icon(Icons.auto_graph_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppConstants.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expected next month',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
                Text(
                  Formatters.money(snapshot.predictedNextMonth, symbol: symbol),
                  style: AppTextStyles.title.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Text(
            '${Formatters.money(snapshot.dailyAverage, symbol: symbol)}/day',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

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
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(insight.icon, color: insight.color, size: 20),
          ),
          const SizedBox(width: AppConstants.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppTextStyles.subtitle
                      .copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.detail,
                  style: AppTextStyles.caption
                      .copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
