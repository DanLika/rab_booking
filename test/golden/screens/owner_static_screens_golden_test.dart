// Goldens: self-contained owner screens (no required ctor args, AppLocalizations
// + hr locale, no Firebase at build time). Captured at the device viewport.
//
// These are the "easy" tier — each provides its own Scaffold, so
// `wrapInScaffold: false`. `tolerateOverflow` keeps a fixed-viewport capture
// from failing on intrinsic-height overflow (the PNG still shows it).

@Tags(['golden'])
library;

import 'package:bookbed/features/auth/presentation/screens/cookies_policy_screen.dart';
import 'package:bookbed/features/auth/presentation/screens/enhanced_register_screen.dart';
import 'package:bookbed/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bookbed/features/auth/presentation/screens/privacy_policy_screen.dart';
import 'package:bookbed/features/auth/presentation/screens/terms_conditions_screen.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/change_password_screen.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/guides/faq_screen.dart';
import 'package:bookbed/shared/presentation/screens/not_found_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_harness.dart';

void main() {
  goldenScreen(
    'legal_privacy_policy',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const PrivacyPolicyScreen(),
  );

  goldenScreen(
    'legal_terms_conditions',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const TermsConditionsScreen(),
  );

  goldenScreen(
    'legal_cookies_policy',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const CookiesPolicyScreen(),
  );

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
