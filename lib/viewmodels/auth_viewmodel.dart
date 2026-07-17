import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _ready = false;
  String? _errorMessage;
  AppUser? _currentUser;
  StreamSubscription<AppUser?>? _authSub;

  bool get isLoading => _isLoading;
  bool get isReady => _ready;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Khôi phục session Firebase Auth khi mở app.
  Future<void> bootstrap() async {
    try {
      await _authService.initialize();
      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        await CrashlyticsService.setUser(
          _currentUser!.id,
          email: _currentUser!.email,
        );
      }
      _authSub = _authService.authStateChanges.listen((user) {
        _currentUser = user;
        CrashlyticsService.setUser(user?.id, email: user?.email);
        notifyListeners();
      });
    } catch (e) {
      debugPrint('AuthViewModel bootstrap error: $e');
    }
    _ready = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentUser = await _authService.signInWithGoogle();
      await CrashlyticsService.setUser(
        _currentUser?.id,
        email: _currentUser?.email,
      );
      await AnalyticsService.logLogin();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await AnalyticsService.logLogout();
    await CrashlyticsService.setUser(null);
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
