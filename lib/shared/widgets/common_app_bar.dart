import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_tokens/gradient_tokens.dart';

/// Reusable standard AppBar (non-sliver) for screens using Scaffold
/// Provides consistent styling with gradient background
/// Uses GradientTokens.brandPrimary for consistent branding across themes
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// App bar title text
  final String title;

  /// Leading icon (menu, back arrow, etc.)
  final IconData leadingIcon;

  /// Action to perform when leading icon is tapped
  /// Receives BuildContext to allow actions like opening drawer
  final void Function(BuildContext) onLeadingIconTap;

  /// Custom gradient colors (optional - defaults to brand gradient)
  /// If null, uses GradientTokens.brandPrimary (Purple 100% → 70%)
  final List<Color>? gradientColors;

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
    this.gradientColors,
    this.titleColor = Colors.white,
    this.iconColor = Colors.white,
    this.height = 56.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use custom colors or brand gradient (Purple 100% → 70%)
    final effectiveColors = gradientColors ??
        [
          GradientTokens.brandPrimaryStart,
          GradientTokens.brandPrimaryEnd,
        ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: effectiveColors,
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: titleColor,
            letterSpacing: 0,
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
