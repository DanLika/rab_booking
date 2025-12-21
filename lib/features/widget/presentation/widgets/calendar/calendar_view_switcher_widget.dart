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
  // Breakpoints for responsive sizing
  // Note: 450px covers most phones in portrait mode (iPhone 14 Pro Max is 430px)
  static const double _smallScreenBreakpoint = 450;
  static const double _tinyScreenBreakpoint = 360; // iPhone SE, Galaxy S small

  // Spacing values
  static const double _paddingTiny = 1;
  static const double _paddingSmall = 2;
  static const double _paddingNormal = 4;
  static const double _gapTiny = 1;
  static const double _gapSmall = 2;
  static const double _gapNormal = 4;
  static const double _horizontalPaddingTiny = 6;
  static const double _horizontalPaddingSmall = 8;
  static const double _horizontalPaddingNormal = 12;
  static const double _verticalPaddingTiny = 4;
  static const double _verticalPaddingSmall = 6;
  static const double _verticalPaddingNormal = 8;

  // Border radius values
  static const double _borderRadiusTiny = 10;
  static const double _borderRadiusSmall = 12;
  static const double _borderRadiusNormal = 16;
  static const double _containerRadiusTiny = 14;
  static const double _containerRadiusSmall = 16;
  static const double _containerRadiusNormal = 20;

  // Icon sizes
  static const double _iconSizeTiny = 14;
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
    // Bug #41 Fix: Use maybeOf with fallback for defensive null handling
    final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 400.0;
    final isSmallScreen = screenWidth < _smallScreenBreakpoint;
    final isTinyScreen = screenWidth < _tinyScreenBreakpoint;

    final padding = isTinyScreen
        ? _paddingTiny
        : isSmallScreen
            ? _paddingSmall
            : _paddingNormal;
    final gap = isTinyScreen
        ? _gapTiny
        : isSmallScreen
            ? _gapSmall
            : _gapNormal;
    final containerRadius = isTinyScreen
        ? _containerRadiusTiny
        : isSmallScreen
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
            isTinyScreen: isTinyScreen,
          ),
          SizedBox(width: gap),
          _buildViewTab(
            ref: ref,
            label: translations.yearView,
            icon: TablerIcons.ktableOptions,
            viewType: CalendarViewType.year,
            isSelected: currentView == CalendarViewType.year,
            isSmallScreen: isSmallScreen,
            isTinyScreen: isTinyScreen,
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
    required bool isTinyScreen,
  }) {
    // Dark theme: selected button has white background with black text
    // Light theme: selected button has black background with white text
    final selectedBg = isDarkMode
        ? ColorTokens.pureWhite
        : ColorTokens.pureBlack;
    final selectedText = isDarkMode
        ? ColorTokens.pureBlack
        : ColorTokens.pureWhite;

    final borderRadius = isTinyScreen
        ? _borderRadiusTiny
        : isSmallScreen
            ? _borderRadiusSmall
            : _borderRadiusNormal;
    final horizontalPadding = isTinyScreen
        ? _horizontalPaddingTiny
        : isSmallScreen
            ? _horizontalPaddingSmall
            : _horizontalPaddingNormal;
    final verticalPadding = isTinyScreen
        ? _verticalPaddingTiny
        : isSmallScreen
            ? _verticalPaddingSmall
            : _verticalPaddingNormal;
    final iconSize = isTinyScreen
        ? _iconSizeTiny
        : isSmallScreen
            ? _iconSizeSmall
            : IconSizeTokens.small;

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
