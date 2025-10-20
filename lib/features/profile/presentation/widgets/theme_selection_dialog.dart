import 'package:flutter/material.dart';
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
      content: RadioGroup<String>(
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedTheme = value);
            widget.onThemeSelected(value);
            Navigator.of(context).pop();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((themeMode) {
            final isSelected = _selectedTheme == themeMode.code;
            return RadioListTile<String>(
              value: themeMode.code,
              title: Text(
                themeMode.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                _getThemeDescription(themeMode),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              secondary: Icon(
                _getThemeIcon(themeMode),
                color: isSelected ? const Color(0xFF667eea) : Colors.grey,
              ),
              activeColor: const Color(0xFF667eea),
            );
          }).toList(),
        ),
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
