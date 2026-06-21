// Goldens: self-contained owner screens (no required ctor args, AppLocalizations
// + hr locale, no Firebase at build time). Captured at the device viewport.
//
// These are the "easy" tier — each provides its own Scaffold, so
// `wrapInScaffold: false`. `tolerateOverflow` keeps a fixed-viewport capture
// from failing on intrinsic-height overflow (the PNG still shows it).

@Tags(['golden'])
library;

import 'package:bookbed/features/auth/presentation/screens/enhanced_register_screen.dart';
import 'package:bookbed/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/change_password_screen.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/guides/faq_screen.dart';
import 'package:bookbed/shared/presentation/screens/not_found_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_harness.dart';

void main() {
  // NOTE: the 3 legal screens (privacy/terms/cookies) are DEFERRED from the net
  // — they render a `DateTime.now()` year/date in product code (annual/daily
  // flaky). See test/golden/README.md deferred ledger. Re-add once their date is
  // injectable.
  goldenScreen(
    'auth_register',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const EnhancedRegisterScreen(),
  );

  goldenScreen(
    'auth_forgot_password',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const ForgotPasswordScreen(),
  );

  goldenScreen(
    'profile_change_password',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const ChangePasswordScreen(),
  );

  goldenScreen(
    'guides_faq',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const FAQScreen(),
  );

  goldenScreen(
    'shared_not_found',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const NotFoundScreen(),
  );
}
