import '../core/utils/json_utils.dart';

enum BillingCycle {
  monthly('Monthly'),
  quarterly('Quarterly'),
  yearly('Yearly');

  const BillingCycle(this.label);
  final String label;

  static BillingCycle fromKey(String? key) => BillingCycle.values.firstWhere(
        (c) => c.name.toLowerCase() == (key ?? '').toLowerCase(),
        orElse: () => BillingCycle.monthly,
      );

  
  double monthlyFactor() => switch (this) {
        BillingCycle.monthly => 1,
        BillingCycle.quarterly => 1 / 3,
        BillingCycle.yearly => 1 / 12,
      };
}

class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.billingDate,
    this.cycle = BillingCycle.monthly,
    this.emoji = '📺',
    this.colorValue = 0xFFEF4444,
    this.active = true,
    this.notes = '',
    this.lastPaidAt,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final double amount;
  final DateTime billingDate;
  final BillingCycle cycle;
  final String emoji;
  final int colorValue;
  final bool active;
  final String notes;
  final DateTime? lastPaidAt;
  final DateTime? createdAt;

  double get monthlyCost => amount * cycle.monthlyFactor();

  
  int get daysUntilBilling {
    final DateTime now = DateTime.now();
    DateTime next = DateTime(now.year, now.month, billingDate.day);
    if (next.isBefore(DateTime(now.year, now.month, now.day))) {
      next = DateTime(now.year, now.month + 1, billingDate.day);
    }
    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  SubscriptionModel copyWith({
    String? name,
    double? amount,
    DateTime? billingDate,
    BillingCycle? cycle,
    String? emoji,
    int? colorValue,
    bool? active,
    String? notes,
    DateTime? lastPaidAt,
  }) =>
      SubscriptionModel(
        id: id,
        userId: userId,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        billingDate: billingDate ?? this.billingDate,
        cycle: cycle ?? this.cycle,
        emoji: emoji ?? this.emoji,
        colorValue: colorValue ?? this.colorValue,
        active: active ?? this.active,
        notes: notes ?? this.notes,
        lastPaidAt: lastPaidAt ?? this.lastPaidAt,
        createdAt: createdAt,
      );

  
  SubscriptionModel copyWithId(String id) => SubscriptionModel(
        id: id,
        userId: userId,
        name: name,
        amount: amount,
        billingDate: billingDate,
        cycle: cycle,
        emoji: emoji,
        colorValue: colorValue,
        active: active,
        notes: notes,
        lastPaidAt: lastPaidAt,
        createdAt: createdAt,
      );

  factory SubscriptionModel.fromMap(String id, Map<String, dynamic> map) =>
      SubscriptionModel(
        id: id,
        userId: asString(map['userId']),
        name: asString(map['name'], 'Subscription'),
        amount: asDouble(map['amount']),
        billingDate: asDateTime(map['billingDate']),
        cycle: BillingCycle.fromKey(map['cycle'] as String?),
        emoji: asString(map['emoji'], '📺'),
        colorValue: asInt(map['colorValue'], 0xFFEF4444),
        active: asBool(map['active'], true),
        notes: asString(map['notes']),
        lastPaidAt: asDateTimeOrNull(map['lastPaidAt']),
        createdAt: asDateTimeOrNull(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'amount': amount,
        'billingDate': billingDate.toIso8601String(),
        'cycle': cycle.name,
        'emoji': emoji,
        'colorValue': colorValue,
        'active': active,
        'notes': notes,
        'lastPaidAt': lastPaidAt?.toIso8601String(),
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };
}
