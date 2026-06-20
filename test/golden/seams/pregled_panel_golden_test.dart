// Golden: owner Pregled (Dashboard Overview) premium panel.
//
// Renders the REAL `_pregledPanelChildren` via `buildPanelForTest` (no
// Scaffold/drawer/providers) with the handoff-sample fixture. Captured WHOLE on
// a tall surface so a change anywhere in the panel — KPI chips, chart,
// occupancy column, arrivals card — is caught.

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
    ),
  );
}
