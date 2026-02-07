import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../../../shared/widgets/platform_icon.dart';
import '../../../../../shared/widgets/animations/animated_empty_state.dart';
import '../../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/enums.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../providers/overbooking_detection_provider.dart';
import '../../widgets/calendar/booking_inline_edit_dialog.dart';
import '../../widgets/booking_create_dialog.dart';
import '../../widgets/owner_app_drawer.dart';

/// Month Calendar Screen using Syncfusion Flutter Calendar
/// Provides Month + Schedule views
class MonthCalendarScreen extends ConsumerStatefulWidget {
  const MonthCalendarScreen({super.key});

  @override
  ConsumerState<MonthCalendarScreen> createState() =>
      _MonthCalendarScreenState();
}

class _MonthCalendarScreenState extends ConsumerState<MonthCalendarScreen> {
  final CalendarController _calendarController = CalendarController();
  CalendarView _currentView = CalendarView.month;
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    // Lock orientation to portrait for calendar view
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _calendarController.dispose();
    // Reset orientation preferences when leaving screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _currentView = _currentView == CalendarView.month
          ? CalendarView.schedule
          : CalendarView.month;
      _calendarController.view = _currentView;
    });
  }

  void _goToToday() {
    _calendarController.displayDate = DateTime.now();
  }

  Future<void> _refreshData() async {
    ref.invalidate(calendarBookingsProvider);
    ref.invalidate(allOwnerUnitsProvider);
    ref.invalidate(overbookingConflictsProvider);
  }

  IconData get _viewToggleIcon {
    return _currentView == CalendarView.month
        ? Icons.view_agenda_outlined
        : Icons.calendar_month_outlined;
  }

  String _viewToggleTooltip(AppLocalizations l10n) {
    return _currentView == CalendarView.month
        ? l10n.monthCalendarScheduleView
        : l10n.monthCalendarMonthView;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bookingsAsync = ref.watch(calendarBookingsProvider);
    final unitsAsync = ref.watch(allOwnerUnitsProvider);
    final conflictsAsync = ref.watch(overbookingConflictsProvider);

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.monthCalendarTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (ctx) => Scaffold.of(ctx).openDrawer(),
        actions: [
          // Today button
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            tooltip: l10n.ownerCalendarToday,
            onPressed: _goToToday,
          ),
          // View toggle button
          IconButton(
            icon: Icon(_viewToggleIcon, color: Colors.white),
            tooltip: _viewToggleTooltip(l10n),
            onPressed: _toggleView,
          ),
        ],
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'calendar/month'),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: bookingsAsync.when(
          loading: () => _buildSkeletonLoader(isDark),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (bookingsMap) {
            final units = unitsAsync.valueOrNull ?? [];
            final conflicts = conflictsAsync.valueOrNull ?? [];

            // Build unit name map for display
            final unitNameMap = <String, String>{};
            for (final unit in units) {
              unitNameMap[unit.id] = unit.name;
            }

            // Auto-select first unit or validate selection
            if (units.isNotEmpty) {
              if (_selectedUnitId == null ||
                  !units.any((u) => u.id == _selectedUnitId)) {
                _selectedUnitId = units.first.id;
              }
            }

            // Build set of conflicting booking IDs
            final conflictingBookingIds = <String>{};
            for (final conflict in conflicts) {
              conflictingBookingIds.add(conflict.booking1.id);
              conflictingBookingIds.add(conflict.booking2.id);
            }

            // Flatten all bookings
            final allBookings = <BookingModel>[];
            for (final entry in bookingsMap.entries) {
              allBookings.addAll(entry.value);
            }

            // Filter by selected unit
            final filteredBookings = _selectedUnitId != null
                ? allBookings.where((b) => b.unitId == _selectedUnitId).toList()
                : allBookings;

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildUnitFilter(
                      units,
                      unitNameMap,
                      isDark,
                      theme,
                      l10n,
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildStatusLegend(isDark, theme)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: math.max(
                        600,
                        MediaQuery.of(context).size.height -
                            kToolbarHeight -
                            140,
                      ),
                      child: filteredBookings.isEmpty
                          ? _buildEmptyState()
                          : _buildCalendar(
                              filteredBookings,
                              unitNameMap,
                              conflictingBookingIds,
                              isDark,
                              theme,
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build skeleton loader while data loads
  Widget _buildSkeletonLoader(bool isDark) {
    final baseColor = isDark
        ? SkeletonColors.darkPrimary
        : SkeletonColors.lightPrimary;
    final highlightColor = isDark
        ? SkeletonColors.darkSecondary
        : SkeletonColors.lightSecondary;

    return Column(
      children: [
        // Dropdown placeholder
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // Legend placeholder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        // Calendar grid placeholder
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                6,
                (row) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: List.generate(
                        7,
                        (col) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Shimmer.fromColors(
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build empty state when unit has no bookings
  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedEmptyState(
            icon: Icons.event_note_outlined,
            iconSize: 120,
            title: l10n.monthCalendarNoBookings,
            subtitle: l10n.monthCalendarNoBookingsSubtitle,
            actionButton: FilledButton.icon(
              onPressed: () => _openCreateDialog(DateTime.now()),
              icon: const Icon(Icons.add),
              label: Text(l10n.monthCalendarCreateBooking),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build status legend bar
  Widget _buildStatusLegend(bool isDark, ThemeData theme) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          _buildLegendItem(
            _getBookingColor(BookingStatus.confirmed, isDark),
            l10n.ownerStatusConfirmed,
            theme,
          ),
          _buildLegendItem(
            _getBookingColor(BookingStatus.pending, isDark),
            l10n.ownerStatusPending,
            theme,
          ),
          _buildLegendItem(
            _getBookingColor(BookingStatus.completed, isDark),
            l10n.ownerStatusCompleted,
            theme,
          ),
          _buildLegendItem(
            _getBookingColor(BookingStatus.cancelled, isDark),
            l10n.ownerStatusCancelled,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// Build the Syncfusion calendar widget
  Widget _buildCalendar(
    List<BookingModel> filteredBookings,
    Map<String, String> unitNameMap,
    Set<String> conflictingBookingIds,
    bool isDark,
    ThemeData theme,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Min/max date boundaries
    final now = DateTime.now();
    final minDate = DateTime(now.year - 1);
    final maxDate = DateTime(now.year + 2, 12, 31);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive agenda height for month view
        final double agendaPercent;
        if (screenWidth >= 1200) {
          agendaPercent = 0.30;
        } else if (screenWidth >= 600) {
          agendaPercent = 0.25;
        } else {
          agendaPercent = 0.10;
        }
        final agendaHeight = (constraints.maxHeight * agendaPercent).clamp(
          60.0,
          300.0,
        );

        final screenHeight = MediaQuery.of(context).size.height;
        final isMobile = screenWidth < 600 || screenHeight < 500;

        return SfCalendar(
          key: ValueKey('calendar_${isMobile}_$agendaHeight'),
          controller: _calendarController,
          view: _currentView,
          minDate: minDate,
          maxDate: maxDate,
          dataSource: _BookingDataSource(
            filteredBookings,
            unitNameMap,
            conflictingBookingIds,
            isDark,
          ),
          // Month view settings
          monthViewSettings: MonthViewSettings(
            showAgenda: true,
            agendaViewHeight: agendaHeight,
            agendaItemHeight: isMobile ? 54 : 56,
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            monthCellStyle: MonthCellStyle(
              textStyle: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: isMobile ? 12 : 14,
              ),
              trailingDatesTextStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
              ),
              leadingDatesTextStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
            agendaStyle: AgendaStyle(
              backgroundColor: isDark
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFF8F9FA),
              dayTextStyle: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              dateTextStyle: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              appointmentTextStyle: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Month cell builder for custom cell content
          monthCellBuilder: _currentView == CalendarView.month
              ? (context, details) => _buildMonthCell(details, isDark, theme)
              : null,
          // Schedule view settings
          scheduleViewSettings: ScheduleViewSettings(
            appointmentItemHeight: 62,
            monthHeaderSettings: MonthHeaderSettings(
              height: 80,
              backgroundColor: isDark
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFFEEF0F2),
              monthTextStyle: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            weekHeaderSettings: WeekHeaderSettings(
              height: 40,
              weekTextStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Appearance
          backgroundColor: Colors.transparent,
          todayHighlightColor: theme.colorScheme.primary,
          cellBorderColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
          todayTextStyle: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          headerStyle: CalendarHeaderStyle(
            textAlign: TextAlign.center,
            textStyle: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.transparent,
          ),
          viewHeaderStyle: ViewHeaderStyle(
            dayTextStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          selectionDecoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          // Interaction
          showNavigationArrow: true,
          showDatePickerButton: true,
          allowViewNavigation: true,
          onTap: (details) =>
              _handleCalendarTap(details, filteredBookings, unitNameMap),
          // Custom appointment builder
          appointmentBuilder: (context, details) {
            return _buildAppointmentWidget(
              context,
              details,
              conflictingBookingIds,
              unitNameMap,
              isDark,
            );
          },
        );
      },
    );
  }

  /// Build custom month cell with date number, booking count badge, and status dots
  Widget _buildMonthCell(
    MonthCellDetails details,
    bool isDark,
    ThemeData theme,
  ) {
    final date = details.date;
    final appointments = details.appointments;
    final isToday = _isSameDay(date, DateTime.now());
    final visibleDates = details.visibleDates;

    // Determine if this date is from the current visible month
    // The visible month is the middle of the visibleDates range
    final midDate = visibleDates[visibleDates.length ~/ 2];
    final isCurrentMonth = date.month == midDate.month;

    final textColor = isCurrentMonth
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.4);

    // Collect unique statuses present on this day
    final statusColors = <Color>{};
    for (final apt in appointments) {
      if (apt is _BookingAppointment) {
        statusColors.add(_getBookingColor(apt.booking.status, isDark));
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Stack(
        children: [
          // Date number (top-left)
          Positioned(
            left: 4,
            top: 2,
            child: isToday
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
          ),
          // Booking count badge (top-right)
          if (appointments.isNotEmpty)
            Positioned(
              right: 4,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${appointments.length}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Status dots (bottom-center)
          if (statusColors.isNotEmpty)
            Positioned(
              bottom: 2,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: statusColors
                    .take(4) // Max 4 dots to avoid overflow
                    .map(
                      (color) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Build unit filter dropdown bar
  Widget _buildUnitFilter(
    List<dynamic> units,
    Map<String, String> unitNameMap,
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<String>(
        key: ValueKey('unit_dropdown_$_selectedUnitId'),
        initialValue: _selectedUnitId,
        isExpanded: true,
        dropdownColor: InputDecorationHelper.getDropdownColor(context),
        borderRadius: InputDecorationHelper.dropdownBorderRadius,
        decoration: InputDecorationHelper.buildDecoration(
          labelText: l10n.monthCalendarSelectUnit,
          prefixIcon: const Icon(Icons.apartment_outlined),
          context: context,
        ),
        items: units
            .map(
              (unit) => DropdownMenuItem<String>(
                value: unit.id,
                child: Text(unit.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _selectedUnitId = value;
          });
        },
      ),
    );
  }

  /// Handle tap on calendar
  void _handleCalendarTap(
    CalendarTapDetails details,
    List<BookingModel> allBookings,
    Map<String, String> unitNameMap,
  ) {
    // Tap on appointment → open booking details
    if (details.appointments != null && details.appointments!.isNotEmpty) {
      final appointment = details.appointments!.first;
      if (appointment is! _BookingAppointment) return;

      showDialog(
        context: context,
        builder: (context) =>
            BookingInlineEditDialog(booking: appointment.booking),
      );
      return;
    }

    // Tap on empty date → open create booking dialog
    if (details.date != null && _selectedUnitId != null) {
      _openCreateDialog(details.date!);
    }
  }

  /// Open create booking dialog with pre-filled unit and date
  void _openCreateDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (context) =>
          BookingCreateDialog(unitId: _selectedUnitId, initialCheckIn: date),
    );
  }

  /// Build custom appointment widget with conflict indicator and platform icon
  Widget _buildAppointmentWidget(
    BuildContext context,
    CalendarAppointmentDetails details,
    Set<String> conflictingBookingIds,
    Map<String, String> unitNameMap,
    bool isDark,
  ) {
    final appointment = details.appointments.first;
    if (appointment is! _BookingAppointment) {
      return const SizedBox.shrink();
    }

    final booking = appointment.booking;
    final hasConflict = conflictingBookingIds.contains(booking.id);
    final unitName = unitNameMap[booking.unitId] ?? '';

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600 || screenHeight < 500;

    // Differentiate between small cell bars and large agenda/schedule items
    // Syncfusion returns larger bounds for agenda items
    final isDetailedView =
        _currentView == CalendarView.schedule || details.bounds.height > 40;

    // Status-based color
    final color = _getBookingColor(booking.status, isDark);

    // Prevent rendering if height is too small to avoid negative radius/size issues
    if (details.bounds.height < 2) return const SizedBox.shrink();

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          math.min(4, details.bounds.height / 2),
        ),
        border: hasConflict ? Border.all(color: Colors.red, width: 2) : null,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDetailedView ? 12 : (isMobile ? 2 : 4),
        vertical: isDetailedView ? 4 : (isMobile ? 1 : 2),
      ),
      child: isDetailedView
          ? _buildScheduleAppointment(booking, unitName, hasConflict, isDark)
          : _buildMonthAppointment(
              booking,
              unitName,
              hasConflict,
              isMobile,
              details.bounds.width,
            ),
    );
  }

  /// Compact appointment for month view cells
  Widget _buildMonthAppointment(
    BookingModel booking,
    String unitName,
    bool hasConflict,
    bool isMobile,
    double width,
  ) {
    // Smart-hiding: Hide text if the bar is too thin (e.g., 1 day on narrow screen)
    // 40px is a reasonable threshold for showing at least a few characters
    if (width < 40) return const SizedBox.shrink();

    return Row(
      children: [
        if (hasConflict) ...[
          const Icon(Icons.warning, color: Colors.white, size: 10),
          const SizedBox(width: 2),
        ],
        Expanded(
          child: Text(
            booking.guestName ?? unitName,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 9 : 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Detailed appointment for schedule/agenda view
  Widget _buildScheduleAppointment(
    BookingModel booking,
    String unitName,
    bool hasConflict,
    bool isDark,
  ) {
    return Row(
      children: [
        // Platform icon
        if (PlatformIcon.shouldShowIcon(booking.source))
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PlatformIcon(source: booking.source, size: 24),
          ),
        // Booking info
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Row(
                  children: [
                    if (hasConflict) ...[
                      const Icon(Icons.warning, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                    ],
                    if (booking.guestName != null)
                      Flexible(
                        child: Text(
                          booking.guestName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else if (!PlatformIcon.shouldShowIcon(booking.source))
                      Flexible(
                        child: Text(
                          PlatformIcon.getDisplayName(booking.source),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              Flexible(
                child: Text(
                  '$unitName  ·  ${booking.numberOfNights}n',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getStatusLabel(booking.status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static Color _getBookingColor(BookingStatus status, bool isDark) {
    switch (status) {
      case BookingStatus.confirmed:
        return isDark ? const Color(0xFF2E7D32) : const Color(0xFF43A047);
      case BookingStatus.pending:
        return isDark ? const Color(0xFFE65100) : const Color(0xFFF57C00);
      case BookingStatus.cancelled:
        return isDark ? const Color(0xFF616161) : const Color(0xFF9E9E9E);
      case BookingStatus.completed:
        return isDark ? const Color(0xFF1565C0) : const Color(0xFF1E88E5);
    }
  }

  String _getStatusLabel(BookingStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case BookingStatus.confirmed:
        return l10n.ownerStatusConfirmed;
      case BookingStatus.pending:
        return l10n.ownerStatusPending;
      case BookingStatus.cancelled:
        return l10n.ownerStatusCancelled;
      case BookingStatus.completed:
        return l10n.ownerStatusCompleted;
    }
  }
}

/// Custom Syncfusion data source
class _BookingDataSource extends CalendarDataSource {
  final List<BookingModel> bookings;
  final Map<String, String> unitNameMap;
  final Set<String> conflictingBookingIds;
  final bool isDark;

  _BookingDataSource(
    this.bookings,
    this.unitNameMap,
    this.conflictingBookingIds,
    this.isDark,
  ) {
    appointments = bookings.map((booking) {
      return _BookingAppointment(
        booking: booking,
        unitName: unitNameMap[booking.unitId] ?? '',
        hasConflict: conflictingBookingIds.contains(booking.id),
        isDark: isDark,
      );
    }).toList();
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as _BookingAppointment).booking.checkIn;
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as _BookingAppointment).booking.checkOut;
  }

  @override
  String getSubject(int index) {
    final apt = appointments![index] as _BookingAppointment;
    final booking = apt.booking;
    return booking.guestName ?? apt.unitName;
  }

  @override
  Color getColor(int index) {
    final apt = appointments![index] as _BookingAppointment;
    return _MonthCalendarScreenState._getBookingColor(
      apt.booking.status,
      apt.isDark,
    );
  }

  @override
  bool isAllDay(int index) => true;
}

/// Wrapper class for booking data in Syncfusion calendar
class _BookingAppointment {
  final BookingModel booking;
  final String unitName;
  final bool hasConflict;
  final bool isDark;

  _BookingAppointment({
    required this.booking,
    required this.unitName,
    required this.hasConflict,
    required this.isDark,
  });
}
