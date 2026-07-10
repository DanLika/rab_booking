import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:bookbed/core/services/deep_link_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGoRouter extends Mock implements GoRouter {}

class MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

void main() {
  late MockGoRouter mockGoRouter;
  late MockUrlLauncher mockUrlLauncher;
  late BuildContext testContext;
  late DeepLinkService service;

  setUpAll(() {
    registerFallbackValue(const LaunchOptions());
  });

  setUp(() {
    mockGoRouter = MockGoRouter();
    mockUrlLauncher = MockUrlLauncher();
    UrlLauncherPlatform.instance = mockUrlLauncher;
    service = DeepLinkService();
  });

  Future<void> pumpContext(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: Builder(
            builder: (context) {
              testContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  group('DeepLinkService - App deep links', () {
    testWidgets('handles /owner/calendar with all params', (tester) async {
      await pumpContext(tester);
      when(() => mockGoRouter.go(any())).thenReturn(null);

      final result = await service.handleDeepLink(
        'bookbed:///owner/calendar?unit=123&date=2024-01-01&conflict=456',
        testContext,
      );

      expect(result, isTrue);
      verify(() => mockGoRouter.go('/owner/calendar?unit=123&date=2024-01-01&conflict=456')).called(1);
    });

    testWidgets('handles /owner/calendar with only unit param', (tester) async {
      await pumpContext(tester);
      when(() => mockGoRouter.go(any())).thenReturn(null);

      final result = await service.handleDeepLink(
        'bookbed:///owner/calendar?unit=123',
        testContext,
      );

      expect(result, isTrue);
      verify(() => mockGoRouter.go('/owner/calendar?unit=123')).called(1);
    });

    testWidgets('does not handle /owner/calendar without unit param', (tester) async {
      await pumpContext(tester);
      final result = await service.handleDeepLink(
        'bookbed:///owner/calendar',
        testContext,
      );

      expect(result, isFalse);
      verifyNever(() => mockGoRouter.go(any()));
    });

    testWidgets('handles /owner/bookings with booking param', (tester) async {
      await pumpContext(tester);
      when(() => mockGoRouter.go(any())).thenReturn(null);

      final result = await service.handleDeepLink(
        'bookbed:///owner/bookings?booking=789',
        testContext,
      );

      expect(result, isTrue);
      verify(() => mockGoRouter.go('/owner/bookings?booking=789')).called(1);
    });

    testWidgets('handles /owner/bookings with conflict param', (tester) async {
      await pumpContext(tester);
      when(() => mockGoRouter.go(any())).thenReturn(null);

      final result = await service.handleDeepLink(
        'bookbed:///owner/bookings?conflict=456',
        testContext,
      );

      expect(result, isTrue);
      verify(() => mockGoRouter.go('/owner/bookings?conflict=456')).called(1);
    });

    testWidgets('handles /owner/bookings without params', (tester) async {
      await pumpContext(tester);
      when(() => mockGoRouter.go(any())).thenReturn(null);

      final result = await service.handleDeepLink(
        'bookbed:///owner/bookings',
        testContext,
      );

      expect(result, isTrue);
      verify(() => mockGoRouter.go('/owner/bookings')).called(1);
    });

    testWidgets('handles /owner/platform-connections with unit param', (tester) async {
      await pumpContext(tester);
      when(() => mockGoRouter.go(any())).thenReturn(null);

      final result = await service.handleDeepLink(
        'bookbed:///owner/platform-connections?unit=123',
        testContext,
      );

      expect(result, isTrue);
      verify(() => mockGoRouter.go('/owner/platform-connections?unit=123')).called(1);
    });

    testWidgets('handles /owner/platform-connections without unit param', (tester) async {
      await pumpContext(tester);
      when(() => mockGoRouter.go(any())).thenReturn(null);

      final result = await service.handleDeepLink(
        'bookbed:///owner/platform-connections',
        testContext,
      );

      expect(result, isTrue);
      verify(() => mockGoRouter.go('/owner/platform-connections')).called(1);
    });

    testWidgets('does not handle unknown app paths', (tester) async {
      await pumpContext(tester);
      final result = await service.handleDeepLink(
        'bookbed:///unknown/path',
        testContext,
      );

      expect(result, isFalse);
      verifyNever(() => mockGoRouter.go(any()));
    });
  });

  group('DeepLinkService - External Web URLs', () {
    testWidgets('handles allowed external URL (exact match)', (tester) async {
      await pumpContext(tester);
      when(() => mockUrlLauncher.canLaunch('https://booking.com'))
          .thenAnswer((_) async => true);
      when(() => mockUrlLauncher.launchUrl('https://booking.com', any()))
          .thenAnswer((_) async => true);

      final result = await service.handleDeepLink('https://booking.com', testContext);

      expect(result, isTrue);
      verify(() => mockUrlLauncher.launchUrl('https://booking.com', any())).called(1);
    });

    testWidgets('handles allowed external URL (subdomain)', (tester) async {
      await pumpContext(tester);
      when(() => mockUrlLauncher.canLaunch('https://admin.booking.com'))
          .thenAnswer((_) async => true);
      when(() => mockUrlLauncher.launchUrl('https://admin.booking.com', any()))
          .thenAnswer((_) async => true);

      final result = await service.handleDeepLink('https://admin.booking.com', testContext);

      expect(result, isTrue);
      verify(() => mockUrlLauncher.launchUrl('https://admin.booking.com', any())).called(1);
    });

    testWidgets('blocks disallowed external URL', (tester) async {
      await pumpContext(tester);
      final result = await service.handleDeepLink('https://example.com', testContext);

      expect(result, isFalse);
      verifyNever(() => mockUrlLauncher.launchUrl(any(), any()));
    });

    testWidgets('returns false when canLaunchUrl returns false', (tester) async {
      await pumpContext(tester);
      when(() => mockUrlLauncher.canLaunch('https://booking.com'))
          .thenAnswer((_) async => false);

      final result = await service.handleDeepLink('https://booking.com', testContext);

      expect(result, isFalse);
      verifyNever(() => mockUrlLauncher.launchUrl(any(), any()));
    });

    testWidgets('returns false when launchUrl throws exception', (tester) async {
      await pumpContext(tester);
      when(() => mockUrlLauncher.canLaunch('https://booking.com'))
          .thenAnswer((_) async => true);
      when(() => mockUrlLauncher.launchUrl('https://booking.com', any()))
          .thenThrow(Exception('Launch failed'));

      final result = await service.handleDeepLink('https://booking.com', testContext);

      expect(result, isFalse);
    });
  });

  group('DeepLinkService - Invalid URLs', () {
    testWidgets('returns false for unknown schemes', (tester) async {
      await pumpContext(tester);
      final result = await service.handleDeepLink('ftp://example.com', testContext);

      expect(result, isFalse);
    });

    testWidgets('returns false for unparseable URLs', (tester) async {
      await pumpContext(tester);
      // FormatException is thrown by Uri.parse
      final result = await service.handleDeepLink('::invalid::', testContext);

      expect(result, isFalse);
    });
  });

  group('DeepLinkService - generateAppDeepLink', () {
    test('generates URL without query params', () {
      final url = DeepLinkService.generateAppDeepLink(path: '/owner/bookings');
      // The Uri class generates scheme:path, it doesn't default to scheme://host/path for custom schemes.
      // E.g., Uri(scheme: 'bookbed', path: '/owner/bookings').toString() == 'bookbed:/owner/bookings'
      expect(url, 'bookbed:/owner/bookings');
    });

    test('generates URL with query params', () {
      final url = DeepLinkService.generateAppDeepLink(
        path: '/owner/calendar',
        queryParams: {'unit': '123', 'date': '2024-01-01'},
      );
      expect(url, 'bookbed:/owner/calendar?unit=123&date=2024-01-01');
    });
  });
}
