import '../core/constants/app_enums.dart';
import '../core/utils/json_utils.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl,
    this.role = UserRole.student,
    this.currencyCode = 'PKR',
    this.currencySymbol = 'Rs.',
    this.monthlyIncomeGoal = 0,
    this.notificationsEnabled = true,
    this.emailUpdates = false,
    this.themeMode = 'system',
    this.blocked = false,
    this.streakDays = 0,
    this.createdAt,
    this.lastActiveAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final UserRole role;
  final String currencyCode;
  final String currencySymbol;
  final double monthlyIncomeGoal;
  final bool notificationsEnabled;
  final bool emailUpdates;

  
  final String themeMode;
  final bool blocked;
  final int streakDays;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  bool get isAdmin => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;

  
  String get firstName => name.trim().isEmpty ? 'there' : name.trim().split(' ').first;

  factory UserModel.fromMap(String id, Map<String, dynamic> map) => UserModel(
        id: id,
        name: asString(map['name'], 'PennyPal User'),
        email: asString(map['email']),
        phone: asString(map['phone']),
        photoUrl: map['photoUrl'] as String?,
        role: UserRole.fromKey(map['role'] as String?),
        currencyCode: asString(map['currencyCode'], 'PKR'),
        currencySymbol: asString(map['currencySymbol'], 'Rs.'),
        monthlyIncomeGoal: asDouble(map['monthlyIncomeGoal']),
        notificationsEnabled: asBool(map['notificationsEnabled'], true),
        emailUpdates: asBool(map['emailUpdates']),
        themeMode: asString(map['themeMode'], 'system'),
        blocked: asBool(map['blocked']),
        streakDays: asInt(map['streakDays']),
        createdAt: asDateTimeOrNull(map['createdAt']),
        lastActiveAt: asDateTimeOrNull(map['lastActiveAt']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'role': role.name,
        'currencyCode': currencyCode,
        'currencySymbol': currencySymbol,
        'monthlyIncomeGoal': monthlyIncomeGoal,
        'notificationsEnabled': notificationsEnabled,
        'emailUpdates': emailUpdates,
        'themeMode': themeMode,
        'blocked': blocked,
        'streakDays': streakDays,
        'createdAt': createdAt?.toIso8601String(),
        'lastActiveAt': lastActiveAt?.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    UserRole? role,
    String? currencyCode,
    String? currencySymbol,
    double? monthlyIncomeGoal,
    bool? notificationsEnabled,
    bool? emailUpdates,
    String? themeMode,
    bool? blocked,
    int? streakDays,
    DateTime? lastActiveAt,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        currencyCode: currencyCode ?? this.currencyCode,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        monthlyIncomeGoal: monthlyIncomeGoal ?? this.monthlyIncomeGoal,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        emailUpdates: emailUpdates ?? this.emailUpdates,
        themeMode: themeMode ?? this.themeMode,
        blocked: blocked ?? this.blocked,
        streakDays: streakDays ?? this.streakDays,
        createdAt: createdAt,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      );
}
