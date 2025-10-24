import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'responsive_app_bar.dart';
import 'app_drawer.dart';
import 'adaptive_bottom_navigation_bar.dart';

/// Adaptive Scaffold - Main app scaffold with full navigation
///
/// Use this for PRIMARY pages:
/// - Home, Search, My Bookings, Favorites, Profile
///
/// Features:
/// - Desktop (≥1200px): Top nav bar only
/// - Tablet (768-1199px): Top bar + Drawer + Optional Bottom Nav
/// - Mobile (<768px): Top bar + Drawer + Bottom Nav
class AdaptiveScaffold extends ConsumerWidget {
  const AdaptiveScaffold({
    required this.body,
    this.floatingActionButton,
    this.scrollController,
    super.key,
  });

  final Widget body;
  final Widget? floatingActionButton;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return Scaffold(
      appBar: const ResponsiveAppBar(),

      // Drawer: Only for mobile/tablet (Desktop uses top nav links)
      drawer: isDesktop ? null : const AppDrawer(),

      body: body,

      floatingActionButton: floatingActionButton,

      // Bottom Navigation: Only for mobile/tablet
      bottomNavigationBar: isDesktop
          ? null
          : AdaptiveBottomNavigationBar(
              scrollController: scrollController ?? ScrollController(),
            ),
    );
  }
}

/// Detail Page Scaffold - For secondary pages with back navigation
///
/// Use this for DETAIL pages:
/// - Property Details, Booking Details, Review Pages, etc.
///
/// Features:
/// - Always shows back button (can return to previous page)
/// - No bottom navigation (focused experience)
/// - Clean, minimal header
class DetailPageScaffold extends StatelessWidget {
  const DetailPageScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.onBackPressed,
    this.showBackButton = true,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Nazad',
                onPressed: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else {
                    // Smart back: Go back or to home if can't go back
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      // Can't go back - go to home (no dead end!)
                      Navigator.of(context).pushReplacementNamed('/');
                    }
                  }
                },
              )
            : null,
        title: Text(title),
        actions: actions,
        elevation: 1,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Auth Scaffold - For authentication pages
///
/// Use this for AUTH pages:
/// - Login, Register, Forgot Password, Email Verification, etc.
///
/// Features:
/// - Back button to exit auth flow (no dead end!)
/// - Minimal header with logo
/// - Clean, focused design
/// - Can always return to home/previous page
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.body,
    this.title,
    this.showBackButton = true,
    this.showLogo = true,
    this.onBackPressed,
    super.key,
  });

  final Widget body;
  final String? title;
  final bool showBackButton;
  final bool showLogo;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Nazad',
                onPressed: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else {
                    // Smart back for auth pages
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      // Can't go back - go to home (user can browse without auth)
                      Navigator.of(context).pushReplacementNamed('/');
                    }
                  }
                },
              )
            : null,
        title: showLogo
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home_work,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title ?? 'Rab Booking',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              )
            : title != null
                ? Text(title!)
                : null,
        centerTitle: true,
        elevation: 0,
      ),
      body: body,
    );
  }
}

/// Simple Scaffold - For pages that need custom navigation
///
/// Use this for SPECIAL pages:
/// - Splash Screen, Onboarding, Custom Full-Screen experiences
///
/// Features:
/// - Full control over AppBar and navigation
/// - Use when other scaffolds don't fit your needs
class SimpleScaffold extends StatelessWidget {
  const SimpleScaffold({
    required this.body,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
