import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class UsernameProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool? _isAvailable;
  bool _isChecking = false;
  Timer? _debounce;

  bool? get isAvailable => _isAvailable;
  bool get isChecking => _isChecking;

  void checkUsername(String username) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (username.length < 3) {
      _isAvailable = null;
      _isChecking = false;
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      _isChecking = true;
      notifyListeners();

      try {
        _isAvailable = await _authService.isUsernameUnique(username);
      } catch (e) {
        debugPrint('Username check failed: $e');
        _isAvailable = null;
      }
      _isChecking = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
