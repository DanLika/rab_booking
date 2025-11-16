import '../errors/app_exceptions.dart';

/// Result type for functional error handling
/// Represents either a successful result with data or a failure with an exception
abstract class Result<T> {
  const Result();
}

/// Success result with data
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Failure result with exception
class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);
}

/// Extension methods for convenient Result handling
extension ResultExtension<T> on Result<T> {
  /// Check if result is successful
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Get data if success, null if failure
  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;

  /// Get exception if failure, null if success
  AppException? get exceptionOrNull =>
      this is Failure<T> ? (this as Failure<T>).exception : null;

  /// Pattern matching for Result
  /// Execute success callback with data if successful,
  /// or failure callback with exception if failed
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else {
      return failure((this as Failure<T>).exception);
    }
  }

  /// Map data if success, otherwise return failure
  Result<R> map<R>(R Function(T data) transform) {
    if (this is Success<T>) {
      try {
        return Success(transform((this as Success<T>).data));
      } catch (e) {
        if (e is AppException) {
          return Failure(e);
        }
        return const Failure(DatabaseException(message: 'Unexpected error during transformation'));
      }
    }
    return Failure((this as Failure<T>).exception);
  }

  /// Execute async operation on success, otherwise return failure
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    if (this is Success<T>) {
      try {
        final result = await transform((this as Success<T>).data);
        return Success(result);
      } catch (e) {
        if (e is AppException) {
          return Failure(e);
        }
        return const Failure(DatabaseException(message: 'Unexpected error during async transformation'));
      }
    }
    return Failure((this as Failure<T>).exception);
  }
}
