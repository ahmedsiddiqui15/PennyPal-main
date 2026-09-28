import '../core/constants/app_enums.dart';
import '../core/utils/json_utils.dart';
import 'expense_model.dart' show EntrySource;

class IncomeModel {
  const IncomeModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.description = '',
    required this.date,
    this.source = EntrySource.manual,
    this.createdAt,
  });

  final String id;
  final String userId;
  final double amount;
  final IncomeCategory category;
  final String description;
  final DateTime date;
  final EntrySource source;
  final DateTime? createdAt;

  IncomeModel copyWith({
    double? amount,
    IncomeCategory? category,
    String? description,
    DateTime? date,
    EntrySource? source,
  }) =>
      IncomeModel(
        id: id,
        userId: userId,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        description: description ?? this.description,
        date: date ?? this.date,
        source: source ?? this.source,
        createdAt: createdAt,
      );

  
  IncomeModel copyWithId(String id) => IncomeModel(
        id: id,
        userId: userId,
        amount: amount,
        category: category,
        description: description,
        date: date,
        source: source,
        createdAt: createdAt,
      );

  factory IncomeModel.fromMap(String id, Map<String, dynamic> map) => IncomeModel(
        id: id,
        userId: asString(map['userId']),
        amount: asDouble(map['amount']),
        category: IncomeCategory.fromKey(map['category'] as String?),
        description: asString(map['description']),
        date: asDateTime(map['date']),
        source: EntrySource.fromKey(map['source'] as String?),
        createdAt: asDateTimeOrNull(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'amount': amount,
        'category': category.name,
        'description': description,
        'date': date.toIso8601String(),
        'source': source.name,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };
}
