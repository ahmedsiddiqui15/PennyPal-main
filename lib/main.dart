import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/bootstrap_error_app.dart';

Future<void> main() async {
  try {
    final ProviderContainer container = await AppBootstrap.initialize();
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const PennyPalApp(),
      ),
    );
  } catch (error, stackTrace) {
    
    
    if (kDebugMode) {
      debugPrint('PennyPal failed to start: $error\n$stackTrace');
    }
    runApp(BootstrapErrorApp(message: '$error'));
  }
}
