import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';

/// Language model for display
class LanguageOption {
  final String code;
  final String nativeName;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.nativeName,
    required this.flag,
  });
}

/// Available languages
const List<LanguageOption> availableLanguages = [
  LanguageOption(
    code: 'en',
    nativeName: 'English',
    flag: '🇬🇧',
  ),
  LanguageOption(
    code: 'hr',
    nativeName: 'Hrvatski',
    flag: '🇭🇷',
  ),
];

/// Show language selection bottom sheet
Future<void> showLanguageSelectionBottomSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const LanguageSelectionBottomSheet(),
  );
}

/// Language Selection Bottom Sheet
class LanguageSelectionBottomSheet extends ConsumerWidget {
  const LanguageSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(currentLocaleProvider);
    final currentLanguageCode = currentLocale.languageCode;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.language,
                  size: 28,
                  color: Theme.of(context).primaryColor,
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
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Choose your preferred language',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Language options
          ...availableLanguages.map((lang) {
            final isSelected = lang.code == currentLanguageCode;

            return RadioListTile<String>(
              value: lang.code,
              groupValue: currentLanguageCode,
              onChanged: (value) async {
                if (value != null && value != currentLanguageCode) {
                  await ref
                      .read(languageNotifierProvider.notifier)
                      .setLanguage(value);

                  if (context.mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language changed to ${lang.nativeName}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              title: Row(
                children: [
                  Text(
                    lang.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    lang.nativeName,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              secondary: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
            );
          }),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
