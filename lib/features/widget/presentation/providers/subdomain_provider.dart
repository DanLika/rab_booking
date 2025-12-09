import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/services/subdomain_service.dart';

part 'subdomain_provider.g.dart';

/// Provider for SubdomainService instance.
@riverpod
SubdomainService subdomainService(Ref ref) {
  return SubdomainService();
}

/// Provider that returns just the current subdomain string (if any).
///
/// This is a synchronous provider that doesn't require Firestore lookup.
/// Useful when you just need to check if a subdomain is present.
@riverpod
String? currentSubdomain(Ref ref) {
  final service = ref.watch(subdomainServiceProvider);
  return service.getCurrentSubdomain();
}

/// OPTIMIZED: Cached provider that resolves the current subdomain context from the URL.
///
/// This provider is marked with `keepAlive: true` to cache the result for
/// the entire session, eliminating duplicate Firestore queries when:
/// - Navigating between widget screens
/// - Switching views (year/month calendar)
/// - Accessing subdomain context multiple times
///
/// ## Query Savings
/// BEFORE: 1 Firestore query per page load (no caching)
/// AFTER: 1 Firestore query per session (cached with keepAlive)
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(subdomainContextProvider);
/// contextAsync.when(
///   data: (context) {
///     if (context == null) {
///       // No subdomain in URL - show default widget
///     } else if (!context.found) {
///       // Subdomain not found - show error screen
///     } else {
///       // Use context.property and context.branding
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
@Riverpod(keepAlive: true)
Future<SubdomainContext?> subdomainContext(Ref ref) async {
  final service = ref.watch(subdomainServiceProvider);
  return service.resolveCurrentContext();
}

/// OPTIMIZED: Cached provider that resolves full context from subdomain + slug URL.
///
/// URL format: `https://jasko-rab.bookbed.io/apartman-6`
/// 1. Reuses cached property from [subdomainContextProvider] (no query)
/// 2. Resolves unit by slug (1 query, cached by family param)
///
/// ## Query Savings
/// BEFORE: 2 Firestore queries per navigation (property + unit)
/// AFTER: 0-1 Firestore queries (property cached, unit cached by slug)
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(fullSlugContextProvider('apartman-6'));
/// contextAsync.when(
///   data: (context) {
///     if (context == null) {
///       // No subdomain in URL - fallback to query params
///     } else if (!context.propertyFound) {
///       // Property not found for subdomain
///     } else if (!context.unitFound) {
///       // Unit not found for slug
///     } else {
///       // Use context.propertyId and context.unitId
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
@Riverpod(keepAlive: true)
Future<FullSlugContext?> fullSlugContext(Ref ref, String? urlSlug) async {
  // Step 1: Get property from cached subdomain provider (no query if cached)
  final subdomainCtx = await ref.read(subdomainContextProvider.future);

  if (subdomainCtx == null) {
    // No subdomain in URL
    return null;
  }

  if (!subdomainCtx.found || subdomainCtx.property == null) {
    // Property not found for subdomain
    return FullSlugContext(
      subdomain: subdomainCtx.subdomain,
      slug: urlSlug,
      propertyFound: false,
      unitFound: false,
    );
  }

  final property = subdomainCtx.property!;

  // If no slug provided, return property-only context
  if (urlSlug == null || urlSlug.isEmpty) {
    return FullSlugContext(
      subdomain: subdomainCtx.subdomain,
      propertyFound: true,
      unitFound: false,
      property: property,
      branding: property.branding,
    );
  }

  // Step 2: Resolve unit by slug (1 query, will be cached by family param)
  final service = ref.watch(subdomainServiceProvider);
  final unitContext = await service.resolveUnitBySlug(
    propertyId: property.id,
    slug: urlSlug,
  );

  return FullSlugContext(
    subdomain: subdomainCtx.subdomain,
    slug: urlSlug,
    propertyFound: true,
    unitFound: unitContext?.found ?? false,
    property: property,
    branding: property.branding,
    unitId: unitContext?.unitId,
  );
}
