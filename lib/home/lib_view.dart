import 'package:flutter/material.dart';
import 'package:getsocio/authentication/logic/auth_provider.dart';
import 'package:provider/provider.dart';

class LibView extends StatelessWidget {
  const LibView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthProvider>(context, listen: false);
    return Center(
      child: ElevatedButton(
        onPressed: () {
          authService.logout(context);
        },
        child: Text("sign out"),
      ),
    );
  }
}
