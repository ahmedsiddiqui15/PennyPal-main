class UserProfileRecord {
  const UserProfileRecord({
    required this.id,
    required this.userId,
    this.profileImagePath,
    required this.updatedAt,
  });

  final int id;
  final String userId;
  final String? profileImagePath;
  final DateTime updatedAt;

  factory UserProfileRecord.fromMap(Map<String, Object?> map) {
    return UserProfileRecord(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      profileImagePath: map['profile_image_path'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'profile_image_path': profileImagePath,
        'updated_at': updatedAt.toIso8601String(),
      };
}
