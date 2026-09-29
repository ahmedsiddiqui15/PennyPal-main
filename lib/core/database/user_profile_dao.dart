import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import '../../features/student/profile/data/user_profile_record.dart';

class UserProfileDao {
  UserProfileDao({Database? database}) : _database = database;

  Database? _database;

  Future<Database> get _db async => _database ??= await AppDatabase.instance();

  Future<UserProfileRecord?> getByUserId(String userId) async {
    final Database db = await _db;
    final List<Map<String, Object?>> rows = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: <Object>[userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserProfileRecord.fromMap(rows.first);
  }

  Future<UserProfileRecord> upsertImagePath({
    required String userId,
    required String? imagePath,
  }) async {
    final Database db = await _db;
    final DateTime now = DateTime.now().toUtc();
    final UserProfileRecord? existing = await getByUserId(userId);

    if (existing == null) {
      final int id = await db.insert(
        'user_profile',
        <String, Object?>{
          'user_id': userId,
          'profile_image_path': imagePath,
          'updated_at': now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return UserProfileRecord(
        id: id,
        userId: userId,
        profileImagePath: imagePath,
        updatedAt: now,
      );
    }

    await db.update(
      'user_profile',
      <String, Object?>{
        'profile_image_path': imagePath,
        'updated_at': now.toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: <Object>[userId],
    );

    return UserProfileRecord(
      id: existing.id,
      userId: userId,
      profileImagePath: imagePath,
      updatedAt: now,
    );
  }

  Future<void> clearImagePath(String userId) async {
    await upsertImagePath(userId: userId, imagePath: null);
  }
}
