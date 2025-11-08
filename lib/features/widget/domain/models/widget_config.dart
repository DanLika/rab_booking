import 'package:flutter/material.dart';

/// Configuration for the booking widget parsed from URL parameters
///
/// Supported URL parameters:
/// - propertyId: Property ID (required)
/// - unitId: Unit ID (required)
/// - theme: 'light', 'dark', or 'system' (default: 'system')
/// - showBranding: true/false (default: true)
/// - hideBranding: true/false (inverse of showBranding)
/// - enableStripe: true/false (default: false)
/// - language: 'en', 'hr', 'de', etc. (default: 'en')
/// - primaryColor: #RRGGBB hex color
/// - accentColor: #RRGGBB hex color
/// - backgroundColor: #RRGGBB hex color
/// - textColor: #RRGGBB hex color
/// - months: 1-4 (number of months to display, default: auto based on screen size)
/// - borderRadius: 0-20 (corner radius in pixels, default: 8)
class WidgetConfig {
  // Required IDs
  final String? propertyId;
  final String? unitId;

  // Theme & Colors
  final String themeMode;
  final Color? primaryColor;
  final Color? accentColor;
  final Color? backgroundColor;
  final Color? textColor;

  // Branding
  final bool showPoweredByBadge;

  // Features
  final bool enableStripePayment;
  final bool enableBankTransfer;
  final bool enablePayOnPlace;

  // Localization
  final String locale;

  // Layout
  final int? numberOfMonths;
  final double borderRadius;

  const WidgetConfig({
    this.propertyId,
    this.unitId,
    this.themeMode = 'system',
    this.primaryColor,
    this.accentColor,
    this.backgroundColor,
    this.textColor,
    this.showPoweredByBadge = true,
    this.enableStripePayment = false,
    this.enableBankTransfer = true,
    this.enablePayOnPlace = false,
    this.locale = 'en',
    this.numberOfMonths,
    this.borderRadius = 8.0,
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

    // Parse payment methods
    final bool enableStripe = params['enableStripe']?.toLowerCase() == 'true';
    final bool enableBank = params['enableBankTransfer']?.toLowerCase() != 'false'; // default: true
    final bool enablePayOnPlace = params['enablePayOnPlace']?.toLowerCase() == 'true';

    // Parse number of months (1-4)
    int? months;
    if (params['months'] != null) {
      final parsed = int.tryParse(params['months']!);
      if (parsed != null && parsed >= 1 && parsed <= 4) {
        months = parsed;
      }
    }

    // Parse border radius (0-20)
    double radius = 8.0;
    if (params['borderRadius'] != null) {
      final parsed = double.tryParse(params['borderRadius']!);
      if (parsed != null && parsed >= 0 && parsed <= 20) {
        radius = parsed;
      }
    }

    return WidgetConfig(
      propertyId: params['propertyId'] ?? params['property'],
      unitId: params['unitId'] ?? params['unit'],
      primaryColor: _parseColor(params['primaryColor']),
      accentColor: _parseColor(params['accentColor']),
      backgroundColor: _parseColor(params['backgroundColor']),
      textColor: _parseColor(params['textColor']),
      locale: params['language'] ?? params['locale'] ?? 'en',
      showPoweredByBadge: showBadge,
      themeMode: theme.toLowerCase(),
      enableStripePayment: enableStripe,
      enableBankTransfer: enableBank,
      enablePayOnPlace: enablePayOnPlace,
      numberOfMonths: months,
      borderRadius: radius,
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
    String? propertyId,
    String? unitId,
    String? themeMode,
    Color? primaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? textColor,
    bool? showPoweredByBadge,
    bool? enableStripePayment,
    bool? enableBankTransfer,
    bool? enablePayOnPlace,
    String? locale,
    int? numberOfMonths,
    double? borderRadius,
  }) {
    return WidgetConfig(
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      showPoweredByBadge: showPoweredByBadge ?? this.showPoweredByBadge,
      enableStripePayment: enableStripePayment ?? this.enableStripePayment,
      enableBankTransfer: enableBankTransfer ?? this.enableBankTransfer,
      enablePayOnPlace: enablePayOnPlace ?? this.enablePayOnPlace,
      locale: locale ?? this.locale,
      numberOfMonths: numberOfMonths ?? this.numberOfMonths,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  /// Check if all required parameters are present
  bool get isValid => propertyId != null && unitId != null;

  /// Get a human-readable validation error message
  String? get validationError {
    if (propertyId == null && unitId == null) {
      return 'Missing required parameters: propertyId and unitId';
    }
    if (propertyId == null) {
      return 'Missing required parameter: propertyId';
    }
    if (unitId == null) {
      return 'Missing required parameter: unitId';
    }
    return null;
  }
}
