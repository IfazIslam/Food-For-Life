import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

// Import Screens (Placeholders for now)
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/main_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isFirstTime = ref.watch(firstTimeProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _GoRouterNotifier(ref),
    redirect: (context, state) {
      final isAuth = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (isSplash) return null; // Let splash decide after checking shared prefs

      if (isFirstTime && !isOnboarding) {
        return '/onboarding';
      }

      if (!isAuth && !isLoggingIn && !isOnboarding) {
        return '/login';
      }

      if (isAuth && (isLoggingIn || isOnboarding)) {
        return '/main';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
});

class _GoRouterNotifier extends ChangeNotifier {
  _GoRouterNotifier(this.ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(firstTimeProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
