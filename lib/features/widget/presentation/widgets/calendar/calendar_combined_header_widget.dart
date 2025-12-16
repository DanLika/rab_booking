import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/web_utils.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
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

  // Layout constants
  static const _smallScreenBreakpoint = 400.0;
  static const _smallIconSize = 16.0;
  static const _smallContainerSize = 28.0;
  static const _shadowAlpha = 0.04;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < _smallScreenBreakpoint;

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
          border: Border.all(color: colors.borderDefault),
          // Subtle elevation - matches banner and contact pill bar style
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _shadowAlpha),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // View Switcher (year/month toggle)
            CalendarViewSwitcherWidget(
              colors: colors,
              isDarkMode: isDarkMode,
              translations: translations,
            ),
            SizedBox(
              width: isSmallScreen ? SpacingTokens.xxs : SpacingTokens.xs,
            ),

            // Theme Toggle Button
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: isSmallScreen ? _smallIconSize : IconSizeTokens.small,
                color: colors.textPrimary,
              ),
              onPressed: () {
                ref.read(themeProvider.notifier).state = !isDarkMode;
              },
              tooltip: isDarkMode
                  ? translations.tooltipSwitchToLightMode
                  : translations.tooltipSwitchToDarkMode,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isSmallScreen
                    ? _smallContainerSize
                    : ConstraintTokens.iconContainerSmall,
                minHeight: isSmallScreen
                    ? _smallContainerSize
                    : ConstraintTokens.iconContainerSmall,
              ),
            ),

            // Language Switcher Button
            SizedBox(
              width: isSmallScreen ? SpacingTokens.xxs : SpacingTokens.xs,
            ),
            _LanguageSwitcherButton(
              colors: colors,
              isSmallScreen: isSmallScreen,
            ),

            SizedBox(
              width: isSmallScreen ? SpacingTokens.xxs : SpacingTokens.xs,
            ),

            // Custom Navigation Widget (year or month navigation)
            navigationWidget,
          ],
        ),
      ),
    );
  }
}

/// Language switcher button with popup menu
class _LanguageSwitcherButton extends ConsumerWidget {
  final WidgetColorScheme colors;
  final bool isSmallScreen;

  const _LanguageSwitcherButton({
    required this.colors,
    required this.isSmallScreen,
  });

  // Size constants
  static const _smallFontSize = 14.0;
  static const _normalFontSize = 16.0;
  static const _smallButtonWidth = 40.0;
  static const _normalButtonWidth = 48.0;
  static const _menuOffset = 40.0;
  static const _menuItemFontSize = 18.0;
  static const _menuItemSpacing = 12.0;
  static const _checkIconSize = 18.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getFlagEmoji(currentLanguage),
            style: TextStyle(
              fontSize: isSmallScreen ? _smallFontSize : _normalFontSize,
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            size: isSmallScreen ? _smallFontSize : _normalFontSize,
            color: colors.textPrimary,
          ),
        ],
      ),
      tooltip: WidgetTranslations.of(context, ref).tooltipChangeLanguage,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: isSmallScreen ? _smallButtonWidth : _normalButtonWidth,
        minHeight: isSmallScreen
            ? CalendarCombinedHeaderWidget._smallContainerSize
            : ConstraintTokens.iconContainerSmall,
      ),
      offset: const Offset(0, _menuOffset),
      shape: RoundedRectangleBorder(borderRadius: BorderTokens.circularMedium),
      color: colors.backgroundPrimary,
      onSelected: (code) => _changeLanguage(code, ref),
      itemBuilder: (BuildContext context) => [
        _buildLanguageItem('hr', 'Hrvatski', '🇭🇷', currentLanguage),
        _buildLanguageItem('en', 'English', '🇬🇧', currentLanguage),
        _buildLanguageItem('de', 'Deutsch', '🇩🇪', currentLanguage),
        _buildLanguageItem('it', 'Italiano', '🇮🇹', currentLanguage),
      ],
    );
  }

  PopupMenuItem<String> _buildLanguageItem(
    String code,
    String name,
    String flag,
    String currentLanguage,
  ) {
    final isSelected = currentLanguage == code;
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: _menuItemFontSize)),
          const SizedBox(width: _menuItemSpacing),
          Text(
            name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colors.primary : colors.textPrimary,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: _checkIconSize, color: colors.primary),
          ],
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
        // Use globe emoji for unknown languages (neutral fallback)
        return '🌐';
    }
  }

  void _changeLanguage(String languageCode, WidgetRef ref) {
    if (!kIsWeb) return;

    // Update provider (triggers instant rebuild without page reload)
    ref.read(languageProvider.notifier).state = languageCode;

    // Update URL without reload (for persistence/sharing)
    final currentUrl = Uri.base;
    final newParams = Map<String, String>.from(currentUrl.queryParameters);
    newParams['lang'] = languageCode;
    final newUrl = currentUrl.replace(queryParameters: newParams);

    // Use replaceState instead of navigateToUrl (no reload!)
    replaceUrlState(newUrl.toString());
  }
}
