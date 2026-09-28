import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_message_model.dart';
import '../models/app_notification_model.dart';
import '../models/badge_model.dart';
import '../models/budget_model.dart';
import '../models/challenge_model.dart';
import '../models/expense_model.dart';
import '../models/financial_snapshot.dart';
import '../models/income_model.dart';
import '../models/saving_goal_model.dart';
import '../models/subscription_model.dart';
import '../models/transaction_model.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../services/repository.dart';
import 'auth_providers.dart';
import 'service_providers.dart';
import 'settings_providers.dart';

class FinanceState {
  const FinanceState({
    this.transactions = const [],
    this.expenses = const [],
    this.incomes = const [],
    this.budgets = const [],
    this.goals = const [],
    this.subscriptions = const [],
    this.badges = const [],
    this.challenges = const [],
    this.filter = const TransactionFilter(),
    FinancialSnapshot? snapshot,
  }) : _snapshot = snapshot;

  final List<TransactionModel> transactions;
  final List<ExpenseModel> expenses;
  final List<IncomeModel> incomes;
  final List<BudgetModel> budgets;
  final List<SavingGoalModel> goals;
  final List<SubscriptionModel> subscriptions;
  final List<BadgeModel> badges;
  final List<ChallengeModel> challenges;
  final TransactionFilter filter;

  final FinancialSnapshot? _snapshot;

  
  FinancialSnapshot get snapshot =>
      _snapshot ??
      FinancialSnapshot(transactions: const [], budgets: const [], goals: const []);

  
  List<TransactionModel> get filteredTransactions => filter.apply(transactions);

  List<ExpenseModel> get monthExpenses {
    final DateTime now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
  }

  List<IncomeModel> get monthIncomes {
    final DateTime now = DateTime.now();
    return incomes
        .where((i) => i.date.year == now.year && i.date.month == now.month)
        .toList();
  }

  double get monthlySubscriptionCost => subscriptions
      .where((s) => s.active)
      .fold(0, (sum, s) => sum + s.monthlyCost);

  int get unlockedBadgeCount => badges.where((b) => b.unlocked).length;

  FinanceState copyWith({
    List<TransactionModel>? transactions,
    List<ExpenseModel>? expenses,
    List<IncomeModel>? incomes,
    List<BudgetModel>? budgets,
    List<SavingGoalModel>? goals,
    List<SubscriptionModel>? subscriptions,
    List<BadgeModel>? badges,
    List<ChallengeModel>? challenges,
    TransactionFilter? filter,
    FinancialSnapshot? snapshot,
  }) =>
      FinanceState(
        transactions: transactions ?? this.transactions,
        expenses: expenses ?? this.expenses,
        incomes: incomes ?? this.incomes,
        budgets: budgets ?? this.budgets,
        goals: goals ?? this.goals,
        subscriptions: subscriptions ?? this.subscriptions,
        badges: badges ?? this.badges,
        challenges: challenges ?? this.challenges,
        filter: filter ?? this.filter,
        snapshot: snapshot ?? _snapshot,
      );
}

