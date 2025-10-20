import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'app_drawer.dart';
import 'responsive_app_bar.dart';
import 'adaptive_bottom_navigation_bar.dart';

/// App scaffold with responsive navigation
/// - Top: ResponsiveAppBar
/// - Bottom: AdaptiveBottomNavigationBar
///   - iOS/Android: Fixed, always visible
///   - Web: Auto-hide on scroll down, show on scroll up
/// - Desktop (>= 1200px): No drawer (AppBar has text links)
/// - Mobile/Tablet (< 1200px): Drawer with hamburger menu
///
/// Used as a shell route wrapper for main app sections
class AppScaffoldWithNav extends StatefulWidget {
  const AppScaffoldWithNav({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<AppScaffoldWithNav> createState() => _AppScaffoldWithNavState();
}

class _AppScaffoldWithNavState extends State<AppScaffoldWithNav> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    if (isDesktop) {
      // Desktop layout: AppBar with text links (no drawer) + Bottom Nav
      return Scaffold(
        appBar: const ResponsiveAppBar(),
        body: widget.child,
        bottomNavigationBar: AdaptiveBottomNavigationBar(
          scrollController: _scrollController,
        ),
      );
    } else {
      // Mobile/Tablet layout: AppBar with hamburger + Drawer + Bottom Nav
      return Scaffold(
        appBar: const ResponsiveAppBar(),
        drawer: const AppDrawer(),
        body: widget.child,
        bottomNavigationBar: AdaptiveBottomNavigationBar(
          scrollController: _scrollController,
        ),
      );
    }
  }
}
