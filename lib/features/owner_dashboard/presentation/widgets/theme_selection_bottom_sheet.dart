import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';

/// Theme option model for display
class ThemeOption {
  final ThemeMode mode;
  final String title;
  final String description;
  final IconData icon;

  const ThemeOption({
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Available theme options
const List<ThemeOption> availableThemes = [
  ThemeOption(
    mode: ThemeMode.system,
    title: 'System',
    description: 'Follow system theme',
    icon: Icons.brightness_auto,
  ),
  ThemeOption(
    mode: ThemeMode.light,
    title: 'Light',
    description: 'Light mode',
    icon: Icons.light_mode,
  ),
  ThemeOption(
    mode: ThemeMode.dark,
    title: 'Dark',
    description: 'Dark mode',
    icon: Icons.dark_mode,
  ),
];

/// Show theme selection bottom sheet
Future<void> showThemeSelectionBottomSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const ThemeSelectionBottomSheet(),
  );
}

/// Theme Selection Bottom Sheet
class ThemeSelectionBottomSheet extends ConsumerWidget {
  const ThemeSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(currentThemeModeProvider);

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
                  Icons.palette,
                  size: 28,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Select Theme',
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
              'Choose your preferred color theme',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Theme options
          ...availableThemes.map((theme) {
            final isSelected = theme.mode == currentThemeMode;

            return RadioListTile<ThemeMode>(
              value: theme.mode,
              groupValue: currentThemeMode,
              onChanged: (value) async {
                if (value != null && value != currentThemeMode) {
                  await ref
                      .read(themeNotifierProvider.notifier)
                      .setThemeMode(value);

                  if (context.mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Theme changed to ${theme.title}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              title: Row(
                children: [
                  Icon(
                    theme.icon,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.title,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      Text(
                        theme.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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
