import 'package:flutter/material.dart';

/// Configuration for the booking widget parsed from URL parameters
class WidgetConfig {
  final String? unitId;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? accentColor;
  final String? locale;

  /// Whether to show "Powered by BedBooking" badge
  /// Set to false for premium/white-label customers
  /// URL param: ?showBranding=false or ?hideBranding=true
  final bool showPoweredByBadge;

  /// Theme mode for the widget
  /// Can be 'light', 'dark', or 'system' (follows device setting)
  /// URL param: ?theme=dark
  final String themeMode;

  /// Whether Stripe payment is enabled
  /// URL param: ?enableStripe=true
  final bool enableStripePayment;

  const WidgetConfig({
    this.unitId,
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.locale,
    this.showPoweredByBadge = true,
    this.themeMode = 'system',
    this.enableStripePayment = false,
  });

  factory WidgetConfig.fromUrlParameters(Uri uri) {
    final params = uri.queryParameters;

    // Parse badge visibility
    // Support both ?showBranding=false and ?hideBranding=true
    bool showBadge = true;
    if (params['showBranding'] != null) {
      showBadge = params['showBranding']?.toLowerCase() != 'false';
    } else if (params['hideBranding'] != null) {
      showBadge = params['hideBranding']?.toLowerCase() != 'true';
    }

    // Parse theme mode
    String theme = params['theme'] ?? 'system';
    if (!['light', 'dark', 'system'].contains(theme.toLowerCase())) {
      theme = 'system';
    }

    // Parse Stripe enablement
    final bool enableStripe = params['enableStripe']?.toLowerCase() == 'true';

    return WidgetConfig(
      unitId: params['unit'],
      primaryColor: _parseColor(params['primaryColor']),
      secondaryColor: _parseColor(params['secondaryColor']),
      accentColor: _parseColor(params['accentColor']),
      locale: params['locale'] ?? 'en',
      showPoweredByBadge: showBadge,
      themeMode: theme.toLowerCase(),
      enableStripePayment: enableStripe,
    );
  }

  static Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;

    // Remove # if present
    colorString = colorString.replaceAll('#', '');

    // Add FF for opacity if not present
    if (colorString.length == 6) {
      colorString = 'FF$colorString';
    }

    try {
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return null;
    }
  }

  WidgetConfig copyWith({
    String? unitId,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    String? locale,
    bool? showPoweredByBadge,
    String? themeMode,
    bool? enableStripePayment,
  }) {
    return WidgetConfig(
      unitId: unitId ?? this.unitId,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      locale: locale ?? this.locale,
      showPoweredByBadge: showPoweredByBadge ?? this.showPoweredByBadge,
      themeMode: themeMode ?? this.themeMode,
      enableStripePayment: enableStripePayment ?? this.enableStripePayment,
    );
  }
}
