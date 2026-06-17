import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../../../shared/widgets/platform_icon.dart';
import '../../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../../shared/widgets/redesign.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/enums.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../providers/overbooking_detection_provider.dart';
import '../../widgets/calendar/booking_inline_edit_dialog.dart';
import '../../widgets/calendar/month_calendar_kpi_strip.dart';
import '../../widgets/booking_create_dialog.dart';
import '../../widgets/owner_app_drawer.dart';

/// Month Calendar Screen using Syncfusion Flutter Calendar
/// Provides Month + Schedule views
class MonthCalendarScreen extends ConsumerStatefulWidget {
  const MonthCalendarScreen({super.key});

  @override
  ConsumerState<MonthCalendarScreen> createState() =>
      _MonthCalendarScreenState();

  /// Headless render of the premium chrome for the responsive overflow harness
  /// (`test/.../calendar_chrome_responsive_test.dart`). Renders the real chrome
  /// widgets — premium header, legend card, FAB — with the frozen, provider-bound
  /// SfCalendar grid swapped for a sized placeholder so the test needs no
  /// Firebase. The KPI strip + unit-filter dropdown are provider/state-bound and
  /// are intentionally omitted here (covered elsewhere).
  @visibleForTesting
  Widget buildChromeForTest(
    BuildContext context, {
    required bool isMobile,
    int unitCount = 4,
    DateTime? month,
  }) {
    final double pad = isMobile ? _kPagePadHMobile : _kPagePadH;
    return Column(
      children: <Widget>[
        _PremiumCalendarHeader(
          isMobile: isMobile,
          unitCount: unitCount,
          month: month ?? DateTime(2026, 6),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(pad, BBSpace.xxs, pad, _kPagePadBottom),
          child: _CalendarGridCard(
            child: Column(
              children: <Widget>[
                _MonthStatusLegend(bookingCount: 6, unitCount: unitCount),
                SizedBox(
                  height: isMobile ? 360 : 480,
                  child: const Center(child: Text('Grid')),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(pad),
          child: Align(
            alignment: Alignment.centerRight,
            child: _AnimatedGradientFAB(onPressed: () {}),
          ),
        ),
      ],
    );
  }
}

class _MonthCalendarScreenState extends ConsumerState<MonthCalendarScreen> {
  final CalendarController _calendarController = CalendarController();
  CalendarView _currentView = CalendarView.month;
  String? _selectedUnitId;
  // G2: selected day for the mobile day-agenda list below the month grid
  // (defaults to today in the agenda builder).
  DateTime? _selectedDay;

  // Premium-header eyebrow source. Tracks the month the SfCalendar currently
  // displays. Updated from the controller's `displayDate` property-changed
  // notifications (which Syncfusion fires on swipe nav + agenda scroll) — pure
  // State chrome; the frozen SfCalendar widget config is never touched.
  DateTime _displayedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Lock orientation to portrait for calendar view
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _calendarController.addPropertyChangedListener(_onCalendarPropertyChanged);
  }

  /// Keep the header eyebrow in sync with the displayed month. Syncfusion sets
  /// `controller.displayDate` whenever the visible view changes (swipe / agenda
  /// scroll / Today), which notifies the `'displayDate'` property here.
  void _onCalendarPropertyChanged(String property) {
    if (property != 'displayDate') return;
    final DateTime? d = _calendarController.displayDate;
    if (d == null || !mounted) return;
    if (d.year == _displayedMonth.year && d.month == _displayedMonth.month) {
      return;
    }
    setState(() => _displayedMonth = d);
  }

  @override
  void dispose() {
    _calendarController.removePropertyChangedListener(
      _onCalendarPropertyChanged,
    );
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

    final bool hasUnits = unitsAsync.valueOrNull?.isNotEmpty ?? false;
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.monthCalendarTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (ctx) => Scaffold.of(ctx).openDrawer(),
        showTitle: false, // in-body header carries title (audit/126 §2A)
        actions: [
          // Today button
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: l10n.ownerCalendarToday,
            onPressed: _goToToday,
          ),
          // View toggle button
          IconButton(
            icon: Icon(_viewToggleIcon),
            tooltip: _viewToggleTooltip(l10n),
            onPressed: _toggleView,
          ),
        ],
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'calendar/month'),
      floatingActionButton: hasUnits
          ? _AnimatedGradientFAB(
              onPressed: () => _openCreateDialog(DateTime.now()),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                  // Premium header — eyebrow (month · unit count) + "Kalendar"
                  // title + Timeline/Mjesečni view switch (handoff
                  // `calendar-premium.jsx` CALPHeader). Chrome only; mirrors the
                  // Timeline screen. Hidden when owner has no units.
                  if (hasUnits)
                    SliverToBoxAdapter(
                      child: _PremiumCalendarHeader(
                        isMobile: isMobile,
                        unitCount: units.length,
                        month: _displayedMonth,
                      ),
                    ),
                  // Premium KPI strip (audit/117 §B2.4) — chrome over the
                  // FROZEN calendar grid (timeline_dimensions untouched).
                  const SliverToBoxAdapter(child: MonthCalendarKpiStrip()),
                  SliverToBoxAdapter(
                    child: _buildUnitFilter(
                      units,
                      unitNameMap,
                      isDark,
                      theme,
                      l10n,
                    ),
                  ),
                  // Calendar grid wrapped in the premium card (handoff
                  // `calendar-premium.jsx` CALPGridCard): the status legend
                  // becomes the card header, the frozen SfCalendar grid sits
                  // below in a bordered, rounded, soft-shadow surface. The grid
                  // keeps its bounded height via the inner SizedBox — cell
                  // geometry, the controller, and z-index are untouched.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? _kPagePadHMobile : _kPagePadH,
                        BBSpace.xxs,
                        isMobile ? _kPagePadHMobile : _kPagePadH,
                        _kPagePadBottom,
                      ),
                      child: _CalendarGridCard(
                        child: Column(
                          children: [
                            _MonthStatusLegend(
                              bookingCount: filteredBookings.length,
                              unitCount: units.length,
                            ),
                            SizedBox(
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  // G2: mobile day-agenda list (handoff calendar-month.jsx) —
                  // bookings covering the selected day. Mobile only.
                  if (isMobile)
                    SliverToBoxAdapter(
                      child: _buildDayAgenda(filteredBookings, unitNameMap),
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
        child: BbEmptyState(
          icon: 'event_note',
          title: l10n.monthCalendarNoBookings,
          body: l10n.monthCalendarNoBookingsSubtitle,
          primary: BbEmptyStateAction(
            label: l10n.monthCalendarCreateBooking,
            iconLeft: 'add',
            onPressed: () => _openCreateDialog(DateTime.now()),
          ),
        ),
      ),
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
          // i18n: Monday as first day of week (matches Timeline calendar).
          // HR locale text (Pon/Uto/Sri… Backward → Natrag etc.) comes from
          // SfGlobalLocalizations.delegate registered in MaterialApp +
          // syncfusion_localizations dep (audit/82). Affects header
          // day-strip + month-name rendering only; FROZEN calendar cell
          // dimensions untouched.
          firstDayOfWeek: DateTime.monday,
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
            showAgenda:
                !isMobile, // G2: mobile uses the custom day-agenda below
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
              // handoff `--bb-surface-variant` (#F5F5F5 / #1E1E1E)
              backgroundColor: isDark
                  ? BBColor.surfaceVarDark
                  : BBColor.surfaceVarLight,
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
              ? (context, details) =>
                    _buildMonthCell(details, isDark, theme, isMobile)
              : null,
          // Schedule view settings
          scheduleViewSettings: ScheduleViewSettings(
            appointmentItemHeight: 62,
            monthHeaderSettings: MonthHeaderSettings(
              height: 80,
              backgroundColor: isDark
                  ? BBColor.surfaceVarDark
                  : BBColor.surfaceVarLight,
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
    bool isMobile,
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

    // G4 weekend emphasis (handoff calendar-month.jsx): tint SUB/NED cells +
    // amber (tertiary "Golden Sand") weekend date. In-month only — out-of-month
    // dim wins.
    final bool isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final Color weekendAccent = isDark
        ? BBColor.tertiaryDarkMode
        : BBColor.tertiary;
    final Color dateColor = (isWeekend && isCurrentMonth)
        ? weekendAccent
        : textColor;

    // Collect unique statuses present on this day
    final statusColors = <Color>{};
    for (final apt in appointments) {
      if (apt is _BookingAppointment) {
        statusColors.add(_getBookingColor(apt.booking.status, isDark));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: (isWeekend && isCurrentMonth)
            ? weekendAccent.withValues(alpha: 0.05)
            : null,
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
                      color: dateColor,
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
          ),
          // G1 (desktop/tablet): de-cluttered cell — count-badge dropped so the
          // spanning bars read clean (handoff). Status dots are kept on MOBILE
          // only, where G2 suppresses the bars and the dots ARE the indicator.
          if (isMobile && statusColors.isNotEmpty)
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
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double padH = isMobile ? _kPagePadHMobile : _kPagePadH;
    return Padding(
      padding: EdgeInsets.fromLTRB(padH, _kFilterPadV, padH, BBSpace.xxs),
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
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    // G2 mobile: tapping a day selects it (native ring) and drives the
    // day-agenda list below the grid — not a dialog. Agenda items + the FAB own
    // edit/create.
    if (isMobile && _currentView == CalendarView.month) {
      if (details.date != null) {
        final DateTime d = details.date!;
        setState(() => _selectedDay = DateTime(d.year, d.month, d.day));
      }
      return;
    }

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

  // ── G2 mobile day-agenda (handoff calendar-month.jsx) ────────────────────
  // HR weekday + genitive-month names for the agenda header ("Pon, 22. lipnja").
  // Inlined — l10n keys live outside this 2-file scope; the screen's existing
  // l10n debt is tracked in audit/130. Genitive ≠ the header's nominative list.
  static const List<String> _hrWeekdayShort = <String>[
    'Pon',
    'Uto',
    'Sri',
    'Čet',
    'Pet',
    'Sub',
    'Ned',
  ];
  static const List<String> _hrMonthGenitive = <String>[
    'siječnja',
    'veljače',
    'ožujka',
    'travnja',
    'svibnja',
    'lipnja',
    'srpnja',
    'kolovoza',
    'rujna',
    'listopada',
    'studenoga',
    'prosinca',
  ];

  /// Day-agenda list for the selected day (default today). Bookings whose stay
  /// covers the day, each with a kind icon (Dolazak/Odlazak/Boravak), guest +
  /// unit, and a status badge. Tapping an item opens the edit dialog.
  Widget _buildDayAgenda(
    List<BookingModel> bookings,
    Map<String, String> unitNameMap,
  ) {
    final c = BBColor.of(context);
    final DateTime raw = _selectedDay ?? DateTime.now();
    final DateTime day = DateTime(raw.year, raw.month, raw.day);

    bool covers(BookingModel b) {
      final DateTime ci = DateTime(
        b.checkIn.year,
        b.checkIn.month,
        b.checkIn.day,
      );
      final DateTime co = DateTime(
        b.checkOut.year,
        b.checkOut.month,
        b.checkOut.day,
      );
      return !day.isBefore(ci) && !day.isAfter(co); // [checkIn, checkOut]
    }

    final List<BookingModel> dayBookings = bookings.where(covers).toList()
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    final String header =
        '${_hrWeekdayShort[day.weekday - 1]}, '
        '${day.day}. ${_hrMonthGenitive[day.month - 1]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _kPagePadHMobile,
        BBSpace.xs,
        _kPagePadHMobile,
        _kPagePadBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: BBSpace.xs),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    header,
                    style: BBType.h3(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${dayBookings.length} '
                  '${_MonthStatusLegend._rezWord(dayBookings.length)}',
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
          if (dayBookings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: BBSpace.md),
              child: Text(
                'Nema rezervacija za odabrani dan.',
                style: BBType.body(context).copyWith(color: c.textSecondary),
              ),
            )
          else
            ...dayBookings.map((b) => _agendaItem(b, unitNameMap, day, c)),
        ],
      ),
    );
  }

  /// One agenda row — kind icon + guest/unit + status badge.
  Widget _agendaItem(
    BookingModel b,
    Map<String, String> unitNameMap,
    DateTime day,
    BBColorSet c,
  ) {
    final DateTime ci = DateTime(
      b.checkIn.year,
      b.checkIn.month,
      b.checkIn.day,
    );
    final DateTime co = DateTime(
      b.checkOut.year,
      b.checkOut.month,
      b.checkOut.day,
    );
    final bool isArrival = ci == day;
    final bool isDeparture = co == day;
    final IconData kindIcon = isArrival
        ? Icons.login
        : (isDeparture ? Icons.logout : Icons.hotel);
    final String kindLabel = isArrival
        ? 'Dolazak'
        : (isDeparture ? 'Odlazak' : 'Boravak');
    final Color statusColor = b.status.colorOf(context);
    final String unitName = unitNameMap[b.unitId] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: BBSpace.xs),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BBRadius.mdAll,
        border: Border(left: BorderSide(color: statusColor, width: 3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BBRadius.mdAll,
          onTap: () => showDialog(
            context: context,
            builder: (_) => BookingInlineEditDialog(booking: b),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BBSpace.sm),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Icon(kindIcon, size: 18, color: statusColor),
                ),
                const SizedBox(width: BBSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        b.guestName ?? unitName,
                        style: BBType.body(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$unitName · $kindLabel',
                        style: BBType.caption(
                          context,
                        ).copyWith(color: c.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BBSpace.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _kBadgePadH,
                    vertical: _kBadgePadV,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(BBRadius.full),
                  ),
                  child: Text(
                    _getStatusLabel(b.status),
                    style: BBType.caption(
                      context,
                    ).copyWith(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

    // G2: on mobile the month grid is dots-only — bars suppressed; the
    // day-agenda below carries the detail. Schedule view still renders bars.
    if (isMobile && _currentView == CalendarView.month) {
      return const SizedBox.shrink();
    }

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
        // G1 inset highlight (handoff `inset 0 0 0 1px rgba(255,255,255,.18)`),
        // or the conflict ring when overbooked.
        border: hasConflict
            ? Border.all(color: BBColor.error, width: 2)
            : Border.all(color: Colors.white.withValues(alpha: 0.18)),
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
        // G1: trailing night-count (handoff "Xn") when the bar is wide enough
        // to avoid crowding the name.
        if (width >= 80) ...[
          const SizedBox(width: 4),
          Text(
            '${booking.numberOfNights}n',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: isMobile ? 9 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  // Handoff `--bb-status-*` table, dark-lifted variants in dark mode.
  static Color _getBookingColor(BookingStatus status, bool isDark) {
    switch (status) {
      case BookingStatus.confirmed:
        return isDark
            ? BBColor.statusConfirmedDarkMode
            : BBColor.statusConfirmed;
      case BookingStatus.pending:
        return isDark ? BBColor.statusPendingDarkMode : BBColor.statusPending;
      case BookingStatus.cancelled:
        return isDark
            ? BBColor.statusCancelledDarkMode
            : BBColor.statusCancelled;
      case BookingStatus.completed:
        return isDark
            ? BBColor.statusCompletedDarkMode
            : BBColor.statusCompleted;
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

// ── Premium chrome constants (handoff `calendar-premium.jsx`) ──
// In-file copy of the Timeline screen's chrome (b9656008) for Mjesečni↔Timeline
// symmetry. Off-scale values kept exact via named consts (BB* tokens + named
// in-file consts; no bare literals in new chrome). On-scale values
// (4/8/16/24 spacing, 20 radius) use BBSpace/BBRadius directly.
// NOTE: 4th in-file copy of this header/switch — flagged for a future shared
// extraction (BbSegmentedControl / BbPremiumHeader); kept in-file for now to
// keep this fidelity pass scoped to one screen.
const double _kPagePadH = 20.0; // desktop page edge — aligns with KPI strip
const double _kPagePadHMobile =
    12.0; // mobile page edge — aligns with KPI strip
const double _kPagePadBottom = 16.0;
const double _kCardPad = 16.0; // grid-card / legend horizontal padding
const double _kLegendPadV = 12.0; // legend header vertical padding
const double _kFilterPadV = 12.0; // unit-filter top padding (off-scale)
const double _kBadgePadH = 10.0; // status badge horizontal padding
const double _kBadgePadV = 5.0; // status badge vertical padding
const double _kBadgeDot = 7.0; // status badge dot diameter
const double _kFabSize = 56.0; // FAB diameter (handoff CALPFab)
const double _kFabIcon = 28.0; // FAB add-icon size
const double _kSegPadH = 14.0; // view-switch segment horizontal padding
const double _kSegFont = 13.0; // view-switch segment label size
const double _kSegIcon = 16.0; // view-switch segment icon size
const double _kTitleDesktop = 30.0; // "Kalendar" title (desktop)
const double _kTitleMobile = 24.0; // "Kalendar" title (mobile)

/// Premium calendar header — eyebrow (`<Mjesec> <god> · N jedinica`) + the
/// "Kalendar" H1 title + the Timeline/Mjesečni view switch. Pure (no provider
/// watch) so `buildChromeForTest` can render it headless.
class _PremiumCalendarHeader extends StatelessWidget {
  final bool isMobile;
  final int unitCount;
  final DateTime month;

  const _PremiumCalendarHeader({
    required this.isMobile,
    required this.unitCount,
    required this.month,
  });

  // Nominative Croatian month names (handoff eyebrow shows "Lipanj 2026").
  static const List<String> _hrMonths = <String>[
    'Siječanj',
    'Veljača',
    'Ožujak',
    'Travanj',
    'Svibanj',
    'Lipanj',
    'Srpanj',
    'Kolovoz',
    'Rujan',
    'Listopad',
    'Studeni',
    'Prosinac',
  ];

  /// Croatian count agreement for "jedinica" (1 → jedinica, 2-4 → jedinice,
  /// else → jedinica; 11-14 exception handled).
  static String _unitsWord(int n) {
    final int mod10 = n % 10;
    final int mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'jedinica';
    if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
      return 'jedinice';
    }
    return 'jedinica';
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final String monthName = _hrMonths[(month.month - 1).clamp(0, 11)];
    final String eyebrow =
        '$monthName ${month.year} · $unitCount ${_unitsWord(unitCount)}';

    final Widget titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          eyebrow.toUpperCase(),
          style: BBType.eyebrow(context).copyWith(color: c.primary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: BBSpace.xxs),
        Text(
          l10n.ownerCalendar,
          style: BBType.h1(context).copyWith(
            fontSize: isMobile ? _kTitleMobile : _kTitleDesktop,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );

    final EdgeInsets pad = EdgeInsets.fromLTRB(
      isMobile ? _kPagePadHMobile : _kPagePadH,
      isMobile ? _kPagePadHMobile : _kPagePadH,
      isMobile ? _kPagePadHMobile : _kPagePadH,
      BBSpace.xxs,
    );

    return Padding(
      padding: pad,
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                titleBlock,
                const SizedBox(height: BBSpace.xs),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: _CalendarViewSwitch(),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(child: titleBlock),
                const SizedBox(width: BBSpace.sm),
                const _CalendarViewSwitch(),
              ],
            ),
    );
  }
}

/// Timeline / Mjesečni segmented control. On THIS (month) screen "Mjesečni" is
/// the active no-op; "Timeline" routes back to the timeline calendar — the
/// mirror of the Timeline screen's switch (selection reversed).
class _CalendarViewSwitch extends StatelessWidget {
  const _CalendarViewSwitch();

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Container(
      padding: const EdgeInsets.all(BBSpace.xxs),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(BBRadius.full),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ViewSegment(
            icon: Icons.view_timeline_outlined,
            label: 'Timeline',
            selected: false,
            onTap: () => context.go(OwnerRoutes.calendarTimeline),
          ),
          const _ViewSegment(
            icon: Icons.calendar_view_month_outlined,
            label: 'Mjesečni',
            selected: true,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _ViewSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ViewSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BBRadius.full),
          child: AnimatedContainer(
            duration: BBMotion.base,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: _kSegPadH,
              vertical: BBSpace.xs,
            ),
            decoration: BoxDecoration(
              // Active state: surface chip + shadow-sm on the surface-variant
              // track, not a primary fill.
              color: selected ? c.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(BBRadius.full),
              boxShadow: selected ? BBShadow.sm : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: _kSegIcon,
                  color: selected ? c.primary : c.textSecondary,
                ),
                const SizedBox(width: BBSpace.xxs),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? c.textPrimary : c.textSecondary,
                    fontSize: _kSegFont,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: -0.1,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium grid card (handoff CALPGridCard). Border + shadow are painted by the
/// outer [DecoratedBox] (a [ClipRRect] cannot paint a shadow, and the 1px border
/// must survive the clip); the grid scrolls INSIDE the [ClipRRect]. Cell
/// geometry, the SfCalendar controller, and z-index are untouched — only a
/// visual container is added around the grid.
class _CalendarGridCard extends StatelessWidget {
  final Widget child;

  const _CalendarGridCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BBRadius.mdAll,
        border: Border.all(color: c.border),
        boxShadow: BBShadow.cardElevated,
      ),
      child: ClipRRect(borderRadius: BBRadius.mdAll, child: child),
    );
  }
}

/// Status legend (grid-card header) — the four statuses the month grid actually
/// paints (`_getBookingColor`): Potvrđeno · Na čekanju · Završeno · Otkazano.
/// Dot colours come from `BookingStatus.colorOf`, which resolves to the SAME
/// `BBColor.status*` tokens as `_getBookingColor`, so the legend matches the
/// grid in both themes. ("Uvezene" is intentionally omitted — the month grid
/// renders no imported tone; a legend chip for an un-rendered status would
/// mislead.) Desktop/tablet add a trailing `N rezervacija · M jedinice` stat
/// (handoff calendar-month.jsx); dropped on mobile to keep badges on one row.
class _MonthStatusLegend extends StatelessWidget {
  final int bookingCount;
  final int unitCount;

  const _MonthStatusLegend({
    required this.bookingCount,
    required this.unitCount,
  });

  // Croatian count agreement for "rezervacija" (1 → rezervacija, 2-4 →
  // rezervacije, else → rezervacija; 11-14 exception).
  static String _rezWord(int n) {
    final int mod10 = n % 10;
    final int mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'rezervacija';
    if (mod10 >= 2 && mod10 <= 4 && !(mod100 >= 12 && mod100 <= 14)) {
      return 'rezervacije';
    }
    return 'rezervacija';
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    final Widget badges = Wrap(
      spacing: BBSpace.xs,
      runSpacing: BBSpace.xs,
      children: <Widget>[
        _legendBadge(
          context,
          BookingStatus.confirmed.colorOf(context),
          l10n.ownerStatusConfirmed,
        ),
        _legendBadge(
          context,
          BookingStatus.pending.colorOf(context),
          l10n.ownerStatusPending,
        ),
        _legendBadge(
          context,
          BookingStatus.completed.colorOf(context),
          l10n.ownerStatusCompleted,
        ),
        _legendBadge(
          context,
          BookingStatus.cancelled.colorOf(context),
          l10n.ownerStatusCancelled,
        ),
      ],
    );

    // Handoff trailing stat: "N rezervacija · M jedinice" (right-aligned).
    // Reuses the header's unit-word agreement. Desktop/tablet only.
    final String stat =
        '$bookingCount ${_rezWord(bookingCount)} · '
        '$unitCount ${_PremiumCalendarHeader._unitsWord(unitCount)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: _kCardPad,
        vertical: _kLegendPadV,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: isMobile
          ? badges
          : Row(
              children: <Widget>[
                Expanded(child: badges),
                const SizedBox(width: BBSpace.sm),
                Text(
                  stat,
                  style: BBType.caption(context).copyWith(
                    color: c.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }

  /// Status badge: status dot + label in a rounded-full chip with a soft tint
  /// of the status colour.
  Widget _legendBadge(BuildContext context, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _kBadgePadH,
        vertical: _kBadgePadV,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BBRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: _kBadgeDot,
            height: _kBadgeDot,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: BBSpace.xs),
          Text(
            label,
            style: BBType.caption(
              context,
            ).copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Animated gradient FAB with hover and press effects (handoff CALPFab).
class _AnimatedGradientFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedGradientFAB({required this.onPressed});

  @override
  State<_AnimatedGradientFAB> createState() => _AnimatedGradientFABState();
}

class _AnimatedGradientFABState extends State<_AnimatedGradientFAB> {
  // ValueNotifier (not setState) for hover/press so only the FAB content
  // rebuilds.
  late final ValueNotifier<bool> _isHoveredNotifier;
  late final ValueNotifier<bool> _isPressedNotifier;

  @override
  void initState() {
    super.initState();
    _isHoveredNotifier = ValueNotifier<bool>(false);
    _isPressedNotifier = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isHoveredNotifier.dispose();
    _isPressedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => _isHoveredNotifier.value = true,
      onExit: (_) => _isHoveredNotifier.value = false,
      child: GestureDetector(
        onTapDown: (_) => _isPressedNotifier.value = true,
        onTapUp: (_) {
          _isPressedNotifier.value = false;
          widget.onPressed();
        },
        onTapCancel: () => _isPressedNotifier.value = false,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isHoveredNotifier,
          builder: (context, isHovered, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isPressedNotifier,
              builder: (context, isPressed, _) {
                // Handoff CALPFab: solid primary circle + purple glow. Color
                // from the BB token so dark mode lifts to #8B6FFF.
                final Color fabColor = BBColor.of(context).primary;
                return AnimatedContainer(
                  duration: BBMotion.base,
                  curve: Curves.easeOutCubic,
                  width: _kFabSize,
                  height: _kFabSize,
                  transform: Matrix4.diagonal3Values(
                    isPressed ? 0.92 : (isHovered ? 1.08 : 1.0),
                    isPressed ? 0.92 : (isHovered ? 1.08 : 1.0),
                    1.0,
                  ),
                  transformAlignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: fabColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: fabColor.withValues(
                          alpha: isHovered ? 0.5 : 0.35,
                        ),
                        blurRadius: isHovered ? 20 : 12,
                        offset: Offset(0, isHovered ? 8 : 4),
                        spreadRadius: isHovered ? 2 : 0,
                      ),
                    ],
                  ),
                  child: AnimatedRotation(
                    duration: BBMotion.base,
                    turns: isHovered ? 0.125 : 0, // 45 degree rotation on hover
                    child: Icon(
                      Icons.add,
                      color: theme.colorScheme.onPrimary,
                      size: _kFabIcon,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
