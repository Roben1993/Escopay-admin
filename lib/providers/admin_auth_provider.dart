import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/admin_auth_service.dart';

class AdminAuthProvider extends ChangeNotifier {
  final AdminAuthService _authService = AdminAuthService();

  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  User? get currentUser => _authService.currentUser;

  AdminAuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      if (user != null && _authService.isAdminEmail(user.email ?? '')) {
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        if (user != null) _authService.signOut();
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _isAuthenticated = false;
    notifyListeners();
  }
}
