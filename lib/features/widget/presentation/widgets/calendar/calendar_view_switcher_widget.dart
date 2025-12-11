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
  // Breakpoint for small screens (iPhone SE and similar)
  static const double _smallScreenBreakpoint = 400;

  // Spacing values
  static const double _paddingSmall = 2;
  static const double _paddingNormal = 4;
  static const double _gapSmall = 2;
  static const double _gapNormal = 4;
  static const double _horizontalPaddingSmall = 8;
  static const double _horizontalPaddingNormal = 12;
  static const double _verticalPaddingSmall = 6;
  static const double _verticalPaddingNormal = 8;

  // Border radius values
  static const double _borderRadiusSmall = 12;
  static const double _borderRadiusNormal = 16;
  static const double _containerRadiusSmall = 16;
  static const double _containerRadiusNormal = 20;

  // Icon size for small screens
  static const double _iconSizeSmall = 16;

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
    final isSmallScreen = screenWidth < _smallScreenBreakpoint;

    final padding = isSmallScreen ? _paddingSmall : _paddingNormal;
    final gap = isSmallScreen ? _gapSmall : _gapNormal;
    final containerRadius = isSmallScreen
        ? _containerRadiusSmall
        : _containerRadiusNormal;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        borderRadius: BorderRadius.circular(containerRadius),
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
          SizedBox(width: gap),
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
    final selectedBg = isDarkMode
        ? ColorTokens.pureWhite
        : ColorTokens.pureBlack;
    final selectedText = isDarkMode
        ? ColorTokens.pureBlack
        : ColorTokens.pureWhite;

    final borderRadius = isSmallScreen
        ? _borderRadiusSmall
        : _borderRadiusNormal;
    final horizontalPadding = isSmallScreen
        ? _horizontalPaddingSmall
        : _horizontalPaddingNormal;
    final verticalPadding = isSmallScreen
        ? _verticalPaddingSmall
        : _verticalPaddingNormal;
    final iconSize = isSmallScreen ? _iconSizeSmall : IconSizeTokens.small;

    return Semantics(
      label: '$label view',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () {
          ref.read(calendarViewProvider.notifier).state = viewType;
        },
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? selectedText : colors.textPrimary,
                size: iconSize,
                semanticLabel: label,
              ),
              if (!isSmallScreen) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? selectedText : colors.textPrimary,
                    fontSize: TypographyTokens.fontSizeS2,
                    fontWeight: isSelected
                        ? TypographyTokens.semiBold
                        : TypographyTokens.regular,
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
