import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/owner_calendar_widget.dart';
import '../widgets/booking_create_dialog.dart';

/// BedBooking Timeline Calendar Screen
class CalendarWeekViewScreen extends ConsumerWidget {
  const CalendarWeekViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalendar'),
        centerTitle: true,
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'calendar/week'),
      body: const OwnerCalendarWidget(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBookingDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova rezervacija'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCreateBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BookingCreateDialog(),
    );
  }
}
