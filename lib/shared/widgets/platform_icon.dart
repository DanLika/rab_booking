import 'package:flutter/material.dart';

/// Platform icon widget for displaying booking source
///
/// Shows a compact icon/letter representing the booking platform:
/// - Booking.com → Blue circle with "B"
/// - Airbnb → Red/pink circle with "A"
/// - Widget/Direct → Purple circle with "W"
/// - iCal/Other → Orange circle with link icon
///
/// Used in:
/// - Timeline booking blocks (top-right corner)
/// - Booking details dialog (source field)
/// - Conflict warnings (inline with text)
class PlatformIcon extends StatelessWidget {
  /// Booking source value (e.g., 'booking_com', 'airbnb', 'widget')
  final String? source;

  /// Icon size (width and height)
  final double size;

  /// Whether to show background circle
  final bool showBackground;

  /// Whether to show tooltip on hover/long-press
  final bool showTooltip;

  const PlatformIcon({
    super.key,
    required this.source,
    this.size = 16,
    this.showBackground = true,
    this.showTooltip = true,
  });

  /// Get platform display name for tooltips
  static String getDisplayName(String? source) {
    if (source == null) return 'Direct';
    switch (source.toLowerCase()) {
      case 'booking_com':
        return 'Booking.com';
      case 'airbnb':
        return 'Airbnb';
      case 'widget':
      case 'direct':
      case 'manual':
        return 'Direct';
      case 'ical':
        return 'iCal Import';
      case 'admin':
        return 'Admin';
      default:
        // Capitalize first letter for unknown sources
        if (source.isEmpty) return 'Direct';
        return source[0].toUpperCase() + source.substring(1);
    }
  }

  /// Check if this source should show an icon (external sources only)
  static bool shouldShowIcon(String? source) {
    if (source == null) return false;
    final src = source.toLowerCase();
    // Show icon for external platforms, hide for native bookings
    return src == 'booking_com' ||
        src == 'airbnb' ||
        src == 'ical' ||
        src == 'external' ||
        src == 'other';
  }

  @override
  Widget build(BuildContext context) {
    final config = _getPlatformConfig(source);

    Widget icon = Container(
      width: size,
      height: size,
      decoration: showBackground
          ? BoxDecoration(
              color: config.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: config.backgroundColor.withAlpha((0.4 * 255).toInt()),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            )
          : null,
      child: Center(
        child: config.isEmoji
            ? Text(
                config.letter,
                style: TextStyle(
                  fontSize: size * 0.6,
                ),
              )
            : Text(
                config.letter,
                style: TextStyle(
                  color: config.textColor,
                  fontSize: size * 0.55,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
      ),
    );

    if (showTooltip) {
      icon = Tooltip(
        message: getDisplayName(source),
        preferBelow: false,
        child: icon,
      );
    }

    return Semantics(
      label: 'Booking from ${getDisplayName(source)}',
      child: icon,
    );
  }

  /// Get visual configuration for each platform
  _PlatformConfig _getPlatformConfig(String? source) {
    if (source == null) {
      return _PlatformConfig(
        letter: 'D',
        backgroundColor: Colors.grey,
        textColor: Colors.white,
      );
    }

    switch (source.toLowerCase()) {
      case 'booking_com':
        // Official Booking.com blue
        return _PlatformConfig(
          letter: 'B',
          backgroundColor: const Color(0xFF003580),
          textColor: Colors.white,
        );

      case 'airbnb':
        // Official Airbnb red/coral
        return _PlatformConfig(
          letter: 'A',
          backgroundColor: const Color(0xFFFF5A5F),
          textColor: Colors.white,
        );

      case 'widget':
      case 'direct':
      case 'manual':
        // Purple (brand color)
        return _PlatformConfig(
          letter: 'W',
          backgroundColor: const Color(0xFF7C3AED),
          textColor: Colors.white,
        );

      case 'ical':
      case 'external':
      case 'other':
        // Orange with link emoji
        return _PlatformConfig(
          letter: '🔗',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          isEmoji: true,
        );

      case 'admin':
        // Dark grey for admin-created
        return _PlatformConfig(
          letter: '★',
          backgroundColor: Colors.blueGrey,
          textColor: Colors.white,
          isEmoji: true,
        );

      default:
        // Unknown source - show first letter
        return _PlatformConfig(
          letter: source.isNotEmpty ? source[0].toUpperCase() : '?',
          backgroundColor: Colors.grey,
          textColor: Colors.white,
        );
    }
  }
}

/// Internal configuration class for platform visuals
class _PlatformConfig {
  final String letter;
  final Color backgroundColor;
  final Color textColor;
  final bool isEmoji;

  _PlatformConfig({
    required this.letter,
    required this.backgroundColor,
    required this.textColor,
    this.isEmoji = false,
  });
}
