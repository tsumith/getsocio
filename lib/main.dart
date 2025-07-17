import 'package:flutter/material.dart';
import 'package:getsocio/authentication/logic/auth_provider.dart';
import 'package:getsocio/nav/main_router.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  runApp (ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: const AppRoot(),
    ),);
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late GoRouter router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    router = createRouter(authProvider); // reactive router
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}
