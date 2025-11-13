import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/calendar_view_type.dart';

/// Provider for current calendar view type
final calendarViewProvider = StateProvider<CalendarViewType>((ref) {
  return CalendarViewType.month; // Default to month view
});
