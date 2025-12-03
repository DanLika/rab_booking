import 'package:freezed_annotation/freezed_annotation.dart';

part 'property_branding_model.freezed.dart';
part 'property_branding_model.g.dart';

/// Branding configuration for a property.
///
/// Used to customize the widget appearance and email notifications
/// for each property owner's brand identity.
@freezed
class PropertyBranding with _$PropertyBranding {
  const factory PropertyBranding({
    /// Custom display name (defaults to property name if null)
    @JsonKey(name: 'display_name') String? displayName,

    /// Logo URL for branding
    @JsonKey(name: 'logo_url') String? logoUrl,

    /// Primary brand color (hex format, e.g., "#1976d2")
    @JsonKey(name: 'primary_color') String? primaryColor,

    /// Secondary brand color (hex format)
    @JsonKey(name: 'secondary_color') String? secondaryColor,

    /// Favicon URL for widget
    @JsonKey(name: 'favicon_url') String? faviconUrl,
  }) = _PropertyBranding;

  const PropertyBranding._();

  /// Create from JSON
  factory PropertyBranding.fromJson(Map<String, dynamic> json) =>
      _$PropertyBrandingFromJson(json);

  /// Check if branding has any customization
  bool get hasCustomBranding =>
      displayName != null ||
      logoUrl != null ||
      primaryColor != null;

  /// Get primary color as Color (for Flutter)
  /// Returns null if primaryColor is not set or invalid
  int? get primaryColorValue {
    if (primaryColor == null) return null;
    try {
      final hex = primaryColor!.replaceFirst('#', '');
      return int.parse('FF$hex', radix: 16);
    } catch (_) {
      return null;
    }
  }
}
