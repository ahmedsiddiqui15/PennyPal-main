import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../models/user_model.dart';

class DashboardHeader extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.firstName,
                style: AppTextStyles.title.copyWith(color: palette.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                Formatters.greeting(),
                style: AppTextStyles.subtitle
                    .copyWith(color: palette.textSecondary),
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
          imageUrl: user.photoUrl,
          size: 44,
          onTap: onAvatarTap,
        ),
      ],
    );
  }
}
