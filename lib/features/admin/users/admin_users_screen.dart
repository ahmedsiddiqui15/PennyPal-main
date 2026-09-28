import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/stagger.dart';
import '../../../models/user_model.dart';
import '../../../providers/admin_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AdminState> admin = ref.watch(adminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: admin.when(
        loading: () => const LoadingView(label: 'Loading users…'),
        error: (Object e, StackTrace s) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(adminProvider.notifier).load(),
        ),
        data: (AdminState state) {
          final List<UserModel> users = state.filteredUsers;
          final int blocked = state.users.where((u) => u.blocked).length;
          final int admins =
              state.users.where((u) => u.isAdmin).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceMd,
              AppConstants.spaceSm,
              AppConstants.spaceMd,
              AppConstants.spaceXxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Total',
                      value: '${state.users.length}',
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceSm),
                  Expanded(
                    child: _MiniStat(
                      label: 'Admins',
                      value: '$admins',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceSm),
                  Expanded(
                    child: _MiniStat(
                      label: 'Blocked',
                      value: '$blocked',
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceLg),
              TextField(
                controller: _search,
                onChanged: (String v) =>
                    ref.read(adminProvider.notifier).setQuery(v),
                decoration: const InputDecoration(
                  hintText: 'Search by name or email…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              SectionHeader(
                title: 'All Users',
                subtitle: '${users.length} shown',
              ),
              if (users.isEmpty)
                const AppCard(
                  child: EmptyState(
                    compact: true,
                    emoji: '🔍',
                    title: 'No users found',
                    message: 'Try a different search term.',
                  ),
                )
              else
                ...users.asMap().entries.map(
                      (MapEntry<int, UserModel> e) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: AppConstants.spaceSm),
                        child: _UserTile(user: e.value).staggerIn(e.key),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      radius: AppConstants.radiusMd,
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.title.copyWith(color: color)),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: palette.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      radius: AppConstants.radiusMd,
      onTap: () => _showUserSheet(context, ref, user),
      child: Row(
        children: [
          AppAvatar(name: user.name, imageUrl: user.photoUrl, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle.copyWith(
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusPill,
                          ),
                        ),
                        child: Text('Admin',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryDark,
                              fontSize: 9,
                            )),
                      ),
                    ],
                    if (user.blocked) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusPill,
                          ),
                        ),
                        child: Text('Blocked',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.danger,
                              fontSize: 9,
                            )),
                      ),
                    ],
                  ],
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTextStyles.caption.copyWith(color: palette.textSecondary),
                ),
                Text(
                  user.lastActiveAt == null
                      ? 'Never active'
                      : 'Active ${Formatters.relativeDate(user.lastActiveAt!)}',
                  style: AppTextStyles.caption.copyWith(
                    color: palette.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: palette.textSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            onSelected: (String value) {
              if (value == 'view') {
                _showUserSheet(context, ref, user);
              } else if (value == 'block') {
                _toggleBlock(context, ref);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String>(
                value: 'view',
                child: Text('View profile'),
              ),
              PopupMenuItem<String>(
                value: 'block',
                child: Text(
                  user.blocked ? 'Unblock user' : 'Block user',
                  style: TextStyle(
                    color: user.blocked ? AppColors.success : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlock(BuildContext context, WidgetRef ref) async {
    final bool blocking = !user.blocked;
    final bool confirmed = await AppDialog.confirm(
      context,
      title: blocking ? 'Block ${user.name}?' : 'Unblock ${user.name}?',
      message: blocking
          ? 'They will not be able to sign in until unblocked.'
          : 'They will regain access to PennyPal.',
      confirmLabel: blocking ? 'Block' : 'Unblock',
      destructive: blocking,
    );
    if (!confirmed || !context.mounted) return;

    final String? error =
        await ref.read(adminProvider.notifier).setBlocked(user, blocking);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.success(
        context,
        blocking ? '${user.name} blocked.' : '${user.name} unblocked.',
      );
    }
  }
}

void _showUserSheet(BuildContext context, WidgetRef ref, UserModel user) {
  AppDialog.sheet<void>(
    context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetHeader(title: 'User profile'),
        const SizedBox(height: AppConstants.spaceLg),
        Center(
          child: Column(
            children: [
              AppAvatar(name: user.name, imageUrl: user.photoUrl, size: 84),
              const SizedBox(height: AppConstants.spaceMd),
              Text(user.name, style: AppTextStyles.title),
              Text(user.email, style: AppTextStyles.caption),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spaceLg),
        _row('Role', user.role.label),
        _row('Phone', user.phone.isEmpty ? '—' : user.phone),
        _row('Currency', user.currencyCode),
        _row('Streak', '${user.streakDays} days'),
        _row('Status', user.blocked ? 'Blocked' : 'Active'),
        _row(
          'Joined',
          user.createdAt == null ? '—' : Formatters.date(user.createdAt!),
        ),
        _row(
          'Last active',
          user.lastActiveAt == null
              ? '—'
              : Formatters.dateTime(user.lastActiveAt!),
        ),
        const SizedBox(height: AppConstants.spaceMd),
      ],
    ),
  );
}

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label,
              style: AppTextStyles.body
                  .copyWith(color: const Color(0xFF6B7280))),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.subtitle,
          ),
        ),
      ],
    ),
  );
}
