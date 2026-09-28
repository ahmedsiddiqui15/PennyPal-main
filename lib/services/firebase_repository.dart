import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../core/utils/json_utils.dart';
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
import 'firestore_service.dart';
import 'repository.dart';
import 'seed_data.dart';

class FirebaseRepository implements AppRepository {
  FirebaseRepository({FirestoreService? firestore})
      : _fs = firestore ?? FirestoreService();

  final FirestoreService _fs;

  
  @override
  Future<List<TransactionModel>> fetchTransactions(
    String userId, {
    TransactionFilter? filter,
  }) async {
    final List<TransactionModel> all = [
      ...await fetchExpenses(userId).then((l) => l.map(TransactionModel.fromExpense)),
      ...await fetchIncomes(userId).then((l) => l.map(TransactionModel.fromIncome)),
    ];
    return (filter ?? TransactionFilter()).apply(all);
  }

  @override
  Future<List<ExpenseModel>> fetchExpenses(String userId) async {
    final List<Map<String, dynamic>> rows =
        await _fs.byUser(AppConstants.expensesCollection, userId);
    return rows
        .map((r) => ExpenseModel.fromMap(asString(r['id']), r))
        .toList();
  }

  @override
  Future<List<IncomeModel>> fetchIncomes(String userId) async {
    final List<Map<String, dynamic>> rows =
        await _fs.byUser(AppConstants.incomeCollection, userId);
    return rows
        .map((r) => IncomeModel.fromMap(asString(r['id']), r))
        .toList();
  }

  @override
  Future<ExpenseModel> saveExpense(ExpenseModel expense) async {
    if (expense.id.isEmpty) {
      final String id =
          await _fs.create(AppConstants.expensesCollection, expense.toMap());
      return expense.copyWithId(id);
    }
    await _fs.set(AppConstants.expensesCollection, expense.id, expense.toMap());
    return expense;
  }

  @override
  Future<void> deleteExpense(String userId, String id) =>
      _fs.delete(AppConstants.expensesCollection, id);

  @override
  Future<IncomeModel> saveIncome(IncomeModel income) async {
    if (income.id.isEmpty) {
      final String id =
          await _fs.create(AppConstants.incomeCollection, income.toMap());
      return income.copyWithId(id);
    }
    await _fs.set(AppConstants.incomeCollection, income.id, income.toMap());
    return income;
  }

  @override
  Future<void> deleteIncome(String userId, String id) =>
      _fs.delete(AppConstants.incomeCollection, id);

  
  @override
  Future<List<BudgetModel>> fetchBudgets(String userId, DateTime month) async {
    final List<Map<String, dynamic>> rows = await _fs.byUser(
      AppConstants.budgetsCollection,
      userId,
      orderField: 'month',
      descending: false,
    );
    final List<BudgetModel> all = rows
        .map((r) => BudgetModel.fromMap(asString(r['id']), r))
        .toList();
    final List<BudgetModel> thisMonth = all
        .where((b) => b.month.year == month.year && b.month.month == month.month)
        .toList();
    
    
    if (thisMonth.isEmpty) {
      final List<BudgetModel> previous = all
          .where((b) => b.month.isBefore(DateTime(month.year, month.month, 1)))
          .toList()
        ..sort((a, b) => b.month.compareTo(a.month));
      return previous.take(20).toList();
    }
    return thisMonth;
  }

  @override
  Future<BudgetModel> saveBudget(BudgetModel budget) async {
    if (budget.id.isEmpty) {
      final String id =
          await _fs.create(AppConstants.budgetsCollection, budget.toMap());
      return budget.copyWithId(id);
    }
    await _fs.set(AppConstants.budgetsCollection, budget.id, budget.toMap());
    return budget;
  }

  @override
  Future<void> deleteBudget(String userId, String id) =>
      _fs.delete(AppConstants.budgetsCollection, id);

  
  @override
  Future<List<SavingGoalModel>> fetchGoals(String userId) async {
    final List<Map<String, dynamic>> rows = await _fs.byUser(
      AppConstants.savingGoalsCollection,
      userId,
      orderField: 'createdAt',
      descending: true,
    );
    return rows
        .map((r) => SavingGoalModel.fromMap(asString(r['id']), r))
        .toList();
  }

