import '../models/additional_service_model.dart';

/// Repository for managing additional services (parking, breakfast, transfers, etc.)
abstract class AdditionalServicesRepository {
  /// Fetch all services for a specific owner
  Future<List<AdditionalServiceModel>> fetchByOwner(String ownerId);

  /// Fetch services available for a specific unit
  /// Returns services where unitId matches OR unitId is null (available for all units)
  Future<List<AdditionalServiceModel>> fetchByUnit(
    String unitId,
    String ownerId,
  );

  /// Create a new service
  Future<AdditionalServiceModel> create(AdditionalServiceModel service);

  /// Update an existing service
  Future<void> update(AdditionalServiceModel service);

  /// Delete a service
  Future<void> delete(String id);

  /// Reorder services (update sortOrder for multiple services)
  Future<void> reorder(List<String> serviceIds);

  /// Stream of services for an owner (real-time updates)
  Stream<List<AdditionalServiceModel>> watchByOwner(String ownerId);

  /// Stream of services for a unit (real-time updates)
  Stream<List<AdditionalServiceModel>> watchByUnit(
    String unitId,
    String ownerId,
  );
}
