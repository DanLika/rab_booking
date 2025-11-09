import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable gradient SliverAppBar for all screens
/// Provides consistent styling across the app with customizable parameters
class CommonGradientAppBar extends StatelessWidget {
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

  /// Whether the app bar should remain pinned at the top when scrolling
  /// Default: true
  final bool pinned;

  /// Expanded height of the app bar
  /// Default: 100
  final double expandedHeight;

  const CommonGradientAppBar({
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
    this.pinned = true,
    this.expandedHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: pinned,
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: gradientColors.first,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(
                        leadingIcon,
                        color: iconColor,
                        size: 28,
                      ),
                      onPressed: () => onLeadingIconTap(context),
                      tooltip: 'Menu',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
