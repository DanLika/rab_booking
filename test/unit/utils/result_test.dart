import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/core/utils/result.dart';
import 'package:rab_booking/core/exceptions/app_exceptions.dart';

void main() {
  group('Result Tests', () {
    group('Success', () {
      test('should create success result with data', () {
        const result = Success<int>(42);

        expect(result.isSuccess, true);
        expect(result.isFailure, false);
        expect(result.dataOrNull, 42);
        expect(result.exceptionOrNull, null);
      });

      test('should execute success callback in when', () {
        const result = Success<String>('test data');
        String? actualValue;

        result.when(
          success: (data) {
            actualValue = data;
            return data;
          },
          failure: (exception) => 'failure',
        );

        expect(actualValue, 'test data');
      });

      test('should map data correctly', () {
        const result = Success<int>(10);

        final mapped = result.map((data) => data * 2);

        expect(mapped.isSuccess, true);
        expect(mapped.dataOrNull, 20);
      });

      test('should mapAsync correctly', () async {
        const result = Success<int>(5);

        final mapped = await result.mapAsync((data) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return data + 5;
        });

        expect(mapped.isSuccess, true);
        expect(mapped.dataOrNull, 10);
      });
    });

    group('Failure', () {
      test('should create failure result with exception', () {
        const exception = NetworkException();
        const result = Failure<int>(exception);

        expect(result.isSuccess, false);
        expect(result.isFailure, true);
        expect(result.dataOrNull, null);
        expect(result.exceptionOrNull, exception);
      });

      test('should execute failure callback in when', () {
        const exception = DatabaseException();
        const result = Failure<String>(exception);
        AppException? actualException;

        result.when(
          success: (data) => data,
          failure: (ex) {
            actualException = ex;
            return 'failure';
          },
        );

        expect(actualException, exception);
      });

      test('should propagate failure through map', () {
        const exception = ValidationException('Invalid data');
        const result = Failure<int>(exception);

        final mapped = result.map((data) => data * 2);

        expect(mapped.isFailure, true);
        expect(mapped.exceptionOrNull, exception);
      });

      test('should propagate failure through mapAsync', () async {
        const exception = AuthException();
        const result = Failure<int>(exception);

        final mapped = await result.mapAsync((data) async => data + 5);

        expect(mapped.isFailure, true);
        expect(mapped.exceptionOrNull, exception);
      });
    });

    group('Result pattern matching', () {
      test('should handle different result types', () {
        const successResult = Success<int>(100);
        const failureResult = Failure<int>(NetworkException());

        final successValue = successResult.when(
          success: (data) => 'Success: $data',
          failure: (exception) => 'Failed',
        );

        final failureValue = failureResult.when(
          success: (data) => 'Success: $data',
          failure: (exception) => 'Failed: ${exception.message}',
        );

        expect(successValue, 'Success: 100');
        expect(failureValue, contains('Failed'));
      });

      test('should chain map operations on success', () {
        const result = Success<int>(10);

        final chained = result
            .map((data) => data * 2) // 20
            .map((data) => data + 5) // 25
            .map((data) => data.toString()); // "25"

        expect(chained.dataOrNull, '25');
      });

      test('should stop chain on first failure', () {
        const result = Success<int>(10);

        final chained = result
            .map((data) => data * 2) // 20
            .map<int>((data) => throw const ValidationException('Error'))
            .map((data) => (data as int) + 5); // Should not execute

        expect(chained.isFailure, true);
        expect(chained.exceptionOrNull, isA<ValidationException>());
      });
    });
  });
}
