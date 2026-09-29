import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/profile_image_service.dart';
import 'auth_providers.dart';
import 'service_providers.dart';

final localProfileImagePathProvider =
    FutureProvider.autoDispose<String?>((Ref ref) async {
  final UserModel? user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final ProfileImageService service = ref.watch(profileImageServiceProvider);
  return service.getLocalImagePath(user.id);
});
