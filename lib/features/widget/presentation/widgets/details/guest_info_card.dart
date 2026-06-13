import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import 'widget_card_decoration.dart';
import '../common/detail_row_widget.dart';
import '../../l10n/widget_translations.dart';

/// Card displaying guest information (name, email, phone)
/// Matches design of PropertyInfoCard and BookingDatesCard
class GuestInfoCard extends ConsumerWidget {
  /// Guest name
  final String guestName;

  /// Guest email
  final String guestEmail;

  /// Guest phone (optional)
  final String? guestPhone;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  /// Whether dark mode is active
  final bool isDarkMode;

  const GuestInfoCard({
    super.key,
    required this.guestName,
    required this.guestEmail,
    this.guestPhone,
    required this.colors,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    return Container(
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: premiumWidgetCardDecoration(
        colors: colors,
        isDark: isDarkMode,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header matching other cards
          Text(
            tr.guestInformation,
            style: TextStyle(
              fontSize: BBTypeBridges.fontSizeL,
              fontWeight: BBTypeBridges.weightBold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: BBSpace.sm),
          // Use DetailRowWidget for consistent styling
          DetailRowWidget(
            label: tr.guest,
            value: guestName,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: tr.email,
            value: guestEmail,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
            autoSize: true, // Shrink long emails to fit on one line
          ),
          if (guestPhone != null && guestPhone!.isNotEmpty)
            DetailRowWidget(
              label: tr.phone,
              value: guestPhone!,
              isDarkMode: isDarkMode,
              hasPadding: true,
              valueFontWeight: FontWeight.w400,
            ),
        ],
      ),
    );
  }
}
