import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/models/booking_model.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../providers/owner_bookings_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import 'booking_details_dialog.dart';
import 'edit_booking_dialog.dart';
import 'send_email_dialog.dart';

/// BedBooking-style Table View for bookings
/// Desktop: Full data table with all columns
/// Displays: Guest | Property/Unit | Check-in/Check-out | Nights | Guests | Status | Price | Source | Actions
class BookingsTableView extends ConsumerStatefulWidget {
  const BookingsTableView({super.key, required this.bookings});

  final List<OwnerBooking> bookings;

  @override
  ConsumerState<BookingsTableView> createState() => _BookingsTableViewState();
}

class _BookingsTableViewState extends ConsumerState<BookingsTableView> {
  // Selection state
  final Set<String> _selectedBookingIds = {};

  @override
  Widget build(BuildContext context) {
    // Check if all selected bookings are pending
    final selectedBookings = widget.bookings
        .where((b) => _selectedBookingIds.contains(b.booking.id))
        .toList();
    final allSelectedArePending = selectedBookings.isNotEmpty &&
        selectedBookings.every((b) => b.booking.status == BookingStatus.pending);

    return Card(
      elevation: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium selection action bar with MenuAnchor
          if (_selectedBookingIds.isNotEmpty)
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                boxShadow: AppShadows.getElevation(
                  2,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Selection count badge with gradient
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_selectedBookingIds.length} odabrano',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Clear selection button
                  TextButton.icon(
                    onPressed: () {
                      setState(_selectedBookingIds.clear);
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Poništi odabir'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Bulk actions MenuAnchor
                  MenuAnchor(
                    builder: (context, controller, child) {
                      return IconButton(
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        icon: const Icon(Icons.edit_note),
                        tooltip: 'Grupne akcije',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                    menuChildren: [
                      // Confirm action (only if all pending)
                      if (allSelectedArePending)
                        MenuItemButton(
                          leadingIcon: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                          ),
                          onPressed: _confirmSelectedBookings,
                          child: const Text('Potvrdi odabrane'),
                        ),

                      // Reject action (only if all pending)
                      if (allSelectedArePending)
                        MenuItemButton(
                          leadingIcon: const Icon(
                            Icons.cancel_outlined,
                            color: AppColors.error,
                          ),
                          onPressed: _rejectSelectedBookings,
                          child: const Text('Odbij odabrane'),
                        ),

                      // Delete action (always available)
                      MenuItemButton(
                        leadingIcon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: _deleteSelectedBookings,
                        child: const Text('Obriši odabrane'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Table - no fixed height, parent CustomScrollView controls vertical scrolling
          // Only horizontal scroll for wide table, vertical scroll removed to work with parent
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 48,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith((states) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return isDark
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.surfaceContainerHigh;
                }),
                columns: const [
                  DataColumn(label: Text('Gost')),
                  DataColumn(label: Text('Objekt / Jedinica')),
                  DataColumn(label: Text('Check-in')),
                  DataColumn(label: Text('Check-out')),
                  DataColumn(label: Text('Noći')),
                  DataColumn(label: Text('Gostiju')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Cijena')),
                  DataColumn(label: Text('Izvor')),
                  DataColumn(label: Text('Akcije')),
                ],
                rows: widget.bookings.map(_buildTableRow).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildTableRow(OwnerBooking ownerBooking) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;
    final isSelected = _selectedBookingIds.contains(booking.id);

    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        setState(() {
          if (selected == true) {
            _selectedBookingIds.add(booking.id);
          } else {
            _selectedBookingIds.remove(booking.id);
          }
        });
      },
      cells: [
        // Guest name - clickable to open details
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ownerBooking.guestName,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                ownerBooking.guestEmail,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textColorSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          onTap: () => _showBookingDetails(ownerBooking),
        ),

        // Property / Unit
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                property.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                unit.name,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textColorSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Check-in
        DataCell(Text(DateFormat('dd.MM.yyyy').format(booking.checkIn))),

        // Check-out
        DataCell(Text(DateFormat('dd.MM.yyyy').format(booking.checkOut))),

        // Number of nights
        DataCell(Text('${booking.numberOfNights}')),

        // Guest count
        DataCell(Text('${booking.guestCount}')),

        // Status badge
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: booking.status.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
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
        ),

        // Price
        DataCell(
          Text(
            booking.formattedTotalPrice,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).primaryColor,
            ),
          ),
        ),

        // Source
        DataCell(_buildSourceBadge(booking.source)),

        // Actions menu
        DataCell(_buildActionsMenu(booking)),
      ],
    );
  }

  Widget _buildSourceBadge(String? source) {
    if (source == null) {
      return const Text('Direktno');
    }

    // Map source to display name and icon
    String displayName;
    IconData icon;
    Color color;

    switch (source.toLowerCase()) {
      case 'ical':
        displayName = 'iCal';
        icon = Icons.sync;
        color = AppColors.authSecondary;
        break;
      case 'booking_com':
      case 'booking.com':
        displayName = 'Booking.com';
        icon = Icons.public;
        color = Colors.orange;
        break;
      case 'airbnb':
        displayName = 'Airbnb';
        icon = Icons.home;
        color = Colors.red;
        break;
      case 'widget':
        displayName = 'Widget';
        icon = Icons.web;
        color = Colors.green;
        break;
      case 'admin':
      case 'manual':
        displayName = 'Manualno';
        icon = Icons.person;
        color = Colors.grey;
        break;
      default:
        displayName = source;
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Tooltip(
      message: displayName,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(BookingModel booking) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Akcije',
      onSelected: (value) => _handleAction(value, booking),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined),
              SizedBox(width: 8),
              Text('Detalji'),
            ],
          ),
        ),
        if (booking.status == BookingStatus.pending)
          const PopupMenuItem(
            value: 'confirm',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success),
                SizedBox(width: 8),
                Text('Potvrdi'),
              ],
            ),
          ),
        if (booking.status == BookingStatus.confirmed && booking.isPast)
          const PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Icon(Icons.done_all),
                SizedBox(width: 8),
                Text('Završi'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 8),
              Text('Uredi'),
            ],
          ),
        ),
        if (booking.canBeCancelled)
          const PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, color: AppColors.error),
                SizedBox(width: 8),
                Text('Otkaži'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'email',
          child: Row(
            children: [
              Icon(Icons.email_outlined),
              SizedBox(width: 8),
              Text('Pošalji email'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.error),
              SizedBox(width: 8),
              Text('Obriši', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleAction(String action, BookingModel booking) {
    switch (action) {
      case 'details':
        _showBookingDetailsById(booking.id);
        break;
      case 'confirm':
        _confirmBooking(booking.id);
        break;
      case 'complete':
        _completeBooking(booking.id);
        break;
      case 'edit':
        _editBooking(booking.id);
        break;
      case 'cancel':
        _cancelBooking(booking.id);
        break;
      case 'email':
        _sendEmail(booking);
        break;
      case 'delete':
        _deleteBooking(booking.id);
        break;
    }
  }

  void _showBookingDetails(OwnerBooking ownerBooking) {
    showDialog(
      context: context,
      builder: (context) => BookingDetailsDialog(ownerBooking: ownerBooking),
    );
  }

  void _showBookingDetailsById(String bookingId) {
    // Find booking in the list
    final ownerBooking = widget.bookings.firstWhere(
      (b) => b.booking.id == bookingId,
    );
    _showBookingDetails(ownerBooking);
  }

  Future<void> _confirmBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdi rezervaciju'),
        content: const Text(
          'Jeste li sigurni da želite potvrditi ovu rezervaciju?',
        ),
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

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.confirmBooking(bookingId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija je uspješno potvrđena'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.invalidate(allOwnerBookingsProvider);
          ref.invalidate(ownerBookingsProvider);

          // Auto-regenerate iCal if enabled
          _triggerIcalRegeneration(bookingId);
        }
      } catch (e) {
        if (mounted) {
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

  Future<void> _completeBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Označi kao završeno'),
        content: const Text(
          'Jeste li sigurni da želite označiti ovu rezervaciju kao završenu?',
        ),
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

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.completeBooking(bookingId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija je označena kao završena'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.invalidate(allOwnerBookingsProvider);
          ref.invalidate(ownerBookingsProvider);

          // Auto-regenerate iCal if enabled
          _triggerIcalRegeneration(bookingId);
        }
      } catch (e) {
        if (mounted) {
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

  Future<void> _cancelBooking(String bookingId) async {
    final reasonController = TextEditingController();
    final sendEmailNotifier = ValueNotifier<bool>(true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkaži rezervaciju'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: sendEmailNotifier,
              builder: (context, sendEmail, _) {
                return CheckboxListTile(
                  title: const Text('Pošalji email gostu'),
                  value: sendEmail,
                  onChanged: (value) {
                    sendEmailNotifier.value = value ?? true;
                  },
                  contentPadding: EdgeInsets.zero,
                );
              },
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Otkaži rezervaciju'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.cancelBooking(
          bookingId,
          reasonController.text.isEmpty
              ? 'Otkazano od strane vlasnika'
              : reasonController.text,
          sendEmail: sendEmailNotifier.value,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija je otkazana'),
              backgroundColor: AppColors.warning,
            ),
          );
          ref.invalidate(allOwnerBookingsProvider);
          ref.invalidate(ownerBookingsProvider);

          // Auto-regenerate iCal if enabled
          _triggerIcalRegeneration(bookingId);
        }
      } catch (e) {
        if (mounted) {
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

  void _editBooking(String bookingId) async {
    final ownerBooking = widget.bookings.firstWhere(
      (b) => b.booking.id == bookingId,
    );
    await showEditBookingDialog(context, ref, ownerBooking.booking);
  }

  void _sendEmail(BookingModel booking) async {
    await showSendEmailDialog(context, ref, booking);
  }

  Future<void> _deleteBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši rezervaciju'),
        content: const Text(
          'Jeste li sigurni da želite TRAJNO obrisati ovu rezervaciju? Ova akcija se ne može poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.deleteBooking(bookingId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervacija je obrisana'),
              backgroundColor: AppColors.error,
            ),
          );
          ref.invalidate(allOwnerBookingsProvider);
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (mounted) {
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

  Future<void> _confirmSelectedBookings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdi odabrane rezervacije'),
        content: Text(
          'Jeste li sigurni da želite potvrditi ${_selectedBookingIds.length} ${_selectedBookingIds.length == 1 ? 'rezervaciju' : 'rezervacija'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Potvrdi sve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);

        // Confirm all selected bookings
        for (final bookingId in _selectedBookingIds) {
          await repository.confirmBooking(bookingId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_selectedBookingIds.length} ${_selectedBookingIds.length == 1 ? 'rezervacija je potvrđena' : 'rezervacija su potvrđene'}',
              ),
              backgroundColor: AppColors.success,
            ),
          );

          setState(_selectedBookingIds.clear);

          ref.invalidate(allOwnerBookingsProvider);
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (mounted) {
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

  Future<void> _rejectSelectedBookings() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odbij odabrane rezervacije'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jeste li sigurni da želite odbiti ${_selectedBookingIds.length} ${_selectedBookingIds.length == 1 ? 'rezervaciju' : 'rezervacija'}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Razlog odbijanja (opcionalno)',
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Odbij sve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        final reason = reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim();

        // Reject all selected bookings
        for (final bookingId in _selectedBookingIds) {
          await repository.rejectBooking(bookingId, reason: reason);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_selectedBookingIds.length} ${_selectedBookingIds.length == 1 ? 'rezervacija je odbijena' : 'rezervacija su odbijene'}',
              ),
              backgroundColor: AppColors.warning,
            ),
          );

          setState(_selectedBookingIds.clear);

          ref.invalidate(allOwnerBookingsProvider);
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        reasonController.dispose();
      }
    } else {
      reasonController.dispose();
    }
  }

  Future<void> _deleteSelectedBookings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši odabrane rezervacije'),
        content: Text(
          'Jeste li sigurni da želite TRAJNO obrisati ${_selectedBookingIds.length} ${_selectedBookingIds.length == 1 ? 'rezervaciju' : 'rezervacija'}? Ova akcija se ne može poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Obriši sve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);

        // Delete all selected bookings
        for (final bookingId in _selectedBookingIds) {
          await repository.deleteBooking(bookingId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_selectedBookingIds.length} ${_selectedBookingIds.length == 1 ? 'rezervacija je obrisana' : 'rezervacija su obrisane'}',
              ),
              backgroundColor: AppColors.error,
            ),
          );

          setState(_selectedBookingIds.clear);

          ref.invalidate(allOwnerBookingsProvider);
          ref.invalidate(ownerBookingsProvider);
        }
      } catch (e) {
        if (mounted) {
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

  /// Trigger iCal regeneration for the unit after booking status changes
  void _triggerIcalRegeneration(String bookingId) async {
    try {
      // Find booking in the list
      final ownerBooking = widget.bookings.firstWhere(
        (b) => b.booking.id == bookingId,
      );

      // Get iCal export service
      final icalService = ref.read(icalExportServiceProvider);

      // Auto-regenerate if enabled (service will check if enabled)
      await icalService.autoRegenerateIfEnabled(
        propertyId: ownerBooking.property.id,
        unitId: ownerBooking.unit.id,
        unit: ownerBooking.unit,
      );
    } catch (e) {
      // Silently fail - iCal regeneration is non-critical
      debugPrint('iCal regeneration failed: $e');
    }
  }
}
