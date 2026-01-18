import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/models/ical_feed.dart';
import '../../providers/ical_feeds_provider.dart';
import '../../providers/overbooking_detection_provider.dart';
import '../../../../../shared/widgets/animations/skeleton_loader.dart';
import 'booking_card/booking_card_header.dart';
import 'booking_card/booking_card_actions.dart';

/// Widget that displays imported reservations (iCal events)
/// Uses the same visual design as regular booking cards for consistency
class ImportedReservationsList extends ConsumerWidget {
  const ImportedReservationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(allOwnerIcalEventsProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return eventsAsync.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              0,
              context.horizontalPadding,
              16,
            ),
            child: const _ImportedCardSkeleton(),
          ),
          childCount: 5,
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.calendarErrorDefault,
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
      data: (events) {
        if (events.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: _buildEmptyState(context, theme, l10n)),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final event = events[index];
            return Padding(
              padding: EdgeInsets.fromLTRB(
                context.horizontalPadding,
                0,
                context.horizontalPadding,
                16,
              ),
              child: _ImportedReservationCard(event: event),
            );
          }, childCount: events.length),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_download_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.icalNoEventsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.icalNoEventsSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Skeleton loader for imported card
class _ImportedCardSkeleton extends StatelessWidget {
  const _ImportedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.elevation2,
      ),
      child: const SkeletonLoader(
        width: double.infinity,
        height: 200,
        borderRadius: 16,
      ),
    );
  }
}

/// Card widget for a single imported reservation
/// Uses same visual design as regular booking cards
class _ImportedReservationCard extends ConsumerWidget {
  final IcalEvent event;

  const _ImportedReservationCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Check if imported reservation is in conflict
    // iCal events in calendar are prefixed with 'ical_'
    final hasConflict = ref.watch(
      isBookingInConflictProvider('ical_${event.id}'),
    );

    // Calculate nights
    final nights = event.endDate.difference(event.startDate).inDays;

    return Opacity(
      opacity: 0.9, // Slightly dimmed for read-only indication
      child: Container(
        decoration: BoxDecoration(
          color: context.gradients.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasConflict
                ? Colors.red
                : isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: hasConflict ? 2 : 1,
          ),
          boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header - uses shared component with imported mode
                  BookingCardHeader(
                    isMobile: isMobile,
                    importedSource: event.source,
                    importedGuestName: event.guestName,
                    hasConflict: hasConflict,
                  ),

                  // Content body
                  Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Guest name row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.08,
                                ),
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
                              child: Text(
                                event.guestName.isNotEmpty
                                    ? event.guestName
                                    : l10n.futureBookingsUnknownGuest,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: isMobile ? 12 : 16),

                        // Date range row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  Text(
                                    '${dateFormat.format(event.startDate)} - ${dateFormat.format(event.endDate)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '($nights ${nights == 1 ? l10n.ownerBookingCardNight : l10n.ownerBookingCardNights})',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Description if available
                        if (event.description?.isNotEmpty ?? false) ...[
                          SizedBox(height: isMobile ? 12 : 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.notes_outlined,
                                  size: 20,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  event.description!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Footer - uses shared component with imported mode
                  BookingCardActions(
                    isMobile: isMobile,
                    isImported: true,
                    importedSource: event.source,
                  ),
                ],
              ),
            ),
            // Warning icon overlay for conflicts
            if (hasConflict)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade300, width: 2),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
