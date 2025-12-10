import 'package:flutter/material.dart';

import '../../presentation/providers/booking_price_provider.dart';
import '../constants/widget_constants.dart';

/// Result of a price lock check.
enum PriceLockResult {
  /// Price unchanged - proceed with booking.
  noChange,

  /// Price changed and user confirmed to proceed.
  confirmedProceed,

  /// Price changed and user cancelled.
  cancelled,
}

/// Configuration for price change dialogs.
///
/// Allows customization of dialog appearance and text.
/// Use [PriceChangeDialogConfig.defaultConfig] for standard behavior.
class PriceChangeDialogConfig {
  /// Title for price increase dialog.
  final String increaseTitleText;

  /// Title for price decrease dialog.
  final String decreaseTitleText;

  /// Text for cancel button.
  final String cancelButtonText;

  /// Text for proceed button.
  final String proceedButtonText;

  /// Color for price increase indicator.
  final Color increaseColor;

  /// Color for price decrease indicator.
  final Color decreaseColor;

  /// Currency symbol for price display.
  final String currencySymbol;

  const PriceChangeDialogConfig({
    this.increaseTitleText = '⚠️ Price Increased',
    this.decreaseTitleText = 'ℹ️ Price Decreased',
    this.cancelButtonText = 'Cancel',
    this.proceedButtonText = 'Proceed',
    this.increaseColor = Colors.orange,
    this.decreaseColor = Colors.blue,
    this.currencySymbol = '€',
  });

  /// Default configuration with standard colors and text.
  static const defaultConfig = PriceChangeDialogConfig();

  /// Croatian localized configuration.
  static const croatianConfig = PriceChangeDialogConfig(
    increaseTitleText: '⚠️ Cijena Povećana',
    decreaseTitleText: 'ℹ️ Cijena Snižena',
    cancelButtonText: 'Odustani',
    proceedButtonText: 'Nastavi',
  );
}

/// Builder for price change confirmation dialogs.
///
/// Extracted from [PriceLockService] for better testability
/// and separation of concerns.
///
/// ## Usage
/// ```dart
/// final result = await PriceChangeDialogBuilder.showPriceChangeDialog(
///   context: context,
///   priceIncreased: true,
///   changeAmount: 10.50,
///   originalPrice: 100.0,
///   currentPrice: 110.50,
/// );
/// ```
class PriceChangeDialogBuilder {
  /// Build and show a price change dialog with navigation handling.
  ///
  /// Returns `true` if user confirms, `false` if cancelled, `null` if dismissed.
  static Future<bool?> showPriceChangeDialog({
    required BuildContext context,
    required bool priceIncreased,
    required double changeAmount,
    required double originalPrice,
    required double currentPrice,
    PriceChangeDialogConfig config = PriceChangeDialogConfig.defaultConfig,
  }) {
    final symbol = config.currencySymbol;
    final changeFormatted = changeAmount.toStringAsFixed(2);
    final originalFormatted = originalPrice.toStringAsFixed(2);
    final currentFormatted = currentPrice.toStringAsFixed(2);

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          priceIncreased ? config.increaseTitleText : config.decreaseTitleText,
          style: TextStyle(
            color: priceIncreased ? config.increaseColor : config.decreaseColor,
          ),
        ),
        content: Text(
          priceIncreased
              ? 'The price has increased by $symbol$changeFormatted since you started booking.\n\n'
                    'Original: $symbol$originalFormatted\n'
                    'Current: $symbol$currentFormatted\n\n'
                    'Do you want to proceed with the new price?'
              : 'Good news! The price decreased by $symbol$changeFormatted.\n\n'
                    'Original: $symbol$originalFormatted\n'
                    'Current: $symbol$currentFormatted\n\n'
                    'Proceed with the new price?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(config.cancelButtonText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: priceIncreased
                  ? config.increaseColor
                  : config.decreaseColor,
            ),
            child: Text(config.proceedButtonText),
          ),
        ],
      ),
    );
  }

  /// Build a dialog widget without showing it.
  ///
  /// Useful for testing dialog appearance.
  static Widget buildDialogWidget({
    required bool priceIncreased,
    required double changeAmount,
    required double originalPrice,
    required double currentPrice,
    required VoidCallback onCancel,
    required VoidCallback onProceed,
    PriceChangeDialogConfig config = PriceChangeDialogConfig.defaultConfig,
  }) {
    final symbol = config.currencySymbol;
    final changeFormatted = changeAmount.toStringAsFixed(2);
    final originalFormatted = originalPrice.toStringAsFixed(2);
    final currentFormatted = currentPrice.toStringAsFixed(2);

    return AlertDialog(
      title: Text(
        priceIncreased ? config.increaseTitleText : config.decreaseTitleText,
        style: TextStyle(
          color: priceIncreased ? config.increaseColor : config.decreaseColor,
        ),
      ),
      content: Text(
        priceIncreased
            ? 'The price has increased by $symbol$changeFormatted since you started booking.\n\n'
                  'Original: $symbol$originalFormatted\n'
                  'Current: $symbol$currentFormatted\n\n'
                  'Do you want to proceed with the new price?'
            : 'Good news! The price decreased by $symbol$changeFormatted.\n\n'
                  'Original: $symbol$originalFormatted\n'
                  'Current: $symbol$currentFormatted\n\n'
                  'Proceed with the new price?',
      ),
      actions: [
        TextButton(onPressed: onCancel, child: Text(config.cancelButtonText)),
        ElevatedButton(
          onPressed: onProceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: priceIncreased
                ? config.increaseColor
                : config.decreaseColor,
          ),
          child: Text(config.proceedButtonText),
        ),
      ],
    );
  }
}

