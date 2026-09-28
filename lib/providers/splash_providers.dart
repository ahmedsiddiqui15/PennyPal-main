import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashHoldController extends StateNotifier<bool> {
  SplashHoldController({
    this.minDisplay = const Duration(milliseconds: 2400),
  }) : super(false) {
    _timer = Timer(minDisplay, () {
      if (mounted) state = true;
    });
  }

  final Duration minDisplay;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final splashHoldProvider =
    StateNotifierProvider<SplashHoldController, bool>(
  (Ref ref) => SplashHoldController(),
);
