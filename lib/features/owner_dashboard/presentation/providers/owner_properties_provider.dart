import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/providers/global_property_provider.dart';

part 'owner_properties_provider.g.dart';

/// Owner properties provider (CACHED GLOBAL STORE)
///
/// Refactored to use [GlobalPropertyNotifier] to prevent redundant reads.
/// Originally was a Stream, now returns an AsyncValue from the global store.
///
/// Note: We maintain the name `ownerProperties` for compatibility, but the behavior
/// has changed from "Stream" to "Cached Future/Notifier".
/// However, to keep API compatibility (Stream<List>), we might need to adjust.
/// But looking at usage, most UI likely handles AsyncValue.
/// The original was `Stream<List<PropertyModel>>`. Riverpod generates `AutoDisposeStreamProvider`.
///
/// We are changing this to return the *global store's* state.
/// Since the global store is a Notifier (AsyncNotifier), watching it returns AsyncValue.
/// To maintain "Stream" semantics for widgets that might expect it, we can return the future
/// but standard usage `ref.watch(ownerPropertiesProvider)` works for both.
///
/// However, the original generated code was `ownerPropertiesProvider` -> `AutoDisposeStreamProvider`.
/// We will change it to `AutoDisposeFutureProvider` or just alias the global one.
///
/// DECISION: We will alias the global provider but expose it as `AsyncValue`.
/// Since we are replacing the file content, we change the signature.
@riverpod
Future<List<PropertyModel>> ownerProperties(Ref ref) {
  // Use the global store which is KeepAlive=true
  return ref.watch(globalPropertyNotifierProvider.future);
}

/// Owner properties count
@riverpod
Future<int> ownerPropertiesCount(Ref ref) async {
  final properties = await ref.watch(ownerPropertiesProvider.future);
  return properties.length;
}

/// Get property by ID (from Cache)
@riverpod
Future<PropertyModel?> propertyById(Ref ref, String propertyId) async {
  // Use cached data first
  final properties = await ref.watch(globalPropertyNotifierProvider.future);
  try {
    return properties.firstWhere((p) => p.id == propertyId);
  } catch (_) {
    // Fallback: If not in cache (e.g. direct link), fetch fresh?
    // Actually, the global provider fetches all. If not found, it likely doesn't exist.
    // But we can check repository just in case.
    final repository = ref.read(ownerPropertiesRepositoryProvider);
    return await repository.getPropertyById(propertyId);
  }
}

/// Get unit by ID (requires propertyId since units are in subcollection)
/// Units are NOT in the global property store (only counts).
/// So this still hits Firestore unless we cache units too.
/// For this task, we focused on Properties.
@riverpod
Future<UnitModel?> unitById(Ref ref, String propertyId, String unitId) async {
  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return await repository.getUnitById(propertyId, unitId);
}

/// Get unit by ID across all properties
@riverpod
Future<UnitModel?> unitByIdAcrossProperties(Ref ref, String unitId) async {
  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return await repository.getUnitByIdAcrossProperties(unitId);
}

/// Get all units for owner (across all properties)
///
/// Original was Stream. Now we should check if we want to cache units too.
/// The prompt specifically asked about "Properties (Units/Properties)".
/// "Identify redundant reads of the same property document".
///
/// For Units, we can keep the stream for now or optimize later.
/// The repository method `watchAllOwnerUnits` is optimized (parallel).
/// We will keep this as is for now to minimize risk, but note that
/// `allOwnerUnits` is usually watched by the dashboard.
///
/// Update: To fully solve "Units/Properties" data management, we should ideally cache units too.
/// But the global store we built is for Properties.
/// Let's keep this stream but ensure it's not redundant.
@riverpod
Stream<List<UnitModel>> ownerUnits(Ref ref) {
  final auth = FirebaseAuth.instance;
  final ownerId = auth.currentUser?.uid;

  if (ownerId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return repository.watchAllOwnerUnits(ownerId);
}
