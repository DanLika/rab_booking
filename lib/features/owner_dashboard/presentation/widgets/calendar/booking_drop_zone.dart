import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/calendar_drag_drop_provider.dart';

/// Booking Drop Zone Widget
/// Reusable drop target for calendar cells with enhanced visual feedback
class BookingDropZone extends ConsumerWidget {
  final DateTime date;
  final UnitModel unit;
  final Map<String, List<BookingModel>> allBookings;
  final double width;
  final double height;
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final void Function(BookingModel booking)? onBookingDropped;
  final bool isEnabled;
  final bool isPast;
  final bool isToday;

  const BookingDropZone({
    super.key,
    required this.date,
    required this.unit,
    required this.allBookings,
    required this.width,
    required this.height,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onBookingDropped,
    this.isEnabled = true,
    this.isPast = false,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (!isEnabled) {
      // Just return a container without drag target
      return GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        child: Container(width: width, height: height, decoration: _buildBaseDecoration(theme), child: child),
      );
    }

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: DragTarget<BookingModel>(
        onWillAcceptWithDetails: (details) {
          // Validate drop in real-time
          ref
              .read(dragDropProvider.notifier)
              .validateDrop(dropDate: date, targetUnitId: unit.id, allBookings: allBookings);
          return true; // Always show feedback
        },
        onAcceptWithDetails: (details) {
          final dragState = ref.read(dragDropProvider);
          if (dragState.isValidDrop && onBookingDropped != null) {
            onBookingDropped!(details.data);
          }
        },
        onLeave: (_) {
          // Clear validation when drag leaves
          ref.read(dragDropProvider.notifier).stopDragging();
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          final dragState = ref.watch(dragDropProvider);
          final isValid = dragState.isValidDrop;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: width,
            height: height,
            decoration: _buildDropZoneDecoration(theme: theme, isHovering: isHovering, isValid: isValid),
            child: Stack(
              alignment: Alignment.topLeft, // Explicit alignment to avoid TextDirection dependency on Chrome Mobile
              children: [
                // Base child
                if (child != null) child!,

                // Drop indicator overlay
                if (isHovering)
                  Positioned.fill(
                    child: _buildDropIndicator(
                      context: context,
                      isValid: isValid,
                      errorMessage: dragState.errorMessage,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build base decoration (no hover)
  BoxDecoration _buildBaseDecoration(ThemeData theme) {
    return BoxDecoration(
      color: isPast
          ? theme.disabledColor.withAlpha((0.05 * 255).toInt())
          : (isToday
                ? theme.colorScheme.primary.withAlpha((0.05 * 255).toInt())
                : Colors.transparent), // Transparent to show parent gradient
      border: Border(
        right: BorderSide(color: theme.dividerColor.withAlpha((0.6 * 255).toInt())),
        bottom: BorderSide(color: theme.dividerColor.withAlpha((0.6 * 255).toInt())),
      ),
    );
  }

  /// Build drop zone decoration (with hover feedback)
  BoxDecoration _buildDropZoneDecoration({required ThemeData theme, required bool isHovering, required bool isValid}) {
    Color backgroundColor;
    Color borderColor;

    if (isHovering) {
      if (isValid) {
        // Valid drop - green
        backgroundColor = AppColors.success.withAlpha((0.15 * 255).toInt());
        borderColor = AppColors.success;
      } else {
        // Invalid drop - red
        backgroundColor = AppColors.error.withAlpha((0.15 * 255).toInt());
        borderColor = AppColors.error;
      }
    } else {
      // No hover
      backgroundColor = isPast
          ? theme.disabledColor.withAlpha((0.05 * 255).toInt())
          : (isToday
                ? theme.colorScheme.primary.withAlpha((0.05 * 255).toInt())
                : Colors.transparent); // Transparent to show parent gradient
      borderColor = theme.dividerColor.withAlpha((0.6 * 255).toInt());
    }

    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(color: borderColor, width: isHovering ? 2 : 1),
      borderRadius: BorderRadius.circular(isHovering ? 4 : 0),
    );
  }

  /// Build drop indicator (icon + message)
  Widget _buildDropIndicator({required BuildContext context, required bool isValid, String? errorMessage}) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isValid ? AppColors.success : AppColors.error).withAlpha((0.3 * 255).toInt()),
            (isValid ? AppColors.success : AppColors.error).withAlpha((0.1 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              isValid ? Icons.check_circle : Icons.cancel,
              color: isValid ? AppColors.success : AppColors.error,
              size: width > 60 ? 32 : 20,
            ),

            // Message (only if space available)
            if (height > 50 && width > 80) ...[
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    isValid ? l10n.bookingDropZoneDropHere : (errorMessage ?? l10n.bookingDropZoneCannotDrop),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isValid ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
