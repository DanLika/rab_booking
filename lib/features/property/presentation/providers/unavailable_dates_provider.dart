import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'unavailable_dates_provider.g.dart';

/// Get unavailable dates for a unit
@riverpod
Future<List<DateTime>> unitUnavailableDates(
  Ref ref,
  String unitId,
) async {
  final supabase = Supabase.instance.client;

  try {
    // Fetch all confirmed/pending bookings for this unit
    final response = await supabase
        .from('bookings')
        .select('check_in, check_out')
        .eq('unit_id', unitId)
        .inFilter('status', ['confirmed', 'pending']);

    final unavailableDates = <DateTime>{};

    for (final booking in response as List) {
      final checkIn = DateTime.parse(booking['check_in'] as String);
      final checkOut = DateTime.parse(booking['check_out'] as String);

      // Add all dates between check-in and check-out (inclusive)
      for (var date = checkIn;
          date.isBefore(checkOut) || date.isAtSameMomentAs(checkOut);
          date = date.add(const Duration(days: 1))) {
        unavailableDates.add(DateTime(date.year, date.month, date.day));
      }
    }

    return unavailableDates.toList()..sort();
  } catch (e) {
    // Return empty list on error
    return [];
  }
}
