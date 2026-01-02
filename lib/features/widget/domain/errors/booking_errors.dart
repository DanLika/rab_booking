/// Exception thrown when creating a booking fails.
class BookingCreationException implements Exception {
  final String message;

  BookingCreationException(this.message);

  @override
  String toString() => 'BookingCreationException: $message';
}
