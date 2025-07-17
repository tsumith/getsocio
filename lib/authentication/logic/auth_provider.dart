import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:getsocio/authentication/logic/auth_service.dart';
import 'package:getsocio/home/home_screen.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(email, password);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (cont) {
            return HomeScreen();
          },
        ),
      );
    } catch (e) {
      print(e.toString());
    }
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
