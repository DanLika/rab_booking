import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'currency_service.g.dart';

/// Supported currencies
enum Currency {
  eur('EUR', 'Euro', '€', 1.0),
  usd('USD', 'US Dollar', '\$', 1.09),
  gbp('GBP', 'British Pound', '£', 0.86),
  hrk('HRK', 'Croatian Kuna', 'kn', 7.53);

  const Currency(this.code, this.name, this.symbol, this.rateToEur);

  final String code;
  final String name;
  final String symbol;
  final double rateToEur; // Exchange rate relative to EUR (base currency)

  /// Get currency from code
  static Currency fromCode(String code) {
    return Currency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => Currency.eur,
    );
  }
}

/// Currency service for managing selected currency and conversions
@riverpod
CurrencyService currencyService(Ref ref) {
  return CurrencyService();
}

/// Current selected currency provider
@riverpod
class SelectedCurrency extends _$SelectedCurrency {
  static const String _storageKey = 'selected_currency';

  @override
  Future<Currency> build() async {
    // Load from storage
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey);
    return code != null ? Currency.fromCode(code) : Currency.eur;
  }

  /// Change the selected currency
  Future<void> setCurrency(Currency currency) async {
    state = AsyncValue.data(currency);

    // Persist to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, currency.code);
  }
}

class CurrencyService {
  /// Convert amount from EUR to target currency
  double convert(double amountInEur, Currency targetCurrency) {
    return amountInEur * targetCurrency.rateToEur;
  }

  /// Convert amount from source currency to target currency
  double convertBetween(
    double amount,
    Currency from,
    Currency to,
  ) {
    // Convert to EUR first, then to target currency
    final amountInEur = amount / from.rateToEur;
    return amountInEur * to.rateToEur;
  }

  /// Format price with currency symbol
  String formatPrice(double priceInEur, Currency currency) {
    final convertedPrice = convert(priceInEur, currency);
    return _formatWithSymbol(convertedPrice, currency);
  }

  /// Format amount with currency symbol
  String _formatWithSymbol(double amount, Currency currency) {
    final formatted = amount.toStringAsFixed(2);

    // Symbol position based on currency
    switch (currency) {
      case Currency.eur:
      case Currency.gbp:
        return '${currency.symbol}$formatted';
      case Currency.usd:
        return '${currency.symbol}$formatted';
      case Currency.hrk:
        return '$formatted ${currency.symbol}';
    }
  }
}

/// Extension to easily get formatted price from any widget
extension CurrencyConversionExtension on double {
  /// Convert EUR price to selected currency and format
  String toCurrency(Currency currency) {
    final service = CurrencyService();
    return service.formatPrice(this, currency);
  }
}
