import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_success.dart';
import '../../../core/widgets/auth_error_banner.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/google_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final bool ok = await ref.read(authProvider.notifier).register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
        );

    if (!mounted) return;

    if (!ok) {
      final String message = ref.read(authProvider).error ??
          'Your account could not be created.';

      if (message.toLowerCase().contains('already exists')) {
        final bool goToLogin = await AppDialog.confirm(
          context,
          title: 'Account already exists',
          message: 'An account with that email already exists. Sign in instead?',
          confirmLabel: 'Go to Login',
          cancelLabel: 'Try again',
        );
        if (!mounted) return;
        if (goToLogin) context.go(AppRoutes.login);
        return;
      }

      AppSnackbar.error(context, message);
      return;
    }

    await showSuccessOverlay(
      context,
      title: 'Account created!',
      message: 'We emailed you a verification link. Verify your address, then '
          'sign in to continue.',
      buttonLabel: 'Continue to Login',
    );
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    final bool ok = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (!ok) {
      AppSnackbar.error(
        context,
        ref.read(authProvider).error ?? 'Google sign-up failed.',
      );
    }
  }

  Widget? _strengthMeter(AppPalette palette) {
    final String value = _password.text;
    if (value.isEmpty) return null;

    final double strength = Validators.passwordStrength(value);
    final Color color = strength >= 0.75
        ? AppColors.success
        : strength >= 0.45
            ? AppColors.warning
            : AppColors.danger;
    final String label = strength >= 0.75
        ? 'Strong'
        : strength >= 0.45
            ? 'Fair'
            : 'Weak';

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
              child: LinearProgressIndicator(
                value: strength,
                minHeight: 6,
                backgroundColor: palette.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
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
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spaceLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join PennyPal',
                      style: AppTextStyles.heading
                          .copyWith(color: palette.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create your account and start tracking in seconds.',
                      style: AppTextStyles.body
                          .copyWith(color: palette.textSecondary),
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: AppConstants.spaceLg),
                      AuthErrorBanner(message: auth.error!),
                    ],
                    const SizedBox(height: AppConstants.spaceXl),
                    AppTextField(
                      label: 'Full Name',
                      hint: 'Enter your name',
                      controller: _name,
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: Validators.name,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppConstants.spaceMd),
                    AppTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      controller: _email,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppConstants.spaceMd),
                    AppTextField(
                      label: 'Mobile Number',
                      hint: '+92 300 1234567',
                      controller: _phone,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: AppConstants.spaceMd),
                    AppTextField(
                      label: 'Password',
                      hint: 'At least 8 characters, with a number',
                      controller: _password,
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      textInputAction: TextInputAction.next,
                      validator: Validators.password,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_strengthMeter(palette) != null) _strengthMeter(palette)!,
                    const SizedBox(height: AppConstants.spaceMd),
                    AppTextField(
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      controller: _confirm,
                      icon: Icons.lock_reset_rounded,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          Validators.confirmPassword(v, _password.text),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppConstants.spaceXl),
                    PrimaryButton(
                      label: 'Create Account',
                      isLoading: auth.loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppConstants.spaceLg),
                    Row(
                      children: [
                        Expanded(child: Divider(color: palette.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: AppTextStyles.caption
                                .copyWith(color: palette.textSecondary),
                          ),
                        ),
                        Expanded(child: Divider(color: palette.border)),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spaceLg),
                    GoogleSignInButton(
                      label: 'Sign up with Google',
                      onPressed: auth.loading ? null : _google,
                    ),
                    const SizedBox(height: AppConstants.spaceLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: AppTextStyles.body
                              .copyWith(color: palette.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Login'),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: AppConstants.durationNormal).slideY(
                      begin: 0.05,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
