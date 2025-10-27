import '../models/additional_service_model.dart';
import '../models/booking_service_model.dart';

/// Abstract additional service repository interface
abstract class AdditionalServiceRepository {
  /// Get all services for owner
  Future<List<AdditionalServiceModel>> fetchServicesForOwner(String ownerId);

  /// Get available services for owner
  Future<List<AdditionalServiceModel>> fetchAvailableServices(String ownerId);

  /// Get service by ID
  Future<AdditionalServiceModel?> fetchServiceById(String id);

  /// Create new service
  Future<AdditionalServiceModel> createService(AdditionalServiceModel service);

  /// Update service
  Future<AdditionalServiceModel> updateService(AdditionalServiceModel service);

  /// Delete service
  Future<void> deleteService(String id);

  /// Get services attached to a booking
  Future<List<BookingServiceModel>> fetchBookingServices(String bookingId);

  /// Add service to booking
  Future<BookingServiceModel> addServiceToBooking({
    required String bookingId,
    required String serviceId,
    required int quantity,
    required int nights,
    required int guests,
  });

  /// Remove service from booking
  Future<void> removeServiceFromBooking(String bookingServiceId);

  /// Update booking service quantity
  Future<BookingServiceModel> updateBookingServiceQuantity({
    required String bookingServiceId,
    required int quantity,
    required int nights,
    required int guests,
  });

  /// Calculate total services price for booking
  Future<double> calculateServicesTotal(String bookingId);
}
