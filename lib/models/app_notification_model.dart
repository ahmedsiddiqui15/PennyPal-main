import '../core/utils/json_utils.dart';

enum AppNotificationType {
  budget('Budget Alert', '💰'),
  saving('Saving Reminder', '🐖'),
  tip('Financial Tip', '💡'),
  system('System', '🔔'),
  badge('Achievement', '🏅');

  const AppNotificationType(this.label, this.emoji);
  final String label;
  final String emoji;

  static AppNotificationType fromKey(String? key) =>
      AppNotificationType.values.firstWhere(
        (t) => t.name.toLowerCase() == (key ?? '').toLowerCase(),
        orElse: () => AppNotificationType.system,
      );
}

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = AppNotificationType.system,
    this.read = false,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final AppNotificationType type;
  final bool read;
  final DateTime createdAt;

  AppNotificationModel copyWith({bool? read}) => AppNotificationModel(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        read: read ?? this.read,
        createdAt: createdAt,
      );

  factory AppNotificationModel.fromMap(String id, Map<String, dynamic> map) =>
      AppNotificationModel(
        id: id,
        userId: asString(map['userId']),
        title: asString(map['title']),
        body: asString(map['body']),
        type: AppNotificationType.fromKey(map['type'] as String?),
        read: asBool(map['read']),
        createdAt: asDateTime(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
      };
}
