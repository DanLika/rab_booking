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

      // Skip view.bookbed.io domain (booking details page, not a property subdomain)
      if (host == 'view.bookbed.io' || host.startsWith('view.')) {
        return null;
      }

      // Parse subdomain from hostname (e.g., "jasko-rab.bookbed.io" -> "jasko-rab")
      // But skip if it's a known special domain like "view", "app", "www"
      final parts = host.split('.');
      if (parts.length >= 3) {
        final subdomain = parts.first.toLowerCase();
        // Skip known special domains that are not property subdomains
        const specialDomains = ['view', 'app', 'www', 'owner', 'admin'];
        if (specialDomains.contains(subdomain)) {
          return null;
        }
        return subdomain;
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
      final property = PropertyModel.fromJson({...doc.data(), 'id': doc.id});

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
    return property.branding ?? PropertyBranding(displayName: property.name);
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
      return SubdomainContext(subdomain: subdomain, found: false);
    }

    return SubdomainContext(
      subdomain: subdomain,
      found: true,
      property: property,
      branding: property.branding,
    );
  }

  /// Fetch unit by slug within a property.
  ///
  /// Used for clean URL resolution: `/apartman-6` -> unit with slug "apartman-6"
  /// Returns null if no unit is found with the given slug in the property.
  Future<UnitSlugContext?> resolveUnitBySlug({
    required String propertyId,
    required String slug,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .where('slug', isEqualTo: slug.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return UnitSlugContext(
          slug: slug,
          propertyId: propertyId,
          found: false,
        );
      }

      final doc = snapshot.docs.first;
      return UnitSlugContext(
        slug: slug,
        propertyId: propertyId,
        found: true,
        unitId: doc.id,
      );
    } catch (e) {
      return UnitSlugContext(slug: slug, propertyId: propertyId, found: false);
    }
  }

  /// Resolve full context from subdomain + slug URL.
  ///
  /// URL format: `https://jasko-rab.bookbed.io/apartman-6`
  /// 1. Parse subdomain from hostname -> get property
  /// 2. Parse slug from path -> get unit within property
  ///
  /// Returns null if no subdomain present.
  Future<FullSlugContext?> resolveFullContext({String? urlSlug}) async {
    final subdomain = getCurrentSubdomain();
    if (subdomain == null) {
      return null;
    }

    final property = await getPropertyBySubdomain(subdomain);
    if (property == null) {
      return FullSlugContext(
        subdomain: subdomain,
        slug: urlSlug,
        propertyFound: false,
        unitFound: false,
      );
    }

    // If no slug provided, return property-only context
    if (urlSlug == null || urlSlug.isEmpty) {
      return FullSlugContext(
        subdomain: subdomain,
        propertyFound: true,
        unitFound: false,
        property: property,
        branding: property.branding,
      );
    }

    // Resolve unit by slug
    final unitContext = await resolveUnitBySlug(
      propertyId: property.id,
      slug: urlSlug,
    );

    return FullSlugContext(
      subdomain: subdomain,
      slug: urlSlug,
      propertyFound: true,
      unitFound: unitContext?.found ?? false,
      property: property,
      branding: property.branding,
      unitId: unitContext?.unitId,
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

/// Context resolved from unit slug lookup.
///
/// Contains information about the unit found by slug within a property.
class UnitSlugContext {
  /// The slug parsed from the URL path
  final String slug;

  /// The property ID the slug was looked up within
  final String propertyId;

  /// Whether a unit was found for this slug
  final bool found;

  /// The unit ID (null if not found)
  final String? unitId;

  const UnitSlugContext({
    required this.slug,
    required this.propertyId,
    required this.found,
    this.unitId,
  });
}

/// Full context resolved from subdomain + slug URL.
///
/// URL format: `https://jasko-rab.bookbed.io/apartman-6`
/// Contains both property (from subdomain) and unit (from slug) information.
class FullSlugContext {
  /// The subdomain parsed from the URL hostname
  final String subdomain;

  /// The slug parsed from the URL path (null if root path)
  final String? slug;

  /// Whether a property was found for this subdomain
  final bool propertyFound;

  /// Whether a unit was found for this slug
  final bool unitFound;

  /// The property associated with this subdomain (null if not found)
  final PropertyModel? property;

  /// The branding configuration for this property
  final PropertyBranding? branding;

  /// The unit ID (null if not found or no slug provided)
  final String? unitId;

  const FullSlugContext({
    required this.subdomain,
    this.slug,
    required this.propertyFound,
    required this.unitFound,
    this.property,
    this.branding,
    this.unitId,
  });

  /// Get the property ID (null if not found)
  String? get propertyId => property?.id;

  /// Get the display name (property's display name or subdomain as fallback)
  String get displayName =>
      branding?.displayName ?? property?.name ?? subdomain;

  /// Check if both property and unit were resolved successfully
  bool get isFullyResolved => propertyFound && unitFound && unitId != null;
}
