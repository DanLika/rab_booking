import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../l10n/widget_translations.dart';
import '../../../theme/minimalist_colors.dart';

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
class GuestCountPicker extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final totalGuests = adults + children;
    final isAtCapacity = totalGuests >= maxGuests;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        // Pure white (light) / pure black (dark) for form containers
        color: colors.backgroundPrimary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: colors.borderDefault),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
              Text(
                'Max: $maxGuests',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isAtCapacity ? colors.error : colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.s),

          // Adults row
          _buildGuestRow(
            icon: Icons.person,
            label: WidgetTranslations.of(context, ref).adults,
            count: adults,
            canDecrement: adults > 1,
            canIncrement: !isAtCapacity && adults < maxGuests,
            onDecrement: () => onAdultsChanged(adults - 1),
            onIncrement: () => onAdultsChanged(adults + 1),
            colors: colors,
            isAtCapacity: isAtCapacity,
          ),

          const SizedBox(height: 8),

          // Children row
          _buildGuestRow(
            icon: Icons.child_care,
            label: WidgetTranslations.of(context, ref).children,
            count: children,
            canDecrement: children > 0,
            canIncrement: !isAtCapacity && children < maxGuests,
            onDecrement: () => onChildrenChanged(children - 1),
            onIncrement: () => onChildrenChanged(children + 1),
            colors: colors,
            isAtCapacity: isAtCapacity,
          ),

          // Capacity warning
          if (isAtCapacity) ...[const SizedBox(height: 12), _buildCapacityWarning(colors)],
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
    required MinimalistColorSchemeAdapter colors,
    required bool isAtCapacity,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: colors.textPrimary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: canDecrement ? onDecrement : null,
              icon: Icon(Icons.remove_circle_outline, color: colors.textPrimary),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
            ),
            IconButton(
              onPressed: canIncrement ? onIncrement : null,
              icon: Icon(
                Icons.add_circle_outline,
                color: isAtCapacity ? colors.textSecondary.withValues(alpha: 0.5) : colors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCapacityWarning(MinimalistColorSchemeAdapter colors) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.error),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, color: colors.error, size: 14),
          const SizedBox(width: 6),
          Text(
            'Max capacity: $maxGuests guests',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.error),
          ),
        ],
      ),
    );
  }
}
