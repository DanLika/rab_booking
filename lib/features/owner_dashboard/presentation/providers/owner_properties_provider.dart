import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../shared/providers/repository_providers.dart';

part 'owner_properties_provider.g.dart';

/// Owner properties provider
@riverpod
Future<List<PropertyModel>> ownerProperties(Ref ref) async {
  final auth = FirebaseAuth.instance;
  final ownerId = auth.currentUser?.uid;

  if (ownerId == null) {
    return [];
  }

  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return await repository.getOwnerProperties(ownerId);
}

/// Owner properties count
@riverpod
Future<int> ownerPropertiesCount(Ref ref) async {
  final properties = await ref.watch(ownerPropertiesProvider.future);
  return properties.length;
}

/// Get property by ID
@riverpod
Future<PropertyModel?> propertyById(Ref ref, String propertyId) async {
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

/// Get all units for owner (across all properties)
/// Used for calendar views that display all units
@riverpod
Future<List<UnitModel>> ownerUnits(Ref ref) async {
  final auth = FirebaseAuth.instance;
  final ownerId = auth.currentUser?.uid;

  if (ownerId == null) {
    return [];
  }

  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return await repository.getAllOwnerUnits(ownerId);
}
