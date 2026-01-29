import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../l10n/widget_translations.dart';
import '../../../theme/minimalist_colors.dart';

/// A widget for selecting adult, children, and pet counts.
///
/// Provides increment/decrement buttons for adults, children, and pets,
/// with capacity validation to prevent exceeding max guests.
/// Uses [maxTotalCapacity] (if set) for the upper guest limit,
/// falling back to [maxGuests] (base capacity).
class GuestCountPicker extends ConsumerWidget {
  final int adults;
  final int children;
  final int maxGuests;
  final int? maxTotalCapacity;
  final double? petFee;
  final int pets;
  final bool isDarkMode;
  final ValueChanged<int> onAdultsChanged;
  final ValueChanged<int> onChildrenChanged;
  final ValueChanged<int>? onPetsChanged;

  const GuestCountPicker({
    super.key,
    required this.adults,
    required this.children,
    required this.maxGuests,
    this.maxTotalCapacity,
    this.petFee,
    this.pets = 0,
    required this.isDarkMode,
    required this.onAdultsChanged,
    required this.onChildrenChanged,
    this.onPetsChanged,
  });

  static const _countDisplayWidth = 40.0;
  static const _maxPets = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context, ref);
    final totalGuests = adults + children;
    // Use maxTotalCapacity if set, otherwise fall back to maxGuests
    final effectiveMax = maxTotalCapacity ?? maxGuests;
    final isAtCapacity = totalGuests >= effectiveMax;
    final allowsPets = petFee != null && onPetsChanged != null;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors, tr, isAtCapacity, effectiveMax),
          const SizedBox(height: SpacingTokens.s),
          _GuestRow(
            icon: Icons.person,
            label: tr.adults,
            count: adults,
            canDecrement: adults > 1,
            canIncrement: !isAtCapacity,
            onDecrement: () => onAdultsChanged(adults - 1),
            onIncrement: () => onAdultsChanged(adults + 1),
            colors: colors,
            isAtCapacity: isAtCapacity,
          ),
          const SizedBox(height: SpacingTokens.s),
          _GuestRow(
            icon: Icons.child_care,
            label: tr.children,
            count: children,
            canDecrement: children > 0,
            canIncrement: !isAtCapacity,
            onDecrement: () => onChildrenChanged(children - 1),
            onIncrement: () => onChildrenChanged(children + 1),
            colors: colors,
            isAtCapacity: isAtCapacity,
          ),
          if (allowsPets) ...[
            const SizedBox(height: SpacingTokens.s),
            _GuestRow(
              icon: Icons.pets,
              label: tr.pets,
              count: pets,
              canDecrement: pets > 0,
              canIncrement: pets < GuestCountPicker._maxPets,
              onDecrement: () => onPetsChanged!(pets - 1),
              onIncrement: () => onPetsChanged!(pets + 1),
              colors: colors,
              isAtCapacity: false,
            ),
          ],
          if (isAtCapacity) ...[
            const SizedBox(height: SpacingTokens.m),
            _CapacityWarning(maxGuests: effectiveMax, colors: colors, tr: tr),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    MinimalistColorSchemeAdapter colors,
    WidgetTranslations tr,
    bool isAtCapacity,
    int effectiveMax,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tr.numberOfGuests,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        Text(
          tr.maxLabel(effectiveMax),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isAtCapacity ? colors.error : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GuestRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final MinimalistColorSchemeAdapter colors;
  final bool isAtCapacity;

  const _GuestRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
    required this.colors,
    required this.isAtCapacity,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: colors.textPrimary, size: 20),
            const SizedBox(width: SpacingTokens.s),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: canDecrement ? onDecrement : null,
              icon: Icon(
                Icons.remove_circle_outline,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(
              width: GuestCountPicker._countDisplayWidth,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: canIncrement ? onIncrement : null,
              icon: Icon(
                Icons.add_circle_outline,
                color: isAtCapacity
                    ? colors.textSecondary.withValues(alpha: 0.5)
                    : colors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CapacityWarning extends StatelessWidget {
  final int maxGuests;
  final MinimalistColorSchemeAdapter colors;
  final WidgetTranslations tr;

  const _CapacityWarning({
    required this.maxGuests,
    required this.colors,
    required this.tr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.s),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.1),
        borderRadius: BorderTokens.circularSmall,
        border: Border.all(color: colors.error),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, color: colors.error, size: 14),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            tr.maxCapacityWarning(maxGuests),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.error,
            ),
          ),
        ],
      ),
    );
  }
}
