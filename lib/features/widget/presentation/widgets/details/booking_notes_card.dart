import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import 'widget_card_decoration.dart';
import '../../../../../core/design/tokens.dart';
import '../../l10n/widget_translations.dart';

/// Card displaying additional booking notes.
///
/// Shows notes text from guest with icon header.
///
/// Usage:
/// ```dart
/// BookingNotesCard(
///   notes: 'Late arrival expected around 10 PM',
///   colors: ColorTokens.light,
/// )
/// ```
class BookingNotesCard extends ConsumerWidget {
  /// Notes text
  final String notes;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const BookingNotesCard({
    super.key,
    required this.notes,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bug #61 Fix: Check for empty notes string
    if (notes.isEmpty) {
      return const SizedBox.shrink();
    }

    final tr = WidgetTranslations.of(context, ref);
    // Detect dark mode for better contrast
    final isDark = colors.backgroundPrimary.computeLuminance() < 0.5;
    return Container(
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: premiumWidgetCardDecoration(colors: colors, isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, size: 20, color: colors.textSecondary),
              const SizedBox(width: BBSpace.xxs),
              Text(
                tr.additionalNotes,
                style: TextStyle(
                  fontSize: BBTypeBridges.fontSizeM,
                  fontWeight: BBTypeBridges.weightBold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: BBSpace.xs),
          Text(
            notes,
            style: TextStyle(
              fontSize: BBTypeBridges.fontSizeS,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
