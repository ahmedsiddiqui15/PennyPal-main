import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../providers/auth_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _cooldown;
  int _seconds = 0;
  bool _sending = false;
  bool _checking = false;

  @override
  void dispose() {
    _cooldown?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldown?.cancel();
    setState(() => _seconds = 30);
    _cooldown = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _seconds--);
      if (_seconds <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    final String? error =
        await ref.read(authProvider.notifier).resendVerificationEmail();
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    AppSnackbar.success(context, 'Verification email sent.');
    _startCooldown();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final bool verified =
        await ref.read(authProvider.notifier).checkEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);
    if (verified) {
      AppSnackbar.success(context, 'Email verified — welcome to PennyPal!');
      final bool isAdmin = ref.read(authProvider).isAdmin;
      context.go(isAdmin ? AppRoutes.adminDashboard : AppRoutes.home);
    } else {
      AppSnackbar.warning(
        context,
        'Not verified yet. Open the link in your inbox, then try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String email = ref.watch(currentUserProvider)?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Verify Email'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            child: const Text('Log Out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spaceLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(AppConstants.spaceLg),
                    child: Column(
                      children: [
                        Container(
                          height: 76,
                          width: 76,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_unread_rounded,
                              size: 36, color: AppColors.primary),
                        ),
                        const SizedBox(height: AppConstants.spaceLg),
                        Text(
                          'Confirm your email',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading
                              .copyWith(color: palette.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email.isEmpty
                              ? 'We sent a verification link to your inbox.'
                              : 'We sent a verification link to:',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body
                              .copyWith(color: palette.textSecondary),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.subtitle
                                .copyWith(color: AppColors.primaryDark),
                          ),
                        ],
                        const SizedBox(height: AppConstants.spaceLg),
                        Text(
                          'Open the link in that email, then come back and tap '
                          '"I\'ve verified". Didn\'t get it? Check your spam '
                          'folder or resend it below.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption
                              .copyWith(color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceLg),
                  PrimaryButton(
                    label: 'I\'ve verified my email',
                    icon: Icons.verified_rounded,
                    isLoading: _checking,
                    onPressed: _check,
                  ),
                  const SizedBox(height: AppConstants.spaceMd),
                  PrimaryButton(
                    label: _seconds > 0
                        ? 'Resend in ${_seconds}s'
                        : 'Resend verification email',
                    icon: Icons.send_rounded,
                    outlined: true,
                    isLoading: _sending,
                    enabled: _seconds == 0,
                    onPressed: _resend,
                  ),
                  const SizedBox(height: AppConstants.spaceLg),
                  Center(
                    child: Text(
                      'Already verified on another device? Just log in again.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption
                          .copyWith(color: palette.textSecondary),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: AppConstants.durationNormal),
            ),
          ),
        ),
      ),
    );
  }
}
