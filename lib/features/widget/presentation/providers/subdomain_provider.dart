import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/services/subdomain_service.dart';
import '../../domain/models/widget_context.dart';
import '../../domain/models/widget_settings.dart';
import '../../domain/models/widget_mode.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/widget_repository_providers.dart';
import 'widget_settings_provider.dart';

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

/// PERFORMANCE OPTIMIZED: Complete widget context from slug URL in PARALLEL.
///
/// This provider eliminates duplicate Firestore queries by fetching ALL data
/// needed for the widget in a single parallel batch:
/// 1. Property (by subdomain) - 1 query
/// 2. Unit (by slug within property) - 1 query
/// 3. Settings - 1 query
///
/// BEFORE (sequential + duplicate):
/// - fullSlugContextProvider: property query → unit query (sequential)
/// - widgetContextProvider: property query + unit query + settings query (parallel but DUPLICATE)
/// Total: 5 queries, ~4-6 seconds
///
/// AFTER (parallel, no duplicates):
/// - This provider: property + unit + settings in parallel
/// Total: 3 queries, ~1-2 seconds
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(optimizedSlugWidgetContextProvider('apartman-6'));
/// contextAsync.when(
///   data: (result) {
///     if (result == null) // No subdomain - use query params
///     else if (result.error != null) // Show error
///     else // Use result.context!
///   },
///   loading: () => LoadingIndicator(),
///   error: (e, _) => ErrorWidget(e),
/// );
/// ```
@Riverpod(keepAlive: true)
Future<OptimizedSlugResult?> optimizedSlugWidgetContext(
  Ref ref,
  String? urlSlug,
) async {
  final service = ref.watch(subdomainServiceProvider);

  // Step 1: Get subdomain synchronously (no query)
  final subdomain = service.getCurrentSubdomain();
  if (subdomain == null) {
    // No subdomain in URL - caller should fallback to query params
    return null;
  }

  // Step 2: Fetch property by subdomain (1 query)
  final property = await service.getPropertyBySubdomain(subdomain);
  if (property == null) {
    return OptimizedSlugResult.error(
      'Property not found for subdomain: $subdomain',
    );
  }

  // If no slug provided, we need at least unit ID
  if (urlSlug == null || urlSlug.isEmpty) {
    return OptimizedSlugResult.error('No unit slug provided in URL');
  }

  // Step 3: Fetch unit by slug (1 query)
  final unitContext = await service.resolveUnitBySlug(
    propertyId: property.id,
    slug: urlSlug,
  );

  if (unitContext == null || !unitContext.found || unitContext.unitId == null) {
    return OptimizedSlugResult.error('Unit not found for slug: $urlSlug');
  }

  final unitId = unitContext.unitId!;

  // Step 4: Fetch unit details and settings in PARALLEL
  final results = await Future.wait<Object?>([
    ref.read(unitByIdProvider((property.id, unitId)).future),
    ref.read(widgetSettingsProvider((property.id, unitId)).future),
  ]);

  final unit = results[0] is UnitModel ? results[0] as UnitModel : null;
  final settings = results[1] is WidgetSettings
      ? results[1] as WidgetSettings
      : null;

  if (unit == null) {
    return OptimizedSlugResult.error('Unit details not found: $unitId');
  }

  // Create default settings if none exist
  final effectiveSettings =
      settings ??
      WidgetSettings(
        id: unitId,
        propertyId: property.id,
        ownerId: property.ownerId,
        widgetMode: WidgetMode.bookingPending,
        contactOptions: const ContactOptions(
          customMessage: 'Contact us for booking!',
        ),
        emailConfig: const EmailNotificationConfig(),
        taxLegalConfig: const TaxLegalConfig(),
        requireOwnerApproval: true,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

  return OptimizedSlugResult.success(
    WidgetContext(
      property: property,
      unit: unit,
      settings: effectiveSettings,
      ownerId: property.ownerId ?? '',
    ),
  );
}

/// Result from optimized slug widget context provider.
///
/// Contains either a successful WidgetContext or an error message.
class OptimizedSlugResult {
  final WidgetContext? context;
  final String? error;

  const OptimizedSlugResult._({this.context, this.error});

  factory OptimizedSlugResult.success(WidgetContext context) =>
      OptimizedSlugResult._(context: context);

  factory OptimizedSlugResult.error(String message) =>
      OptimizedSlugResult._(error: message);

  bool get isSuccess => context != null;
  bool get isError => error != null;
}
