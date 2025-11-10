import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/owner_calendar_provider.dart';
import 'calendar/booking_inline_edit_dialog.dart';

/// BedBooking-style Timeline Calendar
/// Gantt/Timeline layout: Units vertical, Dates horizontal
/// Starts from today, horizontal scroll, pinch-to-zoom support
class TimelineCalendarWidget extends ConsumerStatefulWidget {
  const TimelineCalendarWidget({super.key});

  @override
  ConsumerState<TimelineCalendarWidget> createState() => _TimelineCalendarWidgetState();
}

class _TimelineCalendarWidgetState extends ConsumerState<TimelineCalendarWidget> {
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  late ScrollController _headerScrollController;
  late ScrollController _summaryScrollController;
  late TransformationController _transformationController;

  // Scroll sync listener reference for cleanup
  late VoidCallback _scrollSyncListener;

  // Zoom scale (1.0 = normal, 0.5 = zoomed out, 2.0 = zoomed in)
  double _zoomScale = 1.0;
  static const double _minZoomScale = 0.5;
  static const double _maxZoomScale = 2.5;

  // Summary bar toggle
  bool _showSummary = false;

  // Responsive dimensions based on screen size and accessibility settings
  double _getDayWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    // Base width adjusted for screen size
    double baseWidth = 80.0;
    if (screenWidth < AppDimensions.mobile) {
      baseWidth = 80.0; // Mobile
    } else if (screenWidth < AppDimensions.tablet) {
      baseWidth = 90.0; // Tablet
    } else {
      baseWidth = 100.0; // Desktop
    }

    // Apply zoom scale (pinch-to-zoom)
    baseWidth = baseWidth * _zoomScale;

