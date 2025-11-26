import 'package:flutter/material.dart';

import '../../presentation/providers/booking_price_provider.dart';

/// Result of a price lock check
enum PriceLockResult {
  /// Price unchanged - proceed with booking
  noChange,

  /// Price changed and user confirmed to proceed
  confirmedProceed,

  /// Price changed and user cancelled
  cancelled,
}

/// Service for handling price lock checks during booking
/// Detects if price changed since user started booking flow
class PriceLockService {
  /// Check if price changed and show confirmation dialog if needed
  ///
  /// Returns [PriceLockResult] indicating how to proceed.
  /// [onLockUpdated] is called when the locked price needs to be updated
  /// (both on cancel and confirm).
  static Future<PriceLockResult> checkAndConfirmPriceChange({
    required BuildContext context,
    required BookingPriceCalculation currentCalculation,
    required BookingPriceCalculation? lockedCalculation,
    required VoidCallback onLockUpdated,
    double tolerance = 0.01, // 1 cent tolerance
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
    final changeAmount = priceDelta.abs().toStringAsFixed(2);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          priceIncreased ? '⚠️ Price Increased' : 'ℹ️ Price Decreased',
          style: TextStyle(
            color: priceIncreased ? Colors.orange : Colors.blue,
          ),
        ),
        content: Text(
          priceIncreased
              ? 'The price has increased by €$changeAmount since you started booking.\n\n'
                    'Original: €${lockedCalculation.totalPrice.toStringAsFixed(2)}\n'
                    'Current: €${currentCalculation.totalPrice.toStringAsFixed(2)}\n\n'
                    'Do you want to proceed with the new price?'
              : 'Good news! The price decreased by €$changeAmount.\n\n'
                    'Original: €${lockedCalculation.totalPrice.toStringAsFixed(2)}\n'
                    'Current: €${currentCalculation.totalPrice.toStringAsFixed(2)}\n\n'
                    'Proceed with the new price?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: priceIncreased ? Colors.orange : Colors.blue,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    // Update locked price regardless of user choice
    onLockUpdated();

    if (confirmed == true) {
      return PriceLockResult.confirmedProceed;
    }

    return PriceLockResult.cancelled;
  }
}
