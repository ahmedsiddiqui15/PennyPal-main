import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../firebase_options.dart';
import '../providers/service_providers.dart';
import '../services/auth_service.dart';
import '../services/firebase_repository.dart';
import '../services/firestore_service.dart';
import '../services/preferences_service.dart';

class AppBootstrap {
  AppBootstrap._();

  
  
  
  
  static Future<ProviderContainer> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      
      
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppConfig.firebaseReady = true;

    
    
    FirestoreService.enableOfflinePersistence();

    final PreferencesService preferences = await PreferencesService.create();

    final FirestoreService firestore = FirestoreService();

    final ProviderContainer container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        authServiceProvider.overrideWithValue(
          FirebaseAuthService(firestore: firestore),
        ),
        repositoryProvider.overrideWithValue(
          FirebaseRepository(firestore: firestore),
        ),
      ],
    );

    
    await container.read(notificationServiceProvider).initialize();

    return container;
  }
}
