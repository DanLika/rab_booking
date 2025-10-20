import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../features/payment/data/payment_service.dart';
import '../../domain/models/user_booking.dart';
import '../../domain/models/booking_status.dart';
import 'package:intl/intl.dart';

/// Cancel Booking Confirmation Dialog
/// Shows cancellation policy and confirms user's intent to cancel
class CancelBookingDialog extends ConsumerStatefulWidget {
  final UserBooking booking;
  final VoidCallback? onCancelled;

  const CancelBookingDialog({
    super.key,
    required this.booking,
    this.onCancelled,
  });

  /// Show dialog as bottom sheet on mobile, dialog on desktop
  static Future<bool?> show(
    BuildContext context, {
    required UserBooking booking,
    VoidCallback? onCancelled,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CancelBookingDialog(
          booking: booking,
          onCancelled: onCancelled,
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: CancelBookingDialog(
              booking: booking,
              onCancelled: onCancelled,
            ),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<CancelBookingDialog> createState() =>
      _CancelBookingDialogState();
}

class _CancelBookingDialogState extends ConsumerState<CancelBookingDialog> {
  bool _isCancelling = false;
  bool _agreedToPolicy = false;
  String? _cancellationReason;

  final List<String> _cancellationReasons = [
    'Change of plans',
    'Found better alternative',
    'Travel restrictions',
    'Personal reasons',
    'Price concerns',
    'Other',
  ];

  Future<void> _handleCancel() async {
    if (!_agreedToPolicy) {
      _showSnackBar('Please accept the cancellation policy to proceed', isError: true);
      return;
    }

    setState(() => _isCancelling = true);

    try {
      // Check if booking is confirmed (paid) - process refund
      if (widget.booking.status == BookingStatus.confirmed) {
        // Process refund via payment service
        final paymentService = ref.read(paymentServiceProvider);
        final result = await paymentService.processRefund(
          bookingId: widget.booking.id,
          reason: _cancellationReason ?? 'No reason provided',
        );

        if (!mounted) return;

        final refundAmount = result['refundAmount'] as int?;
        if (refundAmount != null && refundAmount > 0) {
          _showSnackBar(
            'Booking cancelled and refund of €${(refundAmount / 100).toStringAsFixed(2)} processed',
            isError: false,
          );
        } else {
          _showSnackBar(
            'Booking cancelled. No refund available based on cancellation policy.',
            isError: false,
          );
        }
      } else {
        // Just cancel the booking (no payment to refund)
        await ref.read(bookingRepositoryProvider).cancelBooking(
          widget.booking.id,
          _cancellationReason ?? 'No reason provided',
        );

        if (!mounted) return;

        _showSnackBar('Booking cancelled successfully', isError: false);
      }

      widget.onCancelled?.call();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? context.errorColor : context.successColor,
      ),
    );
  }

  String _calculateRefundAmount() {
    final now = DateTime.now();
    final checkIn = widget.booking.checkInDate;
    final daysUntilCheckIn = checkIn.difference(now).inDays;

    // Cancellation policy:
    // - More than 7 days: 100% refund
    // - 3-7 days: 50% refund
    // - Less than 3 days: No refund

    if (daysUntilCheckIn > 7) {
      return '100% refund (€${widget.booking.totalPrice.toStringAsFixed(2)})';
    } else if (daysUntilCheckIn >= 3) {
      final refund = widget.booking.totalPrice * 0.5;
      return '50% refund (€${refund.toStringAsFixed(2)})';
    } else {
      return 'No refund';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dateFormat = DateFormat('dd MMM yyyy');

    final content = Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL))
            : BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            decoration: BoxDecoration(
              color: context.errorColor.withValues(alpha: 0.1),
              borderRadius: isMobile
                  ? const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL))
                  : const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceS),
                  decoration: BoxDecoration(
                    color: context.errorColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    color: context.iconColorInverted,
                    size: AppDimensions.iconL,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cancel Booking',
                        style: AppTypography.h3.copyWith(
                          color: context.errorColor,
                          fontWeight: AppTypography.weightBold,
                        ),
                      ),
                      Text(
                        'Booking #${widget.booking.id.substring(0, 8).toUpperCase()}',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning message
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    decoration: BoxDecoration(
                      color: context.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(
                        color: context.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: context.warningColor,
                          size: AppDimensions.iconM,
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        Expanded(
                          child: Text(
                            'This action cannot be undone. Please review the cancellation policy below.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: context.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spaceL),

                  // Booking details
                  Text(
                    'Booking Details',
                    style: AppTypography.label.copyWith(
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceS),

                  _buildDetailRow('Property', widget.booking.propertyName),
                  _buildDetailRow('Check-in', dateFormat.format(widget.booking.checkInDate)),
                  _buildDetailRow('Check-out', dateFormat.format(widget.booking.checkOutDate)),
                  _buildDetailRow('Total Paid', '€${widget.booking.totalPrice.toStringAsFixed(2)}'),

                  const SizedBox(height: AppDimensions.spaceL),

                  // Cancellation policy
                  Text(
                    'Cancellation Policy',
                    style: AppTypography.label.copyWith(
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceS),

                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(
                        color: context.dividerColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPolicyItem('More than 7 days before check-in', '100% refund'),
                        _buildPolicyItem('3-7 days before check-in', '50% refund'),
                        _buildPolicyItem('Less than 3 days before check-in', 'No refund'),
                        const Divider(height: AppDimensions.spaceL),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: AppDimensions.iconS,
                              color: context.primaryColor,
                            ),
                            const SizedBox(width: AppDimensions.spaceS),
                            Expanded(
                              child: Text(
                                'Your refund: ${_calculateRefundAmount()}',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: AppTypography.weightBold,
                                  color: context.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spaceL),

                  // Cancellation reason
                  Text(
                    'Reason for Cancellation (Optional)',
                    style: AppTypography.label.copyWith(
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceS),

                  Wrap(
                    spacing: AppDimensions.spaceS,
                    runSpacing: AppDimensions.spaceS,
                    children: _cancellationReasons.map((reason) {
                      final isSelected = _cancellationReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _cancellationReason = selected ? reason : null;
                          });
                        },
                        selectedColor: context.primaryColor.withValues(alpha: 0.2),
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color: isSelected ? context.primaryColor : context.textColor,
                          fontWeight: isSelected ? AppTypography.weightBold : AppTypography.weightRegular,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppDimensions.spaceL),

                  // Agreement checkbox
                  CheckboxListTile(
                    value: _agreedToPolicy,
                    onChanged: (value) {
                      setState(() => _agreedToPolicy = value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'I understand the cancellation policy and agree to proceed',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: isMobile
                  ? null
                  : const BorderRadius.vertical(bottom: Radius.circular(AppDimensions.radiusL)),
              border: Border(
                top: BorderSide(
                  color: context.dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCancelling ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Keep Booking'),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: FilledButton(
                    onPressed: _isCancelling || !_agreedToPolicy ? null : _handleCancel,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.errorColor,
                    ),
                    child: _isCancelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Cancel Booking'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: content,
      );
    }

    return content;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textColorSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: AppTypography.weightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String condition, String refund) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXXS),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: AppDimensions.iconXS,
            color: context.textColorSecondary,
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Expanded(
            child: Text(
              condition,
              style: AppTypography.bodySmall.copyWith(
                color: context.textColorSecondary,
              ),
            ),
          ),
          Text(
            refund,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: AppTypography.weightBold,
            ),
          ),
        ],
      ),
    );
  }
}
