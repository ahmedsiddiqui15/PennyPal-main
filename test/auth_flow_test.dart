import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pennypal/core/constants/app_enums.dart';
import 'package:pennypal/models/user_model.dart';
import 'package:pennypal/providers/auth_providers.dart';
import 'package:pennypal/providers/service_providers.dart';
import 'package:pennypal/services/auth_service.dart';
import 'package:pennypal/services/cloudinary_service.dart';
import 'package:pennypal/services/firestore_service.dart';

/// Regression tests for the auth → Firestore profile flow.
///
/// These cover the two failures that made registration appear to work while the
/// `users` collection stayed empty, and that left the app stuck on the splash
/// screen:
///
/// 1. An error while resolving the profile was swallowed, so the auth state was
///    never resolved and the router waited on the splash forever.
/// 2. Registration created the Auth account but the failure to write the
///    Firestore document was reported as a generic "Registration failed".
void main() {
  group('FirestoreService.describeError', () {
    test('explains unpublished security rules', () {
      final String message = FirestoreService.describeError(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      );
      expect(message.toLowerCase(), contains('security rules'));
    });

    test('explains a missing database and a dead network', () {
      expect(
        FirestoreService.describeError(
          FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
        ).toLowerCase(),
        contains('database'),
      );
      expect(
        FirestoreService.describeError(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ).toLowerCase(),
        contains('internet'),
      );
    });

    test('falls back gracefully for unknown errors', () {
      expect(
        FirestoreService.describeError(StateError('boom')),
        isNotEmpty,
      );
    });
  });

  group('AuthController', () {
    test('releases the splash screen when profile loading fails', () async {
      final _FakeAuthService auth = _FakeAuthService(failProfileLoad: true);
      final ProviderContainer container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      // Instantiate the controller; this attaches the auth-state listener.
      container.read(authProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final AuthState state = container.read(authProvider);

      // The critical assertion: start-up must not hang on the splash screen.
      expect(state.initializing, isFalse);
      expect(state.isAuthenticated, isFalse);
      expect(state.error, contains('denied'));
    });

    test('registration signs out and leaves the user on the login screen',
        () async {
      final _FakeAuthService auth = _FakeAuthService();
      final ProviderContainer container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      final bool ok = await container.read(authProvider.notifier).register(
            name: 'Ahmed Raza',
            email: 'ahmed@pennypal.app',
            phone: '+92 300 1234567',
            password: 'secret123',
          );

      expect(ok, isTrue);
      expect(auth.registerCalled, isTrue);
      // The requested flow: account created, then the user signs in themselves.
      expect(auth.signOutCalled, isTrue);
      expect(container.read(authProvider).isAuthenticated, isFalse);
      expect(container.read(authProvider).initializing, isFalse);
    });

    test('a failed registration surfaces the underlying reason', () async {
      final _FakeAuthService auth = _FakeAuthService(failRegister: true);
      final ProviderContainer container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      final bool ok = await container.read(authProvider.notifier).register(
            name: 'Ahmed Raza',
            email: 'ahmed@pennypal.app',
            phone: '+92 300 1234567',
            password: 'secret123',
          );

      expect(ok, isFalse);
      expect(container.read(authProvider).error, contains('security rules'));
    });

    test('registration creates the account without uploading a photo',
        () async {
      final _FakeAuthService auth = _FakeAuthService();
      final _FakeCloudinaryService cloudinary = _FakeCloudinaryService();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          cloudinaryServiceProvider.overrideWithValue(cloudinary),
        ],
      );
      addTearDown(container.dispose);

      final bool ok = await container.read(authProvider.notifier).register(
            name: 'Ahmed Raza',
            email: 'ahmed@pennypal.app',
            phone: '+92 300 1234567',
            password: 'secret123',
          );

      expect(ok, isTrue);
      expect(auth.registerCalled, isTrue);
      expect(cloudinary.uploadedBytes, isNull);
      expect(auth.updatedUser, isNull);
      expect(auth.signOutCalled, isTrue);
    });
  });
}

/// Minimal in-memory [AuthService] used to drive [AuthController] in tests.
class _FakeAuthService implements AuthService {
  _FakeAuthService({
    this.failProfileLoad = false,
    this.failRegister = false,
  });

  final bool failProfileLoad;
  final bool failRegister;

  bool registerCalled = false;
  bool signOutCalled = false;

  final StreamController<UserModel?> _controller =
      StreamController<UserModel?>.broadcast();
  UserModel? _current;

  @override
  UserModel? get currentUser => _current;

  @override
  Stream<UserModel?> authStateChanges() {
    // Deferred so the listener is attached before the event is emitted.
    scheduleMicrotask(() {
      if (_controller.isClosed) return;
      if (failProfileLoad) {
        _controller.addError(
          const AuthException(
            'Firestore denied the request. Publish the security rules.',
            code: 'profile-write-failed',
          ),
        );
      } else {
        _controller.add(null);
      }
    });
    return _controller.stream;
  }

  @override
  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    registerCalled = true;
    if (failRegister) {
      throw const AuthException(
        'Firestore denied the request. Publish the security rules for the '
        '"users" collection.',
        code: 'profile-write-failed',
      );
    }
    _current = UserModel(
      id: 'uid-1',
      name: name,
      email: email,
      phone: phone,
      role: role,
    );
    return _current!;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    _current = null;
    if (!_controller.isClosed) _controller.add(null);
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<UserModel> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  bool get isEmailVerified => true;

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<bool> refreshEmailVerified() async => true;

  UserModel? updatedUser;

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    updatedUser = user;
    return user;
  }

  @override
  Future<UserModel?> refreshProfile() async => _current;
}

/// Minimal in-memory [CloudinaryService] that records uploads.
class _FakeCloudinaryService extends CloudinaryService {
  Uint8List? uploadedBytes;

  @override
  bool get isConfigured => true;

  @override
  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String folder = 'pennypal/avatars',
  }) async {
    uploadedBytes = bytes;
    return 'https://cdn.test/image.jpg';
  }
}
