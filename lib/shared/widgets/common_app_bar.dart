import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable standard AppBar (non-sliver) for screens using Scaffold
/// Provides consistent styling with gradient background
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// App bar title text
  final String title;

  /// Leading icon (menu, back arrow, etc.)
  final IconData leadingIcon;

  /// Action to perform when leading icon is tapped
  /// Receives BuildContext to allow actions like opening drawer
  final void Function(BuildContext) onLeadingIconTap;

  /// Gradient colors for the app bar background
  /// Default: Purple-Blue gradient [0xFF6B4CE6, 0xFF4A90E2]
  final List<Color> gradientColors;

  /// Title text color
  /// Default: White
  final Color titleColor;

  /// Icon color
  /// Default: White
  final Color iconColor;

  /// App bar height
  /// Default: 56 (standard AppBar height)
  final double height;

  const CommonAppBar({
    super.key,
    required this.title,
    required this.leadingIcon,
    required this.onLeadingIconTap,
    this.gradientColors = const [
      Color(0xFF6B4CE6), // Purple
      Color(0xFF4A90E2), // Blue
    ],
    this.titleColor = Colors.white,
    this.iconColor = Colors.white,
    this.height = 56.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: titleColor,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              leadingIcon,
              color: iconColor,
            ),
            onPressed: () => onLeadingIconTap(context),
            tooltip: 'Menu',
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
    );
  }
}
