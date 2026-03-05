import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:getsocio/auth/logic/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../home/music_lib/player_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    // Automatically listen as soon as the provider is created
    _auth.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }


  Future<void> login(
    String email,
    String password,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(email, password);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> register(String email, String password, String username) async {
    await _auth.registerWithEmailAndPassword(
        email: email,
        password: password,
        username: username
    );
  }

  void logout(BuildContext context) async {
    Provider.of<PlayerProvider>(context, listen: false).stopAndClear();
    await _auth.signOut().then((val) {
      context.go('/login');
    });
    notifyListeners();
  }
}
