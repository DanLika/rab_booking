import 'dart:ui';
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
  /// Default: 80
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
    this.expandedHeight = 80,
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
      backgroundColor: Colors.transparent,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate collapse ratio (0.0 = expanded, 1.0 = collapsed)
          final statusBarHeight = MediaQuery.of(context).padding.top;
          final minHeight = kToolbarHeight + statusBarHeight;
          final maxHeight = expandedHeight + statusBarHeight;
          final currentHeight = constraints.maxHeight;

          final collapseRatio = ((maxHeight - currentHeight) / (maxHeight - minHeight))
              .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
              ),

              // Blur overlay when collapsed
              if (collapseRatio > 0.3)
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: collapseRatio * 10,
                    sigmaY: collapseRatio * 10,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors.map((c) =>
                          c.withOpacity(0.85 + (collapseRatio * 0.15))
                        ).toList(),
                      ),
                    ),
                  ),
                ),

              // Content
              FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    statusBarHeight + 8,
                    isMobile ? 16 : 24,
                    8,
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
            ],
          );
        },
      ),
    );
  }
}
