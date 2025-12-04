# Calendar Widgets Refactoring Plan

**Status:** READY FOR REVIEW
**Created:** 2025-12-03
**Files:** year_calendar_widget.dart (1,152 lines), month_calendar_widget.dart (879 lines)
**Estimated Reduction:** ~600 lines of duplicate code

---

## Executive Summary

Both calendar widgets share **~600 lines of duplicate code** (60% duplication). This duplication creates maintenance burden and increases bug risk. This plan proposes extracting shared logic to:

1. **Shared State Mixin** - 4 state variables + lifecycle methods
2. **Calendar Validation Helper** - Date selection logic (~200 lines)
3. **Calendar Painters** (separate files) - 3 custom painters (~185 lines)
4. **Shared Widget Components** - Header, tooltip, navigation

**Benefits:**
- Single source of truth for date selection logic
- Easier bug fixes (change once, fixes both calendars)
- Reduced cognitive load when reading code
- Consistent behavior between year/month views

**Risks:**
- Medium complexity (shared validation logic has subtle differences)
- Requires careful testing of both calendar views
- Breaking change if abstractions are wrong

---

## Duplication Analysis

### 1. State Variables (EXACT duplicates - 4 variables)

**year_calendar_widget.dart:35-39**
```dart
DateTime? _rangeStart;
DateTime? _rangeEnd;
int _currentYear = DateTime.now().year;
DateTime? _hoveredDate;
Offset _mousePosition = Offset.zero;
```

**month_calendar_widget.dart:38-42**
```dart
DateTime? _rangeStart;
DateTime? _rangeEnd;
DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
DateTime? _hoveredDate;
Offset _mousePosition = Offset.zero;
```

**Difference:** Only `_currentYear` vs `_currentMonth` (navigation state).

---

### 2. Constructor Parameters (EXACT duplicates)

Both widgets have identical constructor:
```dart
final String propertyId;
final String unitId;
final Function(DateTime? start, DateTime? end)? onRangeSelected;
```

---

### 3. Provider Watching Pattern (95% duplicate)

Both widgets watch same providers in `build()`:
- `unitByIdProvider(widget.propertyId, widget.unitId)` → extract basePrice, weekendBasePrice, weekendDays, minNights
- `themeProvider` → isDarkMode
- `MinimalistColorSchemeAdapter(dark: isDarkMode)` → colors

**Difference:** Year watches `yearCalendarDataProvider`, month watches `monthCalendarDataProvider`.

---

### 4. _buildCombinedHeader() (99% duplicate - 54 lines)

**year_calendar_widget.dart:95-155**
**month_calendar_widget.dart:123-183**

Both methods are IDENTICAL except:
- Year calendar: calls `_buildCompactYearNavigation(colors)` at line 150
- Month calendar: calls `_buildCompactMonthNavigation(colors)` at line 178

Everything else (view switcher, theme toggle, layout, styling) is 100% duplicate.

---

### 5. _buildHoverTooltip() (95% duplicate - ~50 lines)

**year_calendar_widget.dart:157-203**
**month_calendar_widget.dart:584-635**

Both methods have IDENTICAL logic:
- Null checks for `_hoveredDate`
- Date key lookup
- Screen bounds calculation
- Tooltip positioning with clamping
- `CalendarHoverTooltip` widget

**Difference:** Month calendar wraps tooltip in `IgnorePointer` widget (line 625).

---

### 6. _onDateTapped() (90% duplicate - ~200 lines!!!)

**year_calendar_widget.dart:647-850**
**month_calendar_widget.dart:637-810**

Both methods have IDENTICAL logic for:
1. ✅ Block past dates check (lines 654-661 / 644-651)
2. ✅ Determine check-in vs check-out selection (lines 664-666 / 654-656)
3. ✅ Advance booking window validation (lines 669-694 / 659-684)
4. ✅ blockCheckIn/blockCheckOut restrictions (lines 698-714 / 688-704)
5. ✅ partialCheckIn/partialCheckOut selection logic (lines 717-728 / 708-731)
6. ✅ Same date prevention (lines 737-739 / 740-742)
7. ✅ Date range ordering (lines 742-745 / 745-748)
8. ✅ minNights validation (lines 750-808 / 751-774)
9. ✅ minNightsOnArrival/maxNightsOnArrival validation (lines 761-793 / 777-803)

