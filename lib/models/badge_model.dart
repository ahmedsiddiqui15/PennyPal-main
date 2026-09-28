import '../core/utils/json_utils.dart';

class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    this.emoji = '🏅',
    this.colorValue = 0xFFF59E0B,
    this.unlocked = false,
    this.unlockedAt,
  });

  final String id;
  final String key;
  final String title;
  final String description;
  final String emoji;
  final int colorValue;
  final bool unlocked;
  final DateTime? unlockedAt;

  BadgeModel copyWith({bool? unlocked, DateTime? unlockedAt}) => BadgeModel(
        id: id,
        key: key,
        title: title,
        description: description,
        emoji: emoji,
        colorValue: colorValue,
        unlocked: unlocked ?? this.unlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );

  factory BadgeModel.fromMap(String id, Map<String, dynamic> map) => BadgeModel(
        id: id,
        key: asString(map['key'], id),
        title: asString(map['title'], 'Badge'),
        description: asString(map['description']),
        emoji: asString(map['emoji'], '🏅'),
        colorValue: asInt(map['colorValue'], 0xFFF59E0B),
        unlocked: asBool(map['unlocked']),
        unlockedAt: asDateTimeOrNull(map['unlockedAt']),
      );

  Map<String, dynamic> toMap() => {
        'key': key,
        'title': title,
        'description': description,
        'emoji': emoji,
        'colorValue': colorValue,
        'unlocked': unlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };
}

class BadgeCatalog {
  BadgeCatalog._();

  static const List<BadgeModel> all = [
    BadgeModel(
      id: 'first_budget',
      key: 'first_budget',
      title: 'First Budget',
      description: 'Created your very first monthly budget.',
      emoji: '🎯',
      colorValue: 0xFFF59E0B,
    ),
    BadgeModel(
      id: 'seven_day_saver',
      key: 'seven_day_saver',
      title: '7 Day Saver',
      description: 'Logged expenses 7 days in a row.',
      emoji: '🔥',
      colorValue: 0xFFF97316,
    ),
    BadgeModel(
      id: 'expense_master',
      key: 'expense_master',
      title: 'Expense Master',
      description: 'Recorded 50 expenses.',
      emoji: '🧾',
      colorValue: 0xFF3B82F6,
    ),
    BadgeModel(
      id: 'goal_getter',
      key: 'goal_getter',
      title: 'Goal Getter',
      description: 'Completed a savings goal.',
      emoji: '🏆',
      colorValue: 0xFF16A34A,
    ),
    BadgeModel(
      id: 'budget_keeper',
      key: 'budget_keeper',
      title: 'Budget Keeper',
      description: 'Stayed under budget for a full month.',
      emoji: '🛡️',
      colorValue: 0xFF8B5CF6,
    ),
    BadgeModel(
      id: 'learner',
      key: 'learner',
      title: 'Money Scholar',
      description: 'Read 5 financial lessons.',
      emoji: '📚',
      colorValue: 0xFF06B6D4,
    ),
    BadgeModel(
      id: 'receipt_scanner',
      key: 'receipt_scanner',
      title: 'Receipt Scanner',
      description: 'Scanned your first receipt.',
      emoji: '📸',
      colorValue: 0xFFEC4899,
    ),
    BadgeModel(
      id: 'ai_explorer',
      key: 'ai_explorer',
      title: 'AI Explorer',
      description: 'Asked Penny AI 10 questions.',
      emoji: '🤖',
      colorValue: 0xFF6366F1,
    ),
  ];
}
