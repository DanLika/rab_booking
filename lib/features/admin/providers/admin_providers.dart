import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/bb_redesign_tokens.dart';
import '../../../core/providers/enhanced_auth_provider.dart';
import '../presentation/screens/activity_log_screen.dart';
import '../presentation/screens/admin_dashboard_screen.dart';
import '../presentation/screens/admin_login_screen.dart';
import '../presentation/screens/admin_shell_screen.dart';
import '../presentation/screens/user_detail_screen.dart';
import '../presentation/screens/users_list_screen.dart';

/// Global admin owners-search query, written by the topbar search input and
/// consumed by [UsersListScreen] to seed its local text filter. DATA-HONEST:
/// this searches OWNERS ONLY (real `UserModel` data via the existing
/// `ownersListProvider` + in-screen filter) — the admin console has no
/// bookings/properties screens, so no other scope is searchable. This is
/// presentation/navigation plumbing only; it introduces NO new search backend.
final adminOwnersSearchQueryProvider = StateProvider<String>((ref) => '');

/// Currently-selected owner id for the desktop master-detail split on the
/// Users screen (handoff `admin-users.jsx` `AUOwnerPanel`). `null` = no row
/// selected yet (panel shows an empty placeholder). Presentation-only state;
/// selecting a row populates the inline detail panel instead of navigating to
/// the standalone `/users/:id` route. Cleared when the screen unmounts.
final adminSelectedOwnerIdProvider = StateProvider<String?>((ref) => null);

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
          // Login route runs OUTSIDE the AdminShellScreen subtree. The admin
          // app's outer MaterialApp ships ThemeMode.dark (admin_main*.dart), so
          // without an explicit wrap the login card would inherit a dark
          // surface. Design source `admin-auth.jsx` declares `theme-light` and
          // renders a WHITE card on the deep-purple gradient — wrap explicitly
          // so the form chrome resolves to light tokens regardless of outer
          // theme. NO BbAdminDarkTokens here: that extension is sidebar-only
          // and would re-route BbCard onto panelBg = #2A2342.
          Theme(
            data: ThemeData.light(useMaterial3: true).copyWith(
              extensions: const <ThemeExtension<dynamic>>[
                BbRedesignTokens.light,
              ],
            ),
            child: AdminLoginScreen(
              errorMessage: state.uri.queryParameters['error'],
            ),
          ),
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
