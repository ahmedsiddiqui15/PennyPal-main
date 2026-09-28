import '../core/constants/app_enums.dart';
import '../core/utils/json_utils.dart';

class SupportModel {
  const SupportModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail = '',
    this.subject = '',
    this.message = '',
    this.rating = 0,
    this.isFeedback = false,
    this.status = SupportStatus.pending,
    this.response = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String message;

  
  final int rating;
  final bool isFeedback;
  final SupportStatus status;
  final String response;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SupportModel copyWith({
    SupportStatus? status,
    String? response,
    DateTime? updatedAt,
  }) =>
      SupportModel(
        id: id,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        subject: subject,
        message: message,
        rating: rating,
        isFeedback: isFeedback,
        status: status ?? this.status,
        response: response ?? this.response,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  
  SupportModel copyWithId(String id) => SupportModel(
        id: id,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        subject: subject,
        message: message,
        rating: rating,
        isFeedback: isFeedback,
        status: status,
        response: response,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory SupportModel.fromMap(String id, Map<String, dynamic> map) => SupportModel(
        id: id,
        userId: asString(map['userId']),
        userName: asString(map['userName'], 'Student'),
        userEmail: asString(map['userEmail']),
        subject: asString(map['subject']),
        message: asString(map['message']),
        rating: asInt(map['rating']),
        isFeedback: asBool(map['isFeedback']),
        status: SupportStatus.fromKey(map['status'] as String?),
        response: asString(map['response']),
        createdAt: asDateTimeOrNull(map['createdAt']),
        updatedAt: asDateTimeOrNull(map['updatedAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'subject': subject,
        'message': message,
        'rating': rating,
        'isFeedback': isFeedback,
        'status': status.name,
        'response': response,
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
        'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
      };
}
