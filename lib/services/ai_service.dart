import 'package:flutter/material.dart';

import '../core/constants/app_enums.dart';
import '../core/utils/finance_math.dart';
import '../core/utils/formatters.dart';
import '../models/ai_message_model.dart';
import '../models/financial_snapshot.dart';
import 'gemini_service.dart';

class AiService {
  AiService({GeminiService? gemini}) : _gemini = gemini ?? GeminiService();

  final GeminiService _gemini;

  static const List<String> suggestedPrompts = [
    'How can I save money?',
    'Where am I overspending?',
    'Create a budget for me',
    'How much will I spend next month?',
    'Tips to cut food expenses',
  ];

  
  
  
  
  
  Future<String> ask(
    String question,
    FinancialSnapshot snapshot, {
    String symbol = 'Rs.',
    String? geminiApiKey,
    String? model,
  }) async {
    final String key = (geminiApiKey ?? '').trim();
    if (key.isNotEmpty) {
      try {
        return await _gemini.generate(
          apiKey: key,
          model: model,
          systemInstruction:
              '$_persona\n\n${_contextBlock(snapshot, symbol)}',
          userMessage: question,
        );
      } on GeminiException catch (e) {
        return '${respond(question, snapshot, symbol: symbol)}\n\n'
            '_(Offline coach — ${e.message})_';
      } catch (_) {
        return '${respond(question, snapshot, symbol: symbol)}\n\n'
            '_(Offline coach — Gemini is unavailable right now.)_';
      }
    }
    
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return respond(question, snapshot, symbol: symbol);
  }

  static const String _persona =
      'You are Penny, the friendly personal-finance coach inside the PennyPal '
      'student app. Answer in a warm, encouraging and concise tone, using short '
      'paragraphs or bullet points. Ground every answer in the student numbers '
      'provided below and refer to them with the given currency symbol. You give '
      'general educational guidance only — never regulated financial advice — and '
      'the student should treat PennyPal as a guidance tool, not a bank. If the '
      'numbers are all zero, gently encourage them to log a few entries first.';

  
  String _contextBlock(FinancialSnapshot s, String symbol) {
    String money(num v) => Formatters.money(v, symbol: symbol);

    final StringBuffer b = StringBuffer('Student snapshot (current month):\n');
    b.writeln('- Currency symbol: $symbol');
    b.writeln('- Income this month: ${money(s.monthIncome)}');
    b.writeln('- Expenses this month: ${money(s.monthExpense)}');
    b.writeln('- Available balance: ${money(s.balance)}');
    b.writeln(
        '- Savings rate: ${Formatters.percent(s.savingsRate.clamp(0, 1))}');
    b.writeln('- Financial health score: ${s.healthScore}/100 (${s.healthLabel})');
    if (s.totalBudget > 0) {
      b.writeln('- Monthly budget: ${money(s.totalBudget)}, '
          '${Formatters.percent(s.budgetProgress)} used, '
          '${money(s.budgetRemaining)} left');
    } else {
      b.writeln('- Monthly budget: not set');
    }

    final List<MapEntry<ExpenseCategory, double>> top =
        s.topCategories.take(3).toList();
    if (top.isEmpty) {
      b.writeln('- No expenses logged this month yet');
    } else {
      b.writeln('- Top spending categories: '
          '${top.map((MapEntry<ExpenseCategory, double> e) => '${e.key.label} ${money(e.value)}').join(', ')}');
    }

    b.writeln('- Predicted spend next month: ${money(s.predictedNextMonth)}');
    b.writeln('- Daily average spend: ${money(s.dailyAverage)}');
    b.writeln('- Saving goals: ${s.goals.length} '
        '(${money(s.totalSaved)} saved of ${money(s.totalGoalTarget)} target)');
    return b.toString();
  }

