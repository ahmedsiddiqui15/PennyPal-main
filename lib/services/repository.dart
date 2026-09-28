import '../core/constants/app_enums.dart';
import '../models/app_notification_model.dart';
import '../models/badge_model.dart';
import '../models/budget_model.dart';
import '../models/challenge_model.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/learning_model.dart';
import '../models/report_model.dart';
import '../models/saving_goal_model.dart';
import '../models/subscription_model.dart';
import '../models/support_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

enum TransactionSort { newest, oldest, highest, lowest }

class TransactionFilter {
  const TransactionFilter({
    this.from,
    this.to,
    this.type,
    this.categories = const {},
    this.query = '',
    this.minAmount,
    this.maxAmount,
    this.sort = TransactionSort.newest,
  });

  final DateTime? from;
  final DateTime? to;
  final TransactionType? type;

  
  final Set<String> categories;
  final String query;
  final double? minAmount;
  final double? maxAmount;
  final TransactionSort sort;

  bool get isEmpty =>
      from == null &&
      to == null &&
      type == null &&
      categories.isEmpty &&
      query.trim().isEmpty &&
      minAmount == null &&
      maxAmount == null &&
      sort == TransactionSort.newest;

  TransactionFilter copyWith({
    DateTime? from,
    DateTime? to,
    TransactionType? type,
    Set<String>? categories,
    String? query,
    double? minAmount,
    double? maxAmount,
    TransactionSort? sort,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearType = false,
    bool clearAmounts = false,
  }) =>
      TransactionFilter(
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
        type: clearType ? null : (type ?? this.type),
        categories: categories ?? this.categories,
        query: query ?? this.query,
        minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
        maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
        sort: sort ?? this.sort,
      );

  
  
  List<TransactionModel> apply(List<TransactionModel> input) {
    final String q = query.trim().toLowerCase();
    Iterable<TransactionModel> result = input.where((tx) {
      if (from != null && tx.date.isBefore(_startOfDay(from!))) return false;
      if (to != null && tx.date.isAfter(_endOfDay(to!))) return false;
      if (type != null && tx.type != type) return false;
      if (categories.isNotEmpty && !categories.contains(tx.categoryKey)) {
        return false;
      }
      if (minAmount != null && tx.amount < minAmount!) return false;
      if (maxAmount != null && tx.amount > maxAmount!) return false;
      if (q.isNotEmpty) {
        final String haystack =
            '${tx.description} ${tx.categoryLabel}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    });

    final List<TransactionModel> list = result.toList();
    switch (sort) {
      case TransactionSort.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
      case TransactionSort.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
      case TransactionSort.highest:
        list.sort((a, b) => b.amount.compareTo(a.amount));
      case TransactionSort.lowest:
        list.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return list;
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);
}

abstract class AppRepository {
  
  Future<List<TransactionModel>> fetchTransactions(
    String userId, {
    TransactionFilter? filter,
  });

  Future<List<ExpenseModel>> fetchExpenses(String userId);

  Future<List<IncomeModel>> fetchIncomes(String userId);

  
  Future<ExpenseModel> saveExpense(ExpenseModel expense);

  Future<void> deleteExpense(String userId, String id);

  Future<IncomeModel> saveIncome(IncomeModel income);

  Future<void> deleteIncome(String userId, String id);

  
  Future<List<BudgetModel>> fetchBudgets(String userId, DateTime month);

  Future<BudgetModel> saveBudget(BudgetModel budget);

  Future<void> deleteBudget(String userId, String id);

  
  Future<List<SavingGoalModel>> fetchGoals(String userId);

  Future<SavingGoalModel> saveGoal(SavingGoalModel goal);

  Future<void> deleteGoal(String userId, String id);

  Future<SavingGoalModel> addToGoal(String userId, String id, double amount);

  
  Future<List<SubscriptionModel>> fetchSubscriptions(String userId);

  Future<SubscriptionModel> saveSubscription(SubscriptionModel subscription);

  Future<void> deleteSubscription(String userId, String id);

  
  Future<List<LearningModel>> fetchLearning({bool includeUnpublished = false});

  Future<LearningModel> saveLearning(LearningModel article);

  Future<void> deleteLearning(String id);

  
  Future<List<SupportModel>> fetchSupport({String? userId});

  Future<SupportModel> submitSupport(SupportModel query);

  Future<SupportModel> updateSupport(SupportModel query);

  
  Future<List<AppNotificationModel>> fetchNotifications(String userId);

  Future<void> addNotification(AppNotificationModel notification);

  Future<void> markNotificationRead(String userId, String id, bool read);

  Future<void> markAllNotificationsRead(String userId);

  
  Future<List<BadgeModel>> fetchBadges(String userId);

  Future<void> unlockBadge(String userId, String key);

  
  Future<List<ChallengeModel>> fetchChallenges(String userId);

  Future<ChallengeModel> saveChallenge(String userId, ChallengeModel challenge);

  
  Future<List<ReportModel>> fetchReports(String userId);

  Future<void> saveReport(ReportModel report);

  
  Future<List<UserModel>> fetchAllUsers();

  Future<void> setUserBlocked(String userId, bool blocked);

  Future<UserModel> updateUser(UserModel user);

  Future<Map<String, dynamic>> adminMetrics();

  
  
  
  
  Future<void> convertCurrencyAmounts(String userId, double factor);
}
