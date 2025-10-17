import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/error_handler.dart';

/// Helper function to wrap async operations with error handling for Riverpod
///
/// Usage example:
/// ```dart
/// @riverpod
/// class PropertiesNotifier extends _$PropertiesNotifier {
///   @override
///   Future<List<Property>> build() async {
///     return executeAsync(() async {
///       final result = await ref.read(propertyRepositoryProvider).fetchProperties();
///       return result.when(
///         success: (data) => data,
///         failure: (exception) => throw exception,
///       );
///     });
///   }
/// }
/// ```
Future<T> executeAsync<T>(Future<T> Function() operation) async {
  try {
    final result = await operation();
    return result;
  } catch (error, stackTrace) {
    await ErrorHandler.logError(error, stackTrace);
    rethrow;
  }
}

/// Helper function to wrap async operations that return AsyncValue
Future<AsyncValue<T>> executeAsyncValue<T>(
  Future<T> Function() operation,
) async {
  try {
    final result = await operation();
    return AsyncValue.data(result);
  } catch (error, stackTrace) {
    await ErrorHandler.logError(error, stackTrace);
    return AsyncValue.error(error, stackTrace);
  }
}
