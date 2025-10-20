import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../domain/models/user_preferences.dart';

/// Language selection dialog using modern Flutter Radio API
class LanguageSelectionDialog extends ConsumerStatefulWidget {
  const LanguageSelectionDialog({
    super.key,
  });

  @override
  ConsumerState<LanguageSelectionDialog> createState() =>
      _LanguageSelectionDialogState();

  /// Show language selection dialog
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const LanguageSelectionDialog(),
    );
  }
}

class _LanguageSelectionDialogState extends ConsumerState<LanguageSelectionDialog> {
  bool _isLoading = false;

  Future<void> _handleLanguageChange(String? value) async {
    if (value == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(languageNotifierProvider.notifier).setLanguage(value);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value == 'hr'
                ? 'Jezik promenjen na Hrvatski'
                : 'Language changed to English',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing language: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(currentLocaleProvider);
    final selectedLanguage = currentLocale.languageCode;

    return AlertDialog(
      title: const Text('Odaberi jezik / Select Language'),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: AppLanguage.values.map((language) {
                final isSelected = selectedLanguage == language.code;
                return ListTile(
                  onTap: _isLoading ? null : () => _handleLanguageChange(language.code),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                  title: Text(
                    language.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    language.code.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        )
                      : null,
                );
              }).toList(),
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Odustani / Cancel'),
        ),
      ],
    );
  }
}
