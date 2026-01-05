import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'enums.dart';

/// Extension for BookingStatus to add localized display names
extension BookingStatusExtensions on BookingStatus {
  /// Get localized display name for booking status
  /// Uses AppLocalizations for proper Croatian/English translation
  String displayNameLocalized(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      BookingStatus.pending => l10n.ownerStatusPending,
      BookingStatus.confirmed => l10n.ownerStatusConfirmed,
      BookingStatus.cancelled => l10n.ownerStatusCancelled,
      BookingStatus.completed => l10n.ownerStatusCompleted,
    };
  }
}
