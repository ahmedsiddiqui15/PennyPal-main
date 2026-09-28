import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/app_notification_model.dart';
import '../../../providers/content_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotificationModel>> notifications =
        ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const LoadingView(),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(notificationsProvider.notifier).load(),
        ),
        data: (List<AppNotificationModel> items) {
          if (items.isEmpty) {
            return const EmptyState(
              emoji: '🔔',
              title: 'No notifications',
              message: 'Budget alerts, saving reminders and tips appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.spaceMd),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int i) => Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
              child: _NotificationTile(notification: items[i])
                  .staggerIn(i),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotificationModel notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final bool unread = !notification.read;
    final Color color = switch (notification.type) {
      AppNotificationType.budget => AppColors.warning,
      AppNotificationType.saving => AppColors.success,
      AppNotificationType.tip => AppColors.info,
      AppNotificationType.badge => AppColors.primary,
      AppNotificationType.system => palette.textSecondary,
    };

    return AppCard(
      onTap: () =>
          ref.read(notificationsProvider.notifier).markRead(notification),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      radius: AppConstants.radiusMd,
      border: unread
          ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
          : null,
      color: unread ? AppColors.primary.withValues(alpha: 0.05) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(notification.type.emoji,
                style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: AppTextStyles.subtitle.copyWith(
                          color: palette.textPrimary,
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(notification.body,
                    style: AppTextStyles.caption
                        .copyWith(color: palette.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      notification.type.label,
                      style: AppTextStyles.caption
                          .copyWith(color: color, fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.relativeDate(notification.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: palette.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
