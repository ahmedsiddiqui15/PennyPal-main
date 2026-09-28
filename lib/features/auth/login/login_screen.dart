import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/google_button.dart';
import '../../../core/widgets/auth_error_banner.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final bool ok = await ref.read(authProvider.notifier).signIn(
          email: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    if (!ok) {
      final String? error = ref.read(authProvider).error;
      AppSnackbar.error(context, error ?? 'Sign-in failed. Please try again.');
    }
    
  }

  Future<void> _google() async {
    final bool ok = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    if (!ok) {
      AppSnackbar.error(
        context,
        ref.read(authProvider).error ?? 'Google sign-in failed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final AuthState auth = ref.watch(authProvider);

    return Scaffold(
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
                    const Center(
                      child: AppLogo(size: 68, showWordmark: false),
                    ),
                    const SizedBox(height: AppConstants.spaceLg),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading
                          .copyWith(color: palette.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to keep your finances fresh.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body
                          .copyWith(color: palette.textSecondary),
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: AppConstants.spaceLg),
                      AuthErrorBanner(message: auth.error!),
                    ],
                    const SizedBox(height: AppConstants.spaceXl),

                    AppTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      controller: _email,
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppConstants.spaceMd),
                    AppTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _password,
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: Validators.loginPassword,
                      onSubmitted: (_) => _submit(),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        child: const Text('Forgot Password?'),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spaceSm),
                    PrimaryButton(
                      label: 'Login',
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
                      onPressed: auth.loading ? null : _google,
                    ),

                    const SizedBox(height: AppConstants.spaceLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: AppTextStyles.body
                              .copyWith(color: palette.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.register),
                          child: const Text('Create Account'),
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

