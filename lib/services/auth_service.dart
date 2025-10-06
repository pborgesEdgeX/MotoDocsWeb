import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_user;

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;

  FirebaseAuth get auth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  // Get current user
  app_user.User? get currentUser {
    try {
      final user = auth.currentUser;
      return user != null ? app_user.User.fromFirebase(user) : null;
    } catch (e) {
      return null;
    }
  }

  // Auth state changes stream
  Stream<app_user.User?> get authStateChanges {
    try {
      return auth
          .authStateChanges()
          .map((user) {
            return user != null ? app_user.User.fromFirebase(user) : null;
          })
          .handleError((error) {
            print('Auth stream error: $error');
            // Return a stream with null user on error
            return null;
          });
    } catch (e) {
      print('Auth service error: $e');
      return Stream.value(null);
    }
  }

  // Sign in with email and password
  Future<app_user.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('DEBUG: AuthService - Starting Firebase sign in');
      print('DEBUG: AuthService - Email: $email');

      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('DEBUG: AuthService - Firebase sign in completed');
      print('DEBUG: AuthService - Credential user: ${credential.user}');

      final user = credential.user != null
          ? app_user.User.fromFirebase(credential.user!)
          : null;

      print('DEBUG: AuthService - Created app user: $user');
      print('DEBUG: AuthService - Calling notifyListeners()');

      notifyListeners();

      print('DEBUG: AuthService - Returning user: $user');
      return user;
    } catch (e) {
      print('DEBUG: AuthService - Sign in error: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  // Create user with email and password
  Future<app_user.User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null && displayName != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      final user = credential.user != null
          ? app_user.User.fromFirebase(credential.user!)
          : null;
      notifyListeners();
      return user;
    } catch (e) {
      throw Exception('Account creation failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await auth.signOut();
      notifyListeners();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get ID token
  Future<String?> getIdToken() async {
    try {
      return await auth.currentUser?.getIdToken();
    } catch (e) {
      throw Exception('Failed to get ID token: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }
}
