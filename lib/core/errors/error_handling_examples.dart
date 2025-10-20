// ignore_for_file: unused_element, unused_local_variable

/// EXAMPLES: How to use error handling in repositories and providers.
///
/// This file contains example implementations showing how to integrate
/// the error handling system with repositories and Riverpod providers.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart';
import '../utils/result.dart';
import '../utils/async_helpers.dart';
import 'error_handler.dart';

// ============================================================================
// EXAMPLE 1: Repository with Result Pattern
// ============================================================================

/// Example repository showing how to use `Result<T>` for error handling
class ExamplePropertyRepository {
  final SupabaseClient _client;

  ExamplePropertyRepository(this._client);

  /// Fetch properties with proper error handling
  Future<Result<List<Map<String, dynamic>>>> fetchProperties() async {
    try {
      final response = await _client.from('properties').select();

      // Success case
      return Success(response);
    } on SocketException {
      // Network error
      return const Failure(NetworkException('Nema internet konekcije'));
    } on PostgrestException catch (e) {
      // Database error from Supabase
      return Failure(DatabaseException(
        e.message,
        e.code,
        e.details,
      ));
    } catch (e, stackTrace) {
      // Unknown error - log it
      await ErrorHandler.logError(e, stackTrace);
      return const Failure(
        DatabaseException('Greška prilikom dohvaćanja podataka'),
      );
    }
  }

  /// Get property by ID with error handling
  Future<Result<Map<String, dynamic>>> getPropertyById(String id) async {
    try {
      final response = await _client
          .from('properties')
          .select()
          .eq('id', id)
          .single();

      return Success(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // Not found
        return Failure(NotFoundException.resource('Property', id));
      }
      return Failure(DatabaseException(e.message, e.code));
    } on SocketException {
      return const Failure(NetworkException());
    } catch (e, stackTrace) {
      await ErrorHandler.logError(e, stackTrace);
      return const Failure(DatabaseException('Greška prilikom dohvaćanja nekretnine'));
    }
  }

  /// Create property with validation
  Future<Result<Map<String, dynamic>>> createProperty(
    Map<String, dynamic> data,
  ) async {
    try {
      // Validate input
      if (data['title'] == null || data['title'].toString().isEmpty) {
        return const Failure(ValidationException('Naslov je obavezan'));
      }

      final response = await _client
          .from('properties')
          .insert(data)
          .select()
          .single();

      return Success(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique constraint violation
        return const Failure(ConflictException('Nekretnina već postoji'));
      }
      return Failure(DatabaseException(e.message, e.code));
    } on SocketException {
      return const Failure(NetworkException());
    } catch (e, stackTrace) {
      await ErrorHandler.logError(e, stackTrace);
      return const Failure(DatabaseException('Greška prilikom kreiranja nekretnine'));
    }
  }
}

// ============================================================================
// EXAMPLE 2: Riverpod Provider with Error Handling
// ============================================================================

/// Example Riverpod provider showing error handling with AsyncValue
class ExamplePropertiesNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    // Use executeAsync helper to automatically log errors
    return executeAsync(() async {
      // Get repository (assume it's provided)
      final repository = ExamplePropertyRepository(Supabase.instance.client);

      // Call repository method
      final result = await repository.fetchProperties();

      // Handle result with pattern matching
      return result.when(
        success: (properties) => properties,
        failure: (exception) {
          // Throw exception to let Riverpod handle it as AsyncValue.error
          throw exception;
        },
      );
    });
  }

  /// Refresh properties with error handling
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

// ============================================================================
// EXAMPLE 3: UI Widget with Error Handling
// ============================================================================

/// Example widget showing how to handle errors in UI
class ExamplePropertiesScreen extends ConsumerWidget {
  const ExamplePropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider
    final propertiesAsync = ref.watch(examplePropertiesProvider);

    // Handle different states
    return propertiesAsync.when(
      // Success state - display data
      data: (properties) {
        return ListView.builder(
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            return ListTile(
              title: Text(property['title'] ?? ''),
              subtitle: Text(property['location'] ?? ''),
            );
          },
        );
      },

      // Loading state
      loading: () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },

      // Error state
      error: (error, stackTrace) {
        // Show error message using SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ErrorHandler.showErrorSnackBar(context, error);
        });

        // Display error widget with retry button
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                ErrorHandler.getUserFriendlyMessage(error),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Retry by invalidating the provider
                  ref.invalidate(examplePropertiesProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// EXAMPLE 4: Manual Error Handling in Method
// ============================================================================

class ExampleBookingService {
  final SupabaseClient _client;

  ExampleBookingService(this._client);

  /// Example showing manual error handling and user feedback
  Future<void> createBooking(
    BuildContext context,
    Map<String, dynamic> bookingData,
  ) async {
    try {
      // Validate dates
      final checkIn = DateTime.parse(bookingData['check_in']);
      final checkOut = DateTime.parse(bookingData['check_out']);

      if (checkOut.isBefore(checkIn)) {
        throw BookingException.invalidDateRange();
      }

      if (checkIn.isBefore(DateTime.now())) {
        throw BookingException.pastDate();
      }

      // Create booking
      await _client.from('bookings').insert(bookingData);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking successfully created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on BookingException catch (e) {
      // Handle booking-specific errors
      await ErrorHandler.logError(e, StackTrace.current);
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } on PostgrestException catch (e) {
      // Handle database errors
      final exception = DatabaseException(e.message, e.code);
      await ErrorHandler.logError(exception, StackTrace.current);
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(context, exception);
      }
    } on SocketException {
      // Handle network errors
      const exception = NetworkException();
      await ErrorHandler.logError(exception, StackTrace.current);
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(context, exception);
      }
    } catch (e, stackTrace) {
      // Handle unexpected errors
      await ErrorHandler.logError(e, stackTrace);
      if (context.mounted) {
        ErrorHandler.showErrorDialog(context, e);
      }
    }
  }
}

// Dummy provider for example
final examplePropertiesProvider =
    AsyncNotifierProvider.autoDispose<ExamplePropertiesNotifier, List<Map<String, dynamic>>>(
  () => ExamplePropertiesNotifier(),
);
