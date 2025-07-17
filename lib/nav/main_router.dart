import 'package:getsocio/authentication/logic/auth_provider.dart';
import 'package:getsocio/authentication/login/login.dart';
import 'package:getsocio/authentication/register/register.dart';
import 'package:getsocio/home/home_screen.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggedIn = authProvider.isLoggedIn;
      final isGoingToAuth =
          state.fullPath == '/login' || state.fullPath == '/register';

      if (!loggedIn && !isGoingToAuth) {
        return '/login';
      } else if (loggedIn && isGoingToAuth) {
        return '/home';
      }

      return null; // No redirect; allow navigation
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    ],
  );
}
