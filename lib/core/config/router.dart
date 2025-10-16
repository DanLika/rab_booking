import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/design_system_demo/design_system_demo_screen.dart';

/// Application router configuration
final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    // Home route - placeholder
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const _PlaceholderScreen(title: 'Home'),
    ),

    // Design System Demo - for development/testing
    GoRoute(
      path: '/design-system-demo',
      name: 'design-system-demo',
      builder: (context, state) => const DesignSystemDemoScreen(),
    ),

    // Auth routes - placeholders
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const _PlaceholderScreen(title: 'Login'),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const _PlaceholderScreen(title: 'Register'),
    ),

    // Search routes - placeholders
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const _PlaceholderScreen(title: 'Search'),
    ),

    // Property routes - placeholders
    GoRoute(
      path: '/property/:id',
      name: 'property-details',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return _PlaceholderScreen(title: 'Property Details: $id');
      },
    ),

    // Booking routes - placeholders
    GoRoute(
      path: '/booking/:id',
      name: 'booking',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return _PlaceholderScreen(title: 'Booking: $id');
      },
    ),

    // Owner dashboard - placeholders
    GoRoute(
      path: '/owner/dashboard',
      name: 'owner-dashboard',
      builder: (context, state) =>
          const _PlaceholderScreen(title: 'Owner Dashboard'),
    ),

    // Payment routes - placeholders
    GoRoute(
      path: '/payment/:bookingId',
      name: 'payment',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId'] ?? '';
        return _PlaceholderScreen(title: 'Payment: $bookingId');
      },
    ),
  ],
  errorBuilder: (context, state) => _ErrorScreen(error: state.error),
);

/// Placeholder screen for routes that haven't been implemented yet
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isHome = title == 'Home';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This screen will be implemented soon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            if (isHome)
              ElevatedButton.icon(
                onPressed: () => context.go('/design-system-demo'),
                icon: const Icon(Icons.palette),
                label: const Text('View Design System'),
              )
            else
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Home'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Error screen for 404 and other routing errors
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
