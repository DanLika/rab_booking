import 'package:flutter/material.dart';

import 'app_drawer.dart';
import 'responsive_app_bar.dart';

/// App scaffold with responsive navigation
/// - Mobile/Tablet (< 1200px): AppBar with hamburger + Drawer
/// - Desktop (>= 1200px): AppBar with text navigation links (no drawer)
/// Used as a shell route wrapper for main app sections
class AppScaffoldWithNav extends StatelessWidget {
  const AppScaffoldWithNav({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    if (isDesktop) {
      // Desktop layout: AppBar with text links (no drawer)
      return Scaffold(
        appBar: const ResponsiveAppBar(),
        body: child,
      );
    } else {
      // Mobile/Tablet layout: AppBar with hamburger + Drawer
      return Scaffold(
        appBar: const ResponsiveAppBar(),
        drawer: const AppDrawer(),
        body: child,
      );
    }
  }
}
