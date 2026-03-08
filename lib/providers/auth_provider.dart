import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  UserModel? _currentUser;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();
    _currentUser = await _authService.getCurrentSession();
    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _error = null;
    final user = await _authService.login(email: email, password: password);
    _setLoading(false);

    if (user == null) {
      _error = _authService.lastError ?? 'Invalid email or password';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    final user = await _authService.signup(
      name: name,
      email: email,
      password: password,
    );
    _setLoading(false);

    if (user == null) {
      _error = _authService.lastError ?? 'Unable to sign up';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    _setLoading(true);
    _error = null;
    final result = await _authService.resetPassword(
      email: email,
      newPassword: newPassword,
    );
    _setLoading(false);

    if (!result) {
      _error = _authService.lastError ?? 'Could not reset password.';
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentUser = null;
    _setLoading(false);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
