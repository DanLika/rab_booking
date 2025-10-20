import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/user_preferences.dart';

/// Theme selection dialog
class ThemeSelectionDialog extends StatefulWidget {
  final String currentTheme;
  final Function(String) onThemeSelected;

  const ThemeSelectionDialog({
    required this.currentTheme,
    required this.onThemeSelected,
    super.key,
  });

  @override
  State<ThemeSelectionDialog> createState() => _ThemeSelectionDialogState();

  /// Show theme selection dialog
  static Future<void> show(
    BuildContext context, {
    required String currentTheme,
    required Function(String) onThemeSelected,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => ThemeSelectionDialog(
        currentTheme: currentTheme,
        onThemeSelected: onThemeSelected,
      ),
    );
  }
}

class _ThemeSelectionDialogState extends State<ThemeSelectionDialog> {
  late String _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Odaberi temu'),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: AppThemeMode.values.map((themeMode) {
          final isSelected = _selectedTheme == themeMode.code;
          return ListTile(
            onTap: () {
              setState(() => _selectedTheme = themeMode.code);
              widget.onThemeSelected(themeMode.code);
              Navigator.of(context).pop();
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            leading: Icon(
              _getThemeIcon(themeMode),
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            title: Text(
              themeMode.displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              _getThemeDescription(themeMode),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            trailing: isSelected
                ? const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  )
                : const Icon(
                    Icons.radio_button_unchecked,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Odustani'),
        ),
      ],
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Uvijek svijetla tema';
      case AppThemeMode.dark:
        return 'Uvijek tamna tema';
      case AppThemeMode.system:
        return 'Prati postavke sustava';
    }
  }
}
