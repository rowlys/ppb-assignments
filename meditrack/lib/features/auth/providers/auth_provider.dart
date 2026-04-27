import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/remote/auth_service.dart';
import '../../../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingDisplayName;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _currentUser = AppUser(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? _pendingDisplayName ?? 'User',
          email: firebaseUser.email ?? '',
        );
        _pendingDisplayName = null;
      } else {
        _currentUser = null;
        _pendingDisplayName = null;
      }
      notifyListeners();
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    _pendingDisplayName = name;
    try {
      await _authService.register(name: name, email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _pendingDisplayName = null;
      _setError(_friendlyError(e.code));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signIn(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateName(String name) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.updateDisplayName(name);
      _currentUser = AppUser(uid: _currentUser!.uid, name: name, email: _currentUser!.email);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _setError('Please sign out and sign back in before changing your password.');
      } else {
        _setError(_friendlyError(e.code));
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}