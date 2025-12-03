import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../providers/theme_provider.dart';
import 'calendar_view_switcher_widget.dart';

/// Combined header widget used by both year and month calendar views.
///
/// Contains:
/// - View switcher (year/month toggle)
/// - Theme toggle button (dark/light mode)
/// - Custom navigation widget slot (year nav or month nav)
///
/// This widget is extracted from YearCalendarWidget and MonthCalendarWidget
/// to reduce code duplication (~54 lines per calendar).
class CalendarCombinedHeaderWidget extends ConsumerWidget {
  /// Color scheme for theming
  final WidgetColorScheme colors;

  /// Whether dark mode is currently active
  final bool isDarkMode;

  /// Custom navigation widget (year selector or month selector)
  final Widget navigationWidget;

  const CalendarCombinedHeaderWidget({
    super.key,
    required this.colors,
    required this.isDarkMode,
    required this.navigationWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400; // iPhone SE and similar

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? SpacingTokens.xxs : SpacingTokens.xs,
          vertical: SpacingTokens.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderTokens.circularRounded,
          boxShadow: ShadowTokens.light,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // View Switcher (year/month toggle)
            CalendarViewSwitcherWidget(colors: colors, isDarkMode: isDarkMode),
            SizedBox(width: isSmallScreen ? 4 : SpacingTokens.xxs),

            // Theme Toggle Button
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: isSmallScreen ? 16 : IconSizeTokens.small,
                color: colors.textPrimary,
              ),
              onPressed: () {
                ref.read(themeProvider.notifier).state = !isDarkMode;
              },
              tooltip: isDarkMode
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isSmallScreen
                    ? 28
                    : ConstraintTokens.iconContainerSmall,
                minHeight: isSmallScreen
                    ? 28
                    : ConstraintTokens.iconContainerSmall,
              ),
            ),

            SizedBox(width: isSmallScreen ? 4 : SpacingTokens.xxs),

            // Custom Navigation Widget (year or month navigation)
            navigationWidget,
          ],
        ),
      ),
    );
  }
}
