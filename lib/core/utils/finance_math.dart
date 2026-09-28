import 'dart:math' as math;

class FinanceMath {
  FinanceMath._();

  
  
  
  
  
  static int healthScore({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double totalBudget,
  }) {
    if (monthlyIncome <= 0 && monthlyExpenses <= 0) return 0;

    double score = 0;

    
    if (monthlyIncome > 0) {
      final double savingsRate =
          ((monthlyIncome - monthlyExpenses) / monthlyIncome).clamp(0.0, 1.0);
      score += (savingsRate / 0.35).clamp(0.0, 1.0) * 40;
    }

    
    if (totalBudget > 0) {
      final double usage = monthlyExpenses / totalBudget;
      if (usage <= 1) {
        score += 35 - (usage * 10);
      } else {
        score += (35 - (usage - 1) * 70).clamp(0.0, 35.0);
      }
    } else {
      
      score += 18;
    }

    
    if (monthlyIncome > 0) {
      final double ratio = monthlyExpenses / monthlyIncome;
      if (ratio <= 0.9) {
        score += 25 * (1 - (ratio - 0.4).abs().clamp(0.0, 1.0));
      } else {
        score += 25 * (1 - (ratio - 0.9).clamp(0.0, 1.0));
      }
    }

    return score.clamp(0, 100).round();
  }

  static String healthLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 45) return 'Fair';
    if (score > 0) return 'Needs Work';
    return 'No Data';
  }

  
  static double predictNextMonth({
    required double currentMonthSpend,
    required double previousMonthSpend,
    int daysElapsedInMonth = 0,
    int daysInMonth = 30,
  }) {
    if (daysElapsedInMonth > 0 && daysElapsedInMonth < daysInMonth) {
      final double runRate = currentMonthSpend / daysElapsedInMonth;
      return runRate * daysInMonth;
    }
    if (previousMonthSpend <= 0) return currentMonthSpend;
    
    return (currentMonthSpend * 0.7) + (previousMonthSpend * 0.3);
  }

  
  static double growth(double current, double previous) {
    if (previous <= 0) return current > 0 ? 1 : 0;
    return (current - previous) / previous;
  }

  static double average(Iterable<num> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double dailyAverage(double total, int days) =>
      days <= 0 ? 0 : total / days;

  
  static double stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final double mean = average(values);
    final double variance = values
            .map((v) => math.pow(v - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }
}