    // Adjust for text scaling (accessibility)
    return baseWidth * textScaleFactor.clamp(0.8, 1.2);
  }

  double _getUnitRowHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    // Base height adjusted for text scaling and screen size
    double baseHeight = 64.0; // Increased for better touch targets
    if (screenWidth < AppDimensions.mobile) {
      baseHeight = 72.0; // Mobile - larger touch targets
    }
    return baseHeight * textScaleFactor.clamp(0.8, 1.3);
  }

  double _getUnitColumnWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    // Base width adjusted for screen size
    double baseWidth = 150.0;
    if (screenWidth < AppDimensions.mobile) {
      baseWidth = 100.0; // Mobile - ~28% of screen
    } else if (screenWidth < AppDimensions.tablet) {
      baseWidth = 130.0; // Tablet
    }

    // Adjust for text scaling (accessibility)
    return baseWidth * textScaleFactor.clamp(0.8, 1.2);
  }

  double _getHeaderHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < AppDimensions.mobile) {
      return 70.0; // Mobile - compact
    } else if (screenWidth < AppDimensions.tablet) {
      return 82.0; // Tablet - standard
    } else {
      return 96.0; // Desktop - spacious
    }
  }

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    _headerScrollController = ScrollController();
    _summaryScrollController = ScrollController();
    _transformationController = TransformationController();

    // Create single listener that syncs both header and summary scroll controllers
    // Using jumpTo() for instant sync without competing animations
    _scrollSyncListener = () {
      final mainOffset = _horizontalScrollController.offset;

      // Sync header scroll
      if (_headerScrollController.hasClients &&
          _headerScrollController.offset != mainOffset &&
          (_headerScrollController.offset - mainOffset).abs() > 1.0) {
        _headerScrollController.jumpTo(mainOffset);
      }

      // Sync summary bar scroll
      if (_summaryScrollController.hasClients &&
          _summaryScrollController.offset != mainOffset &&
          (_summaryScrollController.offset - mainOffset).abs() > 1.0) {
        _summaryScrollController.jumpTo(mainOffset);
      }
    };

    // Add the single scroll sync listener
    _horizontalScrollController.addListener(_scrollSyncListener);

    // Listen to zoom changes from InteractiveViewer
    _transformationController.addListener(_onTransformChanged);

    // Scroll to today on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _onTransformChanged() {
    final matrix = _transformationController.value;
    final newScale = matrix.getMaxScaleOnAxis();

    if ((newScale - _zoomScale).abs() > 0.01) {
      setState(() {
        _zoomScale = newScale.clamp(_minZoomScale, _maxZoomScale);
      });
    }
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    _horizontalScrollController.removeListener(_scrollSyncListener);
    _transformationController.removeListener(_onTransformChanged);

    // Dispose all controllers
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _headerScrollController.dispose();
    _summaryScrollController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    // Check if scroll controller is attached to a scroll view
    if (!_horizontalScrollController.hasClients) {
      return;
    }

    // Calculate position of today
    final now = DateTime.now();
    final startDate = _getStartDate();
    final daysSinceStart = now.difference(startDate).inDays;
    final dayWidth = _getDayWidth(context);
    final scrollPosition = daysSinceStart * dayWidth;

    // Scroll to today (centered in viewport) with smooth animation
    final maxScroll = _horizontalScrollController.position.maxScrollExtent;
    final unitColumnWidth = _getUnitColumnWidth(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final visibleWidth = screenWidth - unitColumnWidth;

    // Center today in the visible area
    final targetScroll = (scrollPosition - (visibleWidth / 2) + (dayWidth / 2))
        .clamp(0.0, maxScroll);

    _horizontalScrollController.animateTo(
      targetScroll,
      duration: AppDimensions.animationSlow,
      curve: Curves.easeInOut,
    );
  }

  DateTime _getStartDate() {
    // Start from 3 months before today
    return DateTime.now().subtract(const Duration(days: 90));
  }

  DateTime _getEndDate() {
    // End 12 months after today
    return DateTime.now().add(const Duration(days: 365));
  }

  List<DateTime> _getDateRange() {
    final start = _getStartDate();
    final end = _getEndDate();
    final days = end.difference(start).inDays;

    return List.generate(days, (index) {
      return start.add(Duration(days: index));
    });
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(allOwnerUnitsProvider);
    final bookingsAsync = ref.watch(calendarBookingsProvider);

    return Column(
      children: [
        // Toolbar with actions
        _buildToolbar(),

        // Zoom info banner (showing current zoom level)
        if (_zoomScale != 1.0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceS,
              vertical: AppDimensions.spaceXXS,
            ),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _zoomScale > 1.0 ? Icons.zoom_in : Icons.zoom_out,
                  size: AppDimensions.iconS,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.spaceXXS),
                Text(
                  'Zoom: ${(_zoomScale * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceXS),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _zoomScale = 1.0;
                      _transformationController.value = Matrix4.identity();
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXS),
                    minimumSize: const Size(0, 28),
                  ),
                  child: const Text('Reset', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),

        // Main timeline
        Expanded(
          child: unitsAsync.when(
            data: (units) {
              if (units.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.spaceM),
                    child: Text('Nema jedinica za prikaz'),
                  ),
                );
              }

              return bookingsAsync.when(
                data: (bookingsByUnit) {
                  return _buildTimelineView(units, bookingsByUnit);
                },
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppDimensions.spaceM),
                      Text('Učitavanje rezervacija...'),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: AppDimensions.spaceM),
                        const Text(
                          'Greška pri učitavanju rezervacija',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppDimensions.spaceS),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(calendarBookingsProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Pokušaj ponovno'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppDimensions.spaceM),
                  Text('Učitavanje jedinica...'),
                ],
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceM),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: AppDimensions.spaceM),
                    const Text(
                      'Greška pri učitavanju jedinica',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(allOwnerUnitsProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Pokušaj ponovno'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Osvježi',
            onPressed: () {
              ref.invalidate(allOwnerUnitsProvider);
              ref.invalidate(calendarBookingsProvider);
            },
          ),
          const SizedBox(width: 8),

          // Go to today button
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Danas',
            onPressed: _scrollToToday,
          ),
          const SizedBox(width: 8),

          // Date picker button
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Odaberi datum',
            onPressed: _showDatePickerDialog,
          ),
          const SizedBox(width: 8),

          // Previous month
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Prethodni mjesec',
            onPressed: () => _scrollToMonth(-1),
          ),

          // Next month
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Sljedeći mjesec',
            onPressed: () => _scrollToMonth(1),
          ),

          const Spacer(),

          // Summary toggle
          IconButton(
            icon: Icon(_showSummary ? Icons.expand_less : Icons.expand_more),
            tooltip: _showSummary ? 'Sakrij sažetak' : 'Prikaži sažetak',
            onPressed: () {
              setState(() {
                _showSummary = !_showSummary;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineView(List<UnitModel> units, Map<String, List<BookingModel>> bookingsByUnit) {
    final dates = _getDateRange();

    return Card(
      child: Column(
        children: [
          // Date headers
          _buildDateHeaders(dates),

          const Divider(height: 1),

          // Units and reservations without InteractiveViewer to avoid unbounded constraints
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed unit names column
                _buildUnitNamesColumn(units),

                // Scrollable timeline grid
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTimelineGrid(units, bookingsByUnit, dates),
                          // Summary bar (if enabled)
                          if (_showSummary)
                            _buildSummaryBar(bookingsByUnit, dates),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeaders(List<DateTime> dates) {
    final unitColumnWidth = _getUnitColumnWidth(context);
    final headerHeight = _getHeaderHeight(context);
    final monthHeaderHeight = headerHeight * 0.35; // ~35% for month header
    final dayHeaderHeight = headerHeight * 0.65; // ~65% for day header

    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          // Empty space for unit names column
          Container(
            width: unitColumnWidth,
            color: Theme.of(context).cardColor,
          ),

          // Scrollable headers
          Expanded(
            child: SingleChildScrollView(
              controller: _headerScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(), // Disable manual scrolling, sync only
              child: Column(
                children: [
                  // Nad-zaglavlje: Month headers
                  SizedBox(
                    height: monthHeaderHeight,
                    child: Row(
                      children: _buildMonthHeaders(dates),
                    ),
                  ),

                  // Pod-zaglavlje: Day headers
                  SizedBox(
                    height: dayHeaderHeight,
                    child: Row(
                      children: dates.map((date) {
                        return _buildDayHeader(date);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMonthHeaders(List<DateTime> dates) {
    final List<Widget> headers = [];
    DateTime? currentMonth;
    int dayCount = 0;

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];

      if (currentMonth == null ||
          date.month != currentMonth.month ||
          date.year != currentMonth.year) {
        // New month started, add previous month header if exists
        if (currentMonth != null && dayCount > 0) {
          headers.add(_buildMonthHeaderCell(currentMonth, dayCount));
        }

        // Start new month
        currentMonth = date;
        dayCount = 1;
      } else {
        dayCount++;
      }
    }

    // Add last month header
    if (currentMonth != null && dayCount > 0) {
      headers.add(_buildMonthHeaderCell(currentMonth, dayCount));
    }

    return headers;
  }

  Widget _buildMonthHeaderCell(DateTime date, int dayCount) {
    final dayWidth = _getDayWidth(context);
    final theme = Theme.of(context);

    return Container(
      width: dayWidth * dayCount,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1.5),
          right: BorderSide(color: theme.dividerColor.withAlpha((0.6 * 255).toInt()), width: 1),
        ),
      ),
      child: Center(
        child: Text(
          DateFormat('MMMM yyyy', 'hr_HR').format(date),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDayHeader(DateTime date) {
    final dayWidth = _getDayWidth(context);
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isFirstDayOfMonth = date.day == 1;

    return Container(
      width: dayWidth,
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withAlpha((0.2 * 255).toInt())
            : theme.cardColor,
        border: Border(
          left: BorderSide(
            color: isFirstDayOfMonth
                ? theme.colorScheme.primary
                : theme.dividerColor.withAlpha((0.5 * 255).toInt()),
            width: isFirstDayOfMonth ? 2 : 1,
          ),
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day of week
          Text(
            DateFormat('EEE', 'hr_HR').format(date).toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isWeekend
                  ? theme.colorScheme.error
                  : (isToday ? theme.colorScheme.primary : null),
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),

          const SizedBox(height: 4),

          // Day number
          Container(
            width: 28,
            height: 28,
            decoration: isToday
                ? BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isToday ? theme.colorScheme.onPrimary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitNamesColumn(List<UnitModel> units) {
    final unitColumnWidth = _getUnitColumnWidth(context);
    final theme = Theme.of(context);

    return Container(
      width: unitColumnWidth,
      color: theme.cardColor.withAlpha((0.95 * 255).toInt()),
      child: Column(
        children: units.map((unit) {
          return _buildUnitNameCell(unit);
        }).toList(),
      ),
    );
  }

  Widget _buildUnitNameCell(UnitModel unit) {
    final unitRowHeight = _getUnitRowHeight(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppDimensions.mobile;

    return Container(
      height: unitRowHeight,
      padding: EdgeInsets.all(isMobile ? AppDimensions.spaceXS : AppDimensions.spaceS),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Bed icon
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.hotel_outlined,
              size: isMobile ? 18 : 20,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: isMobile ? AppDimensions.spaceXS : AppDimensions.spaceS),
          // Unit info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  unit.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spaceXXS / 2),
                Text(
                  '${unit.maxGuests} gostiju',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha((0.7 * 255).toInt()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineGrid(
    List<UnitModel> units,
    Map<String, List<BookingModel>> bookingsByUnit,
    List<DateTime> dates,
  ) {
    return Column(
      children: units.map((unit) {
        final bookings = bookingsByUnit[unit.id] ?? [];
        return _buildUnitRow(unit, bookings, dates);
      }).toList(),
    );
  }

  Widget _buildUnitRow(UnitModel unit, List<BookingModel> bookings, List<DateTime> dates) {
    final unitRowHeight = _getUnitRowHeight(context);
    final theme = Theme.of(context);

    return Container(
      height: unitRowHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            width: 1.0,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Day cells (background)
          Row(
            children: dates.map((date) {
              return _buildDayCell(date);
            }).toList(),
          ),

          // Reservation blocks (foreground)
          ..._buildReservationBlocks(bookings, dates),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final dayWidth = _getDayWidth(context);
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isFirstDayOfMonth = date.day == 1;

    return Container(
      width: dayWidth,
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withAlpha((0.05 * 255).toInt())
            : isWeekend
                ? theme.dividerColor.withAlpha((0.05 * 255).toInt())
                : theme.scaffoldBackgroundColor,
        border: Border(
          left: BorderSide(
            color: isFirstDayOfMonth
                ? theme.colorScheme.primary
                : theme.dividerColor.withAlpha((0.5 * 255).toInt()),
            width: isFirstDayOfMonth ? 2 : 1,
          ),
          right: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            width: 0.5,
          ),
          top: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildReservationBlocks(List<BookingModel> bookings, List<DateTime> dates) {
    final dayWidth = _getDayWidth(context);
    final List<Widget> blocks = [];

    for (final booking in bookings) {
      // Calculate position and width
      final checkIn = booking.checkIn;
      final nights = _calculateNights(booking.checkIn, booking.checkOut);

      // Find index of check-in date
      final startIndex = dates.indexWhere((d) => _isSameDay(d, checkIn));
      if (startIndex == -1) continue; // Booking not in visible range

      // Calculate left position
      final left = startIndex * dayWidth;

      // Calculate width (number of nights * day width)
      final width = nights * dayWidth;

      // Create reservation block
      blocks.add(
        Positioned(
          left: left,
          top: 8,
          child: _buildReservationBlock(booking, width),
        ),
      );
    }

    return blocks;
  }

  Widget _buildReservationBlock(BookingModel booking, double width) {
    final unitRowHeight = _getUnitRowHeight(context);
    final blockHeight = unitRowHeight - 16;
    final nights = _calculateNights(booking.checkIn, booking.checkOut);
    final isIcalBooking = booking.source == 'ical' ||
                          booking.source == 'airbnb' ||
                          booking.source == 'booking_com';

    return GestureDetector(
      onTap: () => _showReservationDetails(booking),
      child: Stack(
        children: [
          // Main reservation block
          Container(
            width: width - 4,
            height: blockHeight,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: booking.status.color,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXS,
              vertical: AppDimensions.spaceXXS,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  booking.guestName ?? 'Gost',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.guestCount} gost${booking.guestCount > 1 ? 'a' : ''} • $nights noć${nights > 1 ? 'i' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // iCal sync badge (top right)
          if (isIcalBooking)
            Positioned(
              right: 6,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.grey.shade400),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, size: 10, color: Colors.blue[700]),
                    const SizedBox(width: 2),
                    Text(
                      'iCal',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showReservationDetails(BookingModel booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookingInlineEditDialog(booking: booking),
    );

    // If edited successfully, result will be true
    if (result == true && mounted) {
      // Calendar already refreshed by dialog
    }
  }

  Widget _buildSummaryBar(Map<String, List<BookingModel>> bookingsByUnit, List<DateTime> dates) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: _summaryScrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(), // Sync only, no manual scroll
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withAlpha((0.5 * 255).toInt()),
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: dates.map((date) {
            return _buildSummaryCell(date, bookingsByUnit);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCell(DateTime date, Map<String, List<BookingModel>> bookingsByUnit) {
    final theme = Theme.of(context);
    // Calculate statistics for this date
    int totalGuests = 0;
    int checkIns = 0;
    int checkOuts = 0;

    // Iterate through all bookings
    for (final bookings in bookingsByUnit.values) {
      for (final booking in bookings) {
        // Count guests currently in property (checkIn <= date < checkOut)
        if (!booking.checkIn.isAfter(date) && booking.checkOut.isAfter(date)) {
          totalGuests += booking.guestCount;
        }

        // Count check-ins (checkIn == date)
        if (_isSameDay(booking.checkIn, date)) {
          checkIns++;
        }

        // Count check-outs (checkOut == date)
        if (_isSameDay(booking.checkOut, date)) {
          checkOuts++;
        }
      }
    }

    // Calculate meals (2 meals per guest per day)
    final int meals = totalGuests * 2;

    final dayWidth = _getDayWidth(context);
    final isToday = _isToday(date);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    return Container(
      width: dayWidth,
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withValues(alpha: 0.1)
            : isWeekend
                ? theme.colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).toInt())
                : theme.cardColor,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor.withAlpha((0.3 * 255).toInt()),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spaceXS,
        horizontal: AppDimensions.spaceXXS,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Guests
          _buildSummaryItem(
            Icons.people,
            totalGuests.toString(),
            Colors.blue,
            'Gosti',
          ),
          // Meals
          _buildSummaryItem(
            Icons.restaurant,
            meals.toString(),
            Colors.orange,
            'Obroci',
          ),
          // Check-ins
          _buildSummaryItem(
            Icons.login,
            checkIns.toString(),
            Colors.green,
            'Dolasci',
          ),
          // Check-outs
          _buildSummaryItem(
            Icons.logout,
            checkOuts.toString(),
            Colors.red,
            'Odlasci',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _showDatePickerDialog() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: _getStartDate(),
      lastDate: _getEndDate(),
      helpText: 'Izaberite datum',
      cancelText: 'Otkaži',
      confirmText: 'Potvrdi',
      locale: const Locale('hr', 'HR'),
    );

    if (selectedDate != null) {
      _scrollToDate(selectedDate);
    }
  }

  void _scrollToDate(DateTime date) {
    // Check if scroll controller is attached to a scroll view
    if (!_horizontalScrollController.hasClients) {
      return;
    }

    final dayWidth = _getDayWidth(context);
    final startDate = _getStartDate();
    final daysSinceStart = date.difference(startDate).inDays;
    final scrollPosition = daysSinceStart * dayWidth;

    final maxScroll = _horizontalScrollController.position.maxScrollExtent;
    final targetScroll = (scrollPosition - (MediaQuery.of(context).size.width / 2))
        .clamp(0.0, maxScroll);

    _horizontalScrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToMonth(int monthOffset) {
    final dayWidth = _getDayWidth(context);

    // Calculate target date (current visible center + monthOffset months)
    final startDate = _getStartDate();
    final currentScroll = _horizontalScrollController.hasClients
        ? _horizontalScrollController.offset
        : 0.0;
    final currentDayIndex = (currentScroll / dayWidth).round();
    final currentDate = startDate.add(Duration(days: currentDayIndex));

    // Add months
    final targetDate = DateTime(
      currentDate.year,
      currentDate.month + monthOffset,
      1, // First day of the month
    );

    _scrollToDate(targetDate);
  }

  /// Calculate nights between two dates with proper normalization
  /// Normalizes dates to midnight to avoid time-of-day calculation errors
  int _calculateNights(DateTime checkIn, DateTime checkOut) {
    final normalizedCheckIn = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final normalizedCheckOut = DateTime(checkOut.year, checkOut.month, checkOut.day);
    return normalizedCheckOut.difference(normalizedCheckIn).inDays;
  }
}
