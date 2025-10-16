import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/user_repository.dart';
import '../repositories/property_repository.dart';
import '../repositories/unit_repository.dart';
import '../repositories/booking_repository.dart';
import '../repositories/supabase/supabase_user_repository.dart';
import '../repositories/supabase/supabase_property_repository.dart';
import '../repositories/supabase/supabase_unit_repository.dart';
import '../repositories/supabase/supabase_booking_repository.dart';

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseUserRepository(client);
});

/// Property repository provider
final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabasePropertyRepository(client);
});

/// Unit repository provider
final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseUnitRepository(client);
});

/// Booking repository provider
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseBookingRepository(client);
});