class FinanceController extends StateNotifier<AsyncValue<FinanceState>> {
  FinanceController(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen<String>(
      currentUserIdProvider,
      (previous, next) {
        if (previous != next) {
          if (next.isEmpty) {
            state = const AsyncValue.data(FinanceState());
          } else {
            load();
          }
        }
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;

  AppRepository get _repo => _ref.read(repositoryProvider);
  String get _userId => _ref.read(currentUserIdProvider);

  Future<void> load() async {
    final String userId = _userId;
    if (userId.isEmpty) {
      state = const AsyncValue.data(FinanceState());
      return;
    }
    state = const AsyncValue.loading();
    await _reload(showLoading: false);
  }

  Future<void> refresh() => _reload(showLoading: false);

  Future<void> _reload({bool showLoading = true}) async {
    final String userId = _userId;
    if (userId.isEmpty) return;

    try {
      final List<dynamic> results = await Future.wait<dynamic>([
        _repo.fetchTransactions(userId),
        _repo.fetchExpenses(userId),
        _repo.fetchIncomes(userId),
        _repo.fetchBudgets(userId, DateTime.now()),
        _repo.fetchGoals(userId),
        _repo.fetchSubscriptions(userId),
        _repo.fetchBadges(userId),
        _repo.fetchChallenges(userId),
      ]);

      final List<TransactionModel> transactions =
          results[0] as List<TransactionModel>;
      final List<ExpenseModel> expenses = results[1] as List<ExpenseModel>;
      final List<IncomeModel> incomes = results[2] as List<IncomeModel>;
      final List<BudgetModel> budgets = results[3] as List<BudgetModel>;
      final List<SavingGoalModel> goals = results[4] as List<SavingGoalModel>;
      final List<SubscriptionModel> subscriptions =
          results[5] as List<SubscriptionModel>;
      final List<BadgeModel> badges = results[6] as List<BadgeModel>;
      final List<ChallengeModel> challenges =
          results[7] as List<ChallengeModel>;

      final FinanceState next = FinanceState(
        transactions: transactions,
        expenses: expenses,
        incomes: incomes,
        budgets: budgets,
        goals: goals,
        subscriptions: subscriptions,
        badges: badges,
        challenges: challenges,
        filter: state.valueOrNull?.filter ?? const TransactionFilter(),
        snapshot: FinancialSnapshot(
          transactions: transactions,
          budgets: budgets,
          goals: goals,
        ),
      );

      state = AsyncValue.data(next);
      await _evaluateBadges(next);
      await _pushBudgetAlerts(next);
    } catch (e, st) {
      
      
      state = AsyncValue.error(FirestoreService.describeError(e), st);
    }
  }

  
  void updateFilter(TransactionFilter filter) {
    final FinanceState? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(filter: filter));
  }

  void clearFilter() {
    final FinanceState? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(filter: TransactionFilter()));
  }

  
  Future<String?> addExpense(ExpenseModel expense) async {
    try {
      await _repo.saveExpense(expense);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not save the expense. Please try again.';
    }
  }

  Future<String?> updateExpense(ExpenseModel expense) async {
    try {
      await _repo.saveExpense(expense);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not update the expense.';
    }
  }

  Future<String?> deleteExpense(String id) async {
    try {
      await _repo.deleteExpense(_userId, id);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not delete the expense.';
    }
  }

  
  Future<String?> addIncome(IncomeModel income) async {
    try {
      await _repo.saveIncome(income);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not save the income entry.';
    }
  }

  Future<String?> updateIncome(IncomeModel income) async {
    try {
      await _repo.saveIncome(income);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not update the income entry.';
    }
  }

  Future<String?> deleteIncome(String id) async {
    try {
      await _repo.deleteIncome(_userId, id);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not delete the income entry.';
    }
  }

  
  Future<String?> saveBudget(BudgetModel budget) async {
    try {
      await _repo.saveBudget(budget);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not save the budget.';
    }
  }

  Future<String?> deleteBudget(String id) async {
    try {
      await _repo.deleteBudget(_userId, id);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not delete the budget.';
    }
  }

  
  Future<String?> saveGoal(SavingGoalModel goal) async {
    try {
      await _repo.saveGoal(goal);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not save the goal.';
    }
  }

  Future<String?> deleteGoal(String id) async {
    try {
      await _repo.deleteGoal(_userId, id);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not delete the goal.';
    }
  }

  Future<String?> addToGoal(String id, double amount) async {
    try {
      await _repo.addToGoal(_userId, id, amount);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not update the goal.';
    }
  }

  
  Future<String?> saveSubscription(SubscriptionModel subscription) async {
    try {
      await _repo.saveSubscription(subscription);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not save the subscription.';
    }
  }

  Future<String?> deleteSubscription(String id) async {
    try {
      await _repo.deleteSubscription(_userId, id);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not delete the subscription.';
    }
  }

  Future<String?> toggleSubscription(SubscriptionModel subscription) =>
      saveSubscription(subscription.copyWith(active: !subscription.active));

  
  Future<String?> toggleChallenge(ChallengeModel challenge) async {
    try {
      final ChallengeModel updated = challenge.joined
          ? challenge.copyWith(joined: false)
          : challenge.copyWith(
              joined: true,
              joinedAt: DateTime.now(),
            );
      await _repo.saveChallenge(_userId, updated);
      await _reload(showLoading: false);
      return null;
    } catch (e) {
      return 'Could not update the challenge.';
    }
  }

  Future<void> progressChallenge(ChallengeModel challenge, int days) async {
    if (!challenge.joined) return;
    final int next = (challenge.progressDays + days).clamp(0, challenge.targetDays);
    await _repo.saveChallenge(
      _userId,
      challenge.copyWith(
        progressDays: next,
        completed: next >= challenge.targetDays,
      ),
    );
    await _reload(showLoading: false);
  }

  
  
  Future<void> _evaluateBadges(FinanceState data) async {
    final Set<String> shouldUnlock = {};

    if (data.budgets.isNotEmpty) shouldUnlock.add('first_budget');
    if (data.expenses.length >= 50) shouldUnlock.add('expense_master');
    if (data.goals.any((g) => g.completed || g.progress >= 1)) {
      shouldUnlock.add('goal_getter');
    }
    if (data.expenses.any((e) => e.source == EntrySource.receipt)) {
      shouldUnlock.add('receipt_scanner');
    }
    if (data.snapshot.streakLikeDays >= 7) shouldUnlock.add('seven_day_saver');
    if (data.snapshot.healthScore >= 80 && data.snapshot.totalBudget > 0) {
      shouldUnlock.add('budget_keeper');
    }

    for (final String key in shouldUnlock) {
      final BadgeModel? badge = _badgeFor(data.badges, key);
      if (badge != null && !badge.unlocked) {
        await _repo.unlockBadge(_userId, key);
      }
    }
  }

  BadgeModel? _badgeFor(List<BadgeModel> badges, String key) {
    for (final BadgeModel b in badges) {
      if (b.key == key) return b;
    }
    return null;
  }

  
  Future<void> _pushBudgetAlerts(FinanceState data) async {
    if (data.budgets.isEmpty) return;
    final List<AppNotificationModel> generated = _ref
        .read(notificationServiceProvider)
        .buildSmartNotifications(_userId, data.snapshot);

    for (final AppNotificationModel notification in generated) {
      if (notification.type == AppNotificationType.budget) {
        await _repo.addNotification(notification);
      }
    }
  }
}

final financeProvider =
    StateNotifierProvider<FinanceController, AsyncValue<FinanceState>>(
  (ref) => FinanceController(ref),
);

final snapshotProvider = Provider<FinancialSnapshot>((ref) {
  return ref.watch(financeProvider).valueOrNull?.snapshot ??
      FinancialSnapshot(transactions: const [], budgets: const [], goals: const []);
});

final financeStateProvider = Provider<FinanceState?>(
  (ref) => ref.watch(financeProvider).valueOrNull,
);

final insightsProvider = Provider<List<InsightModel>>((ref) {
  final FinancialSnapshot snapshot = ref.watch(snapshotProvider);
  final AiService ai = ref.watch(aiServiceProvider);
  final String symbol = ref.watch(currencySymbolProvider);
  return ai.insights(snapshot, symbol: symbol);
});

final predictionProvider = Provider<double>(
  (ref) => ref.watch(snapshotProvider).predictedNextMonth,
);

final healthScoreProvider = Provider<int>(
  (ref) => ref.watch(snapshotProvider).healthScore,
);

extension FinanceSnapshotX on FinancialSnapshot {
  int get streakLikeDays {
    final Set<String> days = {};
    for (final TransactionModel tx in transactions) {
      if (tx.isExpense) {
        days.add('${tx.date.year}-${tx.date.month}-${tx.date.day}');
      }
    }
    return days.length.clamp(0, 30);
  }
}
