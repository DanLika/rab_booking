import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/widget/presentation/screens/booking_widget_screen.dart';
import '../../shared/presentation/screens/not_found_screen.dart';

/// Routes constants
class Routes {
  static const String widget = '/';
  static const String notFound = '/404';
}

/// Minimal GoRouter for widget-only app
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.widget,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: Routes.widget,
        builder: (context, state) => const BookingWidgetScreen(),
      ),
      GoRoute(
        path: Routes.notFound,
        builder: (context, state) => const NotFoundScreen(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
