// Goldens: a few more self-contained owner screens. `stripe_connect` reads a
// status provider; if it can't pump hermetically it gets moved to DEFERRED.md
// rather than papered over.

import 'package:bookbed/features/owner_dashboard/presentation/screens/about_screen.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/guides/embed_help_screen.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/stripe_connect_setup_screen.dart';
import 'package:bookbed/features/subscription/screens/subscription_screen.dart';

import '../../helpers/golden_harness.dart';

void main() {
  goldenScreen(
    'owner_about',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const AboutScreen(),
  );

  goldenScreen(
    'guides_embed_help',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const EmbedHelpScreen(),
  );

  goldenScreen(
    'subscription',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const SubscriptionScreen(),
  );

  goldenScreen(
    'stripe_connect_setup',
    wrapInScaffold: false,
    tolerateOverflow: true,
    build: (v) => const StripeConnectSetupScreen(),
  );
}
