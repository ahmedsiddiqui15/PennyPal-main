import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../core/database/user_profile_dao.dart';
import '../features/student/profile/data/user_profile_record.dart';

class ProfileImageException implements Exception {
  const ProfileImageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileImageService {
  ProfileImageService({
    UserProfileDao? dao,
    ImagePicker? picker,
    Uuid? uuid,
  })  : _dao = dao ?? UserProfileDao(),
        _picker = picker ?? ImagePicker(),
        _uuid = uuid ?? const Uuid();

  final UserProfileDao _dao;
  final ImagePicker _picker;
  final Uuid _uuid;

  static const int maxBytes = 5 * 1024 * 1024;
  static const Set<String> allowedExtensions = <String>{
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.heif',
  };

  Future<String?> getLocalImagePath(String userId) async {
    final UserProfileRecord? record = await _dao.getByUserId(userId);
    final String? path = record?.profileImagePath;
    if (path == null || path.isEmpty) return null;
    final File file = File(path);
    if (!await file.exists()) return null;
    return path;
  }

  Future<UserProfileRecord?> getProfileRecord(String userId) {
    return _dao.getByUserId(userId);
  }

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) {
    return _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
  }

  Future<String> savePickedImage({
    required String userId,
    required XFile picked,
  }) async {
    if (userId.trim().isEmpty) {
      throw const ProfileImageException('User is not authenticated.');
    }

    final String extension = _normalizeExtension(picked.path, picked.name);
    if (!allowedExtensions.contains(extension)) {
      throw ProfileImageException(
        'Unsupported image format ($extension). Use JPG, PNG, or WEBP.',
      );
    }

    final File sourceFile = File(picked.path);
    if (!await sourceFile.exists()) {
      throw const ProfileImageException(
        'Selected image is no longer available. Please choose another.',
      );
    }

    final Uint8List bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw const ProfileImageException('Selected image is empty.');
    }
    if (bytes.lengthInBytes > maxBytes) {
      throw const ProfileImageException(
        'Image is too large. Please choose a file under 5 MB.',
      );
    }

    final Directory dir = await AppDatabase.profileImagesDirectory();
    final String uniqueId = _uuid.v4().replaceAll('-', '');
    final String safeUserId = _sanitizeUserId(userId);
    final String fileName = 'user_${safeUserId}_$uniqueId$extension';
    final String destPath = p.join(dir.path, fileName);
    final File destFile = File(destPath);

    await destFile.writeAsBytes(bytes, flush: true);

    if (!await destFile.exists()) {
      throw const ProfileImageException('Failed to save image locally.');
    }

    final String? previousPath = await getLocalImagePath(userId);
    await _dao.upsertImagePath(userId: userId, imagePath: destPath);

    if (previousPath != null &&
        previousPath.isNotEmpty &&
        previousPath != destPath) {
      await _deleteFileQuietly(previousPath);
    }

    return destPath;
  }

  Future<void> deleteProfileImage(String userId) async {
    final String? path = await getLocalImagePath(userId);
    await _dao.clearImagePath(userId);
    if (path != null) {
      await _deleteFileQuietly(path);
    }
  }

  String _sanitizeUserId(String userId) {
    final String cleaned =
        userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (cleaned.length <= 40) return cleaned;
    return cleaned.substring(0, 40);
  }

  String _normalizeExtension(String path, String name) {
    String ext = p.extension(path).toLowerCase();
    if (ext.isEmpty) {
      ext = p.extension(name).toLowerCase();
    }
    if (ext == '.jpeg') return '.jpg';
    if (ext.isEmpty) return '.jpg';
    return ext;
  }

  Future<void> _deleteFileQuietly(String path) async {
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
