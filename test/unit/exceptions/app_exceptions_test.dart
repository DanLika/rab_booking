import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/core/exceptions/app_exceptions.dart';

void main() {
  group('App Exceptions Tests', () {
    group('NetworkException', () {
      test('should create with default message', () {
        const exception = NetworkException();

        expect(exception.message, 'Network connection failed');
        expect(exception.code, 'NETWORK_ERROR');
      });

      test('should create with custom message', () {
        const exception = NetworkException('Custom network error');

        expect(exception.message, 'Custom network error');
        expect(exception.code, 'NETWORK_ERROR');
      });
    });

    group('AuthException', () {
      test('should create with default message', () {
        const exception = AuthException();

        expect(exception.message, 'Authentication failed');
        expect(exception.code, 'AUTH_ERROR');
      });

      test('should create with custom message and code', () {
        const exception = AuthException('Invalid token', 'TOKEN_ERROR');

        expect(exception.message, 'Invalid token');
        expect(exception.code, 'TOKEN_ERROR');
      });
    });

    group('ValidationException', () {
      test('should create with message', () {
        const exception = ValidationException('Invalid email');

        expect(exception.message, 'Invalid email');
        expect(exception.code, 'VALIDATION_ERROR');
      });

      test('should create field validation exception', () {
        final exception = ValidationException.field('email', 'must be valid');

        expect(exception.message, 'email: must be valid');
        expect(exception.code, 'FIELD_VALIDATION_ERROR');
      });
    });

    group('NotFoundException', () {
      test('should create with default message', () {
        const exception = NotFoundException();

        expect(exception.message, 'Resource not found');
        expect(exception.code, 'NOT_FOUND');
      });

      test('should create resource-specific exception', () {
        final exception = NotFoundException.resource('Property', '123');

        expect(exception.message, 'Property with id 123 not found');
        expect(exception.code, 'RESOURCE_NOT_FOUND');
      });
    });

    group('BookingException', () {
      test('should create unit not available exception', () {
        final exception = BookingException.unitNotAvailable();

        expect(exception.message, contains('not available'));
        expect(exception.code, 'UNIT_NOT_AVAILABLE');
      });

      test('should create dates overlap exception', () {
        final exception = BookingException.datesOverlap();

        expect(exception.message, contains('overlap'));
        expect(exception.code, 'DATES_OVERLAP');
      });

      test('should create minimum stay exception with nights count', () {
        final exception = BookingException.minimumStayNotMet(3);

        expect(exception.message, contains('3'));
        expect(exception.message, contains('nights'));
        expect(exception.code, 'MINIMUM_STAY_NOT_MET');
      });

      test('should use singular form for 1 night', () {
        final exception = BookingException.minimumStayNotMet(1);

        expect(exception.message, contains('1 night'));
      });

      test('should create guest count exceeded exception', () {
        final exception = BookingException.guestCountExceeded(4);

        expect(exception.message, contains('4'));
        expect(exception.code, 'GUEST_COUNT_EXCEEDED');
      });

      test('should create cannot cancel exception', () {
        final exception = BookingException.cannotCancel('Too late');

        expect(exception.message, contains('Too late'));
        expect(exception.code, 'CANNOT_CANCEL');
      });

      test('should create invalid date range exception', () {
        final exception = BookingException.invalidDateRange();

        expect(exception.message, contains('after'));
        expect(exception.code, 'INVALID_DATE_RANGE');
      });

      test('should create past date exception', () {
        final exception = BookingException.pastDate();

        expect(exception.message, contains('past'));
        expect(exception.code, 'PAST_DATE');
      });
    });

    group('PaymentException', () {
      test('should create payment failed exception without reason', () {
        final exception = PaymentException.paymentFailed();

        expect(exception.message, 'Payment failed');
        expect(exception.code, 'PAYMENT_FAILED');
      });

      test('should create payment failed exception with reason', () {
        final exception = PaymentException.paymentFailed('Insufficient funds');

        expect(exception.message, 'Payment failed: Insufficient funds');
        expect(exception.code, 'PAYMENT_FAILED');
      });

      test('should create payment cancelled exception', () {
        final exception = PaymentException.paymentCancelled();

        expect(exception.message, contains('cancelled'));
        expect(exception.code, 'PAYMENT_CANCELLED');
      });

      test('should create invalid amount exception', () {
        final exception = PaymentException.invalidAmount();

        expect(exception.message, contains('Invalid'));
        expect(exception.code, 'INVALID_AMOUNT');
      });

      test('should create insufficient funds exception', () {
        final exception = PaymentException.insufficientFunds();

        expect(exception.message, contains('Insufficient'));
        expect(exception.code, 'INSUFFICIENT_FUNDS');
      });
    });

    group('Exception toString', () {
      test('should format with code', () {
        const exception = NetworkException('Test error');

        expect(exception.toString(), '[NETWORK_ERROR] Test error');
      });

      test('should format without code', () {
        const exception = ValidationException('Test validation');

        final string = exception.toString();
        expect(string, contains('Test validation'));
      });
    });
  });
}