  @override
  Future<SavingGoalModel> saveGoal(SavingGoalModel goal) async {
    if (goal.id.isEmpty) {
      final String id =
          await _fs.create(AppConstants.savingGoalsCollection, goal.toMap());
      return goal.copyWithId(id);
    }
    await _fs.set(AppConstants.savingGoalsCollection, goal.id, goal.toMap());
    return goal;
  }

  @override
  Future<void> deleteGoal(String userId, String id) =>
      _fs.delete(AppConstants.savingGoalsCollection, id);

  @override
  Future<SavingGoalModel> addToGoal(String userId, String id, double amount) async {
    final Map<String, dynamic>? row =
        await _fs.doc(AppConstants.savingGoalsCollection, id);
    if (row == null) throw StateError('Goal not found');
    final SavingGoalModel goal =
        SavingGoalModel.fromMap(id, row);
    final SavingGoalModel updated = goal.copyWith(
      currentAmount: goal.currentAmount + amount,
      completed: goal.currentAmount + amount >= goal.targetAmount,
    );
    await _fs.set(AppConstants.savingGoalsCollection, id, updated.toMap());
    return updated;
  }

  
  @override
  Future<List<SubscriptionModel>> fetchSubscriptions(String userId) async {
    final List<Map<String, dynamic>> rows = await _fs.byUser(
      AppConstants.subscriptionsCollection,
      userId,
      orderField: 'billingDate',
      descending: false,
    );
    return rows
        .map((r) => SubscriptionModel.fromMap(asString(r['id']), r))
        .toList();
  }

  @override
  Future<SubscriptionModel> saveSubscription(SubscriptionModel subscription) async {
    if (subscription.id.isEmpty) {
      final String id = await _fs.create(
        AppConstants.subscriptionsCollection,
        subscription.toMap(),
      );
      return subscription.copyWithId(id);
    }
    await _fs.set(
      AppConstants.subscriptionsCollection,
      subscription.id,
      subscription.toMap(),
    );
    return subscription;
  }

  @override
  Future<void> deleteSubscription(String userId, String id) =>
      _fs.delete(AppConstants.subscriptionsCollection, id);

  
  @override
  Future<List<LearningModel>> fetchLearning({
    bool includeUnpublished = false,
  }) async {
    List<Map<String, dynamic>> rows = await _fs.all(
      AppConstants.learningContentCollection,
      orderField: 'createdAt',
    );

    
    
    if (rows.isEmpty) {
      for (final LearningModel article in SeedData.learning) {
        await _fs.set(
          AppConstants.learningContentCollection,
          article.id,
          article.toMap(),
        );
      }
      rows = await _fs.all(
        AppConstants.learningContentCollection,
        orderField: 'createdAt',
      );
    }

    final List<LearningModel> all = rows
        .map((r) => LearningModel.fromMap(asString(r['id']), r))
        .toList();
    return includeUnpublished
        ? all
        : all.where((l) => l.published).toList();
  }

  @override
  Future<LearningModel> saveLearning(LearningModel article) async {
    if (article.id.isEmpty) {
      final String id = await _fs.create(
        AppConstants.learningContentCollection,
        article.toMap(),
      );
      return article.copyWithId(id);
    }
    await _fs.set(
      AppConstants.learningContentCollection,
      article.id,
      article.toMap(),
    );
    return article;
  }

  @override
  Future<void> deleteLearning(String id) =>
      _fs.delete(AppConstants.learningContentCollection, id);

  
  @override
  Future<List<SupportModel>> fetchSupport({String? userId}) async {
    final List<Map<String, dynamic>> rows = userId == null
        ? await _fs.all(AppConstants.supportQueriesCollection, orderField: 'createdAt')
        : await _fs.byUser(
            AppConstants.supportQueriesCollection,
            userId,
            orderField: 'createdAt',
          );
    return rows
        .map((r) => SupportModel.fromMap(asString(r['id']), r))
        .toList();
  }

