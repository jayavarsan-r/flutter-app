import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/gst_verification_screen.dart';
import '../features/profile/screens/provider_profile_screen.dart';
import '../features/auth/providers/auth_provider.dart';

/// Provider for the app router with authentication state handling
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final currentPath = state.matchedLocation;
      
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      
      print('[v0] Router Check: path=$currentPath, authenticated=$isAuthenticated');

      // Public routes - ALWAYS allow access, no questions asked
      final publicRoutes = ['/login', '/signup', '/otp', '/gst-verification', '/loading'];
      final isPublicRoute = publicRoutes.contains(currentPath);

      if (isPublicRoute) {
        print('[v0] Router: Allowing public route access to $currentPath');
        return null;
      }

      // Protected routes - require authentication
      if (!isAuthenticated) {
        print('[v0] Router: Unauthenticated access to $currentPath, redirecting to /login');
        return '/login';
      }

      print('[v0] Router: Authenticated access granted to $currentPath');
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final phoneNumber = state.extra as String? ?? '';
          return OTPScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: '/gst-verification',
        name: 'gst-verification',
        builder: (context, state) => const GSTVerificationScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProviderProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

/// Loading screen shown while checking authentication status
class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
