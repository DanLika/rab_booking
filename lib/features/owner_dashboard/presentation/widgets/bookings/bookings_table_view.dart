import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/constants/booking_status_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../providers/owner_bookings_provider.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../booking_details_dialog.dart';
import '../edit_booking_dialog.dart';
import '../send_email_dialog.dart';

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
    final l10n = AppLocalizations.of(context);
    // Check if all selected bookings are pending
    final selectedBookings = widget.bookings
        .where((b) => _selectedBookingIds.contains(b.booking.id))
        .toList();
    final allSelectedArePending =
        selectedBookings.isNotEmpty &&
        selectedBookings.every(
          (b) => b.booking.status == BookingStatus.pending,
        );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use design system colors for consistency
    final cardBackground = context.gradients.cardBackground;
    final borderColor = isDark
        ? AppColors.sectionDividerDark
        : AppColors.sectionDividerLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium selection action bar with MenuAnchor
            if (_selectedBookingIds.isNotEmpty)
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  boxShadow: AppShadows.getElevation(2, isDark: isDark),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // Selection count badge with gradient
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
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
                            Flexible(
                              child: Text(
                                l10n.ownerTableSelected(
                                  _selectedBookingIds.length,
                                ),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Clear selection button
                    TextButton.icon(
                      onPressed: () {
                        setState(_selectedBookingIds.clear);
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(
                        l10n.ownerTableClearSelection,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),

                    const SizedBox(width: 4),

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
                          tooltip: l10n.ownerTableBulkActions,
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.15),
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
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
                            child: Text(l10n.ownerTableConfirmSelected),
                          ),

                        // Reject action (only if all pending)
                        if (allSelectedArePending)
                          MenuItemButton(
                            leadingIcon: const Icon(
                              Icons.cancel_outlined,
                              color: AppColors.error,
                            ),
                            onPressed: _rejectSelectedBookings,
                            child: Text(l10n.ownerTableRejectSelected),
                          ),

                        // Delete action (always available)
                        MenuItemButton(
                          leadingIcon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          onPressed: _deleteSelectedBookings,
                          child: Text(l10n.ownerTableDeleteSelected),
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
                    return theme.colorScheme.primary.withAlpha(
                      (0.12 * 255).toInt(),
                    );
                  }),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.87),
                  ),
                  columns: [
                    DataColumn(label: Text(l10n.ownerTableColumnGuest)),
                    DataColumn(label: Text(l10n.ownerTableColumnPropertyUnit)),
                    DataColumn(label: Text(l10n.ownerTableColumnCheckIn)),
                    DataColumn(label: Text(l10n.ownerTableColumnCheckOut)),
                    DataColumn(label: Text(l10n.ownerTableColumnNights)),
                    DataColumn(label: Text(l10n.ownerTableColumnGuests)),
                    DataColumn(label: Text(l10n.ownerTableColumnStatus)),
                    DataColumn(label: Text(l10n.ownerTableColumnPrice)),
                    DataColumn(label: Text(l10n.ownerTableColumnSource)),
                    DataColumn(label: Text(l10n.ownerTableColumnActions)),
                  ],
                  rows: widget.bookings
                      .map((b) => _buildTableRow(b, l10n))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildTableRow(OwnerBooking ownerBooking, AppLocalizations l10n) {
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
              booking.status.displayNameLocalized(context),
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
        DataCell(_buildSourceBadge(booking.source, l10n)),

        // Actions menu
        DataCell(_buildActionsMenu(booking, l10n)),
      ],
    );
  }

  Widget _buildSourceBadge(String? source, AppLocalizations l10n) {
    if (source == null) {
      return Text(l10n.ownerTableSourceDirect);
    }

    // Map source to display name and icon
    String displayName;
    IconData icon;
    Color color;

    switch (source.toLowerCase()) {
      case 'ical':
        displayName = l10n.ownerTableSourceIcal;
        icon = Icons.sync;
        color = AppColors.authSecondary;
        break;
      case 'booking_com':
      case 'booking.com':
        displayName = l10n.ownerTableSourceBookingCom;
        icon = Icons.public;
        color = Colors.orange;
        break;
      case 'airbnb':
        displayName = l10n.ownerTableSourceAirbnb;
        icon = Icons.home;
        color = Colors.red;
        break;
      case 'widget':
        displayName = l10n.ownerTableSourceWidget;
        icon = Icons.web;
        color = Colors.green;
        break;
      case 'admin':
      case 'manual':
        displayName = l10n.ownerTableSourceManual;
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

  Widget _buildActionsMenu(BookingModel booking, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: l10n.ownerTableColumnActions,
      onSelected: (value) => _handleAction(value, booking),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined),
              const SizedBox(width: 8),
              Text(l10n.ownerTableActionDetails),
            ],
          ),
        ),
        if (booking.status == BookingStatus.pending)
          PopupMenuItem(
            value: 'confirm',
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(l10n.ownerTableActionConfirm),
              ],
            ),
          ),
        if (booking.status == BookingStatus.pending)
          PopupMenuItem(
            value: 'reject',
            child: Row(
              children: [
                const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(l10n.ownerBookingCardReject),
              ],
            ),
          ),
        if (booking.status == BookingStatus.confirmed && booking.isPast)
          PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                const Icon(Icons.done_all),
                const SizedBox(width: 8),
                Text(l10n.ownerTableActionComplete),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined),
              const SizedBox(width: 8),
              Text(l10n.ownerTableActionEdit),
            ],
          ),
        ),
        if (booking.canBeCancelled)
          PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: AppColors.error),
                const SizedBox(width: 8),
                Text(l10n.ownerTableActionCancel),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'email',
          child: Row(
            children: [
              const Icon(Icons.email_outlined),
              const SizedBox(width: 8),
              Text(l10n.ownerTableActionSendEmail),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                l10n.ownerTableActionDelete,
                style: const TextStyle(color: AppColors.error),
              ),
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
      case 'reject':
        _rejectBooking(booking.id);
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
      orElse: () => widget.bookings.first, // Fallback if booking not found (rare race condition)
    );
    _showBookingDetails(ownerBooking);
  }

  Future<void> _confirmBooking(String bookingId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.ownerTableConfirmBooking),
          content: Text(dialogL10n.ownerTableConfirmBookingMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dialogL10n.confirm),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.confirmBooking(bookingId);

        if (mounted) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.ownerTableBookingConfirmed,
          );
          ref
              .read(windowedBookingsNotifierProvider.notifier)
              .updateBookingStatus(bookingId, BookingStatus.confirmed);

          // Auto-regenerate iCal if enabled
          _triggerIcalRegeneration(bookingId);
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.error,
          );
        }
      }
    }
  }

  Future<void> _rejectBooking(String bookingId) async {
    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.bookingRejectTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dialogL10n.bookingRejectMessage),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecorationHelper.buildDecoration(
                  labelText: dialogL10n.ownerTableRejectionReasonOptional,
                  hintText: dialogL10n.ownerTableCancellationReasonHint,
                  context: dialogContext,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(dialogL10n.bookingRejectConfirm),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        final reason = reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim();
        await repository.rejectBooking(bookingId, reason: reason);

        if (mounted) {
          ErrorDisplayUtils.showWarningSnackBar(
            context,
            l10n.ownerBookingsRejected,
          );
          ref
              .read(windowedBookingsNotifierProvider.notifier)
              .updateBookingStatus(bookingId, BookingStatus.cancelled);
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.ownerBookingsRejectError,
          );
        }
      }
    }

    reasonController.dispose();
  }

  Future<void> _completeBooking(String bookingId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.ownerTableCompleteBooking),
          content: Text(dialogL10n.ownerTableCompleteBookingMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dialogL10n.ownerTableActionComplete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.completeBooking(bookingId);

        if (mounted) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.ownerTableBookingCompleted,
          );
          ref
              .read(windowedBookingsNotifierProvider.notifier)
              .updateBookingStatus(bookingId, BookingStatus.completed);

          // Auto-regenerate iCal if enabled
          _triggerIcalRegeneration(bookingId);
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.error,
          );
        }
      }
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();
    final sendEmailNotifier = ValueNotifier<bool>(true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.ownerTableCancelBooking),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dialogL10n.ownerTableCancelBookingMessage),
                const SizedBox(height: 16),
                Builder(
                  builder: (ctx) => TextField(
                    controller: reasonController,
                    decoration: InputDecorationHelper.buildDecoration(
                      labelText: dialogL10n.ownerTableCancellationReason,
                      hintText: dialogL10n.ownerTableCancellationReasonHint,
                      context: ctx,
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: sendEmailNotifier,
                  builder: (context, sendEmail, _) {
                    return CheckboxListTile(
                      title: Text(dialogL10n.ownerTableSendEmailToGuest),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(dialogL10n.ownerTableCancelBookingButton),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.cancelBooking(
          bookingId,
          reasonController.text.isEmpty
              ? l10n.ownerTableCancelledByOwner
              : reasonController.text,
          sendEmail: sendEmailNotifier.value,
        );

        if (mounted) {
          ErrorDisplayUtils.showWarningSnackBar(
            context,
            l10n.ownerTableBookingCancelled,
          );
          ref
              .read(windowedBookingsNotifierProvider.notifier)
              .updateBookingStatus(bookingId, BookingStatus.cancelled);

          // Auto-regenerate iCal if enabled
          _triggerIcalRegeneration(bookingId);
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.error,
          );
        }
      }
    }
  }

  void _editBooking(String bookingId) async {
    final ownerBooking = widget.bookings.firstWhereOrNull(
      (b) => b.booking.id == bookingId,
    );
    if (ownerBooking == null) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, 'Booking not found. Please refresh.');
      }
      return;
    }
    await showEditBookingDialog(context, ref, ownerBooking.booking);
  }

  void _sendEmail(BookingModel booking) async {
    await showSendEmailDialog(context, ref, booking);
  }

  Future<void> _deleteBooking(String bookingId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.ownerTableDeleteBooking),
          content: Text(dialogL10n.ownerTableDeleteBookingMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(dialogL10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        await repository.deleteBooking(bookingId);

        if (mounted) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.ownerTableBookingDeleted,
          );
          ref
              .read(windowedBookingsNotifierProvider.notifier)
              .removeBooking(bookingId);
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.error,
          );
        }
      }
    }
  }

  Future<void> _confirmSelectedBookings() async {
    final l10n = AppLocalizations.of(context);
    final count = _selectedBookingIds.length;
    final label = count == 1 ? l10n.ownerTableBooking : l10n.ownerTableBookings;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.ownerTableConfirmSelectedTitle),
          content: Text(
            dialogL10n.ownerTableConfirmSelectedMessage(count, label),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              child: Text(dialogL10n.ownerTableConfirmAll),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);

        // Confirm all selected bookings
        for (final bookingId in _selectedBookingIds) {
          await repository.confirmBooking(bookingId);
        }

        if (mounted) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.ownerTableBookingsConfirmed(count, label),
          );

          // Update each booking status in local state
          for (final bookingId in _selectedBookingIds) {
            ref
                .read(windowedBookingsNotifierProvider.notifier)
                .updateBookingStatus(bookingId, BookingStatus.confirmed);
          }

          setState(_selectedBookingIds.clear);
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.error,
          );
        }
      }
    }
  }

  Future<void> _rejectSelectedBookings() async {
    final l10n = AppLocalizations.of(context);
    final count = _selectedBookingIds.length;
    final label = count == 1 ? l10n.ownerTableBooking : l10n.ownerTableBookings;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.ownerTableRejectSelectedTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dialogL10n.ownerTableRejectSelectedMessage(count, label)),
                const SizedBox(height: 16),
                Builder(
                  builder: (ctx) => TextField(
                    controller: reasonController,
                    decoration: InputDecorationHelper.buildDecoration(
                      labelText: dialogL10n.ownerTableRejectionReasonOptional,
                      hintText: dialogL10n.ownerTableCancellationReasonHint,
                      context: ctx,
                    ),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(dialogL10n.ownerTableRejectAll),
            ),
          ],
        );
      },
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
          ErrorDisplayUtils.showWarningSnackBar(
            context,
            l10n.ownerTableBookingsRejected(count, label),
          );

          // Update each booking status in local state (rejected = cancelled)
          for (final bookingId in _selectedBookingIds) {
            ref
                .read(windowedBookingsNotifierProvider.notifier)
                .updateBookingStatus(bookingId, BookingStatus.cancelled);
          }

          setState(_selectedBookingIds.clear);
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.error,
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
    final l10n = AppLocalizations.of(context);
    final count = _selectedBookingIds.length;
    final label = count == 1 ? l10n.ownerTableBooking : l10n.ownerTableBookings;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.ownerTableDeleteSelectedTitle),
          content: Text(
            dialogL10n.ownerTableDeleteSelectedMessage(count, label),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(dialogL10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);

        // Delete all selected bookings
        for (final bookingId in _selectedBookingIds) {
          await repository.deleteBooking(bookingId);
        }

        if (mounted) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            l10n.ownerTableBookingsDeleted(count, label),
          );

          // Remove each deleted booking from local state
          _selectedBookingIds.forEach(
            ref.read(windowedBookingsNotifierProvider.notifier).removeBooking,
          );

          setState(_selectedBookingIds.clear);
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            e,
            userMessage: l10n.error,
          );
        }
      }
    }
  }

  /// Trigger iCal regeneration for the unit after booking status changes
  void _triggerIcalRegeneration(String bookingId) async {
    try {
      // Find booking in the list
      final ownerBooking = widget.bookings.firstWhereOrNull(
        (b) => b.booking.id == bookingId,
      );
      if (ownerBooking == null) return; // Booking not found, skip regeneration

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
    }
  }
}
