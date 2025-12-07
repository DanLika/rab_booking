import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/subdomain_service.dart';

/// Provider for SubdomainService instance.
final subdomainServiceProvider = Provider<SubdomainService>((ref) {
  return SubdomainService();
});

/// Provider that resolves the current subdomain context from the URL.
///
/// This is an async provider that:
/// 1. Parses the subdomain from the current URL
/// 2. Fetches the associated property from Firestore
/// 3. Returns the context with property and branding info
///
/// Usage:
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
final subdomainContextProvider = FutureProvider<SubdomainContext?>((ref) async {
  final service = ref.watch(subdomainServiceProvider);
  return service.resolveCurrentContext();
});

/// Provider that returns just the current subdomain string (if any).
///
/// This is a synchronous provider that doesn't require Firestore lookup.
/// Useful when you just need to check if a subdomain is present.
final currentSubdomainProvider = Provider<String?>((ref) {
  final service = ref.watch(subdomainServiceProvider);
  return service.getCurrentSubdomain();
});

/// Provider that resolves full context from subdomain + slug URL.
///
/// URL format: `https://jasko-rab.bookbed.io/apartman-6`
/// 1. Parse subdomain from hostname -> get property
/// 2. Parse slug from path parameter -> get unit within property
///
/// Usage:
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
final fullSlugContextProvider = FutureProvider.family<FullSlugContext?, String?>((ref, urlSlug) async {
  final service = ref.watch(subdomainServiceProvider);
  return service.resolveFullContext(urlSlug: urlSlug);
});
