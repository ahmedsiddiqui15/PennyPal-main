import '../core/utils/json_utils.dart';

class ChallengeModel {
  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDays,
    this.progressDays = 0,
    this.reward = '500 points',
    this.emoji = '💪',
    this.joined = false,
    this.active = true,
    this.completed = false,
    this.joinedAt,
  });

  final String id;
  final String title;
  final String description;
  final int targetDays;
  final int progressDays;
  final String reward;
  final String emoji;
  final bool joined;
  final bool active;
  final bool completed;
  final DateTime? joinedAt;

  double get progress =>
      targetDays <= 0 ? 0 : (progressDays / targetDays).clamp(0.0, 1.0);

  int get percent => (progress * 100).round();

  ChallengeModel copyWith({
    int? progressDays,
    bool? joined,
    bool? completed,
    DateTime? joinedAt,
  }) =>
      ChallengeModel(
        id: id,
        title: title,
        description: description,
        targetDays: targetDays,
        progressDays: progressDays ?? this.progressDays,
        reward: reward,
        emoji: emoji,
        joined: joined ?? this.joined,
        active: active,
        completed: completed ?? this.completed,
        joinedAt: joinedAt ?? this.joinedAt,
      );

  
  ChallengeModel copyWithId(String id) => ChallengeModel(
        id: id,
        title: title,
        description: description,
        targetDays: targetDays,
        progressDays: progressDays,
        reward: reward,
        emoji: emoji,
        joined: joined,
        active: active,
        completed: completed,
        joinedAt: joinedAt,
      );

  factory ChallengeModel.fromMap(String id, Map<String, dynamic> map) =>
      ChallengeModel(
        id: id,
        title: asString(map['title'], 'Challenge'),
        description: asString(map['description']),
        targetDays: asInt(map['targetDays'], 30),
        progressDays: asInt(map['progressDays']),
        reward: asString(map['reward'], '500 points'),
        emoji: asString(map['emoji'], '💪'),
        joined: asBool(map['joined']),
        active: asBool(map['active'], true),
        completed: asBool(map['completed']),
        joinedAt: asDateTimeOrNull(map['joinedAt']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'targetDays': targetDays,
        'progressDays': progressDays,
        'reward': reward,
        'emoji': emoji,
        'joined': joined,
        'active': active,
        'completed': completed,
        'joinedAt': joinedAt?.toIso8601String(),
      };
}
