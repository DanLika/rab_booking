import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/calendar_view_switcher.dart';

/// Provider for current calendar view type
final calendarViewProvider = StateProvider<CalendarViewType>((ref) {
  return CalendarViewType.month; // Default to month view
});