  void dispose() => _gemini.dispose();

  
  String respond(
    String question,
    FinancialSnapshot snapshot, {
    String symbol = 'Rs.',
  }) {
    final String q = question.toLowerCase();
    String money(num v) => Formatters.money(v, symbol: symbol);

    
    if (_has(q, ['hello', 'hi', 'hey', 'salam', 'assalam'])) {
      return 'Hey! I am Penny, your finance buddy. 🪙\n\n'
          'This month you have spent ${money(snapshot.monthExpense)} of '
          '${money(snapshot.monthIncome)} income. Ask me anything about '
          'budgeting, saving or cutting costs.';
    }

    
    if (_has(q, ['overspend', 'overspending', 'where am i', 'biggest', 'most'])) {
      final ExpenseCategory? top = snapshot.topCategory;
      if (top == null) {
        return 'You have not logged any expenses this month yet. '
            'Add a few and I will spot your overspending patterns. 📊';
      }
      final double current = snapshot.amountFor(top);
      final double previous = snapshot.prevAmountFor(top);
      final double change = FinanceMath.growth(current, previous);
      final String trend = previous <= 0
          ? 'no data for last month to compare yet'
          : change >= 0
              ? '${(change * 100).toStringAsFixed(0)}% more than last month'
              : '${(change.abs() * 100).toStringAsFixed(0)}% less than last month';
      return 'Your biggest category is ${top.label} at ${money(current)} '
          '($trend).\n\n'
          'Try the 50-30-20 rule: 50% needs, 30% wants, 20% savings. '
          'Capping ${top.label} at ${money(current * 0.85)} would free up '
          '${money(current * 0.15)} this month. 💡';
    }

    
    if (_has(q, ['food', 'eat', 'lunch', 'dinner', 'cafe', 'restaurant'])) {
      final double food = snapshot.amountFor(ExpenseCategory.food);
      return 'You have spent ${money(food)} on Food this month.\n\n'
          'Student-friendly fixes:\n'
          '• Cook 3 dinners a week at home\n'
          '• Set a daily food cap of ${money(snapshot.dailyAverage * 0.6)}\n'
          '• Use the receipt scanner so every rupee is tracked 📸';
    }

    
    if (_has(q, ['save', 'saving', 'savings', 'save money'])) {
      final double suggested = snapshot.monthIncome * 0.2;
      return 'Here is a simple plan:\n\n'
          '1. Save first — move ${money(suggested)} (20% of income) the day '
          'you get paid.\n'
          '2. Automate it — set a saving goal in PennyPal.\n'
          '3. Cut one subscription you barely use.\n\n'
          'Your current savings rate is '
          '${Formatters.percent(snapshot.savingsRate.clamp(0, 1))}. '
          '${snapshot.savingsRate < 0.2 ? 'Let us push it above 20%! 💪' : 'Great work — keep it up! 🎉'}';
    }

    
    if (_has(q, ['budget', 'plan', 'limit'])) {
      final double needs = snapshot.monthIncome * 0.5;
      final double wants = snapshot.monthIncome * 0.3;
      final double savings = snapshot.monthIncome * 0.2;
      return 'Based on your ${money(snapshot.monthIncome)} monthly income, '
          'here is a starter budget:\n\n'
          '• Needs (food, transport, bills): ${money(needs)}\n'
          '• Wants (shopping, fun): ${money(wants)}\n'
          '• Savings: ${money(savings)}\n\n'
          'Open Budget → Add limit to save these. You are currently at '
          '${Formatters.percent(snapshot.budgetProgress)} of your budget. 🎯';
    }

    
    if (_has(q, ['predict', 'next month', 'forecast', 'future', 'expect'])) {
      return 'Expected next month: ${money(snapshot.predictedNextMonth)}.\n\n'
          'That is based on your ${money(snapshot.monthExpense)} spend so far '
          'and last month\'s ${money(snapshot.prevMonthExpense)}. '
          'Your daily average is ${money(snapshot.dailyAverage)}. 📈';
    }

    
    if (_has(q, ['subscription', 'netflix', 'spotify', 'recurring'])) {
      return 'Subscriptions are silent budget killers. 🕵️\n\n'
          'Open Subscriptions to see your monthly total. Rule of thumb: if you '
          'have not used it in 30 days, cancel it and redirect that money into '
          'a saving goal.';
    }

    
    if (_has(q, ['income', 'earn', 'job', 'allowance', 'salary'])) {
      return 'This month you earned ${money(snapshot.monthIncome)}.\n\n'
          'Student income boosters:\n'
          '• Part-time or freelance gigs (tuition, design, coding)\n'
          '• Scholarships and grants — apply early\n'
          '• Sell notes or old books\n\n'
          'Log every source in Income so your insights stay accurate. 💼';
    }

    
    if (_has(q, ['goal', 'laptop', 'phone', 'buy', 'target'])) {
      return 'You have ${snapshot.goals.length} saving '
          '${snapshot.goals.length == 1 ? 'goal' : 'goals'} with '
          '${money(snapshot.totalSaved)} saved so far.\n\n'
          'Tip: break big goals into weekly chunks. Saving a little every week '
          'beats one big payment at the end. 🎯';
    }

    
    if (_has(q, ['health', 'score', 'rating', 'how am i'])) {
      return 'Your Financial Health Score is ${snapshot.healthScore}/100 '
          '(${snapshot.healthLabel}).\n\n'
          'It blends your savings rate, budget adherence and spending '
          'stability. Improve the weakest one and the score follows. 📊';
    }

    
    if (_has(q, ['needs', 'wants', 'difference'])) {
      return 'Needs = things you cannot skip (rent, food, transport, books).\n'
          'Wants = things you can delay (new sneakers, extra takeout).\n\n'
          'Before buying, wait 24 hours. If you still want it tomorrow, it is '
          'probably a real need. ⏳';
    }

    
    if (_has(q, ['debt', 'borrow', 'loan', 'credit'])) {
      return 'Avoid high-interest debt as a student. If you already owe money:\n\n'
          '1. List every debt and its amount.\n'
          '2. Pay the smallest first for momentum.\n'
          '3. Set a hard monthly repayment cap and log it as an expense. 🧾';
    }

    
    return 'Good question! Here is what I can see:\n\n'
        '• Balance: ${money(snapshot.balance)}\n'
        '• This month spent: ${money(snapshot.monthExpense)}\n'
        '• Health score: ${snapshot.healthScore}/100\n\n'
        'Ask me about saving, budgeting, overspending or next-month '
        'predictions and I will dig into your numbers. 🪙';
  }

  
  
