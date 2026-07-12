// Golden: owner profile-hub BookBed Pro trial card.
//
// Renders the REAL `_ProfilProCard` via `buildProCardForTest` (no
// Scaffold/drawer/providers) so any change to the benefits grid, price, or
// CTA is caught. The handoff's trial-progress bar is intentionally absent
// (no trial-day-count field on the model → would be fabricated data).

@Tags(['golden'])
library;

import 'package:bookbed/features/owner_dashboard/presentation/screens/profile_screen.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_harness.dart';

void main() {
  goldenSurface(
    'profile_pro_card',
    maxContentWidth: 1100,
    padding: const EdgeInsets.all(12),
    build: (context, v) => buildProCardForTest(
      l10n: AppLocalizations.of(context),
      isMobile: v.isMobile,
    ),
  );
}
