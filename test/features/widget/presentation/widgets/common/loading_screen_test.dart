import 'package:bookbed/features/widget/presentation/widgets/common/bookbed_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/widgets/common/loading_screen.dart';

void main() {
  group('WidgetLoadingScreen', () {
    testWidgets('renders BookBedLoader', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: WidgetLoadingScreen(isDarkMode: false))));

      expect(find.byType(BookBedLoader), findsOneWidget);
    });

    testWidgets('passes progress to loader', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: WidgetLoadingScreen(isDarkMode: false, progress: 0.5))),
      );

      final loaderFinder = find.byType(BookBedLoader);
      expect(loaderFinder, findsOneWidget);
      final loader = tester.widget<BookBedLoader>(loaderFinder);
      expect(loader.progress, 0.5);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: WidgetLoadingScreen(isDarkMode: true))));

      expect(find.byType(WidgetLoadingScreen), findsOneWidget);
      expect(find.byType(BookBedLoader), findsOneWidget);
    });

    testWidgets('uses Scaffold with proper background', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: WidgetLoadingScreen(isDarkMode: false))));

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
