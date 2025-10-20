import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/currency_service.dart';

/// Widget that displays a price with automatic currency conversion
///
/// Takes a price in EUR (base currency) and automatically converts
/// it to the user's selected currency.
///
/// Example:
/// ```dart
/// PriceText(
///   priceInEur: 150.00,
///   style: AppTypography.h2,
/// )
/// ```
class PriceText extends ConsumerWidget {
  final double priceInEur;
  final TextStyle? style;
  final bool showPerNight;

  const PriceText({
    super.key,
    required this.priceInEur,
    this.style,
    this.showPerNight = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);

    return selectedCurrencyAsync.when(
      data: (currency) {
        final service = ref.watch(currencyServiceProvider);
        final formattedPrice = service.formatPrice(priceInEur, currency);
        final text = showPerNight ? '$formattedPrice / night' : formattedPrice;

        return Text(text, style: style);
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) {
        // Fallback to EUR
        return Text(
          showPerNight ? '€${priceInEur.toStringAsFixed(2)} / night' : '€${priceInEur.toStringAsFixed(2)}',
          style: style,
        );
      },
    );
  }
}

/// Rich text version with customizable parts
class PriceRichText extends ConsumerWidget {
  final double priceInEur;
  final TextStyle? priceStyle;
  final TextStyle? suffixStyle;
  final String? suffix; // e.g., " / night"

  const PriceRichText({
    super.key,
    required this.priceInEur,
    this.priceStyle,
    this.suffixStyle,
    this.suffix,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);

    return selectedCurrencyAsync.when(
      data: (currency) {
        final service = ref.watch(currencyServiceProvider);
        final formattedPrice = service.formatPrice(priceInEur, currency);

        return RichText(
          text: TextSpan(
            text: formattedPrice,
            style: priceStyle ?? DefaultTextStyle.of(context).style,
            children: suffix != null
                ? [
                    TextSpan(
                      text: suffix,
                      style: suffixStyle ?? priceStyle?.copyWith(fontWeight: FontWeight.normal),
                    ),
                  ]
                : [],
          ),
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) {
        final fallbackText = '€${priceInEur.toStringAsFixed(2)}';
        return RichText(
          text: TextSpan(
            text: fallbackText,
            style: priceStyle ?? DefaultTextStyle.of(context).style,
            children: suffix != null
                ? [
                    TextSpan(
                      text: suffix,
                      style: suffixStyle ?? priceStyle?.copyWith(fontWeight: FontWeight.normal),
                    ),
                  ]
                : [],
          ),
        );
      },
    );
  }
}

/// Format extension for easy formatting without widget
extension PriceFormatting on double {
  /// Format price with current currency (requires BuildContext with WidgetRef)
  String formatInCurrency(Currency currency) {
    final service = CurrencyService();
    return service.formatPrice(this, currency);
  }
}
