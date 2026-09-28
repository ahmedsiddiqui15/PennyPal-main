import '../core/constants/app_enums.dart';
import '../core/utils/finance_math.dart';
import 'budget_model.dart';
import 'saving_goal_model.dart';
import 'transaction_model.dart';

class FinancialSnapshot {
  FinancialSnapshot({
    required this.transactions,
    required this.budgets,
    required this.goals,
    DateTime? reference,
  }) : reference = reference ?? DateTime.now() {
    _compute();
  }

  final List<TransactionModel> transactions;
  final List<BudgetModel> budgets;
  final List<SavingGoalModel> goals;
  final DateTime reference;

  
  double totalIncome = 0;
  double totalExpense = 0;

  double monthIncome = 0;
  double monthExpense = 0;
  double prevMonthExpense = 0;
  double prevMonthIncome = 0;

  double todayExpense = 0;
  double weekExpense = 0;

  
  Map<String, double> monthByCategory = {};

  
  Map<String, double> prevMonthByCategory = {};

  
  List<Map<String, dynamic>> monthlySeries = [];

  double get balance => totalIncome - totalExpense;

  double get totalBudget =>
      budgets.where((b) => b.isMaster).fold(0, (s, b) => s + b.limit);

  double get budgetUsed => monthExpense;

  double get budgetRemaining => (totalBudget - budgetUsed).clamp(0, double.infinity);

  double get budgetProgress =>
      totalBudget <= 0 ? 0 : (budgetUsed / totalBudget).clamp(0.0, 1.0);

  double get savingsRate =>
      monthIncome <= 0 ? 0 : ((monthIncome - monthExpense) / monthIncome).clamp(-1, 1);

  double get totalSaved =>
      goals.fold(0, (sum, g) => sum + g.currentAmount);

  double get totalGoalTarget => goals.fold(0, (sum, g) => sum + g.targetAmount);

  int get healthScore => FinanceMath.healthScore(
        monthlyIncome: monthIncome,
        monthlyExpenses: monthExpense,
        totalBudget: totalBudget,
      );

  String get healthLabel => FinanceMath.healthLabel(healthScore);

  
  double get predictedNextMonth => FinanceMath.predictNextMonth(
        currentMonthSpend: monthExpense,
        previousMonthSpend: prevMonthExpense,
        daysElapsedInMonth: reference.day,
        daysInMonth: DateTime(reference.year, reference.month + 1, 0).day,
      );

  double get dailyAverage => FinanceMath.dailyAverage(
        monthExpense,
        reference.day,
      );

  
  double amountFor(ExpenseCategory category) =>
      monthByCategory[category.name] ?? 0;

  double prevAmountFor(ExpenseCategory category) =>
      prevMonthByCategory[category.name] ?? 0;

  
  ExpenseCategory? get topCategory {
    if (monthByCategory.isEmpty) return null;
    final MapEntry<String, double> top = monthByCategory.entries
        .reduce((a, b) => a.value >= b.value ? a : b);
    if (top.value <= 0) return null;
    return ExpenseCategory.fromKey(top.key);
  }

  
  List<MapEntry<ExpenseCategory, double>> get topCategories {
    final List<MapEntry<ExpenseCategory, double>> list = monthByCategory.entries
        .map((e) => MapEntry(ExpenseCategory.fromKey(e.key), e.value))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  List<TransactionModel> get recentTransactions {
    final List<TransactionModel> sorted = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  
  void _compute() {
    final DateTime monthStart = DateTime(reference.year, reference.month, 1);
    final DateTime nextMonthStart = DateTime(reference.year, reference.month + 1, 1);
    final DateTime prevMonthStart = DateTime(reference.year, reference.month - 1, 1);
    final DateTime today = DateTime(reference.year, reference.month, reference.day);
    final DateTime weekStart = today.subtract(const Duration(days: 6));

    final Map<String, double> incomeByMonth = {};
    final Map<String, double> expenseByMonth = {};

    for (final TransactionModel tx in transactions) {
      final DateTime d = tx.date;
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }

      final bool inThisMonth = !d.isBefore(monthStart) && d.isBefore(nextMonthStart);
      final bool inPrevMonth = !d.isBefore(prevMonthStart) && d.isBefore(monthStart);

      if (inThisMonth) {
        if (tx.isIncome) {
          monthIncome += tx.amount;
        } else {
          monthExpense += tx.amount;
          monthByCategory.update(
            tx.categoryKey,
            (v) => v + tx.amount,
            ifAbsent: () => tx.amount,
          );
        }
      } else if (inPrevMonth) {
        if (tx.isIncome) {
          prevMonthIncome += tx.amount;
        } else {
          prevMonthExpense += tx.amount;
          prevMonthByCategory.update(
            tx.categoryKey,
            (v) => v + tx.amount,
            ifAbsent: () => tx.amount,
          );
        }
      }

      if (!tx.isIncome) {
        if (!d.isBefore(today)) todayExpense += tx.amount;
        if (!d.isBefore(weekStart)) weekExpense += tx.amount;
      }

      final String key = '${d.year}-${d.month}';
      if (tx.isIncome) {
        incomeByMonth.update(key, (v) => v + tx.amount, ifAbsent: () => tx.amount);
      } else {
        expenseByMonth.update(key, (v) => v + tx.amount, ifAbsent: () => tx.amount);
      }
    }

    
    final List<Map<String, dynamic>> series = [];
    for (int i = 11; i >= 0; i--) {
      final DateTime m = DateTime(reference.year, reference.month - i, 1);
      final String key = '${m.year}-${m.month}';
      series.add({
        'label': _monthLabel(m.month),
        'month': m.month,
        'year': m.year,
        'income': incomeByMonth[key] ?? 0,
        'expense': expenseByMonth[key] ?? 0,
      });
    }
    monthlySeries = series;
  }

  static String _monthLabel(int month) {
    const List<String> labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return labels[(month - 1).clamp(0, 11)];
  }

  
  static FinancialSnapshot empty() => FinancialSnapshot(
        transactions: const [],
        budgets: const [],
        goals: const [],
      );
}
