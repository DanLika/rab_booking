import 'package:flutter/material.dart';
import 'owner_app_drawer.dart';
import 'owner_bottom_nav.dart';

/// A responsive scaffold for the owner dashboard.
///
/// On larger screens (width > 768), it displays a permanent side drawer.
/// On smaller screens, it shows a bottom navigation bar and a standard app bar
/// with a drawer that can be opened via an icon button.
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
    this.appBar,
    this.mobileAppBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.endDrawer,
  });

  final Widget body;
  final String currentRoute;
  final PreferredSizeWidget? appBar;
  final PreferredSizeWidget? mobileAppBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? endDrawer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 768;

        if (isDesktop) {
          // Desktop layout with a permanent drawer
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                OwnerAppDrawer(currentRoute: currentRoute),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: body),
              ],
            ),
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
          );
        } else {
          // Mobile layout with a bottom navigation bar and a modal drawer
          return Scaffold(
            appBar: mobileAppBar ?? appBar,
            body: body,
            drawer: OwnerAppDrawer(currentRoute: currentRoute),
            endDrawer: endDrawer,
            bottomNavigationBar: OwnerBottomNav(currentRoute: currentRoute),
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
          );
        }
      },
    );
  }
}
