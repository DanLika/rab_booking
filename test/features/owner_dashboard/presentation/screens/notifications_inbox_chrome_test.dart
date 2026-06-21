// Wiring + render harness for the audit/141 notifications-inbox chrome:
// in-body premium header, "X unread · total Y" count (wired to
// `unreadNotificationsCountProvider`), mark-all-read (wired to
// `NotificationActions.markAllAsRead`), and the data-honest filter chips
// (only the 5 real NotificationTypes — no review / sync / rating).
//
//  * Wiring (en, plain theme): count text + 5 chips + mark-all button render,
//    and a chip narrows the inbox.
//  * Render (hr, real AppTheme + Inter/Material-Symbols fonts): NO overflow at
//    mobile / tablet / desktop × light / dark — plus a best-effort PNG dump to
//    /tmp/notif141-shots for the operator eyeball.
//
// NOT a golden subject: no `matchesGoldenFile` baseline is committed.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:bookbed/core/theme/app_theme.dart';
import 'package:bookbed/features/owner_dashboard/domain/models/notification_model.dart';
import 'package:bookbed/features/owner_dashboard/presentation/providers/notifications_provider.dart';
import 'package:bookbed/features/owner_dashboard/presentation/screens/notifications_screen.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle, FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_helpers.dart';

/// Firebase-free fake — records mark-all-read; everything else no-ops.
class _FakeActions implements NotificationActions {
  bool markAllCalled = false;
  String? markAllOwnerId;

