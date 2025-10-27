import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/models/additional_service_model.dart';

/// Provider for additional services for a unit
final unitAdditionalServicesProvider = FutureProvider.family<List<AdditionalServiceModel>, String>((ref, unitId) async {
  final unitRepo = ref.watch(unitRepositoryProvider);
  final propertyRepo = ref.watch(propertyRepositoryProvider);
  final serviceRepo = ref.watch(additionalServiceRepositoryProvider);

  // Get unit to find property
  final unit = await unitRepo.fetchUnitById(unitId);
  if (unit == null) {
    return [];
  }

  // Get property to find owner
  final property = await propertyRepo.fetchPropertyById(unit.propertyId);
  if (property == null) {
    return [];
  }

  // Get available services for this owner
  final services = await serviceRepo.fetchAvailableServices(property.ownerId);
  return services;
});

/// Provider for selected additional services with quantities
final selectedAdditionalServicesProvider = StateProvider<Map<String, int>>((ref) {
  return {};
});

/// Provider for calculating total additional services price
final additionalServicesTotalProvider = Provider.family<double, (List<AdditionalServiceModel>, Map<String, int>, int, int)>((ref, params) {
  final (services, selectedServices, nights, guests) = params;

  double total = 0.0;

  for (final serviceId in selectedServices.keys) {
    final quantity = selectedServices[serviceId] ?? 0;
    if (quantity <= 0) continue;

    final service = services.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => throw Exception('Service not found'),
    );

    total += service.calculateTotalPrice(
      quantity: quantity,
      nights: nights,
      guests: guests,
    );
  }

  return total;
});
