import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/models/property_model.dart';
import '../../../../shared/models/unit_model.dart';
import 'widget_settings.dart';

part 'widget_context.freezed.dart';

/// Aggregated context for the booking widget.
///
/// Contains all data needed to render the widget, fetched in a single
/// batch operation to minimize Firestore queries.
///
/// ## Usage
/// ```dart
/// final context = ref.watch(widgetContextProvider(unitId));
/// context.when(
///   data: (ctx) => BookingWidget(context: ctx),
///   loading: () => LoadingIndicator(),
///   error: (e, st) => ErrorWidget(e),
/// );
/// ```
///
/// ## Properties
/// - [property] - Parent property with branding, subdomain, etc.
/// - [unit] - Unit with pricing, capacity, etc.
/// - [settings] - Widget settings (payment methods, approval mode, etc.)
/// - [ownerId] - Property owner's user ID (for notifications)
@freezed
class WidgetContext with _$WidgetContext {
  const factory WidgetContext({
    /// Parent property containing this unit
    required PropertyModel property,

    /// The unit being booked
    required UnitModel unit,

    /// Widget settings for this unit (payment, approval, etc.)
    required WidgetSettings settings,

    /// Owner's user ID (extracted for convenience)
    required String ownerId,
  }) = _WidgetContext;

  const WidgetContext._();

  /// Quick access to property subdomain for URL generation
  String? get subdomain => property.subdomain;

  /// Quick access to unit slug for clean URLs
  String? get unitSlug => unit.slug;

  /// Check if the widget can accept bookings (has at least one payment method)
  bool get canAcceptBookings => settings.hasPaymentMethods;

  /// Check if owner approval is required for bookings
  bool get requiresApproval => settings.requireOwnerApproval;

  /// Get the effective minimum nights (from settings, fallback to unit)
  int get effectiveMinNights =>
      settings.minNights > 1 ? settings.minNights : unit.minStayNights;
}
