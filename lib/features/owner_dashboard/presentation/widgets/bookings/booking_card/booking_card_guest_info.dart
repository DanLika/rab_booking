import 'package:flutter/material.dart';
import '../../../../../../shared/widgets/redesign.dart';
import '../../../../data/firebase/firebase_owner_bookings_repository.dart';

/// Guest information section for booking card
///
/// Displays guest name, email, and phone (if provided)
/// with avatar circle and contact icons
class BookingCardGuestInfo extends StatelessWidget {
  final OwnerBooking ownerBooking;
  final bool isMobile;

  const BookingCardGuestInfo({
    super.key,
    required this.ownerBooking,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        BbAvatar(name: ownerBooking.guestName),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guest name
              Text(
                ownerBooking.guestName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Email - selectable for easy copying
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
                      ownerBooking.guestEmail,
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
              if (ownerBooking.guestPhone != null) ...[
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
                        ownerBooking.guestPhone!,
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
          ),
        ),
      ],
    );
  }
}
