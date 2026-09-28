import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final String? error =
        await ref.read(authProvider.notifier).sendPasswordReset(_email.text);

    if (!mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }
    setState(() => _sent = true);
  }

  Future<void> _resend() async {
    final String? error =
        await ref.read(authProvider.notifier).sendPasswordReset(_email.text);
    if (!mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.success(context, 'Reset link sent again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final AuthState auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spaceLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _sent ? _success(palette, auth) : _form(palette, auth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(AppPalette palette, AuthState auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 76,
            width: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: AppConstants.spaceLg),
          Text(
            'Reset your password',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter the email you signed up with and we'll send you a reset link.",
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppConstants.spaceXl),
          AppTextField(
            label: 'Email Address',
            hint: 'you@example.com',
            controller: _email,
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppConstants.spaceXl),
          PrimaryButton(
            label: 'Send Reset Link',
            icon: Icons.send_rounded,
            isLoading: auth.loading,
            onPressed: _submit,
          ),
        ],
      ).animate().fadeIn(duration: AppConstants.durationNormal),
    );
  }

  Widget _success(AppPalette palette, AuthState auth) {
    return Column(
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
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_rounded,
                    size: 36, color: AppColors.success),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              Text(
                'Check your inbox',
                style: AppTextStyles.title.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a password reset link to ${_email.text}.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              PrimaryButton(
                label: 'Back to Login',
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: AppConstants.spaceSm),
              TextButton.icon(
                onPressed: auth.loading ? null : _resend,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Didn't get it? Resend email"),
              ),
            ],
          ),
        ).animate().fadeIn().scale(
              begin: const Offset(0.94, 0.94),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
              duration: AppConstants.durationNormal,
            ),
      ],
    );
  }
}
