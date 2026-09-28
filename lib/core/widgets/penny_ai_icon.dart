import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PennyAiIcon extends StatelessWidget {
  const PennyAiIcon({
    super.key,
    this.size = 34,
    this.iconSize,
    this.filled = true,
  });

  final double size;
  final double? iconSize;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final double glyph = iconSize ?? size * 0.52;

    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled
            ? AppColors.primary.withValues(alpha: 0.16)
            : palette.surfaceMuted,
        shape: BoxShape.circle,
        border: Border.all(
          color: filled
              ? AppColors.primary.withValues(alpha: 0.28)
              : palette.border,
          width: 1,
        ),
      ),
      child: Icon(
        Icons.support_agent_rounded,
        size: glyph,
        color: filled ? AppColors.primaryDark : palette.textSecondary,
      ),
    );
  }
}

IconData get pennyAiGlyph => Icons.support_agent_rounded;
