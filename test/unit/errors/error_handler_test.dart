import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/core/errors/error_handler.dart';
import 'package:rab_booking/core/exceptions/app_exceptions.dart';

void main() {
  group('ErrorHandler Tests', () {
    group('getUserFriendlyMessage', () {
      test('should return Croatian message for NetworkException', () {
        const exception = NetworkException();

        final message = ErrorHandler.getUserFriendlyMessage(exception);

        expect(message, 'Provjerite internet konekciju i pokušajte ponovo.');
      });

      test('should return Croatian message for AuthException', () {
        const exception = AuthException();

        final message = ErrorHandler.getUserFriendlyMessage(exception);

        expect(message, 'Greška prilikom autentifikacije. Molimo prijavite se ponovo.');
      });

      test('should return Croatian message for DatabaseException', () {
        const exception = DatabaseException();

        final message = ErrorHandler.getUserFriendlyMessage(exception);

        expect(message, 'Greška u bazi podataka. Pokušajte ponovo.');
      });

      test('should return exception message for ValidationException', () {
        const exception = ValidationException('Email mora biti validan');

        final message = ErrorHandler.getUserFriendlyMessage(exception);

        expect(message, 'Email mora biti validan');
      });

      test('should return formatted message for PaymentException', () {
        const exception = PaymentException('Card declined');

        final message = ErrorHandler.getUserFriendlyMessage(exception);

        expect(message, 'Greška prilikom plaćanja: Card declined');
      });

      test('should return exception message for BookingException', () {
        final exception = BookingException.unitNotAvailable();

        final message = ErrorHandler.getUserFriendlyMessage(exception);

        expect(message, exception.message);
      });

      test('should return Croatian message for NotFoundException', () {
        const exception = NotFoundException();

        final message = ErrorHandler.getUserFriendlyMessage(exception);

        expect(message, 'Traženi resurs nije pronađen.');
      });

      test('should return Croatian message for ConflictException', () {
        const exception = ConflictException('Duplicate entry');

        final message = ErrorHandler.getUserFriendlyMessage(exception);

        expect(message, 'Konflikt podataka. Duplicate entry');
      });

      test('should return Croatian message for TimeoutException', () {
        const exception = TimeoutException();

        final message = ErrorHandler.getUserFriendlyMessage(exception);

        expect(message, 'Operacija je istekla. Pokušajte ponovo.');
      });

      test('should return Croatian message for AuthorizationException', () {
        const exception = AuthorizationException();

        final message = ErrorHandler.getUserFriendlyMessage(exception);

        expect(message, 'Nemate dozvolu za ovu akciju.');
      });

      test('should return default Croatian message for unknown errors', () {
        final exception = Exception('Unknown error');

        final message = ErrorHandler.getUserFriendlyMessage(exception);

        expect(message, 'Došlo je do neočekivane greške. Pokušajte ponovo.');
      });
    });

    group('logError', () {
      test('should log error without throwing', () async {
        const exception = NetworkException();

        expect(
          () async => await ErrorHandler.logError(exception, StackTrace.current),
          returnsNormally,
        );
      });

      test('should handle null stack trace', () async {
        const exception = DatabaseException();

        expect(
          () async => await ErrorHandler.logError(exception, null),
          returnsNormally,
        );
      });
    });
  });
}
