import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension StaggerX on Widget {
  Widget staggerIn(
    int index, {
    Duration step = const Duration(milliseconds: 55),
    Duration duration = const Duration(milliseconds: 420),
  }) {
    
    final Duration delay = step * (index.clamp(0, 12));
    return animate()
        .fadeIn(delay: delay, duration: duration, curve: Curves.easeOut)
        .slideY(
          begin: 0.18,
          end: 0,
          delay: delay,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}