**Key Difference:**
- **Year calendar (lines 811-850):** Inline validation using `_hasBlockedDatesInRange()` + `_wouldCreateOrphanGap()`
- **Month calendar (lines 807):** Async backend validation using `_validateAndSetRange()`

**Reason for difference:** Bug #72 fix - month calendar uses backend for cross-month validation.

---

### 7. Helper Methods (ONLY in year_calendar_widget.dart)

**_hasBlockedDatesInRange() (lines 854-891 - 38 lines):**
- Checks if any booked/pending/blocked dates exist between start and end
- Allows partial dates at endpoints only

**_wouldCreateOrphanGap() (lines 896-961 - 66 lines):**
- Checks if selection would leave a gap smaller than minNights
- Searches forward and backward for blocked dates
- Prevents creating unbookable gaps

**Question:** Why doesn't month calendar have these methods?
**Answer:** Month calendar delegates ALL validation to backend via `checkDateAvailabilityProvider` (Bug #72 fix).

---

### 8. Custom Painters (EXACT duplicates - ~185 lines)

**year_calendar_widget.dart has 3 private painters:**

1. **_DiagonalLinePainter (lines 964-1041 - 77 lines):**
   - Draws diagonal split for check-in/check-out days
   - Supports pending pattern overlay

2. **_PendingPatternPainter (lines 1043-1070 - 28 lines):**
   - Draws diagonal stripe pattern for full pending days

3. **_PartialBothPainter (lines 1072-1152 - 80 lines):**
   - Draws turnover day with split colors
   - Supports pending pattern on each triangle

**month_calendar_widget.dart:**
- Uses `SplitDayCalendarPainter` from `split_day_calendar_painter.dart` (external file)
- This painter likely consolidates the 3 year calendar painters into one

**Recommendation:** Year calendar should use the same external painter.

---

## Refactoring Strategy

### Phase 1: Extract Custom Painters (LOW RISK)

**Goal:** Move year calendar painters to separate files, matching month calendar pattern.

**Files to create:**
1. `lib/features/widget/presentation/widgets/calendar/calendar_painters.dart`
   - Consolidate 3 year calendar painters
   - OR use existing `split_day_calendar_painter.dart` if compatible

**Changes:**
- `year_calendar_widget.dart`: Remove private painters (lines 964-1152), import external painters
- ZERO functional changes, just file organization

**Testing:** Visual regression test - both calendars should look identical.

---

### Phase 2: Extract Shared State Mixin (LOW RISK)

**Goal:** Centralize date selection state in a reusable mixin.

**File to create:**
```dart
// lib/features/widget/presentation/widgets/calendar/calendar_date_selection_mixin.dart

/// Mixin for shared date selection state between year/month calendar widgets.
///
/// Provides:
/// - Range selection state (_rangeStart, _rangeEnd)
/// - Hover tooltip state (_hoveredDate, _mousePosition)
/// - State helper methods
mixin CalendarDateSelectionMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime? _hoveredDate;
  Offset _mousePosition = Offset.zero;

  // Getters
  DateTime? get rangeStart => _rangeStart;
  DateTime? get rangeEnd => _rangeEnd;
  DateTime? get hoveredDate => _hoveredDate;
  Offset get mousePosition => _mousePosition;

  // Setters (with setState)
  void setRangeStart(DateTime? value) => setState(() => _rangeStart = value);
  void setRangeEnd(DateTime? value) => setState(() => _rangeEnd = value);
  void setHoveredDate(DateTime? value) => setState(() => _hoveredDate = value);
  void setMousePosition(Offset value) => setState(() => _mousePosition = value);

  // Clear selection
  void clearSelection() {
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });
  }
}
```

**Changes:**
- `year_calendar_widget.dart`: `with CalendarDateSelectionMixin`, remove 4 state variables
- `month_calendar_widget.dart`: `with CalendarDateSelectionMixin`, remove 4 state variables
- Replace direct state access with mixin getters/setters

**Testing:** Unit tests for mixin, visual tests for both calendars.

---

### Phase 3: Extract Shared Validation Logic (MEDIUM RISK)

**Goal:** Consolidate date selection validation into a shared helper class.

**File to create:**
```dart
// lib/features/widget/presentation/widgets/calendar/calendar_date_validator.dart

/// Helper class for calendar date selection validation.
///
/// Contains all validation logic for:
/// - Past date blocking
/// - Advance booking window
/// - Check-in/check-out restrictions
/// - Min/max nights validation
class CalendarDateValidator {
  /// Validate if date can be selected for check-in
  static DateValidationResult validateCheckIn({
    required DateTime date,
    required CalendarDateInfo dateInfo,
    required BuildContext context,
  }) {
    // Block past dates
    if (dateInfo.status == DateStatus.disabled) {
      return DateValidationResult.error('Cannot select past dates.');
    }

    // Check advance booking window
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final daysInAdvance = date.difference(todayNormalized).inDays;

    if (dateInfo.minDaysAdvance != null && daysInAdvance < dateInfo.minDaysAdvance!) {
      return DateValidationResult.error(
        'This date requires booking at least ${dateInfo.minDaysAdvance} days in advance.',
      );
    }

    if (dateInfo.maxDaysAdvance != null && daysInAdvance > dateInfo.maxDaysAdvance!) {
      return DateValidationResult.error(
        'This date can only be booked up to ${dateInfo.maxDaysAdvance} days in advance.',
      );
    }

    // Check blockCheckIn
    if (dateInfo.blockCheckIn) {
      return DateValidationResult.error('Check-in is not allowed on this date.');
    }

    // Check status allows check-in
    final canSelectForCheckIn =
        dateInfo.status == DateStatus.available ||
        dateInfo.status == DateStatus.partialCheckOut;

    if (!canSelectForCheckIn) {
      return DateValidationResult.error(
        'This date is not available for check-in. Please select an available date.',
      );
    }

    return DateValidationResult.success();
  }

  /// Validate if date can be selected for check-out
  static DateValidationResult validateCheckOut({
    required DateTime date,
    required DateTime checkInDate,
    required CalendarDateInfo dateInfo,
    required BuildContext context,
  }) {
    // Cannot select same date as check-in
    if (CalendarDateUtils.isSameDay(date, checkInDate)) {
      return DateValidationResult.silent(); // Do nothing
    }

    // Check blockCheckOut
    if (dateInfo.blockCheckOut) {
      return DateValidationResult.error('Check-out is not allowed on this date.');
    }

    // Check status allows check-out
    final canSelectForCheckOut =
        dateInfo.status == DateStatus.available ||
        dateInfo.status == DateStatus.partialCheckIn;

    if (!canSelectForCheckOut) {
      return DateValidationResult.error(
        'This date is not available for check-out. Please select an available date.',
      );
    }

    return DateValidationResult.success();
  }

  /// Validate min/max nights for the selected range
  static DateValidationResult validateStayLength({
    required DateTime start,
    required DateTime end,
    required CalendarDateInfo checkInDateInfo,
    required int minNights,
    required BuildContext context,
  }) {
    final selectedNights = end.difference(start).inDays;

    // Check minNightsOnArrival (per-date minimum)
    if (checkInDateInfo.minNightsOnArrival != null &&
        selectedNights < checkInDateInfo.minNightsOnArrival!) {
      return DateValidationResult.error(
        'Minimum stay for this arrival date is ${checkInDateInfo.minNightsOnArrival} '
        '${checkInDateInfo.minNightsOnArrival == 1 ? 'night' : 'nights'}. '
        'You selected $selectedNights ${selectedNights == 1 ? 'night' : 'nights'}.',
      );
    }

    // Check maxNightsOnArrival (per-date maximum)
    if (checkInDateInfo.maxNightsOnArrival != null &&
        selectedNights > checkInDateInfo.maxNightsOnArrival!) {
      return DateValidationResult.error(
        'Maximum stay for this arrival date is ${checkInDateInfo.maxNightsOnArrival} '
        '${checkInDateInfo.maxNightsOnArrival == 1 ? 'night' : 'nights'}. '
        'You selected $selectedNights ${selectedNights == 1 ? 'night' : 'nights'}.',
      );
    }

    // Fallback to widget's minNights if no date-specific minNightsOnArrival
    if ((checkInDateInfo.minNightsOnArrival == null ||
         checkInDateInfo.minNightsOnArrival == 0) &&
        selectedNights < minNights) {
      return DateValidationResult.error(
        'Minimum stay is $minNights ${minNights == 1 ? 'night' : 'nights'}. '
        'You selected $selectedNights ${selectedNights == 1 ? 'night' : 'nights'}.',
      );
    }

    return DateValidationResult.success();
  }
}

/// Result of a date validation check
class DateValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool isSilent; // True for "do nothing" cases

  const DateValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.isSilent = false,
  });

  factory DateValidationResult.success() =>
      const DateValidationResult._(isValid: true);

  factory DateValidationResult.error(String message) =>
      DateValidationResult._(isValid: false, errorMessage: message);

  factory DateValidationResult.silent() =>
      const DateValidationResult._(isValid: false, isSilent: true);
}
```

**Changes:**
- `year_calendar_widget.dart`: Use `CalendarDateValidator` in `_onDateTapped()` (lines 654-808)
- `month_calendar_widget.dart`: Use `CalendarDateValidator` in `_onDateTapped()` (lines 644-803)
- Keep year calendar's `_hasBlockedDatesInRange()` and `_wouldCreateOrphanGap()` as private methods (backend validation is different)

**Testing:**
- Unit tests for all validation scenarios
- Integration tests for both calendars with various date selections
- Edge cases: same-day selection, cross-month ranges, minNights violations

---

### Phase 4: Extract Shared UI Components (LOW RISK)

**Goal:** Create reusable widgets for header, tooltip, navigation.

**Files to create:**

1. **calendar_combined_header_widget.dart**
```dart
/// Combined header widget used by both year and month calendar views.
///
/// Contains:
/// - View switcher (year/month/week)
/// - Theme toggle button
/// - Custom navigation widget (passed as child)
class CalendarCombinedHeaderWidget extends StatelessWidget {
  final WidgetColorScheme colors;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final Widget navigationWidget; // Year nav or month nav

  const CalendarCombinedHeaderWidget({
    required this.colors,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.navigationWidget,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? SpacingTokens.xxs : SpacingTokens.xs,
          vertical: SpacingTokens.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderTokens.circularRounded,
          boxShadow: ShadowTokens.light,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CalendarViewSwitcherWidget(colors: colors, isDarkMode: isDarkMode),
            SizedBox(width: isSmallScreen ? 4 : SpacingTokens.xxs),
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: isSmallScreen ? 16 : IconSizeTokens.small,
                color: colors.textPrimary,
              ),
              onPressed: onThemeToggle,
              tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
                minHeight: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
              ),
            ),
            SizedBox(width: isSmallScreen ? 4 : SpacingTokens.xxs),
            navigationWidget, // Year or month navigation
          ],
        ),
      ),
    );
  }
}
```

**Changes:**
- `year_calendar_widget.dart`: Replace `_buildCombinedHeader()` with `CalendarCombinedHeaderWidget`, pass `_buildCompactYearNavigation()` as navigationWidget
- `month_calendar_widget.dart`: Replace `_buildCombinedHeader()` with `CalendarCombinedHeaderWidget`, pass `_buildCompactMonthNavigation()` as navigationWidget

**Testing:** Visual regression test, responsive layout tests (small screen, desktop).

---

## Implementation Order

### Priority 1: Phase 1 (Painters) - IMPLEMENT FIRST
- **Why:** Zero functional risk, just file organization
- **Benefit:** Removes 185 lines from year_calendar_widget.dart
- **Time:** 30 minutes

### Priority 2: Phase 2 (State Mixin) - IMPLEMENT SECOND
- **Why:** Low risk, clear abstraction boundary
- **Benefit:** Removes 4 duplicate state variables, centralizes state management
- **Time:** 1 hour

### Priority 3: Phase 4 (UI Components) - IMPLEMENT THIRD
- **Why:** Low risk, visual components are easy to test
- **Benefit:** Removes ~54 duplicate lines from header
- **Time:** 1 hour

### Priority 4: Phase 3 (Validation Logic) - IMPLEMENT LAST
- **Why:** Medium risk due to subtle differences between calendars
- **Benefit:** Removes ~200 duplicate lines, creates single source of truth for validation
- **Time:** 2-3 hours (includes comprehensive testing)

---

## Testing Strategy

### Unit Tests
- `CalendarDateSelectionMixin` - state management
- `CalendarDateValidator` - all validation scenarios
- Custom painters - render tests

### Integration Tests
- Both calendars with all validation scenarios:
  - Past date blocking
  - Advance booking window
  - Check-in/check-out restrictions
  - Min/max nights validation
  - Cross-month ranges (month calendar only)
  - Orphan gap prevention (year calendar only)

### Visual Regression Tests
- Both calendars should look identical before/after refactoring
- Test all states: available, booked, pending, partial, disabled
- Test hover tooltips
- Test responsive layouts (mobile, desktop)

---

## Files to Create

1. ✅ `lib/features/widget/presentation/widgets/calendar/calendar_painters.dart` (185 lines)
2. ✅ `lib/features/widget/presentation/widgets/calendar/calendar_date_selection_mixin.dart` (30 lines)
3. ✅ `lib/features/widget/presentation/widgets/calendar/calendar_date_validator.dart` (200 lines)
4. ✅ `lib/features/widget/presentation/widgets/calendar/calendar_combined_header_widget.dart` (60 lines)

---

## Files to Modify

1. ✅ `year_calendar_widget.dart` - Remove ~440 lines of duplicate code
2. ✅ `month_calendar_widget.dart` - Remove ~160 lines of duplicate code

---

## Expected Results

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| year_calendar_widget.dart | 1,152 lines | ~710 lines | -440 lines (-38%) |
| month_calendar_widget.dart | 879 lines | ~720 lines | -160 lines (-18%) |
| Total widget code | 2,031 lines | 1,430 lines | -600 lines (-30%) |
| Shared code (new files) | 0 lines | ~475 lines | +475 lines |
| **Net reduction** | **2,031 lines** | **1,905 lines** | **-126 lines (-6%)** |

**Note:** Net reduction is modest because we're creating new abstraction files. The real benefit is:
- **Single source of truth** for validation logic
- **Easier maintenance** (1 place to fix bugs instead of 2)
- **Reduced cognitive load** when reading code

---

## Rollback Plan

If any phase introduces bugs:

1. **Immediate:** Revert the specific commit for that phase
2. **Keep:** All previous phases that are working
3. **Investigate:** Root cause in isolated branch
4. **Retry:** After fixing the abstraction

Git strategy: **1 commit per phase** for easy rollback.

---

## Questions to Answer Before Implementation

1. ✅ **Painters:** Can year calendar use existing `SplitDayCalendarPainter` or do we need consolidation?
   - **Answer:** Check if `split_day_calendar_painter.dart` supports all 3 year calendar painter use cases

2. ✅ **Validation:** Should month calendar adopt year calendar's local validation methods?
   - **Current:** Month uses backend (Bug #72 fix for cross-month validation)
   - **Recommendation:** Keep backend validation for month calendar, extract only shared pre-checks

3. ✅ **Testing:** Do we have visual regression test infrastructure?
   - **Fallback:** Manual testing with screenshots before/after

---

## Success Criteria

✅ **Functionality preserved:** Both calendars work identically
✅ **Code reduced:** ~600 lines of duplication removed
✅ **Maintainability improved:** Single source of truth for validation
✅ **No new bugs:** All existing tests pass
✅ **Documentation updated:** New files have clear comments

---

## Notes

- **CRITICAL:** Year calendar has local validation (`_hasBlockedDatesInRange`, `_wouldCreateOrphanGap`) while month calendar uses backend validation. This difference must be preserved.
- **CRITICAL:** Month calendar wraps tooltip in `IgnorePointer` - investigate why before extracting.
- **CRITICAL:** Navigation state differs (`_currentYear` vs `_currentMonth`) - cannot be extracted to mixin.

---

**Last Updated:** 2025-12-03
**Status:** READY FOR USER REVIEW
**Recommendation:** Approve Phase 1 (Painters) for immediate implementation.
