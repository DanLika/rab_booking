// Golden: owner Timeline + Mjesečni (month) premium chrome.
//
// Renders the REAL premium header (eyebrow + "Kalendar" title + Timeline∣Mjesečni
// switch), toolbar/legend card and FAB via `buildChromeForTest` — the FROZEN
// grid is swapped for a sized placeholder inside the builder, so no Firebase.

@Tags(['golden'])
library;

import 'package:bookbed/features/owner_dashboard/presentation/screens/calendar/month_calendar_screen.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/owner_timeline_calendar_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_harness.dart';

void main() {
  goldenSurface(
    'timeline_chrome',
    maxContentWidth: 1100,
    build: (context, v) => const OwnerTimelineCalendarScreen()
        .buildChromeForTest(context, isMobile: v.isMobile),
  );

  goldenSurface(
    'month_chrome',
    maxContentWidth: 1100,
    build: (context, v) => const MonthCalendarScreen().buildChromeForTest(
      context,
      isMobile: v.isMobile,
    ),
  );
}
