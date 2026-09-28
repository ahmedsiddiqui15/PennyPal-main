import '../core/constants/app_enums.dart';
import '../core/utils/json_utils.dart';

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.userId,
    required this.limit,
    this.category,
    this.period = BudgetPeriod.monthly,
    required this.month,
    this.createdAt,
  });

  final String id;
  final String userId;
  final double limit;

  
  final String? category;
  final BudgetPeriod period;

  
  final DateTime month;
  final DateTime? createdAt;

  bool get isMaster => category == null;

  String get categoryLabel => category == null
      ? 'Overall Budget'
      : ExpenseCategory.fromKey(category).label;

  BudgetModel copyWith({
    double? limit,
    String? category,
    BudgetPeriod? period,
    DateTime? month,
  }) =>
      BudgetModel(
        id: id,
        userId: userId,
        limit: limit ?? this.limit,
        category: category ?? this.category,
        period: period ?? this.period,
        month: month ?? this.month,
        createdAt: createdAt,
      );

  
  BudgetModel copyWithId(String id) => BudgetModel(
        id: id,
        userId: userId,
        limit: limit,
        category: category,
        period: period,
        month: month,
        createdAt: createdAt,
      );

  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) => BudgetModel(
        id: id,
        userId: asString(map['userId']),
        limit: asDouble(map['limit']),
        category: map['category'] as String?,
        period: BudgetPeriod.fromKey(map['period'] as String?),
        month: asDateTime(map['month']),
        createdAt: asDateTimeOrNull(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'limit': limit,
        'category': category,
        'period': period.name,
        'month': month.toIso8601String(),
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };
}
