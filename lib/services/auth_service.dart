import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_enums.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

abstract class AuthService {
  
  Stream<UserModel?> authStateChanges();

  
  UserModel? get currentUser;

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  
  
  bool get isEmailVerified;

  
  Future<void> sendEmailVerification();

  
  
  Future<bool> refreshEmailVerified();

  Future<void> signOut();

  Future<UserModel> updateProfile(UserModel user);

  
  Future<UserModel?> refreshProfile();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth, FirestoreService? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _fs = firestore ?? FirestoreService();

  final fb.FirebaseAuth _auth;
  final FirestoreService _fs;
  final StreamController<UserModel?> _controller =
      StreamController<UserModel?>.broadcast();

  UserModel? _current;
  StreamSubscription<fb.User?>? _sub;

  @override
  UserModel? get currentUser => _current;

  @override
  Stream<UserModel?> authStateChanges() {
    _sub ??= _auth.authStateChanges().listen(
      (fb.User? user) async {
        if (user == null) {
          _current = null;
          _controller.add(null);
          return;
        }
        try {
          final UserModel model = await _loadOrCreate(user);
          _current = model;
          _controller.add(model);
        } catch (error) {
          
          
          _current = null;
          _controller.addError(error);
        }
      },
      onError: (Object error) => _controller.addError(error),
    );
    return _controller.stream;
  }

  
  
  
  
  
  
  
  
  Future<UserModel> _loadOrCreate(fb.User user) async {
    try {
      final Map<String, dynamic>? existing =
          await _fs.doc(AppConstants.usersCollection, user.uid);

      if (existing != null) {
        final UserModel model = UserModel.fromMap(user.uid, existing);
        if (model.blocked) {
          await _auth.signOut();
          throw const AuthException(
            'This account has been blocked. Contact support.',
            code: 'blocked',
          );
        }
        try {
          await _fs.set(AppConstants.usersCollection, user.uid, {
            'lastActiveAt': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          
        }
        return model;
      }

      final UserModel created = UserModel(
        id: user.uid,
        name: user.displayName ??
            user.email?.split('@').first ??
            'PennyPal User',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        photoUrl: user.photoURL,
        role: UserRole.student,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
      await _fs.set(AppConstants.usersCollection, user.uid, created.toMap());
      return created;
    } on AuthException {
      rethrow;
    } catch (error) {
      throw AuthException(
        FirestoreService.describeError(error),
        code: 'profile-write-failed',
      );
    }
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final fb.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final UserModel model = await _loadOrCreate(result.user!);
      _current = model;
      _controller.add(model);
      return model;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    }
  }

  @override
  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    UserRole role = UserRole.student,
  }) async {
    
    final fb.UserCredential result;
    try {
      result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    }

    final fb.User user = result.user!;
    final UserModel model = UserModel(
      id: user.uid,
      name: name,
      email: email.trim(),
      phone: phone,
      role: role,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );

    
    
    
    
    
    
    try {
      await user.updateDisplayName(name);
      await _fs.set(AppConstants.usersCollection, user.uid, model.toMap());
    } catch (error) {
      await _auth.signOut();
      _current = null;
      throw AuthException(
        FirestoreService.describeError(error),
        code: 'profile-write-failed',
      );
    }

    
    
    
    try {
      await user.sendEmailVerification();
    } catch (_) {}

    _current = model;
    _controller.add(model);
    return model;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled.');
      }
      final GoogleSignInAuthentication auth =
          await googleUser.authentication;
      final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final fb.UserCredential result =
          await _auth.signInWithCredential(credential);
      final UserModel model = await _loadOrCreate(result.user!);
      _current = model;
      _controller.add(model);
      return model;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    }
  }

  @override
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? true;

  @override
  Future<void> sendEmailVerification() async {
    final fb.User? user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in to verify your email.');
    }
    if (user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    }
  }

  @override
  Future<bool> refreshEmailVerified() async {
    final fb.User? user = _auth.currentUser;
    if (user == null) return true;
    try {
      await user.reload();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    }
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      
    }
    await _auth.signOut();
    _current = null;
    _controller.add(null);
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    await _fs.set(AppConstants.usersCollection, user.id, user.toMap());
    _current = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<UserModel?> refreshProfile() async {
    final fb.User? user = _auth.currentUser;
    if (user == null) return null;
    final Map<String, dynamic>? data =
        await _fs.doc(AppConstants.usersCollection, user.uid);
    if (data == null) return _current;
    _current = UserModel.fromMap(user.uid, data);
    return _current;
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }

  String _mapFirebaseError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
