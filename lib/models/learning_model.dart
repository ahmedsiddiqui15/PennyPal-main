import '../core/utils/json_utils.dart';

class LearningModel {
  const LearningModel({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.content,
    this.readMinutes = 3,
    this.emoji = '📘',
    this.author = 'PennyPal Team',
    this.published = true,
    this.createdAt,
  });

  final String id;
  final String title;

  
  final String category;
  final String summary;
  final String content;
  final int readMinutes;
  final String emoji;
  final String author;
  final bool published;
  final DateTime? createdAt;

  LearningModel copyWith({
    String? title,
    String? category,
    String? summary,
    String? content,
    int? readMinutes,
    String? emoji,
    String? author,
    bool? published,
  }) =>
      LearningModel(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        summary: summary ?? this.summary,
        content: content ?? this.content,
        readMinutes: readMinutes ?? this.readMinutes,
        emoji: emoji ?? this.emoji,
        author: author ?? this.author,
        published: published ?? this.published,
        createdAt: createdAt,
      );

  
  LearningModel copyWithId(String id) => LearningModel(
        id: id,
        title: title,
        category: category,
        summary: summary,
        content: content,
        readMinutes: readMinutes,
        emoji: emoji,
        author: author,
        published: published,
        createdAt: createdAt,
      );

  factory LearningModel.fromMap(String id, Map<String, dynamic> map) =>
      LearningModel(
        id: id,
        title: asString(map['title'], 'Untitled'),
        category: asString(map['category'], 'Budgeting'),
        summary: asString(map['summary']),
        content: asString(map['content']),
        readMinutes: asInt(map['readMinutes'], 3),
        emoji: asString(map['emoji'], '📘'),
        author: asString(map['author'], 'PennyPal Team'),
        published: asBool(map['published'], true),
        createdAt: asDateTimeOrNull(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'summary': summary,
        'content': content,
        'readMinutes': readMinutes,
        'emoji': emoji,
        'author': author,
        'published': published,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };
}
