import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/connectivity_service.dart';
import '../services/notification_service.dart';
import '../services/ocr/receipt_ocr.dart';
import '../services/preferences_service.dart';
import '../services/profile_image_service.dart';
import '../services/report_service.dart';
import '../services/repository.dart';
import '../services/voice_service.dart';

final preferencesProvider = Provider<PreferencesService>(
  (ref) => throw UnimplementedError('preferencesProvider must be overridden'),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => throw UnimplementedError('authServiceProvider must be overridden'),
);

final repositoryProvider = Provider<AppRepository>(
  (ref) => throw UnimplementedError('repositoryProvider must be overridden'),
);

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  final CloudinaryService service = CloudinaryService();
  ref.onDispose(service.dispose);
  return service;
});

final profileImageServiceProvider = Provider<ProfileImageService>(
  (ref) => ProfileImageService(),
);

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final NotificationService service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});

final aiServiceProvider = Provider<AiService>((ref) {
  final AiService service = AiService();
  ref.onDispose(service.dispose);
  return service;
});

final ocrServiceProvider = Provider<ReceiptOcrService>(
  (ref) => createReceiptOcrService(),
);

final voiceServiceProvider = Provider<VoiceCaptureService>(
  (ref) => VoiceCaptureService(),
);

final reportServiceProvider = Provider<ReportService>(
  (ref) => const ReportService(),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final isOnlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).watch(),
);
