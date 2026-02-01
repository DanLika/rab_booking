import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/enhanced_auth_provider.dart';
import '../presentation/screens/activity_log_screen.dart';
import '../presentation/screens/admin_dashboard_screen.dart';
import '../presentation/screens/admin_login_screen.dart';
import '../presentation/screens/admin_shell_screen.dart';
import '../presentation/screens/user_detail_screen.dart';
import '../presentation/screens/users_list_screen.dart';

/// Fade transition for tab-like navigation (dashboard, users, activity log)
CustomTransitionPage<void> _fadePage(LocalKey key, Widget child) =>
    CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// Slide transition for drill-down navigation (user detail)
CustomTransitionPage<void> _slidePage(LocalKey key, Widget child) =>
    CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    );

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
        pageBuilder: (context, state) => _fadePage(
          state.pageKey,
          AdminLoginScreen(errorMessage: state.uri.queryParameters['error']),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AdminShellScreen(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                _fadePage(state.pageKey, const AdminDashboardScreen()),
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) =>
                _fadePage(state.pageKey, const UsersListScreen()),
          ),
          GoRoute(
            path: '/users/:userId',
            pageBuilder: (context, state) => _slidePage(
              state.pageKey,
              UserDetailScreen(userId: state.pathParameters['userId']!),
            ),
          ),
          GoRoute(
            path: '/activity-log',
            pageBuilder: (context, state) =>
                _fadePage(state.pageKey, const ActivityLogScreen()),
          ),
        ],
      ),
    ],
  );
});
