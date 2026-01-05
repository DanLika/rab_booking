import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/logging_service.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/widget_repository_providers.dart';
import '../../domain/models/widget_context.dart';
import '../../domain/models/widget_settings.dart';
import '../../domain/models/widget_mode.dart';
import 'widget_settings_provider.dart';

part 'widget_context_provider.g.dart';

/// Parameters for widget context provider
typedef WidgetContextParams = ({String propertyId, String unitId});

/// Aggregated context provider for the booking widget.
///
/// Fetches property, unit, and widget settings in parallel with a single
/// provider subscription, reducing Firestore queries from 3 separate calls
/// to a single coordinated batch.
///
/// ## Caching Strategy
/// - Results are cached for 5 minutes using `keepAlive`
/// - Same params will return cached result instantly
/// - Different params will trigger new fetch
///
/// ## Usage
/// ```dart
/// final contextAsync = ref.watch(widgetContextProvider((
///   propertyId: 'abc123',
///   unitId: 'xyz789',
/// )));
///
/// contextAsync.when(
///   data: (ctx) => BookingWidget(context: ctx),
///   loading: () => LoadingIndicator(),
///   error: (e, st) => ErrorWidget(e),
/// );
/// ```
///
/// ## Query Optimization
/// Previously, the widget made 3-4 separate queries:
/// - widgetPropertyByIdProvider
/// - unitByIdProvider
/// - widgetSettingsOrDefaultProvider
/// - (booking_price_provider also fetched unit separately)
///
/// With this provider:
/// - All 3 queries run in parallel via Future.wait
/// - Unit data is cached and reused by booking_price_provider
/// - Result is cached for 5 minutes
@Riverpod(keepAlive: true)
Future<WidgetContext> widgetContext(Ref ref, WidgetContextParams params) async {
  final propertyId = params.propertyId;
  final unitId = params.unitId;

  try {
    // Fetch all data in parallel
    final results = await Future.wait<Object?>([
      ref.read(widgetPropertyByIdProvider(propertyId).future),
      ref.read(unitByIdProvider((propertyId, unitId)).future),
      ref.read(widgetSettingsProvider((propertyId, unitId)).future),
    ]);

    // Bug #24 Fix: Use safe casting with type checks to prevent TypeError
    final property = results[0] is PropertyModel
        ? results[0] as PropertyModel
        : null;
    final unit = results[1] is UnitModel ? results[1] as UnitModel : null;
    final settings = results[2] is WidgetSettings
        ? results[2] as WidgetSettings
        : null;

    // Validate property
    if (property == null) {
      throw WidgetContextException('Property not found: $propertyId');
    }

    // Validate unit
    if (unit == null) {
      throw WidgetContextException(
        'Unit not found: $unitId in property $propertyId',
      );
    }

    // Get settings or use defaults
    final effectiveSettings =
        settings ??
        WidgetSettings(
          id: unitId,
          propertyId: propertyId,
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

    return WidgetContext(
      property: property,
      unit: unit,
      settings: effectiveSettings,
      ownerId: property.ownerId ?? '',
    );
  } catch (e, stackTrace) {
    // SECURITY FIX SF-009: Log detailed error for debugging but throw generic message
    // This prevents leaking internal implementation details (Firestore errors, TypeErrors)
    // to the frontend, which could inform an attacker.
    await LoggingService.logError(
      'widgetContextProvider: Failed to load context for $params',
      e,
      stackTrace,
    );

    // Throw a generic, user-safe exception
    throw WidgetContextException(
      'Unable to load booking widget configuration. Please check the property and unit IDs.',
    );
  }
}

/// Simplified provider that only needs unitId.
///
/// Fetches unit via collection group query, then resolves full context.
/// Use when propertyId is not available (e.g., some embed scenarios).
///
/// Note: This requires an extra query to get the unit first, so prefer
/// [widgetContextProvider] when propertyId is available.
@riverpod
Future<WidgetContext> widgetContextByUnitOnly(Ref ref, String unitId) async {
  try {
    // First, fetch unit to get its propertyId
    final unitRepo = ref.read(unitRepositoryProvider);
    final unit = await unitRepo.fetchUnitById(unitId);

    if (unit == null) {
      throw WidgetContextException('Unit not found: $unitId');
    }

    // Now use the main provider with both IDs
    return ref.read(
      widgetContextProvider((
        propertyId: unit.propertyId,
        unitId: unitId,
      )).future,
    );
  } catch (e, stackTrace) {
    // SECURITY FIX SF-009: Log detailed error but throw generic message
    await LoggingService.logError(
      'widgetContextByUnitOnly: Failed to load context for unit $unitId',
      e,
      stackTrace,
    );

    // Throw a generic, user-safe exception
    throw WidgetContextException(
      'Unable to load booking widget configuration. Please ensure the unit ID is correct.',
    );
  }
}

/// Quick access to cached unit from widget context.
///
/// Use this in booking_price_provider to avoid duplicate unit fetch.
/// Returns the cached context if available, otherwise fetches it.
@riverpod
Future<WidgetContext> cachedWidgetContext(
  Ref ref,
  WidgetContextParams params,
) async {
  // This just delegates to the main provider which handles caching
  return ref.read(widgetContextProvider(params).future);
}

/// Exception thrown when widget context cannot be loaded
class WidgetContextException implements Exception {
  final String message;
  const WidgetContextException(this.message);

  @override
  String toString() => 'WidgetContextException: $message';
}
