import 'package:flutter/material.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../l10n/app_localizations.dart';

/// Context menu for booking blocks (right-click menu)
class BookingContextMenu extends StatelessWidget {
  final BookingModel booking;
  final Offset position;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSendEmail;
  final Function(BookingStatus) onChangeStatus;

  const BookingContextMenu({
    super.key,
    required this.booking,
    required this.position,
    required this.onEdit,
    required this.onDelete,
    required this.onSendEmail,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Transparent overlay to dismiss menu
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),
        ),

        // Context menu
        Positioned(
          left: position.dx,
          top: position.dy,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with guest name
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.authPrimary.withAlpha((0.1 * 255).toInt()),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: booking.status.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.guestName ?? 'N/A',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Edit
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _buildMenuItem(
                        icon: Icons.edit,
                        label: l10n.editBookingTitle,
                        onTap: () {
                          Navigator.of(context).pop();
                          onEdit();
                        },
                      );
                    },
                  ),

                  const Divider(height: 1),

                  // Change status submenu
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _buildSubmenuHeader(l10n.ownerCalendarChangeStatus);
                    },
                  ),

                  if (booking.status != BookingStatus.confirmed)
                    _buildStatusMenuItem(
                      status: BookingStatus.confirmed,
                      onTap: () {
                        Navigator.of(context).pop();
                        onChangeStatus(BookingStatus.confirmed);
                      },
                    ),

                  if (booking.status != BookingStatus.pending)
                    _buildStatusMenuItem(
                      status: BookingStatus.pending,
                      onTap: () {
                        Navigator.of(context).pop();
                        onChangeStatus(BookingStatus.pending);
                      },
                    ),

                  if (booking.status != BookingStatus.completed)
                    _buildStatusMenuItem(
                      status: BookingStatus.completed,
                      onTap: () {
                        Navigator.of(context).pop();
                        onChangeStatus(BookingStatus.completed);
                      },
                    ),

                  if (booking.status != BookingStatus.cancelled)
                    _buildStatusMenuItem(
                      status: BookingStatus.cancelled,
                      onTap: () {
                        Navigator.of(context).pop();
                        onChangeStatus(BookingStatus.cancelled);
                      },
                    ),

                  const Divider(height: 1),

                  // Send email
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _buildMenuItem(
                        icon: Icons.email_outlined,
                        label: l10n.ownerTableActionSendEmail,
                        onTap: () {
                          Navigator.of(context).pop();
                          onSendEmail();
                        },
                      );
                    },
                  ),

                  const Divider(height: 1),

                  // Delete
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _buildMenuItem(
                        icon: Icons.delete_outline,
                        label: l10n.ownerTableDeleteBooking,
                        color: AppColors.error,
                        onTap: () {
                          Navigator.of(context).pop();
                          onDelete();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 13, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmenuHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildStatusMenuItem({required BookingStatus status, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 6),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(status.displayName, style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }
}

/// Show booking context menu at cursor position
Future<void> showBookingContextMenu({
  required BuildContext context,
  required BookingModel booking,
  required Offset position,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onSendEmail,
  required Function(BookingStatus) onChangeStatus,
}) {
  // Adjust position to keep menu on screen
  final screenSize = MediaQuery.of(context).size;
  final menuWidth = 220.0;
  final menuHeight = 400.0;

  double left = position.dx;
  double top = position.dy;

  // Keep menu within horizontal bounds
  if (left + menuWidth > screenSize.width) {
    left = screenSize.width - menuWidth - 16;
  }

  // Keep menu within vertical bounds
  if (top + menuHeight > screenSize.height) {
    top = screenSize.height - menuHeight - 16;
  }

  // Ensure minimum padding from edges
  left = left.clamp(16.0, screenSize.width - menuWidth - 16);
  top = top.clamp(16.0, screenSize.height - menuHeight - 16);

  return showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => BookingContextMenu(
      booking: booking,
      position: Offset(left, top),
      onEdit: onEdit,
      onDelete: onDelete,
      onSendEmail: onSendEmail,
      onChangeStatus: onChangeStatus,
    ),
  );
}
