import '../core/utils/json_utils.dart';

class SavingGoalModel {
  const SavingGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.monthlyContribution = 0,
    this.deadline,
    this.emoji = '🎯',
    this.colorValue = 0xFFF59E0B,
    this.completed = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;

  
  
  final double monthlyContribution;
  final DateTime? deadline;
  final String emoji;
  final int colorValue;
  final bool completed;
  final DateTime? createdAt;

  
  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  int get percent => (progress * 100).round();

  
  List<int> get reachedMilestones =>
      [25, 50, 75, 100].where((m) => percent >= m).toList();

  int get daysLeft =>
      deadline == null ? 0 : deadline!.difference(DateTime.now()).inDays;

  
  
  
  
  int? get monthsToComplete {
    if (remaining <= 0 || monthlyContribution <= 0) return null;
    return (remaining / monthlyContribution).ceil();
  }

  
  
  
  DateTime? get estimatedCompletion {
    final int? months = monthsToComplete;
    if (months == null) return null;
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month + months, now.day);
  }

  SavingGoalModel copyWith({
    String? title,
    double? targetAmount,
    double? currentAmount,
    double? monthlyContribution,
    DateTime? deadline,
    String? emoji,
    int? colorValue,
    bool? completed,
  }) =>
      SavingGoalModel(
        id: id,
        userId: userId,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        monthlyContribution: monthlyContribution ?? this.monthlyContribution,
        deadline: deadline ?? this.deadline,
        emoji: emoji ?? this.emoji,
        colorValue: colorValue ?? this.colorValue,
        completed: completed ?? this.completed,
        createdAt: createdAt,
      );

  
  SavingGoalModel copyWithId(String id) => SavingGoalModel(
        id: id,
        userId: userId,
        title: title,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        monthlyContribution: monthlyContribution,
        deadline: deadline,
        emoji: emoji,
        colorValue: colorValue,
        completed: completed,
        createdAt: createdAt,
      );

  factory SavingGoalModel.fromMap(String id, Map<String, dynamic> map) =>
      SavingGoalModel(
        id: id,
        userId: asString(map['userId']),
        title: asString(map['title'], 'Savings goal'),
        targetAmount: asDouble(map['targetAmount']),
        currentAmount: asDouble(map['currentAmount']),
        monthlyContribution: asDouble(map['monthlyContribution']),
        deadline: asDateTimeOrNull(map['deadline']),
        emoji: asString(map['emoji'], '🎯'),
        colorValue: asInt(map['colorValue'], 0xFFF59E0B),
        completed: asBool(map['completed']),
        createdAt: asDateTimeOrNull(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'monthlyContribution': monthlyContribution,
        'deadline': deadline?.toIso8601String(),
        'emoji': emoji,
        'colorValue': colorValue,
        'completed': completed,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };
}
