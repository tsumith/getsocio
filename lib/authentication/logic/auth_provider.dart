import 'package:flutter/material.dart';
import 'package:getsocio/authentication/logic/auth_service.dart';
import 'package:getsocio/home/home_screen.dart';
import 'package:go_router/go_router.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  bool get isLoggedIn => _auth.getCurrentUser() != null;

  /// Optional listener for reactive auth state changes
  void listenToAuthChanges() {
    _auth.authStateChanges.listen((user) {
      notifyListeners(); // this will trigger go_router refresh
    });
  }

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

  void logout(BuildContext context) async {
    await _auth.signOut().then((val) {
      context.go('/login');
    });
    notifyListeners();
  }
}
