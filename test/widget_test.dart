import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennypal/core/constants/app_enums.dart';
import 'package:pennypal/core/utils/currency_converter.dart';
import 'package:pennypal/core/utils/finance_math.dart';
import 'package:pennypal/core/utils/formatters.dart';
import 'package:pennypal/core/utils/validators.dart';
import 'package:pennypal/core/widgets/app_avatar.dart';
import 'package:pennypal/models/expense_model.dart';
import 'package:pennypal/models/financial_snapshot.dart';
import 'package:pennypal/models/income_model.dart';
import 'package:pennypal/models/transaction_model.dart';
import 'package:pennypal/services/ocr/receipt_ocr.dart';
import 'package:pennypal/services/voice_service.dart';

/// A 1x1 transparent PNG so `Image.memory` decodes cleanly in widget tests.
const List<int> _pngBytes = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
  0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54,
  0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01,
  0x0D, 0x0A, 0x2D, 0xB4,
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

void main() {
  group('Formatters', () {
    test('formats money with grouping and symbol', () {
      expect(Formatters.money(25500), 'Rs.25,500');
      expect(Formatters.money(1500, symbol: r'$'), r'$1,500.00');
      expect(Formatters.money(-250), '-Rs.250');
    });

    test('keeps decimals for fractional amounts', () {
      expect(Formatters.money(10.5, symbol: r'$'), r'$10.50');
      expect(Formatters.money(10.5, symbol: 'Rs.'), 'Rs.10.50');
    });

    test('compacts large amounts', () {
      expect(Formatters.compact(1500), 'Rs.1.5K');
      expect(Formatters.compact(2500000), 'Rs.2.5M');
    });

    test('derives initials', () {
      expect(Formatters.initials('Ahmed Raza'), 'AR');
      expect(Formatters.initials('Sara'), 'SA');
    });
  });

  group('CurrencyConverter', () {
    test('converts PKR to USD approximately', () {
      expect(
        CurrencyConverter.convert(2780, fromCode: 'PKR', toCode: 'USD'),
        10,
      );
    });

    test('is identity for the same currency', () {
      expect(
        CurrencyConverter.convert(500, fromCode: 'EUR', toCode: 'EUR'),
        500,
      );
      expect(CurrencyConverter.factor(fromCode: 'GBP', toCode: 'GBP'), 1);
    });

    test('round-trips PKR through USD', () {
      final double usd =
          CurrencyConverter.convert(2780, fromCode: 'PKR', toCode: 'USD');
      final double back =
          CurrencyConverter.convert(usd, fromCode: 'USD', toCode: 'PKR');
      expect(back, closeTo(2780, 1));
    });
  });

  group('Validators', () {
    test('accepts valid emails and rejects bad ones', () {
      expect(Validators.email('student@pennypal.app'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('enforces password length', () {
      expect(Validators.password('secret123'), isNull);
      expect(Validators.password('123'), isNotNull);
    });

    test('applies the sign-up password policy', () {
      expect(Validators.password('secret123'), isNull);
      expect(Validators.password('short1'), isNotNull); // too short
      expect(Validators.password('onlyletters'), isNotNull); // no digit
      expect(Validators.password('has space1'), isNotNull);
      expect(Validators.loginPassword('secret123'), isNull);
      expect(Validators.passwordStrength('secret123'), greaterThan(0.5));
    });

    test('validates amounts', () {
      expect(Validators.amount('500'), isNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
    });

    test('only accepts letters in a name', () {
      expect(Validators.name('Ayesha Khan'), isNull);
      expect(Validators.name("O'Brien"), isNull);
      expect(Validators.name('Anne-Marie'), isNull);
      expect(Validators.name('123'), isNotNull);
      expect(Validators.name('Ali1'), isNotNull);
      expect(Validators.name('Ali@'), isNotNull);
      expect(Validators.name(''), isNotNull);
    });
  });

  group('AppAvatar', () {
    testWidgets('previews locally picked bytes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              name: 'Ahmed Raza',
              imageBytes: Uint8List.fromList(_pngBytes),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget w) => w is Image && w.image is MemoryImage,
        ),
        findsOneWidget,
      );
    });

    testWidgets('falls back to initials without an image',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppAvatar(name: 'Ahmed Raza')),
        ),
      );

      expect(find.text('AR'), findsOneWidget);
    });
  });

  group('FinanceMath', () {
    test('scores a healthy budget highly', () {
      final int score = FinanceMath.healthScore(
        monthlyIncome: 40000,
        monthlyExpenses: 20000,
        totalBudget: 30000,
      );
      expect(score, greaterThan(60));
    });

    test('predicts next month from the current burn rate', () {
      final double predicted = FinanceMath.predictNextMonth(
        currentMonthSpend: 1500,
        previousMonthSpend: 3000,
        daysElapsedInMonth: 15,
        daysInMonth: 30,
      );
      expect(predicted, closeTo(3000, 1));
    });

    test('computes growth safely when the previous value is zero', () {
      expect(FinanceMath.growth(100, 0), 1);
      expect(FinanceMath.growth(150, 100), closeTo(0.5, 0.001));
    });
  });

  group('FinancialSnapshot', () {
    test('aggregates income, expenses and category totals', () {
      final DateTime now = DateTime.now();
      final List<TransactionModel> transactions = [
        TransactionModel.fromIncome(IncomeModel(
          id: 'i1',
          userId: 'u1',
          amount: 10000,
          category: IncomeCategory.allowance,
          date: now,
        )),
        TransactionModel.fromExpense(ExpenseModel(
          id: 'e1',
          userId: 'u1',
          amount: 1500,
          category: ExpenseCategory.food,
          date: now,
        )),
        TransactionModel.fromExpense(ExpenseModel(
          id: 'e2',
          userId: 'u1',
          amount: 500,
          category: ExpenseCategory.transport,
          date: now,
        )),
      ];

      final FinancialSnapshot snapshot = FinancialSnapshot(
        transactions: transactions,
        budgets: const [],
        goals: const [],
      );

      expect(snapshot.monthIncome, 10000);
      expect(snapshot.monthExpense, 2000);
      expect(snapshot.balance, 8000);
      expect(snapshot.amountFor(ExpenseCategory.food), 1500);
      expect(snapshot.topCategory, ExpenseCategory.food);
      expect(snapshot.monthlySeries.length, 12);
    });
  });

  group('Receipt parsing', () {
    test('prefers a labeled TOTAL over larger invoice numbers', () {
      const String text =
          'STORE\nInvoice 24000\nDate 28/09/2026\nItem 80\nTOTAL 120';
      expect(extractAmount(text), 120);
    });

    test('ignores the year when no TOTAL label exists', () {
      const String text = 'Cafe Latte\n2026\nPaid 120';
      expect(extractAmount(text), 120);
    });

    test('extracts amount after a TOTAL label', () {
      const String text = 'PIZZA POINT\nBurger 450\nPizza 800\nTOTAL 1250';
      expect(extractAmount(text), 1250);
    });

    test('reads Rs. prefixed totals', () {
      expect(extractAmount('Grand Total Rs. 1,250.50'), 1250.50);
    });

    test('categorises receipts by keyword', () {
      expect(categoriseText('Pizza Point restaurant'), ExpenseCategory.food);
      expect(categoriseText('Uber ride'), ExpenseCategory.transport);
      expect(categoriseText('Electricity bill'), ExpenseCategory.bills);
    });

    test('builds a parsed receipt with confidence', () {
      final ParsedReceipt parsed = buildParsedReceipt('Cafe Total 500');
      expect(parsed.amount, 500);
      expect(parsed.category, ExpenseCategory.food);
      expect(parsed.isValid, isTrue);
    });

    test('parses EMVCo QR tag 54 as the amount', () {
      // Minimal EMV payload: payload format + amount 120.00 + merchant.
      const String qr =
          '000201'
          '5406120.00'
          '5908TestCafe'
          '6304ABCD';
      expect(extractAmountFromQrPayload(qr), 120);
      final ParsedReceipt parsed =
          buildParsedReceipt('', qrPayloads: [qr]);
      expect(parsed.amount, 120);
      expect(parsed.merchant, 'TestCafe');
      expect(parsed.isValid, isTrue);
    });

    test('parses amount= from a QR query payload', () {
      expect(
        extractAmountFromQrPayload('https://pay.example/bill?amount=350.5'),
        350.5,
      );
    });

    test('QR amount wins over noisy OCR text', () {
      final ParsedReceipt parsed = buildParsedReceipt(
        'Invoice 24000\nYear 2026\nThanks',
        qrPayloads: ['amount=120'],
      );
      expect(parsed.amount, 120);
    });
  });

  group('Voice parsing', () {
    test('parses amount and category from a sentence', () {
      final ParsedVoiceExpense parsed =
          parseVoiceExpense('I spent 500 on lunch');
      expect(parsed.amount, 500);
      expect(parsed.category, ExpenseCategory.food);
      expect(parsed.isValid, isTrue);
    });

    test('handles thousand suffixes', () {
      final ParsedVoiceExpense parsed =
          parseVoiceExpense('paid 2 thousand for books');
      expect(parsed.amount, 2000);
    });
  });

  test('percentage formatting is stable', () {
    expect(Formatters.percent(0.78), '78%');
  });
}
