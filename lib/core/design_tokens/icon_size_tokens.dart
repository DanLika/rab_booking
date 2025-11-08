/// Icon size design tokens for consistent icon sizing
///
/// Usage:
/// ```dart
/// Icon(
///   Icons.check,
///   size: IconSizeTokens.medium,
/// )
///
/// IconButton(
///   icon: Icon(Icons.menu, size: IconSizeTokens.large),
/// )
/// ```
class IconSizeTokens {
  // Prevent instantiation
  IconSizeTokens._();

  // ============================================================
  // ICON SIZES
  // ============================================================

  /// Tiny - 8px
  /// Use for: Badges, powered by branding, decorative micro-icons
  static const double tiny = 8.0;

  /// Extra Small - 12px
  /// Use for: Small badges, inline icons in dense UI
  static const double xs = 12.0;

  /// Small - 16px
  /// Use for: List item icons, input field icons, compact toolbars
  static const double small = 16.0;

  /// Medium - 20px
  /// Use for: Standard icons, navigation icons, button icons
  static const double medium = 20.0;

  /// Large - 24px (Material Design default)
  /// Use for: Primary actions, prominent icons, standard buttons
  static const double large = 24.0;

  /// Extra Large - 32px
  /// Use for: Feature icons, card headers, emphasis icons
  static const double xl = 32.0;

  /// Extra Extra Large - 40px
  /// Use for: Payment methods, large feature icons
  static const double xxl = 40.0;

  /// Huge - 48px
  /// Use for: Hero icons, empty states, major feature graphics
  static const double huge = 48.0;

  /// Massive - 64px
  /// Use for: Splash screens, onboarding illustrations
  static const double massive = 64.0;

  /// Gigantic - 80px
  /// Use for: Empty state illustrations, error pages
  static const double gigantic = 80.0;

  // ============================================================
  // SEMANTIC ICON SIZES
  // ============================================================

  /// Icon size for app bar actions
  static const double appBarAction = large; // 24px

  /// Icon size for navigation items
  static const double navigation = large; // 24px

  /// Icon size for list items
  static const double listItem = medium; // 20px

  /// Icon size for input fields
  static const double input = medium; // 20px

  /// Icon size for buttons
  static const double button = medium; // 20px

  /// Icon size for fab (floating action button)
  static const double fab = large; // 24px

  /// Icon size for chips
  static const double chip = small; // 16px

  /// Icon size for avatar
  static const double avatar = xl; // 32px
}