  @override
  Future<SupportModel> submitSupport(SupportModel query) async {
    if (query.id.isEmpty) {
      final String id = await _fs.create(
        AppConstants.supportQueriesCollection,
        query.toMap(),
      );
      return query.copyWithId(id);
    }
    await _fs.set(
      AppConstants.supportQueriesCollection,
      query.id,
      query.toMap(),
    );
    return query;
  }

  @override
  Future<SupportModel> updateSupport(SupportModel query) async {
    await _fs.set(
      AppConstants.supportQueriesCollection,
      query.id,
      query.toMap(),
    );
    return query;
  }

  
  @override
  Future<List<AppNotificationModel>> fetchNotifications(String userId) async {
    final List<Map<String, dynamic>> rows = await _fs.byUser(
      AppConstants.notificationsCollection,
      userId,
      orderField: 'createdAt',
    );
    return rows
        .map((r) => AppNotificationModel.fromMap(asString(r['id']), r))
        .toList();
  }

  @override
  Future<void> addNotification(AppNotificationModel notification) async {
    await _fs.create(
      AppConstants.notificationsCollection,
      notification.toMap(),
    );
  }

  @override
  Future<void> markNotificationRead(
    String userId,
    String id,
    bool read,
  ) =>
      _fs.set(AppConstants.notificationsCollection, id, {'read': read});

  @override
  Future<void> markAllNotificationsRead(String userId) async {
    final List<AppNotificationModel> items = await fetchNotifications(userId);
    for (final AppNotificationModel n in items) {
      if (!n.read) {
        await _fs.set(AppConstants.notificationsCollection, n.id, {'read': true});
      }
    }
  }

  
  @override
  Future<List<BadgeModel>> fetchBadges(String userId) async {
    
    
    
    final List<Map<String, dynamic>> rows = await _fs.byUser(
      AppConstants.badgesCollection,
      userId,
      orderField: 'key',
      descending: false,
    );

    final Map<String, DateTime?> unlockTimes = <String, DateTime?>{};
    for (final Map<String, dynamic> row in rows) {
      unlockTimes[asString(row['key'])] = asDateTimeOrNull(row['unlockedAt']);
    }

    return BadgeCatalog.all.map((BadgeModel badge) {
      if (!unlockTimes.containsKey(badge.key)) return badge;
      return badge.copyWith(
        unlocked: true,
        unlockedAt: unlockTimes[badge.key],
      );
    }).toList();
  }

  @override
  Future<void> unlockBadge(String userId, String key) async {
    
    await _fs.set(AppConstants.badgesCollection, '${userId}_$key', {
      'userId': userId,
      'key': key,
      'unlocked': true,
      'unlockedAt': DateTime.now().toIso8601String(),
    });
  }

  
  @override
  Future<List<ChallengeModel>> fetchChallenges(String userId) async {
    List<Map<String, dynamic>> rows = await _fs.byUser(
      AppConstants.challengesCollection,
      userId,
      orderField: 'title',
      descending: false,
    );

    
    
    if (rows.isEmpty) {
      for (final ChallengeModel challenge in SeedData.challenges(userId)) {
        final Map<String, dynamic> data = challenge.toMap()
          ..['userId'] = userId;
        await _fs.set(
          AppConstants.challengesCollection,
          challenge.id,
          data,
        );
      }
      rows = await _fs.byUser(
        AppConstants.challengesCollection,
        userId,
        orderField: 'title',
        descending: false,
      );
    }

    return rows
        .map((r) => ChallengeModel.fromMap(asString(r['id']), r))
        .toList();
  }

  @override
  Future<ChallengeModel> saveChallenge(
    String userId,
    ChallengeModel challenge,
  ) async {
    final Map<String, dynamic> data = challenge.toMap()..['userId'] = userId;
    if (challenge.id.isEmpty) {
      final String id =
          await _fs.create(AppConstants.challengesCollection, data);
      return challenge.copyWithId(id);
    }
    await _fs.set(AppConstants.challengesCollection, challenge.id, data);
    return challenge;
  }

  
  @override
  Future<List<ReportModel>> fetchReports(String userId) async {
    final List<Map<String, dynamic>> rows = await _fs.byUser(
      AppConstants.reportsCollection,
      userId,
      orderField: 'generatedAt',
    );
    return rows
        .map((r) => ReportModel.fromMap(asString(r['id']), r))
        .toList();
  }

