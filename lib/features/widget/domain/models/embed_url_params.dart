import 'package:flutter/material.dart';

/// Configuration parsed from URL parameters for the embeddable booking widget.
///
/// This class parses URL query parameters to configure the widget appearance
/// and behavior when embedded via iframe.
///
/// ## Supported URL Parameters
///
/// ### Required
/// - `propertyId` or `property`: Property ID
/// - `unitId` or `unit`: Unit ID
///
/// ### Theme & Colors
/// - `theme`: 'light', 'dark', or 'system' (default: 'system')
/// - `primaryColor`: #RRGGBB hex color
/// - `accentColor`: #RRGGBB hex color
/// - `backgroundColor`: #RRGGBB hex color
/// - `textColor`: #RRGGBB hex color
///
/// ### Branding
/// - `showBranding`: true/false (default: true)
/// - `hideBranding`: true/false (inverse of showBranding)
///
/// ### Payment Methods
/// - `enableStripe`: true/false (default: false)
/// - `enableBankTransfer`: true/false (default: true)
/// - `enablePayOnPlace`: true/false (default: false)
///
/// ### Layout & Style
/// - `months`: 1-4 (number of months to display)
/// - `borderRadius`: 0-20 (corner radius in pixels, default: 8)
/// - `shadowLevel`: 0-5 (elevation intensity, default: 2)
/// - `transparentMode`: true/false (ultra-minimal blend)
/// - `preset`: 'neutral'|'flat'|'material' (predefined theme presets)
///
/// ### Localization
/// - `language` or `locale`: 'en', 'hr', 'de', etc. (default: 'en')
///
/// ## Example Usage
/// ```dart
/// final uri = Uri.parse('https://widget.example.com/?propertyId=abc&unitId=123&theme=dark');
/// final params = EmbedUrlParams.fromUrlParameters(uri);
///
/// if (params.isValid) {
///   // Use params to configure widget
/// } else {
///   print(params.validationError);
/// }
/// ```
///
/// ## Naming Note
/// This class was previously named `WidgetConfig`. It was renamed to `EmbedUrlParams`
/// to avoid confusion with `WidgetSettings` (Firestore-stored configuration).
/// - `EmbedUrlParams` = URL query parameters (runtime, ephemeral)
/// - `WidgetSettings` = Firestore document (persistent, owner-configured)
class EmbedUrlParams {
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

  // Universal theme options
  final int shadowLevel; // 0-5
  final bool transparentMode;
  final String? preset; // 'neutral', 'flat', 'material'

  const EmbedUrlParams({
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
    this.shadowLevel = 2,
    this.transparentMode = false,
    this.preset,
  });

  /// Parse URL parameters into [EmbedUrlParams].
  ///
  /// Example URL:
  /// ```
  /// https://widget.example.com/?propertyId=abc&unitId=123&theme=dark&primaryColor=%236B4CE6
  /// ```
  factory EmbedUrlParams.fromUrlParameters(Uri uri) {
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
    final bool enableStripe =
        params['enableStripe']?.toLowerCase() == 'true';
    final bool enableBank =
        params['enableBankTransfer']?.toLowerCase() != 'false'; // default: true
    final bool enablePayOnPlace =
        params['enablePayOnPlace']?.toLowerCase() == 'true';

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

    // Parse shadow level (0-5)
    int shadowLvl = 2; // default
    if (params['shadowLevel'] != null) {
      final parsed = int.tryParse(params['shadowLevel']!);
      if (parsed != null && parsed >= 0 && parsed <= 5) {
        shadowLvl = parsed;
      }
    }

    // Parse transparent mode
    final bool isTransparent =
        params['transparentMode']?.toLowerCase() == 'true';

    // Parse preset
    final String? themePreset = params['preset'];
    if (themePreset != null &&
        !['neutral', 'flat', 'material'].contains(themePreset.toLowerCase())) {
      // Invalid preset, ignore
    }

    // Sanitize IDs - remove any path segments (e.g., /calendar suffix)
    String? sanitizeId(String? id) {
      if (id == null) return null;
      // Remove any path segments after the ID
      final slashIndex = id.indexOf('/');
      if (slashIndex > 0) {
        return id.substring(0, slashIndex);
      }
      return id;
    }

    return EmbedUrlParams(
      propertyId: sanitizeId(params['propertyId'] ?? params['property']),
      unitId: sanitizeId(params['unitId'] ?? params['unit']),
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
      shadowLevel: shadowLvl,
      transparentMode: isTransparent,
      preset: themePreset?.toLowerCase(),
    );
  }

  /// Parse hex color string to [Color].
  ///
  /// Supports formats: #RRGGBB, RRGGBB, #AARRGGBB, AARRGGBB
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

  /// Create a copy with some fields replaced.
  EmbedUrlParams copyWith({
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
    return EmbedUrlParams(
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

  /// Check if all required parameters are present.
  bool get isValid => propertyId != null && unitId != null;

  /// Get a human-readable validation error message.
  ///
  /// Returns `null` if configuration is valid.
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

/// Type alias for backward compatibility.
///
/// @deprecated Use [EmbedUrlParams] instead. This alias will be removed in future versions.
typedef WidgetConfig = EmbedUrlParams;
