import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_enums.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'service_providers.dart';
import 'settings_providers.dart';

class AuthState {
  const AuthState({
    this.user,
    this.initializing = true,
    this.loading = false,
    this.error,
    this.emailVerified = true,
  });

  final UserModel? user;

  
  final bool initializing;

  
  final bool loading;
  final String? error;

  
  
  final bool emailVerified;

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({
    UserModel? user,
    bool? initializing,
    bool? loading,
    String? error,
    bool? emailVerified,
    bool clearUser = false,
    bool clearError = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        initializing: initializing ?? this.initializing,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        emailVerified: emailVerified ?? this.emailVerified,
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref, this._auth) : super(const AuthState()) {
    _subscription = _auth.authStateChanges().listen(
      (UserModel? user) {
        state = state.copyWith(
          user: user,
          clearUser: user == null,
          initializing: false,
          emailVerified: _auth.isEmailVerified,
        );
        if (user != null) {
          
          
          final SettingsState settings = _ref.read(settingsProvider);
          if (settings.currencyCode != user.currencyCode) {
            _ref
                .read(settingsProvider.notifier)
                .syncCurrencyPreference(user.currencyCode);
          }
        }
      },
      onError: (Object error) {
        
        
        state = AuthState(
          initializing: false,
          error: error is AuthException
              ? error.message
              : 'Could not load your profile. Please sign in again.',
        );
      },
    );
  }

  final Ref _ref;
  final AuthService _auth;
  StreamSubscription<UserModel?>? _subscription;

  UserModel? get currentUser => state.user ?? _auth.currentUser;

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final UserModel user =
          await _auth.signInWithEmail(email: email, password: password);
      state = AuthState(
        user: user,
        initializing: false,
        emailVerified: _auth.isEmailVerified,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Sign-in failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _auth.registerWithEmail(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );

      await _auth.signOut();
      state = const AuthState(initializing: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Registration failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final UserModel user = await _auth.signInWithGoogle();
      state = AuthState(
        user: user,
        initializing: false,
        emailVerified: _auth.isEmailVerified,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Google sign-in failed. Please try again.',
      );
      return false;
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _auth.sendPasswordReset(email);
      state = state.copyWith(loading: false);
      return null;
    } on AuthException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return e.message;
    } catch (e) {
      const String message = 'Could not send the reset email.';
      state = state.copyWith(loading: false, error: message);
      return message;
    }
  }

  
  Future<String?> resendVerificationEmail() async {
    try {
      await _auth.sendEmailVerification();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not send the verification email. Please try again.';
    }
  }

  
  Future<bool> checkEmailVerified() async {
    try {
      final bool verified = await _auth.refreshEmailVerified();
      state = state.copyWith(emailVerified: verified);
      return verified;
    } catch (_) {
      return state.emailVerified;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const AuthState(initializing: false);
  }

  Future<void> updateProfile(UserModel user) async {
    final UserModel updated = await _auth.updateProfile(user);
    state = state.copyWith(user: updated);
  }

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref, ref.watch(authServiceProvider)),
);

final currentUserProvider = Provider<UserModel?>(
  (ref) => ref.watch(authProvider).user,
);

final currentUserIdProvider = Provider<String>(
  (ref) => ref.watch(authProvider).user?.id ?? '',
);

final isAdminProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).isAdmin,
);
