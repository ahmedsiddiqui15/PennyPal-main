import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/profile_image_providers.dart';
import '../../../../providers/settings_providers.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({
    super.key,
    required this.user,
    this.onAvatarTap,
    this.onBellTap,
    this.unreadCount = 0,
  });

  final UserModel user;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onBellTap;
  final int unreadCount;

  Future<void> _toggleTheme(WidgetRef ref, BuildContext context) async {
    final ThemeMode current = ref.read(settingsProvider).themeMode;
    final bool isDark = switch (current) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    await ref.read(settingsProvider.notifier).setThemeMode(
          isDark ? ThemeMode.light : ThemeMode.dark,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final ThemeMode themeMode = ref.watch(settingsProvider).themeMode;
    final bool isDark = switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    final String? localImagePath =
        ref.watch(localProfileImagePathProvider).valueOrNull;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Formatters.greeting(),
                style: AppTextStyles.subtitle
                    .copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                user.name,
                style: AppTextStyles.title.copyWith(color: palette.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Here is your money snapshot.',
                style: AppTextStyles.caption
                    .copyWith(color: palette.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _toggleTheme(ref, context),
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: palette.textPrimary,
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onBellTap,
              icon: Icon(
                Icons.notifications_none_rounded,
                color: palette.textPrimary,
              ),
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
        AppAvatar(
          name: user.name,
          imagePath: localImagePath,
          imageUrl: localImagePath == null ? user.photoUrl : null,
          size: 44,
          onTap: onAvatarTap,
        ),
      ],
    );
  }
}
