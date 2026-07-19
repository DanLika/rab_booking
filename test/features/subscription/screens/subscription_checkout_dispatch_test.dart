import 'package:bookbed/core/config/environment.dart';
import 'package:bookbed/features/subscription/data/subscription_repository.dart';
import 'package:bookbed/features/subscription/screens/subscription_screen.dart';
import 'package:bookbed/features/subscription/utils/stripe_url_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/widget_test_helpers.dart';

/// Dispatch tests for the subscription checkout wiring.
///
/// `kIsWeb` is false under `flutter test`, so the web surface itself is not
/// pumpable; these tests exercise the shared `handleSubscriptionCheckoutTap`
/// seam that BOTH "Nadogradi na Pro" call sites and the manage button invoke.
/// Live wiring is verified on the running dev web app (per CLAUDE.md
/// seam-test note).
class _FakeRepo implements SubscriptionRepository {
  _FakeRepo({this.checkoutUrl, this.portalUrl});

  final String? checkoutUrl;
  final String? portalUrl;
  String? lastPriceId;
  String? lastReturnUrl;
  int checkoutCalls = 0;
  int portalCalls = 0;

  @override
  Future<String> createCheckoutSession({
    required String priceId,
    required String returnUrl,
  }) async {
    checkoutCalls++;
    lastPriceId = priceId;
    lastReturnUrl = returnUrl;
    return checkoutUrl!;
  }

  @override
  Future<String> createPortalSession({required String returnUrl}) async {
    portalCalls++;
    lastReturnUrl = returnUrl;
    return portalUrl!;
  }
}

void main() {
  const String safeUrl = 'https://checkout.stripe.com/c/pay/cs_test_123';

  tearDown(() => EnvironmentConfig.setEnvironment(Environment.development));

  group('isSafeStripeUrl', () {
    test('accepts the two Stripe-hosted domains over https', () {
      expect(isSafeStripeUrl(safeUrl), isTrue);
      expect(isSafeStripeUrl('https://billing.stripe.com/p/session_x'), isTrue);
    });

    test('rejects lookalikes, http, other hosts, and garbage', () {
      expect(
        isSafeStripeUrl('https://checkout.stripe.com.evil.com/x'),
        isFalse,
      );
      expect(isSafeStripeUrl('http://checkout.stripe.com/x'), isFalse);
      expect(isSafeStripeUrl('https://evil.com/checkout.stripe.com'), isFalse);
      expect(isSafeStripeUrl('https://stripe.com/x'), isFalse);
      expect(isSafeStripeUrl('not a url'), isFalse);
      expect(isSafeStripeUrl(''), isFalse);
    });
  });

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      createTestWidget(
        withL10n: true,
        child: Builder(
          builder: (BuildContext ctx) {
            captured = ctx;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  group('handleSubscriptionCheckoutTap', () {
    testWidgets('monthly toggle sends the monthly dev price ID', (
      WidgetTester tester,
    ) async {
      final BuildContext ctx = await pumpHost(tester);
      final _FakeRepo repo = _FakeRepo(checkoutUrl: safeUrl);
      final List<Uri> redirects = <Uri>[];

      await handleSubscriptionCheckoutTap(
        context: ctx,
        repository: repo,
        yearly: false,
        isSubscribed: false,
        redirect: (Uri u) async => redirects.add(u),
      );

      expect(repo.checkoutCalls, 1);
      expect(repo.lastPriceId, EnvironmentConfig.stripeProMonthlyPriceId);
      expect(repo.lastPriceId, isNotEmpty);
      expect(
        repo.lastReturnUrl,
        '${EnvironmentConfig.dashboardBaseUrl}/owner/subscription',
      );
      expect(redirects.single.toString(), safeUrl);
    });

    testWidgets('yearly toggle sends the yearly dev price ID', (
      WidgetTester tester,
    ) async {
      final BuildContext ctx = await pumpHost(tester);
      final _FakeRepo repo = _FakeRepo(checkoutUrl: safeUrl);

      await handleSubscriptionCheckoutTap(
        context: ctx,
        repository: repo,
        yearly: true,
        isSubscribed: false,
        redirect: (Uri u) async {},
      );

      expect(repo.lastPriceId, EnvironmentConfig.stripeProYearlyPriceId);
      expect(
        repo.lastPriceId,
        isNot(EnvironmentConfig.stripeProMonthlyPriceId),
      );
    });

    testWidgets(
      'empty price ID (staging) → coming-soon dialog, repository untouched',
      (WidgetTester tester) async {
        EnvironmentConfig.setEnvironment(Environment.staging);
        final BuildContext ctx = await pumpHost(tester);
        final _FakeRepo repo = _FakeRepo(checkoutUrl: safeUrl);
        final List<Uri> redirects = <Uri>[];

        await handleSubscriptionCheckoutTap(
          context: ctx,
          repository: repo,
          yearly: true,
          isSubscribed: false,
          redirect: (Uri u) async => redirects.add(u),
        );
        await tester.pumpAndSettle();

        expect(repo.checkoutCalls, 0);
        expect(repo.portalCalls, 0);
        expect(redirects, isEmpty);
        expect(find.byType(Dialog), findsOneWidget);
      },
    );

    testWidgets('unsafe URL from server → no redirect, error snackbar', (
      WidgetTester tester,
    ) async {
      final BuildContext ctx = await pumpHost(tester);
      final _FakeRepo repo = _FakeRepo(
        checkoutUrl: 'https://checkout.stripe.com.evil.com/x',
      );
      final List<Uri> redirects = <Uri>[];

      await handleSubscriptionCheckoutTap(
        context: ctx,
        repository: repo,
        yearly: false,
        isSubscribed: false,
        redirect: (Uri u) async => redirects.add(u),
      );
      await tester.pump();

      expect(redirects, isEmpty);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('already subscribed → portal session, not checkout', (
      WidgetTester tester,
    ) async {
      final BuildContext ctx = await pumpHost(tester);
      final _FakeRepo repo = _FakeRepo(
        portalUrl: 'https://billing.stripe.com/p/session_x',
      );
      final List<Uri> redirects = <Uri>[];

      await handleSubscriptionCheckoutTap(
        context: ctx,
        repository: repo,
        yearly: false,
        isSubscribed: true,
        redirect: (Uri u) async => redirects.add(u),
      );

      expect(repo.portalCalls, 1);
      expect(repo.checkoutCalls, 0);
      expect(
        redirects.single.toString(),
        'https://billing.stripe.com/p/session_x',
      );
    });
  });
}
