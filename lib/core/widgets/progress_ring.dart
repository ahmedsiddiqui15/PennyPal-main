import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 96,
    this.strokeWidth = 10,
    this.center,
    this.color,
    this.trackColor,
    this.animate = true,
  });

  
  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final Color? color;
  final Color? trackColor;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double clamped = progress.clamp(0.0, 1.0);
    final Color ringColor = color ?? AppColors.primary;

    return SizedBox(
      height: size,
      width: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: animate ? clamped : clamped),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  progress: value,
                  strokeWidth: strokeWidth,
                  color: ringColor,
                  trackColor: trackColor ?? palette.border,
                ),
              ),
              center ?? const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - strokeWidth) / 2;

    final Paint track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

class PercentageRing extends StatelessWidget {
  const PercentageRing({
    super.key,
    required this.progress,
    this.size = 96,
    this.label,
    this.color,
  });

  final double progress;
  final double size;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return ProgressRing(
      progress: progress,
      size: size,
      color: color,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(progress.clamp(0, 1) * 100).round()}%',
            style: AppTextStyles.title.copyWith(color: palette.textPrimary),
          ),
          if (label != null)
            Text(
              label!,
              style: AppTextStyles.caption.copyWith(color: palette.textSecondary),
            ),
        ],
      ),
    );
  }
}
