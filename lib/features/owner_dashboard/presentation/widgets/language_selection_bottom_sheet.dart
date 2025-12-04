import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/gradient_extensions.dart';

/// Show language selection bottom sheet
void showLanguageSelectionBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const LanguageSelectionBottomSheet(),
  );
}

/// Language selection bottom sheet widget
class LanguageSelectionBottomSheet extends ConsumerWidget {
  const LanguageSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(currentLocaleProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Language',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // Language options
          _LanguageOption(
            locale: const Locale('hr'),
            title: 'Hrvatski',
            subtitle: 'Croatian',
            isSelected: currentLocale.languageCode == 'hr',
            onTap: () {
              ref.read(languageNotifierProvider.notifier).setLanguage('hr');
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          _LanguageOption(
            locale: const Locale('en'),
            title: 'English',
            subtitle: 'English',
            isSelected: currentLocale.languageCode == 'en',
            onTap: () {
              ref.read(languageNotifierProvider.notifier).setLanguage('en');
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// Language option tile
class _LanguageOption extends StatelessWidget {
  final Locale locale;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.locale,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use colorScheme.primary which is more vibrant than primaryColor
    final selectedColor = theme.colorScheme.primary;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? selectedColor.withValues(alpha: isDark ? 0.35 : 0.15)
              : isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.grey[200],
        ),
        child: Center(
          child: Text(
            locale.languageCode.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? (isDark ? Colors.white : selectedColor)
                  : isDark
                      ? Colors.white
                      : Colors.grey[600],
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: isDark ? Colors.white : selectedColor,
            )
          : null,
      onTap: onTap,
    );
  }
}
