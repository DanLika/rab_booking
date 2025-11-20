import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';

/// Show theme selection bottom sheet
void showThemeSelectionBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const ThemeSelectionBottomSheet(),
  );
}

/// Theme selection bottom sheet widget
class ThemeSelectionBottomSheet extends ConsumerWidget {
  const ThemeSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(currentThemeModeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  Icons.brightness_6_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
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
          const SizedBox(height: 16),
          const Divider(height: 1),

          // Theme options
          _ThemeOption(
            themeMode: ThemeMode.light,
            icon: Icons.light_mode,
            title: 'Light',
            subtitle: 'Always use light theme',
            isSelected: currentThemeMode == ThemeMode.light,
            onTap: () {
              ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.light);
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          _ThemeOption(
            themeMode: ThemeMode.dark,
            icon: Icons.dark_mode,
            title: 'Dark',
            subtitle: 'Always use dark theme',
            isSelected: currentThemeMode == ThemeMode.dark,
            onTap: () {
              ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.dark);
              Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),
          _ThemeOption(
            themeMode: ThemeMode.system,
            icon: Icons.brightness_auto,
            title: 'System Default',
            subtitle: 'Follow system theme',
            isSelected: currentThemeMode == ThemeMode.system,
            onTap: () {
              ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.system);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// Theme option tile
class _ThemeOption extends StatelessWidget {
  final ThemeMode themeMode;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.themeMode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.grey[200],
        ),
        child: Icon(
          icon,
          color: isSelected
              ? theme.primaryColor
              : isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                  : Colors.grey[600],
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
              color: Theme.of(context).primaryColor,
            )
          : null,
      onTap: onTap,
    );
  }
}
