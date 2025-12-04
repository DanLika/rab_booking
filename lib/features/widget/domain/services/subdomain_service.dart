import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/property_branding_model.dart';
import '../../../../shared/models/property_model.dart';

/// Service for handling subdomain-based property resolution and branding.
///
/// This service:
/// 1. Parses subdomain from URL (query param for testing, hostname for production)
/// 2. Fetches property by subdomain from Firestore
/// 3. Provides property branding for widget customization
class SubdomainService {
  final FirebaseFirestore _firestore;

  SubdomainService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the current subdomain from the URL.
  ///
  /// Priority:
  /// 1. Query parameter `?subdomain=xxx` (for testing without custom domain)
  /// 2. Hostname subdomain (for production: `xxx.rabbooking.com`)
  ///
  /// Returns null if no subdomain is found.
  String? getCurrentSubdomain() {
    if (!kIsWeb) {
      // Mobile: subdomain not applicable
      return null;
    }

    try {
      final uri = Uri.base;

      // Priority 1: Query parameter (for testing)
      final querySubdomain = uri.queryParameters['subdomain'];
      if (querySubdomain != null && querySubdomain.isNotEmpty) {
        return querySubdomain.toLowerCase();
      }

      // Priority 2: Parse from hostname (production)
      final host = uri.host;

      // Skip localhost and Firebase hosting (default widget URL)
      if (host.contains('localhost') ||
          host.contains('.web.app') ||
          host.contains('.firebaseapp.com')) {
        return null;
      }

      // Parse subdomain from hostname (e.g., "jasko-rab.rabbooking.com" -> "jasko-rab")
      final parts = host.split('.');
      if (parts.length >= 3) {
        final subdomain = parts.first;
        return subdomain.toLowerCase();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch property by subdomain.
  ///
  /// Returns null if no property is found with the given subdomain.
  Future<PropertyModel?> getPropertyBySubdomain(String subdomain) async {
    try {

      final query = await _firestore
          .collection('properties')
          .where('subdomain', isEqualTo: subdomain.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      final property = PropertyModel.fromJson({
        ...doc.data(),
        'id': doc.id,
      });

      return property;
    } catch (e) {
      return null;
    }
  }

  /// Fetch property branding by subdomain.
  ///
  /// Returns a PropertyBranding object with the property's custom branding,
  /// or null if no property is found.
  Future<PropertyBranding?> getPropertyBranding(String subdomain) async {
    final property = await getPropertyBySubdomain(subdomain);
    if (property == null) return null;

    // Return branding or create default branding from property name
    return property.branding ??
        PropertyBranding(
          displayName: property.name,
        );
  }

  /// Resolve property context from current URL.
  ///
  /// This is the main entry point for the widget to determine which property
  /// to show based on the URL. Returns null if no subdomain is present
  /// (meaning widget is accessed directly without property context).
  Future<SubdomainContext?> resolveCurrentContext() async {
    final subdomain = getCurrentSubdomain();
    if (subdomain == null) {
      return null;
    }

    final property = await getPropertyBySubdomain(subdomain);
    if (property == null) {
      return SubdomainContext(
        subdomain: subdomain,
        found: false,
      );
    }

    return SubdomainContext(
      subdomain: subdomain,
      found: true,
      property: property,
      branding: property.branding,
    );
  }
}

/// Context resolved from subdomain URL.
///
/// Contains information about the property and branding to use for the widget.
class SubdomainContext {
  /// The subdomain parsed from the URL
  final String subdomain;

  /// Whether a property was found for this subdomain
  final bool found;

  /// The property associated with this subdomain (null if not found)
  final PropertyModel? property;

  /// The branding configuration for this property (null if not found or no custom branding)
  final PropertyBranding? branding;

  const SubdomainContext({
    required this.subdomain,
    required this.found,
    this.property,
    this.branding,
  });

  /// Get the property ID (null if not found)
  String? get propertyId => property?.id;

  /// Get the display name (property's display name or subdomain as fallback)
  String get displayName =>
      branding?.displayName ?? property?.name ?? subdomain;

  /// Check if this context has custom branding
  bool get hasCustomBranding => branding != null && branding!.hasCustomBranding;
}
