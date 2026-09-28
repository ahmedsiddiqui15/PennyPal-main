import 'package:flutter/material.dart';

enum ChatRole { user, assistant }

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.isTyping = false,
  }) : timestamp = timestamp ?? DateTime.now();

  final ChatRole role;
  final String text;
  final DateTime timestamp;

  
  final bool isTyping;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({String? text, bool? isTyping}) => ChatMessage(
        role: role,
        text: text ?? this.text,
        timestamp: timestamp,
        isTyping: isTyping ?? this.isTyping,
      );

  static ChatMessage typing() =>
      ChatMessage(role: ChatRole.assistant, text: '', isTyping: true);
}

class InsightModel {
  const InsightModel({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    this.severity = InsightSeverity.info,
  });

  final String id;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final InsightSeverity severity;
}

enum InsightSeverity {
  positive(Color(0xFF16A34A), Icons.trending_up_rounded),
  warning(Color(0xFFF59E0B), Icons.warning_amber_rounded),
  negative(Color(0xFFEF4444), Icons.trending_down_rounded),
  info(Color(0xFF3B82F6), Icons.lightbulb_outline_rounded);

  const InsightSeverity(this.color, this.icon);
  final Color color;
  final IconData icon;
}
