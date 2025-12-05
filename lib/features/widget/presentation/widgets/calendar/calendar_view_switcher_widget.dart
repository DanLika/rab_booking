import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/calendar_view_type.dart';
import '../../providers/calendar_view_provider.dart';
import '../../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/theme/custom_icons_tablericons.dart';
import '../../l10n/widget_translations.dart';

/// Reusable Month/Year view toggle used by both calendar widgets.
///
/// This widget provides consistent view switching UI across
/// MonthCalendarWidget and YearCalendarWidget.
class CalendarViewSwitcherWidget extends ConsumerWidget {
  final WidgetColorScheme colors;
  final bool isDarkMode;
  final WidgetTranslations translations;

  const CalendarViewSwitcherWidget({
    super.key,
    required this.colors,
    required this.isDarkMode,
    required this.translations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(calendarViewProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400; // iPhone SE and similar

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 2 : 4),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewTab(
            ref: ref,
            label: translations.monthView,
            icon: TablerIcons.ktableFilled,
            viewType: CalendarViewType.month,
            isSelected: currentView == CalendarViewType.month,
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(width: isSmallScreen ? 2 : 4),
          _buildViewTab(
            ref: ref,
            label: translations.yearView,
            icon: TablerIcons.ktableOptions,
            viewType: CalendarViewType.year,
            isSelected: currentView == CalendarViewType.year,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab({
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required CalendarViewType viewType,
    required bool isSelected,
    required bool isSmallScreen,
  }) {
    // Dark theme: selected button has white background with black text
    // Light theme: selected button has black background with white text
    final selectedBg = isDarkMode ? ColorTokens.pureWhite : ColorTokens.pureBlack;
    final selectedText = isDarkMode ? ColorTokens.pureBlack : ColorTokens.pureWhite;

    return Semantics(
      label: '$label view',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () {
          ref.read(calendarViewProvider.notifier).state = viewType;
        },
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? selectedText : colors.textPrimary,
                size: isSmallScreen ? 16 : IconSizeTokens.small,
                semanticLabel: label,
              ),
              if (!isSmallScreen) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? selectedText : colors.textPrimary,
                    fontSize: TypographyTokens.fontSizeS2,
                    fontWeight: isSelected ? TypographyTokens.semiBold : TypographyTokens.regular,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
