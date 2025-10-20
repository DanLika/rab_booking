import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../booking/domain/models/booking_status.dart';
import '../providers/owner_bookings_provider.dart';
import '../providers/owner_calendar_provider.dart';
import '../../data/owner_bookings_repository.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Owner bookings screen with filters and booking management
class OwnerBookingsScreen extends ConsumerStatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  ConsumerState<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends ConsumerState<OwnerBookingsScreen> {
  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(ownerBookingsProvider);
    final filters = ref.watch(bookingsFiltersNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filters section
          _buildFiltersSection(filters),

          const SizedBox(height: 24),

          // Bookings list
          Expanded(
            child: bookingsAsync.when(
              data: (bookings) => bookings.isEmpty
                  ? _buildEmptyState()
                  : _buildBookingsList(bookings),
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: BookingCardSkeleton(),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Greška pri učitavanju rezervacija',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(BookingsFilters filters) {
    final propertiesAsync = ref.watch(ownerPropertiesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filteri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (filters.hasActiveFilters)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(bookingsFiltersNotifierProvider.notifier).clearFilters();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Očisti filtere'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Responsive filter layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;

                if (isMobile) {
                  // Column layout for mobile - full width filters
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusFilter(filters),
                      const SizedBox(height: 12),
                      _buildPropertyFilter(filters, propertiesAsync),
                      const SizedBox(height: 12),
                      _buildDateRangeFilter(filters),
                    ],
                  );
                } else if (isTablet) {
                  // 2-column layout for tablets
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildStatusFilter(filters)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildPropertyFilter(filters, propertiesAsync)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDateRangeFilter(filters),
                    ],
                  );
                } else {
                  // 3-column Row layout for desktop
                  return Row(
                    children: [
                      Expanded(child: _buildStatusFilter(filters)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPropertyFilter(filters, propertiesAsync)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDateRangeFilter(filters)),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BookingsFilters filters) {
    return DropdownButtonFormField<BookingStatus?>(
      key: ValueKey(filters.status),
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.filter_list),
      ),
      initialValue: filters.status,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Svi statusi'),
        ),
        ...BookingStatus.values
            .where((s) => s != BookingStatus.blocked)
            .map((status) {
          return DropdownMenuItem(
            value: status,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    status.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onChanged: (value) {
        ref.read(bookingsFiltersNotifierProvider.notifier).setStatus(value);
      },
    );
  }

  Widget _buildPropertyFilter(BookingsFilters filters, AsyncValue propertiesAsync) {
    return propertiesAsync.when(
      data: (properties) {
        return DropdownButtonFormField<String?>(
          key: ValueKey(filters.propertyId),
          decoration: const InputDecoration(
            labelText: 'Objekt',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home_outlined),
          ),
          initialValue: filters.propertyId,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Svi objekti'),
            ),
            ...properties.map((property) {
              return DropdownMenuItem(
                value: property.id,
                child: Text(
                  property.name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (value) {
            ref.read(bookingsFiltersNotifierProvider.notifier).setProperty(value);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const Text('Error'),
    );
  }

  Widget _buildDateRangeFilter(BookingsFilters filters) {
    return OutlinedButton.icon(
      onPressed: () => _showDateRangePicker(),
      icon: const Icon(Icons.date_range),
      label: Text(
        filters.startDate != null && filters.endDate != null
            ? '${filters.startDate!.day}.${filters.startDate!.month}. - ${filters.endDate!.day}.${filters.endDate!.month}.'
            : 'Odaberi raspon',
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    );
  }

  Widget _buildBookingsList(List<OwnerBooking> bookings) {
    return ListView.separated(
      itemCount: bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final ownerBooking = bookings[index];
        return _BookingCard(ownerBooking: ownerBooking);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_online_outlined,
            size: 80,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 24),
          Text(
            'Nemate rezervacija',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ovdje će se prikazati sve rezervacije za vaše objekte.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final filters = ref.read(bookingsFiltersNotifierProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: filters.startDate != null && filters.endDate != null
          ? DateTimeRange(start: filters.startDate!, end: filters.endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref
          .read(bookingsFiltersNotifierProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }
}

/// Booking card widget
class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.ownerBooking});

  final OwnerBooking ownerBooking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status badge
            Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: booking.status.color.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: booking.status.color),
                  ),
                  child: Text(
                    booking.status.displayName,
                    style: TextStyle(
                      color: booking.status.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                // Booking ID
                Text(
                  '#${booking.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Guest info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha:0.2),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerBooking.guestName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        ownerBooking.guestEmail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                      ),
                      if (ownerBooking.guestPhone != null)
                        Text(
                          ownerBooking.guestPhone!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Property and unit info
            Row(
              children: [
                Icon(Icons.home_outlined, size: 20, color: AppColors.textSecondaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        unit.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Dates
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: AppColors.textSecondaryLight),
                const SizedBox(width: 8),
                Text(
                  '${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}. - '
                  '${booking.checkOut.day}.${booking.checkOut.month}.${booking.checkOut.year}.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Text(
                  '(${booking.numberOfNights} ${booking.numberOfNights == 1 ? 'noć' : 'noći'})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Guests
            Row(
              children: [
                Icon(Icons.people_outline, size: 20, color: AppColors.textSecondaryLight),
                const SizedBox(width: 8),
                Text(
                  '${booking.guestCount} ${booking.guestCount == 1 ? 'gost' : 'gostiju'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            const Divider(height: 24),

            // Payment info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ukupno',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                      ),
                      Text(
                        booking.formattedTotalPrice,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plaćeno',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                      ),
                      Text(
                        booking.formattedPaidAmount,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preostalo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                      ),
                      Text(
                        booking.formattedRemainingBalance,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: booking.isFullyPaid ? AppColors.success : AppColors.warning,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Payment status indicator
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: booking.paymentPercentage / 100,
              backgroundColor: AppColors.surfaceVariantLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                booking.isFullyPaid ? AppColors.success : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.isFullyPaid
                  ? 'Plaćeno u potpunosti'
                  : '${booking.paymentPercentage.toStringAsFixed(0)}% plaćeno',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),

            // Special requests
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_outlined, size: 20, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Napomene',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          booking.notes!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // View Details button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showBookingDetails(context, ref, ownerBooking);
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Detalji'),
                  ),
                ),

                const SizedBox(width: 8),

                // Confirm button (only for pending)
                if (booking.status == BookingStatus.pending)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        _confirmBooking(context, ref, booking.id);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Potvrdi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),

                // Mark as Completed button (only for confirmed and past check-out)
                if (booking.status == BookingStatus.confirmed && booking.isPast)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        _completeBooking(context, ref, booking.id);
                      },
                      icon: const Icon(Icons.done_all),
                      label: const Text('Završi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.textPrimaryDark,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Cancel button (only for pending/confirmed)
                if (booking.canBeCancelled)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _cancelBooking(context, ref, booking.id);
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Otkaži'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, WidgetRef ref, OwnerBooking ownerBooking) {
    showDialog(
      context: context,
      builder: (context) => _BookingDetailsDialog(ownerBooking: ownerBooking),
    );
  }

  void _confirmBooking(BuildContext context, WidgetRef ref, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdi rezervaciju'),
        content: const Text('Jeste li sigurni da želite potvrditi ovu rezervaciju?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Potvrdi'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.confirmBooking(bookingId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija je uspješno potvrđena'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _completeBooking(BuildContext context, WidgetRef ref, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Označi kao završeno'),
        content: const Text('Jeste li sigurni da želite označiti ovu rezervaciju kao završenu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Završi'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.completeBooking(bookingId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija je označena kao završena'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _cancelBooking(BuildContext context, WidgetRef ref, String bookingId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkaži rezervaciju'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Jeste li sigurni da želite otkazati ovu rezervaciju?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Razlog otkazivanja',
                border: OutlineInputBorder(),
                hintText: 'Unesite razlog...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Otkaži rezervaciju'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.cancelBooking(
          bookingId,
          reasonController.text.isEmpty ? 'Otkazano od strane vlasnika' : reasonController.text,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija je otkazana'),
              backgroundColor: AppColors.warning,
            ),
          );
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

/// Booking details dialog
class _BookingDetailsDialog extends StatelessWidget {
  const _BookingDetailsDialog({required this.ownerBooking});

  final OwnerBooking ownerBooking;

  @override
  Widget build(BuildContext context) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;

    return AlertDialog(
      title: const Text('Detalji rezervacije'),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Booking ID and Status
              _DetailRow(
                label: 'ID rezervacije',
                value: booking.id,
              ),
              _DetailRow(
                label: 'Status',
                value: booking.status.displayName,
                valueColor: booking.status.color,
              ),

              const Divider(height: 24),

              // Guest Information
              Text(
                'Informacije o gostu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Ime', value: ownerBooking.guestName),
              _DetailRow(label: 'Email', value: ownerBooking.guestEmail),
              if (ownerBooking.guestPhone != null)
                _DetailRow(label: 'Telefon', value: ownerBooking.guestPhone!),

              const Divider(height: 24),

              // Property Information
              Text(
                'Informacije o objektu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Objekt', value: property.name),
              _DetailRow(label: 'Jedinica', value: unit.name),
              _DetailRow(label: 'Lokacija', value: property.location),

              const Divider(height: 24),

              // Booking Details
              Text(
                'Detalji boravka',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Prijava',
                value: '${booking.checkIn.day}.${booking.checkIn.month}.${booking.checkIn.year}.',
              ),
              _DetailRow(
                label: 'Odjava',
                value: '${booking.checkOut.day}.${booking.checkOut.month}.${booking.checkOut.year}.',
              ),
              _DetailRow(
                label: 'Broj noći',
                value: '${booking.numberOfNights}',
              ),
              _DetailRow(
                label: 'Broj gostiju',
                value: '${booking.guestCount}',
              ),

              const Divider(height: 24),

              // Payment Information
              Text(
                'Informacije o plaćanju',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Ukupna cijena',
                value: booking.formattedTotalPrice,
                valueColor: Theme.of(context).primaryColor,
              ),
              _DetailRow(
                label: 'Plaćeno',
                value: booking.formattedPaidAmount,
              ),
              _DetailRow(
                label: 'Preostalo',
                value: booking.formattedRemainingBalance,
                valueColor: booking.isFullyPaid ? AppColors.success : AppColors.warning,
              ),
              if (booking.paymentIntentId != null)
                _DetailRow(
                  label: 'Payment Intent ID',
                  value: booking.paymentIntentId!,
                ),

              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  'Napomene',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(booking.notes!),
              ],

              if (booking.status == BookingStatus.cancelled) ...[
                const Divider(height: 24),
                Text(
                  'Informacije o otkazivanju',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (booking.cancelledAt != null)
                  _DetailRow(
                    label: 'Otkazano',
                    value:
                        '${booking.cancelledAt!.day}.${booking.cancelledAt!.month}.${booking.cancelledAt!.year}.',
                  ),
                if (booking.cancellationReason != null)
                  _DetailRow(
                    label: 'Razlog',
                    value: booking.cancellationReason!,
                  ),
              ],

              const Divider(height: 24),

              // Timestamps
              _DetailRow(
                label: 'Kreirano',
                value:
                    '${booking.createdAt.day}.${booking.createdAt.month}.${booking.createdAt.year}. ${booking.createdAt.hour}:${booking.createdAt.minute.toString().padLeft(2, '0')}',
              ),
              if (booking.updatedAt != null)
                _DetailRow(
                  label: 'Ažurirano',
                  value:
                      '${booking.updatedAt!.day}.${booking.updatedAt!.month}.${booking.updatedAt!.year}. ${booking.updatedAt!.hour}:${booking.updatedAt!.minute.toString().padLeft(2, '0')}',
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zatvori'),
        ),
      ],
    );
  }
}

/// Detail row widget
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
