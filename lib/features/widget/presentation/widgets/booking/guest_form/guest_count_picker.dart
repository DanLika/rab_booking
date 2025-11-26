import 'package:flutter/material.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../theme/minimalist_colors.dart';
import '../../common/theme_colors_helper.dart';

/// A widget for selecting adult and children guest counts.
///
/// Provides increment/decrement buttons for both adults and children,
/// with capacity validation to prevent exceeding max guests.
///
/// Usage:
/// ```dart
/// GuestCountPicker(
///   adults: 2,
///   children: 1,
///   maxGuests: 6,
///   isDarkMode: isDarkMode,
///   onAdultsChanged: (value) => setState(() => _adults = value),
///   onChildrenChanged: (value) => setState(() => _children = value),
/// )
/// ```
class GuestCountPicker extends StatelessWidget {
  /// Number of adult guests
  final int adults;

  /// Number of children guests
  final int children;

  /// Maximum total guests allowed
  final int maxGuests;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Callback when adults count changes
  final ValueChanged<int> onAdultsChanged;

  /// Callback when children count changes
  final ValueChanged<int> onChildrenChanged;

  const GuestCountPicker({
    super.key,
    required this.adults,
    required this.children,
    required this.maxGuests,
    required this.isDarkMode,
    required this.onAdultsChanged,
    required this.onChildrenChanged,
  });

  @override
  Widget build(BuildContext context) {
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);
    final totalGuests = adults + children;
    final isAtCapacity = totalGuests >= maxGuests;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: getColor(
            MinimalistColors.borderDefault,
            MinimalistColorsDark.borderDefault,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Number of Guests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                ),
              ),
              Text(
                'Max: $maxGuests',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isAtCapacity
                      ? getColor(
                          MinimalistColors.error,
                          MinimalistColorsDark.error,
                        )
                      : getColor(
                          MinimalistColors.textSecondary,
                          MinimalistColorsDark.textSecondary,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.s),

          // Adults row
          _buildGuestRow(
            icon: Icons.person,
            label: 'Adults',
            count: adults,
            canDecrement: adults > 1,
            canIncrement: !isAtCapacity && adults < maxGuests,
            onDecrement: () => onAdultsChanged(adults - 1),
            onIncrement: () => onAdultsChanged(adults + 1),
            getColor: getColor,
            isAtCapacity: isAtCapacity,
          ),

          const SizedBox(height: 8),

          // Children row
          _buildGuestRow(
            icon: Icons.child_care,
            label: 'Children',
            count: children,
            canDecrement: children > 0,
            canIncrement: !isAtCapacity && children < maxGuests,
            onDecrement: () => onChildrenChanged(children - 1),
            onIncrement: () => onChildrenChanged(children + 1),
            getColor: getColor,
            isAtCapacity: isAtCapacity,
          ),

          // Capacity warning
          if (isAtCapacity) ...[
            const SizedBox(height: 12),
            _buildCapacityWarning(getColor),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestRow({
    required IconData icon,
    required String label,
    required int count,
    required bool canDecrement,
    required bool canIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Color Function(Color light, Color dark) getColor,
    required bool isAtCapacity,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: getColor(
                MinimalistColors.textPrimary,
                MinimalistColorsDark.textPrimary,
              ),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: canDecrement ? onDecrement : null,
              icon: Icon(
                Icons.remove_circle_outline,
                color: getColor(
                  MinimalistColors.textPrimary,
                  MinimalistColorsDark.textPrimary,
                ),
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: getColor(
                    MinimalistColors.textPrimary,
                    MinimalistColorsDark.textPrimary,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: canIncrement ? onIncrement : null,
              icon: Icon(
                Icons.add_circle_outline,
                color: isAtCapacity
                    ? getColor(
                        MinimalistColors.textSecondary,
                        MinimalistColorsDark.textSecondary,
                      ).withValues(alpha: 0.5)
                    : getColor(
                        MinimalistColors.textPrimary,
                        MinimalistColorsDark.textPrimary,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCapacityWarning(
      Color Function(Color light, Color dark) getColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.error.withValues(alpha: 0.1),
          MinimalistColorsDark.error.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: getColor(
            MinimalistColors.error,
            MinimalistColorsDark.error,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning,
            color: getColor(
              MinimalistColors.error,
              MinimalistColorsDark.error,
            ),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'Max capacity: $maxGuests guests',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: getColor(
                MinimalistColors.error,
                MinimalistColorsDark.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
