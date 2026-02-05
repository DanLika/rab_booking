import '../models/additional_service_model.dart';

/// Repository for managing additional services (parking, breakfast, transfers, etc.)
///
/// Services are stored as subcollection under units:
/// `properties/{propertyId}/units/{unitId}/additional_services/{serviceId}`
abstract class AdditionalServicesRepository {
  /// Fetch all services for a specific unit
  Future<List<AdditionalServiceModel>> fetchByUnit({
    required String propertyId,
    required String unitId,
  });

  /// Create a new service for a unit
  Future<AdditionalServiceModel> create({
    required String propertyId,
    required String unitId,
    required AdditionalServiceModel service,
  });

  /// Update an existing service
  Future<void> update({
    required String propertyId,
    required String unitId,
    required AdditionalServiceModel service,
  });

  /// Delete a service (hard delete)
  Future<void> delete({
    required String propertyId,
    required String unitId,
    required String serviceId,
  });

  /// Reorder services (update sortOrder for multiple services)
  Future<void> reorder({
    required String propertyId,
    required String unitId,
    required List<String> serviceIds,
  });

  /// Stream of services for a unit (real-time updates)
  Stream<List<AdditionalServiceModel>> watchByUnit({
    required String propertyId,
    required String unitId,
  });
}