  @override
  Future<void> markAllAsRead(String ownerId) async {
    markAllCalled = true;
    markAllOwnerId = ownerId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

NotificationModel _notif(
  String id,
  NotificationType type,
  String title,
  String message,
  DateTime ts, {
  required bool isRead,
  String? bookingId,
}) => NotificationModel(
  id: id,
  ownerId: 'owner-1',
  type: type,
  title: title,
  message: message,
  timestamp: ts,
  isRead: isRead,
  bookingId: bookingId,
);

/// 5 notifications spanning all 5 real types: 2 unread today, 2 read
/// yesterday, 1 read earlier this week. Noon-anchored so the Danas/Jučer
/// grouping is stable regardless of the wall-clock time the suite runs.
List<NotificationModel> _fixtureNotifs() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 12);
  return <NotificationModel>[
    _notif(
      'n1',
      NotificationType.bookingCreated,
      'Nova rezervacija čeka odobrenje',
      'Marko Horvat · Vila Marina – Studio 4 · 08.07. – 11.07. (3 noći)',
      today,
      isRead: false,
      bookingId: 'b1',
    ),
    _notif(
      'n2',
      NotificationType.paymentReceived,
      'Plaćanje zaprimljeno',
      'Sandra Kovač · Stan Lavanda – Apartman A · €420,00 putem Stripe-a',
      today.subtract(const Duration(hours: 5)),
      isRead: false,
    ),
    _notif(
      'n3',
      NotificationType.bookingCancelled,
      'Gost otkazao rezervaciju',
      'Petra Marić · Stan Lavanda – Apartman A · povrat €280,00 pokrenut',
      today.subtract(const Duration(days: 1)),
      isRead: true,
    ),
    _notif(
      'n4',
      NotificationType.system,
      'Sigurnosno ažuriranje',
      'BookBed v3.4.1 dostupan · sigurnosne zakrpe za widget i Stripe',
      today.subtract(const Duration(days: 1, hours: 6)),
      isRead: true,
    ),
    _notif(
      'n5',
      NotificationType.bookingUpdated,
      'Rezervacija ažurirana',
      'Vila Marina – Premium suite · termin promijenjen',
      today.subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];
}

List<Override> _overrides({
  required List<NotificationModel> notifs,
  required int unread,
  required NotificationActions actions,
}) => <Override>[
  notificationsStreamProvider.overrideWith((ref) => Stream.value(notifs)),
  unreadNotificationsCountProvider.overrideWith((ref) => Stream.value(unread)),
  notificationActionsProvider.overrideWith((ref) => actions),
];

/// Best-effort font load so the dumped PNGs are tofu-free (mirrors the
/// dashboard responsive harness). A miss never fails the test.
Future<void> _loadFonts() async {
  try {
    final inter = FontLoader('Inter');
    for (final w in const ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(rootBundle.load('assets/google_fonts/Inter-$w.ttf'));
    }
    await inter.load();
  } catch (_) {}

  try {
    final base = Directory(
      '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev',
    );
    String path = '';
    if (base.existsSync()) {
      for (final e in base.listSync()) {
        if (e.path.contains('/material_symbols_icons-')) {
          final f = File('${e.path}/lib/fonts/MaterialSymbolsRounded.ttf');
          if (f.existsSync()) {
            path = f.path;
            break;
          }
        }
      }
    }
    if (path.isNotEmpty) {
      final bytes = await File(path).readAsBytes();
      final sym = FontLoader(
        'packages/material_symbols_icons/MaterialSymbolsRounded',
      )..addFont(Future.value(bytes.buffer.asByteData()));
      await sym.load();
    }
  } catch (_) {}
}

const _breakpoints = <({String name, double width})>[
  (name: 'mobile', width: 390),
  (name: 'tablet', width: 768),
  (name: 'desktop', width: 1440),
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  group('audit/141 inbox chrome — wiring (en)', () {
    testWidgets('header count + 5 filter chips + mark-all-read button render', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          overrides: _overrides(
            notifs: _fixtureNotifs(),
            unread: 2,
            actions: _FakeActions(),
          ),
          child: const NotificationsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      allowOverflow(tester);

      // Count wired to unreadNotificationsCountProvider (2) + total (5).
      expect(find.text('2 unread · total 5'), findsOneWidget);

      // Data-honest chips: the 5 real types, no review / sync / rating.
      for (final label in const [
        'All',
        'Unread',
        'Bookings',
        'Payments',
        'System',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'filter chip: $label');
      }
      expect(find.text('Ocijeni'), findsNothing);
      expect(find.textContaining('Sync'), findsNothing);

      // Wide layout (default 800px surface) → mark-all-read is an in-body
      // button.
      expect(find.text('Mark all as read'), findsOneWidget);
    });

    testWidgets('a filter chip narrows the inbox (Payments drops Jučer)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          withL10n: true,
          overrides: _overrides(
            notifs: _fixtureNotifs(),
            unread: 2,
            actions: _FakeActions(),
          ),
          child: const NotificationsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      allowOverflow(tester);

      // Unfiltered: today + yesterday groups both present.
      expect(find.text('Danas'), findsOneWidget);
      expect(find.text('Jučer'), findsOneWidget);

      await tester.tap(find.text('Payments'));
      await tester.pump();
      allowOverflow(tester);

      // Only the (today) payment survives → yesterday's group is gone, total
      // count is unchanged (reflects all, not the filtered view).
      expect(find.text('Danas'), findsOneWidget);
      expect(find.text('Jučer'), findsNothing);
      expect(find.text('2 unread · total 5'), findsOneWidget);
    });
  });

  group('audit/141 inbox render — no overflow (hr, real theme)', () {
    for (final bp in _breakpoints) {
      for (final dark in const [false, true]) {
        final theme = dark ? 'dark' : 'light';
        testWidgets('${bp.name} · $theme — no overflow + PNG', (tester) async {
          tester.view.physicalSize = Size(bp.width, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final boundaryKey = GlobalKey();

          await tester.pumpWidget(
            ProviderScope(
              overrides: _overrides(
                notifs: _fixtureNotifs(),
                unread: 2,
                actions: _FakeActions(),
              ),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('hr'),
                home: RepaintBoundary(
                  key: boundaryKey,
                  child: const NotificationsScreen(),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          // PRIMARY gate — no RenderFlex / layout overflow at this size.
          expect(
            tester.takeException(),
            isNull,
            reason: '${bp.name} $theme overflow',
          );

          // Bonus — dump a PNG for the eyeball (never fails the test).
          await tester.runAsync(() async {
            try {
              final boundary =
                  boundaryKey.currentContext!.findRenderObject()
                      as RenderRepaintBoundary;
              final image = await boundary.toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              if (data != null) {
                final dir = Directory('/tmp/notif141-shots')
                  ..createSync(recursive: true);
                File(
                  '${dir.path}/notif-${bp.name}-$theme.png',
                ).writeAsBytesSync(data.buffer.asUint8List());
              }
            } catch (_) {}
          });
        });
      }
    }
  });
}