  List<InsightModel> insights(FinancialSnapshot s, {String symbol = 'Rs.'}) {
    final List<InsightModel> out = [];

    
    for (final entry in s.monthByCategory.entries) {
      final ExpenseCategory cat = ExpenseCategory.fromKey(entry.key);
      final double current = entry.value;
      final double previous = s.prevMonthByCategory[entry.key] ?? 0;
      if (previous <= 0 || current < 500) continue;
      final double change = FinanceMath.growth(current, previous);
      if (change >= 0.25) {
        out.add(InsightModel(
          id: 'spike_${cat.name}',
          title: 'You spent ${Formatters.percent(change)} more on ${cat.label}',
          detail: '${cat.label} is at ${Formatters.money(current, symbol: symbol)} '
              'vs ${Formatters.money(previous, symbol: symbol)} last month.',
          icon: cat.icon,
          color: cat.color,
          severity: InsightSeverity.warning,
        ));
      }
    }

    
    if (s.savingsRate >= 0.2) {
      out.add(InsightModel(
        id: 'savings_good',
        title: 'Your saving habit improved',
        detail: 'You are saving ${Formatters.percent(s.savingsRate)} of your '
            'income this month. Above the 20% target — excellent!',
        icon: InsightSeverity.positive.icon,
        color: InsightSeverity.positive.color,
        severity: InsightSeverity.positive,
      ));
    } else if (s.monthIncome > 0 && s.savingsRate < 0.1) {
      out.add(const InsightModel(
        id: 'savings_low',
        title: 'Savings look thin this month',
        detail: 'Try moving 10% of your income into a saving goal on payday.',
        icon: Icons.savings_rounded,
        color: Color(0xFFF59E0B),
        severity: InsightSeverity.warning,
      ));
    }

    
    if (s.totalBudget > 0) {
      if (s.budgetProgress >= 0.9) {
        out.add(InsightModel(
          id: 'budget_high',
          title: 'Budget almost used up',
          detail: 'You have used ${Formatters.percent(s.budgetProgress)} of your '
              'budget. Slow down on non-essentials for the rest of the month.',
          icon: InsightSeverity.warning.icon,
          color: InsightSeverity.warning.color,
          severity: InsightSeverity.warning,
        ));
      } else {
        out.add(InsightModel(
          id: 'budget_ok',
          title: 'Budget on track',
          detail: '${Formatters.money(s.budgetRemaining, symbol: symbol)} left '
              'for the rest of the month.',
          icon: InsightSeverity.positive.icon,
          color: InsightSeverity.positive.color,
          severity: InsightSeverity.positive,
        ));
      }
    }

    
    if (s.monthExpense > 0) {
      out.add(InsightModel(
        id: 'prediction',
        title: 'Expected next month: '
            '${Formatters.money(s.predictedNextMonth, symbol: symbol)}',
        detail: 'Forecast from your current burn rate of '
            '${Formatters.money(s.dailyAverage, symbol: symbol)} per day.',
        icon: Icons.auto_graph_rounded,
        color: InsightSeverity.info.color,
        severity: InsightSeverity.info,
      ));
    }

    
    if (s.todayExpense > s.dailyAverage && s.dailyAverage > 0) {
      out.add(InsightModel(
        id: 'today_high',
        title: 'Today is above your daily average',
        detail: 'You spent ${Formatters.money(s.todayExpense, symbol: symbol)} '
            'today vs a ${Formatters.money(s.dailyAverage, symbol: symbol)} '
            'daily average.',
        icon: Icons.today_rounded,
        color: InsightSeverity.warning.color,
        severity: InsightSeverity.warning,
      ));
    }

    if (out.isEmpty) {
      out.add(const InsightModel(
        id: 'welcome',
        title: 'Add a few expenses to unlock insights',
        detail: 'Penny AI needs some data before it can spot your patterns.',
        icon: Icons.support_agent_rounded,
        color: Color(0xFF3B82F6),
        severity: InsightSeverity.info,
      ));
    }

    return out;
  }

  
  bool _has(String q, List<String> keys) => keys.any(
        (String key) => RegExp('\\b${RegExp.escape(key)}\\b').hasMatch(q),
      );
}
