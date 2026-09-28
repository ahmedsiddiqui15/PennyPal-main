import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class CurrencyTile extends StatelessWidget {
  const CurrencyTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final CurrencyOption option;
  final bool selected;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Container(
            height: 42,
            width: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : palette.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              option.symbol.trim(),
              style: AppTextStyles.subtitle.copyWith(
                color: selected ? AppColors.primaryDark : palette.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            option.code,
            style: AppTextStyles.subtitle.copyWith(color: palette.textPrimary),
          ),
          subtitle: Text(
            option.label,
            style: AppTextStyles.caption.copyWith(color: palette.textSecondary),
          ),
          trailing: Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? AppColors.primary : palette.textSecondary,
          ),
        ),
        if (showDivider) Divider(color: palette.divider, height: 1),
      ],
    );
  }
}
