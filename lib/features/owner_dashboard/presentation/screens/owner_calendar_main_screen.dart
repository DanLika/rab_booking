import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/calendar_view_mode.dart';
import '../../domain/models/calendar_filter_options.dart';
import '../providers/owner_calendar_view_provider.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/calendar_filters_provider.dart';
import '../widgets/calendar/calendar_view_switcher.dart';
import '../widgets/calendar/calendar_filter_panel.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/booking_create_dialog.dart';
import '../../utils/calendar_grid_calculator.dart';
import 'owner_week_calendar_screen.dart';
import 'owner_month_calendar_screen.dart';
import 'owner_timeline_calendar_screen.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Owner Calendar Main Screen
/// Container screen with view switcher for Week/Month/Timeline calendars
class OwnerCalendarMainScreen extends ConsumerStatefulWidget {
  const OwnerCalendarMainScreen({super.key});

  @override
  ConsumerState<OwnerCalendarMainScreen> createState() =>
      _OwnerCalendarMainScreenState();
}

class _OwnerCalendarMainScreenState
    extends ConsumerState<OwnerCalendarMainScreen> {
  @override
  void initState() {
    super.initState();
    // Sync view mode with current route on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncViewModeWithRoute();
    });
  }

  /// Sync view mode with current route
  void _syncViewModeWithRoute() {
    final location = GoRouterState.of(context).matchedLocation;
    CalendarViewMode viewMode;

    if (location.contains('/month')) {
      viewMode = CalendarViewMode.month;
    } else if (location.contains('/timeline')) {
      viewMode = CalendarViewMode.timeline;
    } else {
      viewMode = CalendarViewMode.week; // Default
    }

    // Update provider if different
    final currentView = ref.read(ownerCalendarViewProvider);
    if (currentView != viewMode) {
      ref.read(ownerCalendarViewProvider.notifier).setView(viewMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentView = ref.watch(ownerCalendarViewProvider);
    final isCompact = MediaQuery.of(context).size.width < CalendarGridCalculator.mobileBreakpoint;
    final location = GoRouterState.of(context).matchedLocation;
    final filters = ref.watch(calendarFiltersProvider);

    // Extract current route for drawer
    String currentRoute = 'calendar/week'; // Default
    if (location.contains('/month')) {
      currentRoute = 'calendar/month';
    } else if (location.contains('/timeline')) {
      currentRoute = 'calendar/timeline';
    }

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Kalendar',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: OwnerAppDrawer(currentRoute: currentRoute),
      body: _buildCurrentView(currentView),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBookingDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nova rezervacija',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Build the appropriate calendar view based on selected mode
  Widget _buildCurrentView(CalendarViewMode viewMode) {
    switch (viewMode) {
      case CalendarViewMode.week:
        return const OwnerWeekCalendarScreen();
      case CalendarViewMode.month:
        return const OwnerMonthCalendarScreen();
      case CalendarViewMode.timeline:
        return const OwnerTimelineCalendarScreen();
    }
  }

  /// Show create booking dialog
  void _showCreateBookingDialog() async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => const BookingCreateDialog(),
      );

      // If booking was created successfully, refresh calendar
      if (result == true && mounted) {
        try {
          await Future.wait([
            ref.refresh(calendarBookingsProvider.future),
            ref.refresh(allOwnerUnitsProvider.future),
          ]);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Greška pri osvježavanju kalendara: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri otvaranju dijaloga: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
