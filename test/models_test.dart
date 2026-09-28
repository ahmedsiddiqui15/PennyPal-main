import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pennypal/core/config/app_config.dart';
import 'package:pennypal/core/constants/app_enums.dart';
import 'package:pennypal/core/theme/light_theme.dart';
import 'package:pennypal/core/utils/json_utils.dart';
import 'package:pennypal/features/auth/splash/splash_screen.dart';
import 'package:pennypal/models/app_notification_model.dart';
import 'package:pennypal/models/badge_model.dart';
import 'package:pennypal/models/budget_model.dart';
import 'package:pennypal/models/challenge_model.dart';
import 'package:pennypal/models/expense_model.dart';
import 'package:pennypal/models/income_model.dart';
import 'package:pennypal/models/learning_model.dart';
import 'package:pennypal/models/saving_goal_model.dart';
import 'package:pennypal/models/subscription_model.dart';
import 'package:pennypal/models/transaction_model.dart';
import 'package:pennypal/models/user_model.dart';

/// Firestore mapping + UI smoke tests.
///
/// Every model is written to and read back from a plain `Map<String, dynamic>`,
/// which is exactly what `cloud_firestore` does. If these pass, the Firestore
/// layer round-trips correctly without needing a live Firebase project.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Firestore value decoding', () {
    test('parses ISO strings, epoch millis and nulls', () {
      final DateTime expected = DateTime(2026, 3, 14, 10, 30);
      expect(asDateTime(expected.toIso8601String()), expected);
      expect(
        asDateTime(expected.millisecondsSinceEpoch),
        expected,
      );
      expect(asDateTimeOrNull(null), isNull);
      expect(asDateTimeOrNull('not-a-date'), isNull);
    });

    test('coerces numeric and boolean types safely', () {
      expect(asDouble('1500.5'), 1500.5);
      expect(asDouble(null), 0);
      expect(asInt('42'), 42);
      expect(asBool('true'), isTrue);
      expect(asBool(1), isTrue);
      expect(asStringList(['a', 'b']), ['a', 'b']);
    });
  });

  group('UserModel', () {
    test('round-trips through a Firestore map', () {
      final UserModel user = UserModel(
        id: 'uid-1',
        name: 'Ahmed Raza',
        email: 'ahmed@pennypal.app',
        phone: '+92 300 1234567',
        role: UserRole.admin,
        currencyCode: 'USD',
        currencySymbol: r'$',
        monthlyIncomeGoal: 40000,
        notificationsEnabled: false,
        themeMode: 'dark',
        createdAt: DateTime(2026, 1, 5),
      );

      final UserModel restored = UserModel.fromMap(user.id, user.toMap());

      expect(restored.name, 'Ahmed Raza');
      expect(restored.email, 'ahmed@pennypal.app');
      expect(restored.role, UserRole.admin);
      expect(restored.isAdmin, isTrue);
      expect(restored.currencyCode, 'USD');
      expect(restored.monthlyIncomeGoal, 40000);
      expect(restored.notificationsEnabled, isFalse);
      expect(restored.themeMode, 'dark');
      expect(restored.createdAt, DateTime(2026, 1, 5));
      expect(restored.firstName, 'Ahmed');
    });

    test('defaults to a student role when the field is missing', () {
      final UserModel restored = UserModel.fromMap('uid-2', {'name': 'Sara'});
      expect(restored.role, UserRole.student);
      expect(restored.currencySymbol, 'Rs.');
    });
  });

  group('ExpenseModel & IncomeModel', () {
    test('expense round-trips including enum and source', () {
      final ExpenseModel expense = ExpenseModel(
        id: 'exp-1',
        userId: 'uid-1',
        amount: 1250,
        category: ExpenseCategory.education,
        description: 'Semester books',
        date: DateTime(2026, 2, 10),
        receiptUrl: 'https://example.com/receipt.jpg',
        source: EntrySource.receipt,
      );

      final ExpenseModel restored =
          ExpenseModel.fromMap(expense.id, expense.toMap());

      expect(restored.amount, 1250);
      expect(restored.category, ExpenseCategory.education);
      expect(restored.description, 'Semester books');
      expect(restored.date, DateTime(2026, 2, 10));
      expect(restored.receiptUrl, 'https://example.com/receipt.jpg');
      expect(restored.source, EntrySource.receipt);
    });

    test('income round-trips including enum', () {
      final IncomeModel income = IncomeModel(
        id: 'inc-1',
        userId: 'uid-1',
        amount: 35000,
        category: IncomeCategory.scholarship,
        description: 'Merit scholarship',
        date: DateTime(2026, 2, 1),
      );

      final IncomeModel restored =
          IncomeModel.fromMap(income.id, income.toMap());

      expect(restored.amount, 35000);
      expect(restored.category, IncomeCategory.scholarship);
      expect(restored.date, DateTime(2026, 2, 1));
    });

    test('unknown categories fall back to "other"', () {
      final ExpenseModel restored =
          ExpenseModel.fromMap('x', {'amount': 10, 'category': 'nonsense'});
      expect(restored.category, ExpenseCategory.other);
    });
  });

  group('TransactionModel', () {
    test('projects an expense and an income into ledger rows', () {
      final ExpenseModel expense = ExpenseModel(
        id: 'exp-9',
        userId: 'uid-1',
        amount: 800,
        category: ExpenseCategory.food,
        description: 'Pizza',
        date: DateTime(2026, 2, 12),
      );

      final TransactionModel tx = TransactionModel.fromExpense(expense);
      expect(tx.isExpense, isTrue);
      expect(tx.signedAmount, -800);
      expect(tx.categoryLabel, 'Food');

      final TransactionModel restored =
          TransactionModel.fromMap(tx.id, tx.toMap());
      expect(restored.amount, 800);
      expect(restored.type, TransactionType.expense);
      expect(restored.description, 'Pizza');

      // Round-trips back into the concrete expense it came from.
      expect(restored.toExpense().category, ExpenseCategory.food);
    });

    test('income rows are signed positively', () {
      final TransactionModel tx = TransactionModel.fromIncome(IncomeModel(
        id: 'inc-9',
        userId: 'uid-1',
        amount: 5000,
        category: IncomeCategory.partTime,
        date: DateTime(2026, 2, 3),
      ));
      expect(tx.signedAmount, 5000);
      expect(tx.isIncome, isTrue);
    });
  });

  group('BudgetModel', () {
    test('distinguishes the master budget from category limits', () {
      final DateTime month = DateTime(2026, 2, 1);

      final BudgetModel master = BudgetModel(
        id: 'b1',
        userId: 'uid-1',
        limit: 30000,
        month: month,
      );
      final BudgetModel food = BudgetModel(
        id: 'b2',
        userId: 'uid-1',
        limit: 9000,
        category: ExpenseCategory.food.name,
        month: month,
      );

      expect(master.isMaster, isTrue);
      expect(master.categoryLabel, 'Overall Budget');
      expect(food.isMaster, isFalse);
      expect(food.categoryLabel, 'Food');

      final BudgetModel restored =
          BudgetModel.fromMap(food.id, food.toMap());
      expect(restored.limit, 9000);
      expect(restored.category, 'food');
      expect(restored.month, month);
      expect(restored.period, BudgetPeriod.monthly);
    });
  });

  group('SavingGoalModel', () {
    test('round-trips and computes progress', () {
      final SavingGoalModel goal = SavingGoalModel(
        id: 'g1',
        userId: 'uid-1',
        title: 'New Laptop',
        targetAmount: 100000,
        currentAmount: 45000,
        emoji: '💻',
        deadline: DateTime(2026, 6, 1),
      );

      final SavingGoalModel restored =
          SavingGoalModel.fromMap(goal.id, goal.toMap());

      expect(restored.title, 'New Laptop');
      expect(restored.targetAmount, 100000);
      expect(restored.currentAmount, 45000);
      expect(restored.percent, 45);
      expect(restored.remaining, 55000);
      expect(restored.reachedMilestones, [25]);
      expect(restored.emoji, '💻');
    });

    test('clamps progress at 100%', () {
      final SavingGoalModel goal = SavingGoalModel(
        id: 'g2',
        userId: 'uid-1',
        title: 'Emergency',
        targetAmount: 1000,
        currentAmount: 5000,
      );
      expect(goal.progress, 1.0);
      expect(goal.percent, 100);
      expect(goal.reachedMilestones, [25, 50, 75, 100]);
    });

    test('estimates completion from the monthly contribution', () {
      final SavingGoalModel goal = SavingGoalModel(
        id: 'g3',
        userId: 'uid-1',
        title: 'Laptop',
        targetAmount: 100000,
        currentAmount: 40000,
        monthlyContribution: 10000,
      );

      expect(goal.monthsToComplete, 6);
      expect(goal.estimatedCompletion, isNotNull);
      // The new field survives a Firestore round-trip.
      expect(goal.toMap()['monthlyContribution'], 10000);
      expect(
        SavingGoalModel.fromMap(goal.id, goal.toMap()).monthlyContribution,
        10000,
      );
    });

    test('has no estimate without a monthly contribution', () {
      const SavingGoalModel goal = SavingGoalModel(
        id: 'g4',
        userId: 'uid-1',
        title: 'Emergency',
        targetAmount: 1000,
      );
      expect(goal.monthsToComplete, isNull);
      expect(goal.estimatedCompletion, isNull);
    });
  });

  group('SubscriptionModel', () {
    test('round-trips and normalises cost per month', () {
      final SubscriptionModel sub = SubscriptionModel(
        id: 's1',
        userId: 'uid-1',
        name: 'ChatGPT Plus',
        amount: 1200,
        billingDate: DateTime(2026, 2, 5),
        cycle: BillingCycle.yearly,
        emoji: '🤖',
      );

      final SubscriptionModel restored =
          SubscriptionModel.fromMap(sub.id, sub.toMap());

      expect(restored.name, 'ChatGPT Plus');
      expect(restored.cycle, BillingCycle.yearly);
      // 1200 per year ≈ 100 per month.
      expect(restored.monthlyCost, closeTo(100, 0.01));
    });
  });

  group('ChallengeModel & LearningModel', () {
    test('challenge round-trips with progress', () {
      final ChallengeModel challenge = ChallengeModel(
        id: 'c1',
        title: '30 Days Saving Challenge',
        description: 'Save daily',
        targetDays: 30,
        progressDays: 15,
        joined: true,
      );

      final ChallengeModel restored =
          ChallengeModel.fromMap(challenge.id, challenge.toMap());

      expect(restored.targetDays, 30);
      expect(restored.progressDays, 15);
      expect(restored.percent, 50);
      expect(restored.joined, isTrue);
    });

    test('learning article round-trips', () {
      final LearningModel article = LearningModel(
        id: 'l1',
        title: 'Budgeting 101',
        category: 'Budgeting',
        summary: 'The 50-30-20 rule',
        content: 'Body text',
        readMinutes: 5,
        emoji: '📊',
        published: false,
      );

      final LearningModel restored =
          LearningModel.fromMap(article.id, article.toMap());

      expect(restored.title, 'Budgeting 101');
      expect(restored.readMinutes, 5);
      expect(restored.published, isFalse);
      expect(restored.category, 'Budgeting');
    });
  });

  group('AppNotificationModel & BadgeModel', () {
    test('notification round-trips including its type', () {
      final AppNotificationModel notification = AppNotificationModel(
        id: 'n1',
        userId: 'uid-1',
        title: 'Food budget at 82%',
        body: 'Slow down',
        type: AppNotificationType.budget,
        createdAt: DateTime(2026, 2, 14, 9),
      );

      final AppNotificationModel restored =
          AppNotificationModel.fromMap(notification.id, notification.toMap());

      expect(restored.title, 'Food budget at 82%');
      expect(restored.type, AppNotificationType.budget);
      expect(restored.read, isFalse);
      expect(restored.createdAt, DateTime(2026, 2, 14, 9));
    });

    test('badge catalogue has unique keys and is fully defined', () {
      expect(BadgeCatalog.all, isNotEmpty);
      final Set<String> keys =
          BadgeCatalog.all.map((BadgeModel b) => b.key).toSet();
      expect(keys.length, BadgeCatalog.all.length);
      for (final BadgeModel badge in BadgeCatalog.all) {
        expect(badge.title, isNotEmpty);
        expect(badge.description, isNotEmpty);
      }
    });

    test('badge unlock state merges over the catalogue definition', () {
      const BadgeModel template = BadgeModel(
        id: 'first_budget',
        key: 'first_budget',
        title: 'First Budget',
        description: 'Created your first budget',
      );
      final BadgeModel unlocked =
          template.copyWith(unlocked: true, unlockedAt: DateTime(2026, 2, 1));
      expect(unlocked.unlocked, isTrue);
      expect(unlocked.title, 'First Budget');
    });
  });

  group('AppConfig', () {
    test('exposes a valid currency list', () {
      expect(AppConfig.currencies, isNotEmpty);
      final Set<String> codes =
          AppConfig.currencies.map((CurrencyOption c) => c.code).toSet();
      expect(codes.length, AppConfig.currencies.length);
      for (final CurrencyOption option in AppConfig.currencies) {
        expect(option.symbol, isNotEmpty);
        expect(option.label, isNotEmpty);
      }
    });
  });

  group('UI smoke', () {
    testWidgets('splash screen renders the brand mark and tagline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: lightTheme, home: const SplashScreen()),
      );
      await tester.pump();

      expect(find.text('PennyPal'), findsOneWidget);
      expect(find.text('Fresh All Along'), findsOneWidget);
      expect(find.text('Loading'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // `flutter_animate` schedules zero-duration timers as its chain starts.
      // Advance the fake clock so none are left pending when the tree is torn
      // down. (pumpAndSettle cannot be used: the indeterminate bar repeats.)
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    });
  });
}
