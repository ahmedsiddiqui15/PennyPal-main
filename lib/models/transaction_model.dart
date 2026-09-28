import '../core/constants/app_enums.dart';
import '../core/utils/json_utils.dart';
import 'expense_model.dart';
import 'income_model.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.categoryKey,
    required this.categoryLabel,
    required this.date,
    this.description = '',
    this.receiptUrl,
    this.source = EntrySource.manual,
    this.createdAt,
  });

  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String categoryKey;
  final String categoryLabel;
  final String description;
  final DateTime date;
  final String? receiptUrl;
  final EntrySource source;
  final DateTime? createdAt;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  
  double get signedAmount => isIncome ? amount : -amount;

  
  factory TransactionModel.fromExpense(ExpenseModel e) => TransactionModel(
        id: e.id,
        userId: e.userId,
        type: TransactionType.expense,
        amount: e.amount,
        categoryKey: e.category.name,
        categoryLabel: e.category.label,
        description: e.description,
        date: e.date,
        receiptUrl: e.receiptUrl,
        source: e.source,
        createdAt: e.createdAt,
      );

  factory TransactionModel.fromIncome(IncomeModel i) => TransactionModel(
        id: i.id,
        userId: i.userId,
        type: TransactionType.income,
        amount: i.amount,
        categoryKey: i.category.name,
        categoryLabel: i.category.label,
        description: i.description,
        date: i.date,
        source: i.source,
        createdAt: i.createdAt,
      );

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) =>
      TransactionModel(
        id: id,
        userId: asString(map['userId']),
        type: TransactionType.fromKey(map['type'] as String?),
        amount: asDouble(map['amount']),
        categoryKey: asString(map['categoryKey'], 'other'),
        categoryLabel: asString(map['categoryLabel'], 'Other'),
        description: asString(map['description']),
        date: asDateTime(map['date']),
        receiptUrl: map['receiptUrl'] as String?,
        source: EntrySource.fromKey(map['source'] as String?),
        createdAt: asDateTimeOrNull(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.name,
        'amount': amount,
        'categoryKey': categoryKey,
        'categoryLabel': categoryLabel,
        'description': description,
        'date': date.toIso8601String(),
        'receiptUrl': receiptUrl,
        'source': source.name,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };

  
  ExpenseModel toExpense() => ExpenseModel(
        id: id,
        userId: userId,
        amount: amount,
        category: ExpenseCategory.fromKey(categoryKey),
        description: description,
        date: date,
        receiptUrl: receiptUrl,
        source: source,
        createdAt: createdAt,
      );

  IncomeModel toIncome() => IncomeModel(
        id: id,
        userId: userId,
        amount: amount,
        category: IncomeCategory.fromKey(categoryKey),
        description: description,
        date: date,
        source: source,
        createdAt: createdAt,
      );
}
