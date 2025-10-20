import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium cancellation policy widget
/// Features: Policy types, refund timeline, expandable details
class CancellationPolicyWidget extends StatefulWidget {
  /// Policy type
  final CancellationPolicy policy;

  /// Check-in date
  final DateTime checkInDate;

  /// Total booking amount
  final double totalAmount;

  /// Currency symbol
  final String currencySymbol;

  /// Expandable content
  final bool expandable;

  /// Initially expanded
  final bool initiallyExpanded;

  const CancellationPolicyWidget({
    super.key,
    required this.policy,
    required this.checkInDate,
    required this.totalAmount,
    this.currencySymbol = '\$',
    this.expandable = true,
    this.initiallyExpanded = false,
  });

  @override
  State<CancellationPolicyWidget> createState() =>
      _CancellationPolicyWidgetState();
}

class _CancellationPolicyWidgetState extends State<CancellationPolicyWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard.elevated(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: widget.expandable
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceS),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getPolicyIcon(widget.policy),
                      color: context.textColorInverted,
                      size: AppDimensions.iconM,
                    ),
                  ),

                  const SizedBox(width: AppDimensions.spaceM),

                  // Policy info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancellation Policy',
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.textColorSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceXXS),
                        Text(
                          widget.policy.displayName,
                          style: AppTypography.h3.copyWith(
                            fontWeight: AppTypography.weightBold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expand icon
                  if (widget.expandable)
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: context.textColorSecondary,
                    ),
                ],
              ),
            ),
          ),

          // Quick summary (always visible)
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimensions.spaceL,
              right: AppDimensions.spaceL,
              bottom: AppDimensions.spaceL,
            ),
            child: _buildQuickSummary(context),
          ),

          // Expandable details
          if (_isExpanded) ...[
            Divider(
              thickness: 1,
              color: context.borderColor,
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceL),
              child: _buildExpandedDetails(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Text(
        _getQuickSummary(widget.policy),
        style: AppTypography.bodyMedium,
      ),
    );
  }

  Widget _buildExpandedDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Refund Timeline',
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: AppTypography.weightSemibold,
          ),
        ),

        const SizedBox(height: AppDimensions.spaceM),

        // Timeline
        ..._buildTimeline(context, widget.policy),

        const SizedBox(height: AppDimensions.spaceL),

        // Important notes
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          decoration: BoxDecoration(
            color: AppColors.withOpacity(AppColors.warning, AppColors.opacity10),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: AppColors.warning,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.warning,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: AppTypography.weightSemibold,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      'Refunds are processed within 5-10 business days after cancellation. Check-in time is based on the property\'s local timezone.',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTimeline(BuildContext context, CancellationPolicy policy) {
    final timelineItems = _getTimelineItems(policy);

    return timelineItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isLast = index == timelineItems.length - 1;

      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.spaceM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: item.isPositive
                        ? AppColors.success
                        : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      item.isPositive ? Icons.check : Icons.close,
                      color: context.textColorInverted,
                      size: 16,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: context.borderColor,
                  ),
              ],
            ),

            const SizedBox(width: AppDimensions.spaceM),

            // Timeline content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXXS),
                  Text(
                    item.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getQuickSummary(CancellationPolicy policy) {
    switch (policy) {
      case CancellationPolicy.flexible:
        return 'Free cancellation up to 24 hours before check-in. After that, cancel before check-in and get a 50% refund.';
      case CancellationPolicy.moderate:
        return 'Free cancellation up to 5 days before check-in. Cancel within 5 days of check-in and get a 50% refund.';
      case CancellationPolicy.strict:
        return 'Free cancellation up to 14 days before check-in. Cancel within 14 days and the reservation is non-refundable.';
      case CancellationPolicy.nonRefundable:
        return 'This reservation is non-refundable. No refund will be issued for any cancellations.';
    }
  }

  List<_TimelineItem> _getTimelineItems(CancellationPolicy policy) {
    switch (policy) {
      case CancellationPolicy.flexible:
        return [
          _TimelineItem(
            title: 'Before 24 hours of check-in',
            description: 'Full refund of ${widget.currencySymbol}${widget.totalAmount.toStringAsFixed(2)}',
            isPositive: true,
          ),
          _TimelineItem(
            title: 'Within 24 hours of check-in',
            description: '50% refund of ${widget.currencySymbol}${(widget.totalAmount * 0.5).toStringAsFixed(2)}',
            isPositive: true,
          ),
          _TimelineItem(
            title: 'After check-in',
            description: 'No refund',
            isPositive: false,
          ),
        ];

      case CancellationPolicy.moderate:
        return [
          _TimelineItem(
            title: 'Before 5 days of check-in',
            description: 'Full refund of ${widget.currencySymbol}${widget.totalAmount.toStringAsFixed(2)}',
            isPositive: true,
          ),
          _TimelineItem(
            title: 'Within 5 days of check-in',
            description: '50% refund of ${widget.currencySymbol}${(widget.totalAmount * 0.5).toStringAsFixed(2)}',
            isPositive: true,
          ),
          _TimelineItem(
            title: 'After check-in',
            description: 'No refund',
            isPositive: false,
          ),
        ];

      case CancellationPolicy.strict:
        return [
          _TimelineItem(
            title: 'Before 14 days of check-in',
            description: 'Full refund of ${widget.currencySymbol}${widget.totalAmount.toStringAsFixed(2)}',
            isPositive: true,
          ),
          _TimelineItem(
            title: 'Within 14 days of check-in',
            description: 'No refund',
            isPositive: false,
          ),
        ];

      case CancellationPolicy.nonRefundable:
        return [
          _TimelineItem(
            title: 'Any time',
            description: 'No refund available',
            isPositive: false,
          ),
        ];
    }
  }

  IconData _getPolicyIcon(CancellationPolicy policy) {
    switch (policy) {
      case CancellationPolicy.flexible:
        return Icons.check_circle_outline;
      case CancellationPolicy.moderate:
        return Icons.timelapse;
      case CancellationPolicy.strict:
        return Icons.warning_amber_outlined;
      case CancellationPolicy.nonRefundable:
        return Icons.block;
    }
  }
}

/// Cancellation policy enum
enum CancellationPolicy {
  flexible,
  moderate,
  strict,
  nonRefundable,
}

extension CancellationPolicyExtension on CancellationPolicy {
  String get displayName {
    switch (this) {
      case CancellationPolicy.flexible:
        return 'Flexible';
      case CancellationPolicy.moderate:
        return 'Moderate';
      case CancellationPolicy.strict:
        return 'Strict';
      case CancellationPolicy.nonRefundable:
        return 'Non-refundable';
    }
  }
}

/// Timeline item model
class _TimelineItem {
  final String title;
  final String description;
  final bool isPositive;

  _TimelineItem({
    required this.title,
    required this.description,
    required this.isPositive,
  });
}
