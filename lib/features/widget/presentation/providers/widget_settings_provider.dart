import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/widget_settings.dart';
import '../../domain/models/widget_mode.dart';
import '../../../../shared/providers/repository_providers.dart';

// NOTE: widgetSettingsRepositoryProvider is defined in repository_providers.dart
// Do NOT redefine it here to avoid duplicate providers and ensure consistent
// dependency injection (using firestoreProvider instead of direct instance).

/// Provider for widget settings by property and unit ID
///
/// Usage:
/// ```dart
/// final settings = ref.watch(widgetSettingsProvider(propertyId, unitId));
/// ```
final widgetSettingsProvider = FutureProvider.family<WidgetSettings?, (String propertyId, String unitId)>((
  ref,
  params,
) async {
  final (propertyId, unitId) = params;
  final repository = ref.read(widgetSettingsRepositoryProvider);

  return await repository.getWidgetSettings(propertyId: propertyId, unitId: unitId);
});

/// Stream provider for real-time widget settings updates
///
/// Usage:
/// ```dart
/// final settingsStream = ref.watch(widgetSettingsStreamProvider(propertyId, unitId));
/// ```
final widgetSettingsStreamProvider = StreamProvider.family<WidgetSettings?, (String propertyId, String unitId)>((
  ref,
  params,
) {
  final (propertyId, unitId) = params;
  final repository = ref.read(widgetSettingsRepositoryProvider);

  return repository.watchWidgetSettings(propertyId: propertyId, unitId: unitId);
});

/// Provider to check if widget settings exist
final widgetSettingsExistProvider = FutureProvider.family<bool, (String propertyId, String unitId)>((
  ref,
  params,
) async {
  final (propertyId, unitId) = params;
  final repository = ref.read(widgetSettingsRepositoryProvider);

  return await repository.settingsExist(propertyId: propertyId, unitId: unitId);
});

/// Provider for all widget settings of a property
final allPropertyWidgetSettingsProvider = FutureProvider.family<List<WidgetSettings>, String>((ref, propertyId) async {
  final repository = ref.read(widgetSettingsRepositoryProvider);
  return await repository.getAllPropertySettings(propertyId);
});

/// Provider for default widget settings (when no custom settings exist)
///
/// Returns default settings that can be used as fallback
final defaultWidgetSettingsProvider = Provider<WidgetSettings>((ref) {
  return WidgetSettings(
    id: 'default',
    propertyId: 'default',
    widgetMode: WidgetMode.bookingPending, // Default: simple booking without payment
    contactOptions: const ContactOptions(customMessage: 'Kontaktirajte nas za rezervaciju!'),
    emailConfig: const EmailNotificationConfig(), // Default disabled email config
    taxLegalConfig: const TaxLegalConfig(), // Default enabled tax/legal config
    requireOwnerApproval: true, // Default: require approval
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
});

/// Helper provider to get settings or default
///
/// This provider automatically falls back to default settings if none exist
final widgetSettingsOrDefaultProvider = FutureProvider.family<WidgetSettings, (String propertyId, String unitId)>((
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
  final customSettings = await ref.read(widgetSettingsProvider((propertyId, unitId)).future);

  if (customSettings != null) {
    return customSettings;
  }

  // Fall back to default settings
  return ref.read(defaultWidgetSettingsProvider).copyWith(id: unitId, propertyId: propertyId);
});
