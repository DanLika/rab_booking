/// Unit resolver for hybrid slug-based URLs
///
/// This utility resolves unit IDs from hybrid slug URLs
/// Example: "apartman-6-gMIOos" → full unit ID "gMIOos56siO74VkCsSwY"
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'slug_utils.dart';
import '../services/logging_service.dart';

/// Resolve full unit ID from hybrid slug or legacy unit ID
///
/// Supports two URL formats:
/// 1. Hybrid slug: `/booking/apartman-6-gMIOos` → extracts "gMIOos" → queries Firestore
/// 2. Legacy ID: `/?unit=gMIOos56siO74VkCsSwY` → returns as-is
///
/// Returns null if unit cannot be found
Future<String?> resolveUnitId(String input) async {
  if (input.isEmpty) return null;

  // Check if input looks like a hybrid slug (contains hyphens)
  if (input.contains('-')) {
    // Try to parse as hybrid slug
    final shortId = parseShortIdFromHybridSlug(input);
    if (shortId != null) {
      // Query Firestore for unit starting with this short ID
      return await _findUnitByShortId(shortId);
    }
  }

  // If not a hybrid slug, assume it's a legacy full unit ID
  // Validate it exists in Firestore
  final exists = await _validateUnitExists(input);
  return exists ? input : null;
}

/// Find unit document ID by short ID prefix
///
/// Queries all units across all properties where document ID starts with shortId
Future<String?> _findUnitByShortId(String shortId) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Query units collection group (searches across all properties)
    final querySnapshot = await firestore
        .collectionGroup('units')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: shortId)
        .where(FieldPath.documentId, isLessThan: '$shortId\uf8ff')
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    // Return the full document ID
    return querySnapshot.docs.first.id;
  } catch (e) {
    LoggingService.log('Error finding unit by short ID: $e', tag: 'UnitResolver');
    return null;
  }
}

/// Validate that a unit exists in Firestore
///
/// This is used for legacy full unit IDs to ensure they're valid
Future<bool> _validateUnitExists(String unitId) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Query collection group to find this unit
    final querySnapshot = await firestore
        .collectionGroup('units')
        .where(FieldPath.documentId, isEqualTo: unitId)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    LoggingService.log('Error validating unit: $e', tag: 'UnitResolver');
    return false;
  }
}

/// Resolve unit ID with property ID (if known)
///
/// More efficient when property ID is already known
Future<String?> resolveUnitIdWithProperty(
  String input,
  String propertyId,
) async {
  if (input.isEmpty) return null;

  try {
    final firestore = FirebaseFirestore.instance;

    // Check if input is a hybrid slug
    if (input.contains('-')) {
      final shortId = parseShortIdFromHybridSlug(input);
      if (shortId == null) return null;

      // Query within specific property
      final querySnapshot = await firestore
          .collection('properties')
          .doc(propertyId)
          .collection('units')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: shortId)
          .where(FieldPath.documentId, isLessThan: '$shortId\uf8ff')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.id : null;
    }

    // Legacy full ID - validate it exists in this property
    final doc = await firestore
        .collection('properties')
        .doc(propertyId)
        .collection('units')
        .doc(input)
        .get();

    return doc.exists ? input : null;
  } catch (e) {
    LoggingService.log('Error resolving unit with property: $e', tag: 'UnitResolver');
    return null;
  }
}

/// Get unit data by resolved ID
///
/// Returns unit document data including propertyId
Future<Map<String, dynamic>?> getUnitData(String unitId) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Query collection group to get the unit
    final querySnapshot = await firestore
        .collectionGroup('units')
        .where(FieldPath.documentId, isEqualTo: unitId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final doc = querySnapshot.docs.first;
    return {
      ...doc.data(),
      'id': doc.id,
      'propertyId': doc.reference.parent.parent?.id,
    };
  } catch (e) {
    LoggingService.log('Error getting unit data: $e', tag: 'UnitResolver');
    return null;
  }
}
