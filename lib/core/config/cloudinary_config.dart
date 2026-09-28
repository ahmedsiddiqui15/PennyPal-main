

class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String uploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  
  static const String avatarFolder = 'pennypal/avatars';

  
  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  static String uploadUrl([String? cloud]) =>
      'https://api.cloudinary.com/v1_1/${(cloud ?? cloudName).trim()}/image/upload';
}