  @override
  Future<void> saveReport(ReportModel report) async {
    await _fs.create(AppConstants.reportsCollection, report.toMap());
  }

  
  @override
  Future<List<UserModel>> fetchAllUsers() async {
    final List<Map<String, dynamic>> rows = await _fs.all(
      AppConstants.usersCollection,
      orderField: 'createdAt',
    );
    return rows.map((r) => UserModel.fromMap(asString(r['id']), r)).toList();
  }

  @override
  Future<void> setUserBlocked(String userId, bool blocked) =>
      _fs.set(AppConstants.usersCollection, userId, {'blocked': blocked});

  @override
  Future<UserModel> updateUser(UserModel user) async {
    await _fs.set(AppConstants.usersCollection, user.id, user.toMap());
    return user;
  }

  @override
  Future<void> convertCurrencyAmounts(String userId, double factor) async {
    if (userId.isEmpty || factor == 1) return;

    double scale(double value) =>
        ((value * factor) * 100).round() / 100;

    Future<void> scaleField(
      String collection,
      String field,
    ) async {
      final List<Map<String, dynamic>> rows = await _fs.byUser(collection, userId);
      for (final Map<String, dynamic> row in rows) {
        final String id = asString(row['id']);
        if (id.isEmpty) continue;
        final double current = asDouble(row[field]);
        await _fs.set(collection, id, {field: scale(current)});
      }
    }

    await Future.wait<void>([
      scaleField(AppConstants.expensesCollection, 'amount'),
      scaleField(AppConstants.incomeCollection, 'amount'),
      scaleField(AppConstants.budgetsCollection, 'limit'),
      scaleField(AppConstants.subscriptionsCollection, 'amount'),
    ]);

    final List<Map<String, dynamic>> goals =
        await _fs.byUser(AppConstants.savingGoalsCollection, userId);
    for (final Map<String, dynamic> row in goals) {
      final String id = asString(row['id']);
      if (id.isEmpty) continue;
      await _fs.set(AppConstants.savingGoalsCollection, id, {
        'targetAmount': scale(asDouble(row['targetAmount'])),
        'currentAmount': scale(asDouble(row['currentAmount'])),
        'monthlyContribution': scale(asDouble(row['monthlyContribution'])),
      });
    }
  }

  @override
  Future<Map<String, dynamic>> adminMetrics() async {
    final List<UserModel> users = await fetchAllUsers();
    final List<Map<String, dynamic>> expenseRows =
        await _fs.all(AppConstants.expensesCollection);
    final List<Map<String, dynamic>> goalRows =
        await _fs.all(AppConstants.savingGoalsCollection);
    final List<Map<String, dynamic>> supportRows =
        await _fs.all(AppConstants.supportQueriesCollection);
    final List<Map<String, dynamic>> articleRows =
        await _fs.all(AppConstants.learningContentCollection);

    final DateTime now = DateTime.now();
    double totalExpense = 0;
    for (final Map<String, dynamic> row in expenseRows) {
      final DateTime date = asDateTime(row['date']);
      if (date.year == now.year && date.month == now.month) {
        totalExpense += asDouble(row['amount']);
      }
    }

    final DateTime weekAgo = now.subtract(const Duration(days: 7));
    return {
      'totalUsers': users.length,
      'activeUsers': users
          .where((u) => u.lastActiveAt != null && u.lastActiveAt!.isAfter(weekAgo))
          .length,
      'totalExpenses': totalExpense,
      'totalSavings': goalRows.fold<double>(
        0,
        (sum, r) => sum + asDouble(r['currentAmount']),
      ),
      'openQueries': supportRows
          .where((r) => asString(r['status']) != SupportStatus.resolved.name)
          .length,
      'articles': articleRows.length,
    };
  }
}
