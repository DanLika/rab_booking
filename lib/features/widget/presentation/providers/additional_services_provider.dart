import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../shared/models/additional_service_model.dart';
import '../../../../shared/repositories/firebase/firebase_additional_services_repository.dart';

/// Provider parameters for fetching additional services
typedef AdditionalServicesParams = ({String propertyId, String unitId});

/// Provider for additional services for a unit
/// Uses subcollection path: properties/{propertyId}/units/{unitId}/additional_services
final unitAdditionalServicesProvider =
    FutureProvider.family<
      List<AdditionalServiceModel>,
      AdditionalServicesParams
    >((ref, params) async {
      // Guard: Return empty list for invalid params to avoid Firestore path errors
      if (params.propertyId.isEmpty || params.unitId.isEmpty) {
        return [];
      }

      try {
        final serviceRepo = ref.watch(additionalServicesRepositoryProvider);

        // Fetch services directly from subcollection
        final services = await serviceRepo.fetchByUnit(
          propertyId: params.propertyId,
          unitId: params.unitId,
        );

        return services;
      } catch (e, stackTrace) {
        // Log error and return empty list for graceful degradation
        await LoggingService.logError(
          'AdditionalServicesProvider: Failed to fetch services for unit ${params.unitId}',
          e,
          stackTrace,
        );
        return [];
      }
    });

/// Provider for selected additional services with quantities
final selectedAdditionalServicesProvider = StateProvider<Map<String, int>>((
  ref,
) {
  return {};
});

/// Provider for calculating total additional services price
final additionalServicesTotalProvider =
    Provider.family<
      double,
      (List<AdditionalServiceModel>, Map<String, int>, int, int)
    >((ref, params) {
      final (services, selectedServices, nights, guests) = params;

      double total = 0.0;

      for (final serviceId in selectedServices.keys) {
        final quantity = selectedServices[serviceId] ?? 0;
        if (quantity <= 0) continue;

        final service = services.firstWhere(
          (s) => s.id == serviceId,
          orElse: () => throw BookingException(
            'Additional service not found',
            code: 'booking/service-not-found',
          ),
        );

        total += service.calculateTotalPrice(
          quantity: quantity,
          nights: nights,
          guests: guests,
        );
      }

      return total;
    });
