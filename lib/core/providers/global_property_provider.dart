import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Remove direct import of implementation class to decouple
import '../../shared/models/property_model.dart';
import '../../shared/models/property_summary_model.dart';
import '../../shared/providers/repository_providers.dart';
import '../../core/services/logging_service.dart';

part 'global_property_provider.g.dart';

/// GLOBAL STORE for Owner Properties
///
/// Goal: Load once, cache in memory, update optimistically.
/// Solves: Redundant Firestore reads when navigating between tabs.
///
/// Pattern:
/// - Fetches on first read.
/// - Keeps alive during session (`keepAlive: true`).
/// - Updates local state immediately on write (Optimistic UI).
/// - Reverts if backend fails.
@Riverpod(keepAlive: true)
class GlobalPropertyNotifier extends _$GlobalPropertyNotifier {
  @override
  FutureOr<List<PropertyModel>> build() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Fetch initial data
    final repository = ref.read(ownerPropertiesRepositoryProvider);
    return await repository.getOwnerProperties(user.uid);
  }

  /// Force refresh from backend
  Future<void> refresh() async {
    state = const AsyncLoading();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = const AsyncData([]);
      return;
    }

    try {
      final repository = ref.read(ownerPropertiesRepositoryProvider);
      final properties = await repository.getOwnerProperties(user.uid);
      state = AsyncData(properties);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Optimistic Update: Update a property
  Future<void> updateProperty({
    required String propertyId,
    String? name,
    String? description,
    String? location,
    // Add other fields as needed
  }) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // 1. Find and update locally
    final index = currentState.indexWhere((p) => p.id == propertyId);
    if (index == -1) return;

    final oldProperty = currentState[index];
    final updatedProperty = oldProperty.copyWith(
      name: name ?? oldProperty.name,
      description: description ?? oldProperty.description,
      location: location ?? oldProperty.location,
      updatedAt: DateTime.now(),
    );

    final newList = List<PropertyModel>.from(currentState);
    newList[index] = updatedProperty;

    // 2. Apply local state immediately
    state = AsyncData(newList);

    // 3. Call Backend
    try {
      final repository = ref.read(ownerPropertiesRepositoryProvider);
      await repository.updateProperty(
        propertyId: propertyId,
        name: name,
        description: description,
        location: location,
      );
      // Success: No action needed, local state is already correct (mostly)
    } catch (e, st) {
      // 4. Revert on failure
      LoggingService.logError('Failed to update property optimistically', e, st);
      state = AsyncData(currentState); // Revert to old list
      throw e;
    }
  }

  /// Optimistic Create
  Future<void> createProperty(PropertyModel newProperty) async {
    final currentState = state.valueOrNull ?? [];

    // 1. Optimistic Update (with temp ID if needed, but usually we wait for server)
    // Here we assume newProperty is a template.
    // Ideally we should use the repository return value.

    try {
      final repository = ref.read(ownerPropertiesRepositoryProvider);

      // We pass the fields from the model
      // Note: This assumes createProperty accepts these fields.
      // If newProperty has an ID, we might ignore it or use it as a temp.

      final createdProperty = await repository.createProperty(
        ownerId: newProperty.ownerId ?? FirebaseAuth.instance.currentUser!.uid,
        name: newProperty.name,
        description: newProperty.description,
        propertyType: newProperty.propertyType.name, // Enum to string
        location: newProperty.location,
        amenities: newProperty.amenities.map((e) => e.name).toList(), // Assuming enum/string
        // Map other fields... simplified for this example
      );

      // 2. Update state with REAL property from server
      final newList = [createdProperty, ...currentState];
      state = AsyncData(newList);

    } catch (e, st) {
      LoggingService.logError('Failed to create property', e, st);
      throw e;
    }
  }

  /// Update local state manually (e.g. after a separate repository call)
  void updateLocal(PropertyModel property) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final index = currentState.indexWhere((p) => p.id == property.id);
    if (index != -1) {
      final newList = List<PropertyModel>.from(currentState);
      newList[index] = property;
      state = AsyncData(newList);
    } else {
      state = AsyncData([property, ...currentState]);
    }
  }

  void removeLocal(String propertyId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    final newList = currentState.where((p) => p.id != propertyId).toList();
    state = AsyncData(newList);
  }
}

/// Metadata Provider: Returns lightweight property summaries
/// Derived from the Global Store.
@riverpod
Future<List<PropertySummary>> propertyMetadata(Ref ref) async {
  final properties = await ref.watch(globalPropertyNotifierProvider.future);
  return properties.map((p) => PropertySummary.fromModel(p)).toList();
}
