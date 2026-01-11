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

/// BedBooking-style Table View for bookings - Optimized with SliverList
/// Virtualized rendering for performance (60 FPS)
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Check if all selected bookings are pending
    final selectedBookings = widget.bookings
        .where((b) => _selectedBookingIds.contains(b.booking.id))
        .toList();
    final allSelectedArePending =
        selectedBookings.isNotEmpty &&
        selectedBookings.every(
          (b) => b.booking.status == BookingStatus.pending,
        );

    // Columns flex configuration
    // Guest(3), Property(3), Dates(3), Status(2), Price(2), Actions(1)

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      sliver: SliverMainAxisGroup(
        slivers: [
          // Action Bar & Header
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (_selectedBookingIds.isNotEmpty)
                  _buildActionBar(context, l10n, isDark, allSelectedArePending),

                // Header
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border.all(color: context.borderColor.withAlpha(100)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Checkbox placeholder
                      const SizedBox(width: 40),
                      Expanded(flex: 3, child: _HeaderCell(l10n.ownerTableColumnGuest)),
                      Expanded(flex: 3, child: _HeaderCell(l10n.ownerTableColumnPropertyUnit)),
                      Expanded(flex: 3, child: _HeaderCell('${l10n.ownerTableColumnCheckIn} - ${l10n.ownerTableColumnCheckOut}')),
                      Expanded(flex: 2, child: _HeaderCell(l10n.ownerTableColumnStatus)),
                      Expanded(flex: 2, child: _HeaderCell(l10n.ownerTableColumnPrice)),
                      Expanded(flex: 1, child: _HeaderCell(l10n.ownerTableColumnActions, align: TextAlign.end)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Virtualized List of Rows
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final booking = widget.bookings[index];
                return RepaintBoundary(
                  child: _BookingRowItem(
                    key: ValueKey(booking.booking.id),
                    ownerBooking: booking,
                    isSelected: _selectedBookingIds.contains(booking.booking.id),
                    onSelectionChanged: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedBookingIds.add(booking.booking.id);
                        } else {
                          _selectedBookingIds.remove(booking.booking.id);
                        }
                      });
                    },
                    onTap: () => _showBookingDetails(booking),
                    onAction: (action) => _handleAction(action, booking.booking),
                  ),
                );
              },
              childCount: widget.bookings.length,
            ),
          ),

          // Bottom border/spacing to close the table visual
          SliverToBoxAdapter(
            child: Container(
              height: 1,
              color: context.borderColor.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, AppLocalizations l10n, bool isDark, bool allSelectedArePending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.getElevation(2, isDark: isDark),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Selection count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 6),
                Text(
                  l10n.ownerTableSelected(_selectedBookingIds.length),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => setState(_selectedBookingIds.clear),
            icon: const Icon(Icons.close, size: 18),
            label: Text(l10n.ownerTableClearSelection),
          ),
          const Spacer(),
          // Bulk actions
          if (allSelectedArePending) ...[
             IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
              tooltip: l10n.ownerTableConfirmSelected,
              onPressed: _confirmSelectedBookings,
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              tooltip: l10n.ownerTableRejectSelected,
              onPressed: _rejectSelectedBookings,
            ),
          ],
           IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: l10n.ownerTableDeleteSelected,
              onPressed: _deleteSelectedBookings,
            ),
        ],
      ),
    );
  }

  // --- Logic Methods (Same as before) ---

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
    final ownerBooking = widget.bookings.firstWhere(
      (b) => b.booking.id == bookingId,
      orElse: () => widget.bookings.first,
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
          ErrorDisplayUtils.showSuccessSnackBar(context, l10n.ownerTableBookingConfirmed);
          ref.read(windowedBookingsNotifierProvider.notifier).updateBookingStatus(bookingId, BookingStatus.confirmed);
          _triggerIcalRegeneration(bookingId);
        }
      } catch (e) {
        if (mounted) ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.error);
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
        final reason = reasonController.text.trim().isEmpty ? null : reasonController.text.trim();
        await repository.rejectBooking(bookingId, reason: reason);
        if (mounted) {
          ErrorDisplayUtils.showWarningSnackBar(context, l10n.ownerBookingsRejected);
          ref.read(windowedBookingsNotifierProvider.notifier).updateBookingStatus(bookingId, BookingStatus.cancelled);
        }
      } catch (e) {
        if (mounted) ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.ownerBookingsRejectError);
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
          ErrorDisplayUtils.showSuccessSnackBar(context, l10n.ownerTableBookingCompleted);
          ref.read(windowedBookingsNotifierProvider.notifier).updateBookingStatus(bookingId, BookingStatus.completed);
          _triggerIcalRegeneration(bookingId);
        }
      } catch (e) {
        if (mounted) ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.error);
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
                TextField(
                  controller: reasonController,
                  decoration: InputDecorationHelper.buildDecoration(
                    labelText: dialogL10n.ownerTableCancellationReason,
                    hintText: dialogL10n.ownerTableCancellationReasonHint,
                    context: dialogContext,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: sendEmailNotifier,
                  builder: (context, sendEmail, _) {
                    return CheckboxListTile(
                      title: Text(dialogL10n.ownerTableSendEmailToGuest),
                      value: sendEmail,
                      onChanged: (value) => sendEmailNotifier.value = value ?? true,
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
          reasonController.text.isEmpty ? l10n.ownerTableCancelledByOwner : reasonController.text,
          sendEmail: sendEmailNotifier.value,
        );
        if (mounted) {
          ErrorDisplayUtils.showWarningSnackBar(context, l10n.ownerTableBookingCancelled);
          ref.read(windowedBookingsNotifierProvider.notifier).updateBookingStatus(bookingId, BookingStatus.cancelled);
          _triggerIcalRegeneration(bookingId);
        }
      } catch (e) {
        if (mounted) ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.error);
      }
    }
  }

  void _editBooking(String bookingId) async {
    final ownerBooking = widget.bookings.firstWhereOrNull((b) => b.booking.id == bookingId);
    if (ownerBooking == null) return;
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
          ErrorDisplayUtils.showSuccessSnackBar(context, l10n.ownerTableBookingDeleted);
          ref.read(windowedBookingsNotifierProvider.notifier).removeBooking(bookingId);
        }
      } catch (e) {
        if (mounted) ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.error);
      }
    }
  }

  Future<void> _confirmSelectedBookings() async {
    final l10n = AppLocalizations.of(context);
    final count = _selectedBookingIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.ownerTableConfirmSelectedTitle),
        content: Text(l10n.ownerTableConfirmSelectedMessage(count, count == 1 ? l10n.ownerTableBooking : l10n.ownerTableBookings)),
        actions: [
           TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
           FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.ownerTableConfirmAll)),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        for (final bookingId in _selectedBookingIds) {
          await repository.confirmBooking(bookingId);
        }
        if (mounted) {
          ErrorDisplayUtils.showSuccessSnackBar(context, l10n.ownerTableBookingsConfirmed(count, count == 1 ? l10n.ownerTableBooking : l10n.ownerTableBookings));
          for (final id in _selectedBookingIds) {
             ref.read(windowedBookingsNotifierProvider.notifier).updateBookingStatus(id, BookingStatus.confirmed);
          }
          setState(_selectedBookingIds.clear);
        }
      } catch (e) {
        if (mounted) ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _rejectSelectedBookings() async {
     final l10n = AppLocalizations.of(context);
     final count = _selectedBookingIds.length;
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.ownerTableRejectSelectedTitle),
        content: Text(l10n.ownerTableRejectSelectedMessage(count, count == 1 ? l10n.ownerTableBooking : l10n.ownerTableBookings)),
        actions: [
           TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
           FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: Text(l10n.ownerTableRejectAll)),
        ],
      ),
    );
     if (confirmed == true && mounted) {
      try {
        final repository = ref.read(ownerBookingsRepositoryProvider);
        for (final bookingId in _selectedBookingIds) {
          await repository.rejectBooking(bookingId);
        }
        if (mounted) {
          ErrorDisplayUtils.showWarningSnackBar(context, l10n.ownerTableBookingsRejected(count, count == 1 ? l10n.ownerTableBooking : l10n.ownerTableBookings));
          for (final id in _selectedBookingIds) {
             ref.read(windowedBookingsNotifierProvider.notifier).updateBookingStatus(id, BookingStatus.cancelled);
          }
          setState(_selectedBookingIds.clear);
        }
      } catch (e) {
        if (mounted) ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _deleteSelectedBookings() async {
     final l10n = AppLocalizations.of(context);
     final count = _selectedBookingIds.length;
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.ownerTableDeleteSelectedTitle),
        content: Text(l10n.ownerTableDeleteSelectedMessage(count, count == 1 ? l10n.ownerTableBooking : l10n.ownerTableBookings)),
        actions: [
           TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
           FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: Text(l10n.delete)),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
         final repository = ref.read(ownerBookingsRepositoryProvider);
         for (final id in _selectedBookingIds) {
           await repository.deleteBooking(id);
         }
         if (mounted) {
           ErrorDisplayUtils.showSuccessSnackBar(context, l10n.ownerTableBookingsDeleted(count, count == 1 ? l10n.ownerTableBooking : l10n.ownerTableBookings));
           _selectedBookingIds.forEach(ref.read(windowedBookingsNotifierProvider.notifier).removeBooking);
           setState(_selectedBookingIds.clear);
         }
      } catch (e) {
        if (mounted) ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  void _triggerIcalRegeneration(String bookingId) async {
    try {
      final ownerBooking = widget.bookings.firstWhereOrNull((b) => b.booking.id == bookingId);
      if (ownerBooking == null) return;
      final icalService = ref.read(icalExportServiceProvider);
      await icalService.autoRegenerateIfEnabled(
        propertyId: ownerBooking.property.id,
        unitId: ownerBooking.unit.id,
        unit: ownerBooking.unit,
      );
    } catch (_) {}
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _HeaderCell(this.text, {this.align = TextAlign.start});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _BookingRowItem extends StatelessWidget {
  final OwnerBooking ownerBooking;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onTap;
  final Function(String) onAction;

  const _BookingRowItem({
    super.key,
    required this.ownerBooking,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isSelected
        ? theme.colorScheme.primaryContainer.withAlpha(50)
        : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: context.borderColor.withAlpha(100))),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Checkbox
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (v) => onSelectionChanged(v ?? false),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),

                // Guest
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerBooking.guestName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        ownerBooking.guestEmail,
                        style: TextStyle(fontSize: 12, color: context.textColorSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Property/Unit
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        unit.name,
                        style: TextStyle(fontSize: 12, color: context.textColorSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Dates
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        '${DateFormat('dd.MM.').format(booking.checkIn)} - ${DateFormat('dd.MM.yyyy').format(booking.checkOut)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                       Text(
                        '${booking.numberOfNights} ${l10n.nights}',
                        style: TextStyle(fontSize: 12, color: context.textColorSecondary),
                      ),
                    ],
                  ),
                ),

                // Status
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: booking.status.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.status.displayNameLocalized(context),
                          style: TextStyle(
                            color: booking.status.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
                Expanded(
                  flex: 2,
                  child: Text(
                    booking.formattedTotalPrice,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? theme.colorScheme.primaryContainer : theme.primaryColor,
                    ),
                  ),
                ),

                // Actions
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: l10n.ownerTableColumnActions,
                      onSelected: onAction,
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'details', child: Row(children: [const Icon(Icons.visibility_outlined), const SizedBox(width: 8), Text(l10n.ownerTableActionDetails)])),
                        if (booking.status == BookingStatus.pending) PopupMenuItem(value: 'confirm', child: Row(children: [const Icon(Icons.check_circle_outline, color: AppColors.success), const SizedBox(width: 8), Text(l10n.ownerTableActionConfirm)])),
                        if (booking.status == BookingStatus.pending) PopupMenuItem(value: 'reject', child: Row(children: [const Icon(Icons.cancel_outlined, color: AppColors.error), const SizedBox(width: 8), Text(l10n.ownerBookingCardReject)])),
                        if (booking.status == BookingStatus.confirmed && booking.isPast) PopupMenuItem(value: 'complete', child: Row(children: [const Icon(Icons.done_all), const SizedBox(width: 8), Text(l10n.ownerTableActionComplete)])),
                        PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined), const SizedBox(width: 8), Text(l10n.ownerTableActionEdit)])),
                        if (booking.canBeCancelled) PopupMenuItem(value: 'cancel', child: Row(children: [const Icon(Icons.cancel_outlined, color: AppColors.error), const SizedBox(width: 8), Text(l10n.ownerTableActionCancel)])),
                        PopupMenuItem(value: 'email', child: Row(children: [const Icon(Icons.email_outlined), const SizedBox(width: 8), Text(l10n.ownerTableActionSendEmail)])),
                        const PopupMenuDivider(),
                        PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, color: AppColors.error), const SizedBox(width: 8), Text(l10n.ownerTableActionDelete, style: const TextStyle(color: AppColors.error))])),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
