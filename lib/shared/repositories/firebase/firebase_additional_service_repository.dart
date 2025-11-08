import 'package:cloud_firestore/cloud_firestore.dart';
import '../additional_service_repository.dart';
import '../../models/additional_service_model.dart';
import '../../models/booking_service_model.dart';

class FirebaseAdditionalServiceRepository implements AdditionalServiceRepository {
  final FirebaseFirestore _firestore;

  FirebaseAdditionalServiceRepository(this._firestore);

  @override
  Future<List<AdditionalServiceModel>> fetchServicesForOwner(String ownerId) async {
    final snapshot = await _firestore
        .collection('additional_services')
        .where('owner_id', isEqualTo: ownerId)
        .get();
    return snapshot.docs
        .map((doc) => AdditionalServiceModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<List<AdditionalServiceModel>> fetchAvailableServices(String ownerId) async {
    final snapshot = await _firestore
        .collection('additional_services')
        .where('owner_id', isEqualTo: ownerId)
        .where('is_active', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => AdditionalServiceModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<AdditionalServiceModel?> fetchServiceById(String id) async {
    final doc = await _firestore.collection('additional_services').doc(id).get();
    if (!doc.exists) return null;
    return AdditionalServiceModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  @override
  Future<AdditionalServiceModel> createService(AdditionalServiceModel service) async {
    final docRef = await _firestore.collection('additional_services').add(service.toJson());
    return service.copyWith(id: docRef.id);
  }

  @override
  Future<AdditionalServiceModel> updateService(AdditionalServiceModel service) async {
    await _firestore.collection('additional_services').doc(service.id).update(service.toJson());
    return service;
  }

  @override
  Future<void> deleteService(String id) async {
    await _firestore.collection('additional_services').doc(id).delete();
  }

  @override
  Future<List<BookingServiceModel>> fetchBookingServices(String bookingId) async {
    final snapshot = await _firestore
        .collection('booking_services')
        .where('booking_id', isEqualTo: bookingId)
        .get();
    return snapshot.docs
        .map((doc) => BookingServiceModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<BookingServiceModel> addServiceToBooking({
    required String bookingId,
    required String serviceId,
    required int quantity,
    required int nights,
    required int guests,
  }) async {
    // Get service details
    final service = await fetchServiceById(serviceId);
    if (service == null) throw Exception('Service not found');

    final totalPrice = service.calculateTotalPrice(
      quantity: quantity,
      nights: nights,
      guests: guests,
    );

    final bookingService = BookingServiceModel(
      id: '',
      bookingId: bookingId,
      serviceId: serviceId,
      quantity: quantity,
      unitPrice: service.price,
      totalPrice: totalPrice,
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore.collection('booking_services').add(bookingService.toJson());
    return bookingService.copyWith(id: docRef.id);
  }

  @override
  Future<void> removeServiceFromBooking(String bookingServiceId) async {
    await _firestore.collection('booking_services').doc(bookingServiceId).delete();
  }

  @override
  Future<BookingServiceModel> updateBookingServiceQuantity({
    required String bookingServiceId,
    required int quantity,
    required int nights,
    required int guests,
  }) async {
    final doc = await _firestore.collection('booking_services').doc(bookingServiceId).get();
    if (!doc.exists) throw Exception('Booking service not found');

    final bookingService = BookingServiceModel.fromJson({...doc.data()!, 'id': doc.id});

    // Get service to recalculate price
    final service = await fetchServiceById(bookingService.serviceId);
    if (service == null) throw Exception('Service not found');

    final totalPrice = service.calculateTotalPrice(
      quantity: quantity,
      nights: nights,
      guests: guests,
    );

    final updated = bookingService.copyWith(
      quantity: quantity,
      totalPrice: totalPrice,
    );

    await _firestore.collection('booking_services').doc(bookingServiceId).update(updated.toJson());
    return updated;
  }

  @override
  Future<double> calculateServicesTotal(String bookingId) async {
    final services = await fetchBookingServices(bookingId);
    return services.fold<double>(0.0, (total, service) => total + service.totalPrice);
  }
}
