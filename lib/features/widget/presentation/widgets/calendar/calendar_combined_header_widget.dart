import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/web_utils.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/widget_translations.dart';
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

  /// Translations for localization
  final WidgetTranslations translations;

  const CalendarCombinedHeaderWidget({
    super.key,
    required this.colors,
    required this.isDarkMode,
    required this.navigationWidget,
    required this.translations,
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
          color: colors.backgroundTertiary,
          borderRadius: BorderTokens.circularRounded,
          boxShadow: ShadowTokens.light,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // View Switcher (year/month toggle)
            CalendarViewSwitcherWidget(colors: colors, isDarkMode: isDarkMode, translations: translations),
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
              tooltip: isDarkMode ? translations.tooltipSwitchToLightMode : translations.tooltipSwitchToDarkMode,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
                minHeight: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
              ),
            ),

            // Language Switcher Button
            _LanguageSwitcherButton(
              colors: colors,
              isSmallScreen: isSmallScreen,
              currentLanguage: translations.locale.languageCode,
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

/// Language switcher button with popup menu
class _LanguageSwitcherButton extends StatelessWidget {
  final WidgetColorScheme colors;
  final bool isSmallScreen;
  final String currentLanguage;

  const _LanguageSwitcherButton({required this.colors, required this.isSmallScreen, required this.currentLanguage});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getFlagEmoji(currentLanguage), style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
          Icon(Icons.arrow_drop_down, size: isSmallScreen ? 14 : 16, color: colors.textPrimary),
        ],
      ),
      tooltip: WidgetTranslations.of(context).tooltipChangeLanguage,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: isSmallScreen ? 40 : 48,
        minHeight: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
      ),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularMedium),
      color: colors.backgroundPrimary,
      onSelected: _changeLanguage,
      itemBuilder: (BuildContext context) => [
        _buildLanguageItem('hr', 'Hrvatski', '🇭🇷'),
        _buildLanguageItem('en', 'English', '🇬🇧'),
        _buildLanguageItem('de', 'Deutsch', '🇩🇪'),
        _buildLanguageItem('it', 'Italiano', '🇮🇹'),
      ],
    );
  }

  PopupMenuItem<String> _buildLanguageItem(String code, String name, String flag) {
    final isSelected = currentLanguage == code;
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colors.primary : colors.textPrimary,
            ),
          ),
          if (isSelected) ...[const Spacer(), Icon(Icons.check, size: 18, color: colors.primary)],
        ],
      ),
    );
  }

  String _getFlagEmoji(String languageCode) {
    switch (languageCode) {
      case 'hr':
        return '🇭🇷';
      case 'en':
        return '🇬🇧';
      case 'de':
        return '🇩🇪';
      case 'it':
        return '🇮🇹';
      default:
        return '🇭🇷';
    }
  }

  void _changeLanguage(String languageCode) {
    if (!kIsWeb) return;

    // Get current URL and update lang parameter
    final currentUrl = Uri.base;
    final newParams = Map<String, String>.from(currentUrl.queryParameters);
    newParams['lang'] = languageCode;

    final newUrl = currentUrl.replace(queryParameters: newParams);

    // Reload page with new language
    navigateToUrl(newUrl.toString());
  }
}
