import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/widget_settings.dart';
import '../../domain/models/widget_mode.dart';
import '../../../../shared/providers/widget_repository_providers.dart';

// NOTE: widgetSettingsRepositoryProvider is defined in repository_providers.dart
// Do NOT redefine it here to avoid duplicate providers and ensure consistent
// dependency injection (using firestoreProvider instead of direct instance).

/// Provider for widget settings by property and unit ID
///
/// Usage:
/// ```dart
/// final settings = ref.watch(widgetSettingsProvider(propertyId, unitId));
/// ```
final widgetSettingsProvider =
    FutureProvider.family<WidgetSettings?, (String propertyId, String unitId)>((
      ref,
      params,
    ) async {
      final (propertyId, unitId) = params;
      final repository = ref.read(widgetSettingsRepositoryProvider);

      return await repository.getWidgetSettings(
        propertyId: propertyId,
        unitId: unitId,
      );
    });

/// Stream provider for real-time widget settings updates
///
/// Usage:
/// ```dart
/// final settingsStream = ref.watch(widgetSettingsStreamProvider(propertyId, unitId));
/// ```
final widgetSettingsStreamProvider =
    StreamProvider.family<WidgetSettings?, (String propertyId, String unitId)>((
      ref,
      params,
    ) {
      final (propertyId, unitId) = params;
      final repository = ref.read(widgetSettingsRepositoryProvider);

      return repository.watchWidgetSettings(
        propertyId: propertyId,
        unitId: unitId,
      );
    });

/// Provider to check if widget settings exist
final widgetSettingsExistProvider =
    FutureProvider.family<bool, (String propertyId, String unitId)>((
      ref,
      params,
    ) async {
      final (propertyId, unitId) = params;
      final repository = ref.read(widgetSettingsRepositoryProvider);

      return await repository.settingsExist(
        propertyId: propertyId,
        unitId: unitId,
      );
    });

/// Provider for all widget settings of a property
final allPropertyWidgetSettingsProvider =
    FutureProvider.family<List<WidgetSettings>, String>((
      ref,
      propertyId,
    ) async {
      final repository = ref.read(widgetSettingsRepositoryProvider);
      return await repository.getAllPropertySettings(propertyId);
    });

/// Provider for default widget settings (when no custom settings exist)
///
/// Returns default settings that can be used as fallback
final defaultWidgetSettingsProvider = Provider<WidgetSettings>((ref) {
  // LOGIC-004 FIX: Provide comprehensive default settings
  // This ensures that when a unit has no saved settings, the widget falls
  // back to a safe, functional, and predictable configuration instead of
  // failing due to null values for critical fields.
  return WidgetSettings(
    id: 'default',
    propertyId: 'default',
    ownerId:
        null, // ownerId should be populated by the caller when using defaults
    widgetMode:
        WidgetMode.bookingPending, // Safest default: no payment processing
    minNights: 1, // Universal default for minimum stay
    globalDepositPercentage: 20, // Common default deposit
    stripeConfig: null, // Default to disabled
    bankTransferConfig: null, // Default to disabled
    allowPayOnArrival: false, // Default to disabled for security
    requireOwnerApproval: true, // Safest default: always require approval
    allowGuestCancellation: true, // Common default
    cancellationDeadlineHours: 48, // Common default (2 days)
    contactOptions: const ContactOptions(
      showPhone: false,
      showEmail: false,
    ),
    emailConfig: const EmailNotificationConfig(), // Defaults to disabled
    taxLegalConfig: const TaxLegalConfig(enabled: false), // Default to disabled
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
});

/// Helper provider to get settings or default
///
/// This provider automatically falls back to default settings if none exist
final widgetSettingsOrDefaultProvider =
    FutureProvider.family<WidgetSettings, (String propertyId, String unitId)>((
      ref,
      params,
    ) async {
      final (propertyId, unitId) = params;

      // Defensive check: ensure unitId and propertyId are not empty
      // This check must be done early, before any repository calls
      if (unitId.isEmpty || propertyId.isEmpty) {
        throw ArgumentError('unitId and propertyId must not be empty');
      }

      // Try to get custom settings
      final customSettings = await ref.read(
        widgetSettingsProvider((propertyId, unitId)).future,
      );

      if (customSettings != null) {
        return customSettings;
      }

      // Fall back to default settings
      return ref
          .read(defaultWidgetSettingsProvider)
          .copyWith(id: unitId, propertyId: propertyId);
    });
