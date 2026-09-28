import '../core/constants/app_enums.dart';
import '../core/utils/json_utils.dart';

enum EntrySource {
  manual,
  receipt,
  voice,
  recurring;

  static EntrySource fromKey(String? key) => EntrySource.values.firstWhere(
        (s) => s.name.toLowerCase() == (key ?? '').toLowerCase(),
        orElse: () => EntrySource.manual,
      );

  String get label => switch (this) {
        EntrySource.manual => 'Manual',
        EntrySource.receipt => 'Receipt scan',
        EntrySource.voice => 'Voice',
        EntrySource.recurring => 'Recurring',
      };
}

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.description = '',
    required this.date,
    this.receiptUrl,
    this.source = EntrySource.manual,
    this.createdAt,
  });

  final String id;
  final String userId;
  final double amount;
  final ExpenseCategory category;
  final String description;
  final DateTime date;
  final String? receiptUrl;
  final EntrySource source;
  final DateTime? createdAt;

  ExpenseModel copyWith({
    double? amount,
    ExpenseCategory? category,
    String? description,
    DateTime? date,
    String? receiptUrl,
    EntrySource? source,
  }) =>
      ExpenseModel(
        id: id,
        userId: userId,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        description: description ?? this.description,
        date: date ?? this.date,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        source: source ?? this.source,
        createdAt: createdAt,
      );

  
  ExpenseModel copyWithId(String id) => ExpenseModel(
        id: id,
        userId: userId,
        amount: amount,
        category: category,
        description: description,
        date: date,
        receiptUrl: receiptUrl,
        source: source,
        createdAt: createdAt,
      );

  factory ExpenseModel.fromMap(String id, Map<String, dynamic> map) =>
      ExpenseModel(
        id: id,
        userId: asString(map['userId']),
        amount: asDouble(map['amount']),
        category: ExpenseCategory.fromKey(map['category'] as String?),
        description: asString(map['description']),
        date: asDateTime(map['date']),
        receiptUrl: map['receiptUrl'] as String?,
        source: EntrySource.fromKey(map['source'] as String?),
        createdAt: asDateTimeOrNull(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'amount': amount,
        'category': category.name,
        'description': description,
        'date': date.toIso8601String(),
        'receiptUrl': receiptUrl,
        'source': source.name,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };
}
