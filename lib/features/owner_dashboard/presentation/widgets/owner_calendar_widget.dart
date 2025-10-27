import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/owner_calendar_provider.dart';
import 'timeline_calendar_widget.dart';

/// Owner calendar widget with timeline view
/// BedBooking-style timeline: units vertical, dates horizontal
/// Displays ALL units for ALL properties without filters
class OwnerCalendarWidget extends ConsumerStatefulWidget {
  const OwnerCalendarWidget({super.key});

  @override
  ConsumerState<OwnerCalendarWidget> createState() => _OwnerCalendarWidgetState();
}

class _OwnerCalendarWidgetState extends ConsumerState<OwnerCalendarWidget> {

  @override
  Widget build(BuildContext context) {
    // Enable realtime subscription for automatic updates
    ref.watch(ownerCalendarRealtimeManagerProvider);

    // Display TimelineCalendarWidget directly without filters
    return const Padding(
      padding: EdgeInsets.all(24),
      child: TimelineCalendarWidget(),
    );
  }

}
