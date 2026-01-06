import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/guest_pii_model.dart';
import '../../../../../core/services/logging_service.dart';

/// Provider to fetch guest PII data for a specific booking
final piiProvider = FutureProvider.family<GuestPiiModel?, String>((ref, bookingId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .collection('pii_data')
        .doc('guest')
        .get();
    if (doc.exists) {
      return GuestPiiModel.fromJson(doc.data()!);
    }
    return null;
  } catch (e, s) {
    LoggingService.logError('Failed to fetch PII for booking $bookingId', e, s);
    return null;
  }
});

/// Guest information section for booking card
///
/// Displays guest name, email, and phone (if provided)
/// with avatar circle and contact icons. Fetches PII data on demand.
class BookingCardGuestInfo extends ConsumerWidget {
  final BookingModel booking;
  final bool isMobile;

  const BookingCardGuestInfo({
    super.key,
    required this.booking,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final piiAsync = ref.watch(piiProvider(booking.id));

    return Row(
      children: [
        // Avatar circle
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha((0.08 * 255).toInt()),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: piiAsync.when(
            data: (pii) {
              if (pii == null) {
                return Text('Guest info not available.', style: theme.textTheme.bodySmall);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guest name
                  Text(
                    pii.guestName ?? 'Guest',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Email - selectable for easy copying
                  if (pii.guestEmail != null)
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.5 * 255).toInt(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SelectableText(
                            pii.guestEmail!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(
                                (0.6 * 255).toInt(),
                              ),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  // Phone (conditional) - selectable for easy copying
                  if (pii.guestPhone != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.5 * 255).toInt(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SelectableText(
                            pii.guestPhone!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(
                                (0.6 * 255).toInt(),
                              ),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error loading guest info.', style: theme.textTheme.bodySmall),
          ),
        ),
      ],
    );
  }
}
