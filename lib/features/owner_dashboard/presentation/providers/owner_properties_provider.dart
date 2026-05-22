import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';

part 'owner_properties_provider.g.dart';

/// Owner properties provider (REAL-TIME STREAM)
/// Automatically syncs across browser tabs
///
/// ## AutoDispose Decision: TRUE (default @riverpod behavior)
/// AutoDispose is appropriate here because:
/// - Stream re-subscribes quickly on navigation back
/// - Firestore handles caching efficiently
/// - Prevents stale data when user logs out
/// - Memory freed when leaving owner dashboard
///
/// Note: If performance issues arise from frequent re-subscriptions,
/// consider switching to @Riverpod(keepAlive: true)
@riverpod
Stream<List<PropertyModel>> ownerProperties(Ref ref) {
  final auth = FirebaseAuth.instance;
  final ownerId = auth.currentUser?.uid;

  if (ownerId == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return repository.watchOwnerProperties(ownerId);
}

/// Owner properties count
@riverpod
Future<int> ownerPropertiesCount(Ref ref) async {
  final properties = await ref.watch(ownerPropertiesProvider.future);
  return properties.length;
}

/// Get property by ID
///
/// Auth-race guard: cold-boot deep links (e.g. `bookbed://owner/property/<id>`)
/// can fire this provider before Firebase Auth has restored its session.
/// Firestore rules then reject the unauth read and Pigeon surfaces a noisy
/// stacktrace. Hold the provider in `AsyncLoading` until auth settles so
/// PropertyEditLoader keeps showing its UniversalLoader instead of flashing.
/// `ref.watch(enhancedAuthProvider)` also satisfies the provider cache
/// security rule in `.claude/rules/auth.md`.
@riverpod
Future<PropertyModel?> propertyById(Ref ref, String propertyId) async {
  var authState = ref.watch(enhancedAuthProvider);
  if (authState.isLoading) {
    authState = await ref
        .read(enhancedAuthProvider.notifier)
        .stream
        .firstWhere((s) => !s.isLoading);
  }
  if (authState.firebaseUser == null) {
    return null;
  }

  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return await repository.getPropertyById(propertyId);
}

/// Get unit by ID (requires propertyId since units are in subcollection)
@riverpod
Future<UnitModel?> unitById(Ref ref, String propertyId, String unitId) async {
  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return await repository.getUnitById(propertyId, unitId);
}

/// Get unit by ID across all properties (uses collection group query)
/// Useful for routes that only have unitId
@riverpod
Future<UnitModel?> unitByIdAcrossProperties(Ref ref, String unitId) async {
  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return await repository.getUnitByIdAcrossProperties(unitId);
}

/// Get all units for owner (across all properties) - REAL-TIME STREAM
/// Used for calendar views that display all units
/// Automatically syncs across browser tabs
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
