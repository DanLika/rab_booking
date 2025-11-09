import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable gradient AppBar for owner dashboard screens
/// Provides consistent styling across all pages with customizable title and actions
class OwnerStandardAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool pinned;
  final double expandedHeight;

  const OwnerStandardAppBar({
    super.key,
    required this.title,
    this.actions,
    this.pinned = true,
    this.expandedHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final theme = Theme.of(context);

    // Always use Purple-Blue gradient (same for light and dark mode)
    const gradientColors = [
      AppColors.primary, // Purple
      AppColors.authSecondary, // Blue
    ];

    // Always white text and icons (same for light and dark mode)
    const textColor = Colors.white;
    const iconColor = Colors.white;

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
          decoration: const BoxDecoration(
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
                      icon: const Icon(Icons.menu, color: iconColor, size: 28),
                      onPressed: () => Scaffold.of(context).openDrawer(),
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
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
