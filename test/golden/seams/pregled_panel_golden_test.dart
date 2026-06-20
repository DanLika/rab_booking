// Golden: owner Pregled (Dashboard Overview) premium panel.
//
// Renders the REAL `_pregledPanelChildren` via `buildPanelForTest` (no
// Scaffold/drawer/providers) with the handoff-sample fixture. Captured WHOLE on
// a tall surface so a change anywhere in the panel — KPI chips, chart,
// occupancy column, arrivals card — is caught.

@Tags(['golden'])
library;

import 'package:bookbed/features/owner_dashboard/presentation/screens/dashboard_overview_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fixtures.dart';
import '../../helpers/golden_harness.dart';

void main() {
  goldenSurface(
    'pregled_panel',
    maxContentWidth: 1100,
    padding: const EdgeInsets.all(12),
    build: (context, v) => const DashboardOverviewTab().buildPanelForTest(
      context,
      data: dashboardFixture(),
      dateRange: dashboardRange(),
      isMobile: v.isMobile,
      userName: 'Ivana',
      // Pin the clock: the header greeting (hour) + eyebrow date (day) read
      // DateTime.now() in production and were time-of-day/daily flaky. Fixed to
      // the original bless instant (Sat 20 Jun 2026, 09:00 -> "Dobro jutro").
      now: DateTime(2026, 6, 20, 9),
    ),
  );
}
