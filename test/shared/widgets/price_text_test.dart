import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/services/currency_service.dart';
import 'package:bookbed/shared/widgets/price_text.dart';

class MockSelectedCurrency extends SelectedCurrency {
  final Currency currency;
  MockSelectedCurrency(this.currency);

  @override
  Future<Currency> build() async => currency;
}

class LoadingSelectedCurrency extends SelectedCurrency {
  @override
  Future<Currency> build() async {
    return Completer<Currency>().future;
  }
}

class ErrorSelectedCurrency extends SelectedCurrency {
  @override
  Future<Currency> build() async {
    throw Exception('Failed to load currency');
  }
}

void main() {
  group('PriceText', () {
    Widget buildPriceTextWidget({
      required double priceInEur,
      TextStyle? style,
      bool showPerNight = false,
      SelectedCurrency Function()? overrideProvider,
    }) {
      return ProviderScope(
        overrides: [
          if (overrideProvider != null)
            selectedCurrencyProvider.overrideWith(overrideProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PriceText(
              priceInEur: priceInEur,
              style: style,
              showPerNight: showPerNight,
            ),
          ),
        ),
      );
    }

    testWidgets('renders loading state correctly', (tester) async {
      await tester.pumpWidget(
        buildPriceTextWidget(
          priceInEur: 150.50,
          overrideProvider: () => LoadingSelectedCurrency(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state fallback correctly', (tester) async {
      await tester.pumpWidget(
        buildPriceTextWidget(
          priceInEur: 150.50,
          overrideProvider: () => ErrorSelectedCurrency(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('€150.50'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders error state fallback correctly with per night', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPriceTextWidget(
          priceInEur: 150.50,
          showPerNight: true,
          overrideProvider: () => ErrorSelectedCurrency(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('€150.50 / night'), findsOneWidget);
    });

    testWidgets('renders EUR correctly', (tester) async {
      await tester.pumpWidget(
        buildPriceTextWidget(
          priceInEur: 100.00,
          overrideProvider: () => MockSelectedCurrency(Currency.eur),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('€100.00'), findsOneWidget);
    });

    testWidgets('renders USD correctly', (tester) async {
      await tester.pumpWidget(
        buildPriceTextWidget(
          priceInEur: 100.00,
          overrideProvider: () => MockSelectedCurrency(Currency.usd),
        ),
      );

      await tester.pumpAndSettle();
      // 100 * 1.09 = 109.0
      expect(find.text('\$109.00'), findsOneWidget);
    });

    testWidgets('renders GBP correctly', (tester) async {
      await tester.pumpWidget(
        buildPriceTextWidget(
          priceInEur: 100.00,
          overrideProvider: () => MockSelectedCurrency(Currency.gbp),
        ),
      );

      await tester.pumpAndSettle();
      // 100 * 0.86 = 86.0
      expect(find.text('£86.00'), findsOneWidget);
    });

    testWidgets('renders HRK correctly', (tester) async {
      await tester.pumpWidget(
        buildPriceTextWidget(
          priceInEur: 100.00,
          overrideProvider: () => MockSelectedCurrency(Currency.hrk),
        ),
      );

      await tester.pumpAndSettle();
      // 100 * 7.53 = 753.0
      expect(find.text('753.00 kn'), findsOneWidget);
    });

    testWidgets('renders with per night text', (tester) async {
      await tester.pumpWidget(
        buildPriceTextWidget(
          priceInEur: 100.00,
          showPerNight: true,
          overrideProvider: () => MockSelectedCurrency(Currency.eur),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('€100.00 / night'), findsOneWidget);
    });

    testWidgets('applies text style', (tester) async {
      const testStyle = TextStyle(fontSize: 24, color: Colors.red);
      await tester.pumpWidget(
        buildPriceTextWidget(
          priceInEur: 100.00,
          style: testStyle,
          overrideProvider: () => MockSelectedCurrency(Currency.eur),
        ),
      );

      await tester.pumpAndSettle();
      final textWidget = tester.widget<Text>(find.text('€100.00'));
      expect(textWidget.style?.fontSize, 24);
      expect(textWidget.style?.color, Colors.red);
    });
  });

  group('PriceRichText', () {
    Widget buildPriceRichTextWidget({
      required double priceInEur,
      TextStyle? priceStyle,
      TextStyle? suffixStyle,
      String? suffix,
      SelectedCurrency Function()? overrideProvider,
    }) {
      return ProviderScope(
        overrides: [
          if (overrideProvider != null)
            selectedCurrencyProvider.overrideWith(overrideProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PriceRichText(
              priceInEur: priceInEur,
              priceStyle: priceStyle,
              suffixStyle: suffixStyle,
              suffix: suffix,
            ),
          ),
        ),
      );
    }

    testWidgets('renders loading state correctly', (tester) async {
      await tester.pumpWidget(
        buildPriceRichTextWidget(
          priceInEur: 150.50,
          overrideProvider: () => LoadingSelectedCurrency(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state fallback correctly', (tester) async {
      await tester.pumpWidget(
        buildPriceRichTextWidget(
          priceInEur: 150.50,
          overrideProvider: () => ErrorSelectedCurrency(),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(RichText), findsOneWidget);
      // Wait, testing RichText text requires matching TextSpan
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      expect(textSpan.text, '€150.50');
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders error state fallback with suffix', (tester) async {
      await tester.pumpWidget(
        buildPriceRichTextWidget(
          priceInEur: 150.50,
          suffix: ' / night',
          overrideProvider: () => ErrorSelectedCurrency(),
        ),
      );

      await tester.pumpAndSettle();
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      expect(textSpan.text, '€150.50');
      expect(textSpan.children?.first, isA<TextSpan>());
      expect((textSpan.children?.first as TextSpan).text, ' / night');
    });

    testWidgets('renders EUR correctly with suffix and styles', (tester) async {
      const priceStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 20);
      const suffixStyle = TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      );

      await tester.pumpWidget(
        buildPriceRichTextWidget(
          priceInEur: 100.00,
          suffix: ' / night',
          priceStyle: priceStyle,
          suffixStyle: suffixStyle,
          overrideProvider: () => MockSelectedCurrency(Currency.eur),
        ),
      );

      await tester.pumpAndSettle();

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      expect(textSpan.text, '€100.00');
      expect(textSpan.style?.fontWeight, FontWeight.bold);
      expect(textSpan.style?.fontSize, 20);

      final suffixSpan = textSpan.children?.first as TextSpan;
      expect(suffixSpan.text, ' / night');
      expect(suffixSpan.style?.fontWeight, FontWeight.normal);
      expect(suffixSpan.style?.fontSize, 14);
    });

    testWidgets('inherits default style if priceStyle is null', (tester) async {
      await tester.pumpWidget(
        buildPriceRichTextWidget(
          priceInEur: 100.00,
          overrideProvider: () => MockSelectedCurrency(Currency.eur),
        ),
      );

      await tester.pumpAndSettle();

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      expect(textSpan.text, '€100.00');
      // Should have a style based on DefaultTextStyle
      expect(textSpan.style, isNotNull);
    });
  });
}