/// Service for handling price lock checks during booking.
///
/// Detects if price changed since user started booking flow and
/// shows confirmation dialog if needed.
///
/// ## Refactoring Notes (Phase 6)
/// - Dialog building extracted to [PriceChangeDialogBuilder]
/// - Tolerance now uses [WidgetConstants.priceTolerance]
/// - Configurable via [PriceChangeDialogConfig]
///
/// ## Usage
/// ```dart
/// final result = await PriceLockService.checkAndConfirmPriceChange(
///   context: context,
///   currentCalculation: currentPrice,
///   lockedCalculation: lockedPrice,
///   onLockUpdated: () => ref.invalidate(priceProvider),
/// );
///
/// if (result == PriceLockResult.cancelled) {
///   return; // User cancelled
/// }
/// // Proceed with booking
/// ```
class PriceLockService {
  /// Default tolerance for price comparisons.
  ///
  /// Uses [WidgetConstants.priceTolerance] (0.01 = 1 cent).
  static const double defaultTolerance = WidgetConstants.priceTolerance;

  /// Check if price changed and show confirmation dialog if needed.
  ///
  /// Returns [PriceLockResult] indicating how to proceed.
  ///
  /// Parameters:
  /// - [context] - BuildContext for showing dialog
  /// - [currentCalculation] - Current price calculation
  /// - [lockedCalculation] - Price calculation when user started booking
  /// - [onLockUpdated] - Callback when locked price needs update
  /// - [tolerance] - Price difference tolerance (defaults to [defaultTolerance])
  /// - [dialogConfig] - Optional dialog customization
  static Future<PriceLockResult> checkAndConfirmPriceChange({
    required BuildContext context,
    required BookingPriceCalculation currentCalculation,
    required BookingPriceCalculation? lockedCalculation,
    required VoidCallback onLockUpdated,
    double tolerance = defaultTolerance,
    PriceChangeDialogConfig dialogConfig =
        PriceChangeDialogConfig.defaultConfig,
  }) async {
    // No locked price - no change detection needed
    if (lockedCalculation == null) {
      return PriceLockResult.noChange;
    }

    final priceDelta =
        currentCalculation.totalPrice - lockedCalculation.totalPrice;

    // Price within tolerance - no change
    if (priceDelta.abs() <= tolerance) {
      return PriceLockResult.noChange;
    }

    final priceIncreased = priceDelta > 0;
    final changeAmount = priceDelta.abs();

    // Show confirmation dialog using builder
    final confirmed = await PriceChangeDialogBuilder.showPriceChangeDialog(
      context: context,
      priceIncreased: priceIncreased,
      changeAmount: changeAmount,
      originalPrice: lockedCalculation.totalPrice,
      currentPrice: currentCalculation.totalPrice,
      config: dialogConfig,
    );

    // Update locked price regardless of user choice
    onLockUpdated();

    if (confirmed == true) {
      return PriceLockResult.confirmedProceed;
    }

    return PriceLockResult.cancelled;
  }

  /// Check if two prices are equal within tolerance.
  ///
  /// Utility method for price comparisons elsewhere in the codebase.
  static bool pricesEqual(
    double price1,
    double price2, {
    double tolerance = defaultTolerance,
  }) {
    return (price1 - price2).abs() <= tolerance;
  }

  /// Calculate the price delta between two calculations.
  ///
  /// Returns positive value if current > locked (price increased),
  /// negative if current < locked (price decreased).
  static double calculatePriceDelta(
    BookingPriceCalculation current,
    BookingPriceCalculation locked,
  ) {
    return current.totalPrice - locked.totalPrice;
  }
}
