import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookbed/shared/widgets/offline_indicator.dart';
import 'package:bookbed/core/providers/connectivity_provider.dart';

void main() {
  group('OfflineIndicator', () {
    late StreamController<bool> connectivityController;

    setUp(() {
      connectivityController = StreamController<bool>.broadcast();
    });

    tearDown(() {
      connectivityController.close();
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          isOnlineProvider.overrideWith((ref) => connectivityController.stream),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(child: Text('Main Content')),
                OfflineIndicator(),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('shows nothing when online initially', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      connectivityController.add(true);
      await tester.pumpAndSettle();

      expect(find.text('Nema interneta'), findsNothing);
      expect(find.text('Ponovo povezano'), findsNothing);
    });

    testWidgets('shows offline banner when offline', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      connectivityController.add(false);
      await tester.pumpAndSettle();

      expect(find.text('Nema interneta'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('Ponovo povezano'), findsNothing);

      // Let animation complete before disposing
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('shows reconnected banner and hides after delay when coming back online', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Go offline
      connectivityController.add(false);
      await tester.pumpAndSettle();
      expect(find.text('Nema interneta'), findsOneWidget);

      // Come back online
      connectivityController.add(true);
      await tester.pumpAndSettle();

      // Should show reconnected
      expect(find.text('Ponovo povezano'), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);
      expect(find.text('Nema interneta'), findsNothing);

      // Wait for timer (2 seconds)
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should hide everything
      expect(find.text('Ponovo povezano'), findsNothing);
    });
  });
}
