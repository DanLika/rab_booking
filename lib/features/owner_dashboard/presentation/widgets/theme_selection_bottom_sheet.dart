import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/responsive_spacing_helper.dart';

/// Show theme selection bottom sheet
void showThemeSelectionBottomSheet(BuildContext context, WidgetRef ref) {
  final screenHeight = MediaQuery.of(context).size.height;
  final maxHeightPercent = ResponsiveSpacingHelper.getBottomSheetMaxHeightPercent(context);
  final maxSheetHeight = screenHeight * maxHeightPercent;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: maxSheetHeight),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (context) => const ThemeSelectionBottomSheet(),
  );
}

/// Theme selection bottom sheet widget
class ThemeSelectionBottomSheet extends ConsumerWidget {
  const ThemeSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(currentThemeModeProvider);
    final l10n = AppLocalizations.of(context);
    final headerPadding = ResponsiveSpacingHelper.getHeaderPadding(context);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (fixed)
          Padding(
            padding: headerPadding,
            child: Row(
              children: [
                Icon(Icons.brightness_6_outlined, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.themeSelectionTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Theme options (scrollable)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ThemeOption(
                    themeMode: ThemeMode.light,
                    icon: Icons.light_mode,
                    title: l10n.themeSelectionLight,
                    subtitle: l10n.themeSelectionLightDesc,
                    isSelected: currentThemeMode == ThemeMode.light,
                    onTap: () {
                      Navigator.of(context).pop();
                      // Delay theme change to after modal closes to prevent rebuild during animation
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.light);
                      });
                    },
                  ),
                  const Divider(height: 1, indent: 24, endIndent: 24),
                  _ThemeOption(
                    themeMode: ThemeMode.dark,
                    icon: Icons.dark_mode,
                    title: l10n.themeSelectionDark,
                    subtitle: l10n.themeSelectionDarkDesc,
                    isSelected: currentThemeMode == ThemeMode.dark,
                    onTap: () {
                      Navigator.of(context).pop();
                      // Delay theme change to after modal closes to prevent rebuild during animation
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.dark);
                      });
                    },
                  ),
                  const Divider(height: 1, indent: 24, endIndent: 24),
                  _ThemeOption(
                    themeMode: ThemeMode.system,
                    icon: Icons.brightness_auto,
                    title: l10n.themeSelectionSystem,
                    subtitle: l10n.themeSelectionSystemDesc,
                    isSelected: currentThemeMode == ThemeMode.system,
                    onTap: () {
                      Navigator.of(context).pop();
                      // Delay theme change to after modal closes to prevent rebuild during animation
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.system);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
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
        child: Icon(
          icon,
          color: isSelected
              ? (isDark ? Colors.white : selectedColor)
              : isDark
              ? Colors.white
              : Colors.grey[600],
        ),
      ),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check_circle, color: isDark ? Colors.white : selectedColor) : null,
      onTap: onTap,
    );
  }
}
