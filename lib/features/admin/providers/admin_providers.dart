import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/enhanced_auth_provider.dart';
import '../presentation/screens/admin_dashboard_screen.dart';
import '../presentation/screens/admin_login_screen.dart';
import '../presentation/screens/admin_shell_screen.dart';
import '../presentation/screens/user_detail_screen.dart';
import '../presentation/screens/users_list_screen.dart';

/// Admin router provider
final adminRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(enhancedAuthProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isAdmin = authState.isAdmin;
      final isLoginRoute = state.matchedLocation == '/login';

      // Not logged in -> go to login
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }

      // Logged in but not admin -> show error on login page
      if (isLoggedIn && !isAdmin && !isLoginRoute) {
        return '/login?error=not_admin';
      }

      // Logged in as admin on login page -> go to dashboard
      if (isLoggedIn && isAdmin && isLoginRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            AdminLoginScreen(errorMessage: state.uri.queryParameters['error']),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersListScreen(),
          ),
          GoRoute(
            path: '/users/:userId',
            builder: (context, state) =>
                UserDetailScreen(userId: state.pathParameters['userId']!),
          ),
        ],
      ),
    ],
  );
});

/// Admin navigation state
final adminNavIndexProvider = StateProvider<int>((ref) => 0);
