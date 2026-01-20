import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../design_tokens/spacing_tokens.dart';
import '../models/app_config.dart';
import '../services/logging_service.dart';

/// Optional update dialog - can be dismissed
/// User can choose to update now or later
class OptionalUpdateDialog extends StatelessWidget {
  final AppConfig config;

  const OptionalUpdateDialog({super.key, required this.config});

  static const String _lastReminderKey = 'optional_update_last_reminder';

  /// Check if should show optional update dialog
  /// Returns false if user dismissed it less than 24h ago
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReminder = prefs.getInt(_lastReminderKey);

    if (lastReminder == null) return true;

    final lastReminderTime = DateTime.fromMillisecondsSinceEpoch(lastReminder);
    final now = DateTime.now();
    final difference = now.difference(lastReminderTime);

    // Show again after 24 hours
    return difference.inHours >= 24;
  }

  /// Mark that user dismissed the dialog
  static Future<void> markReminded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReminderKey, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(
            Icons.new_releases_outlined,
            color: colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: SpacingTokens.s2),
          Expanded(
            child: Text(
              t.optionalUpdateTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.updateMessage ?? t.optionalUpdateMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: SpacingTokens.m),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.s2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: SpacingTokens.s),
                Expanded(
                  child: Text(
                    t.optionalUpdateVersion(config.latestVersion),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await markReminded();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text(t.optionalUpdateLater),
        ),
        FilledButton.icon(
          onPressed: () => _openStore(context, config),
          icon: const Icon(Icons.download, size: 20),
          label: Text(t.optionalUpdateNow),
        ),
      ],
    );
  }

  Future<void> _openStore(BuildContext context, AppConfig config) async {
    final storeUrl =
        config.storeUrl ??
        'https://play.google.com/store/apps/details?id=io.bookbed.app';

    try {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Close dialog after opening store
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } else {
        unawaited(
          LoggingService.logError(
            'OptionalUpdateDialog: Cannot launch URL',
            Exception('URL cannot be launched: $storeUrl'),
            StackTrace.current,
          ),
        );
      }
    } catch (e, stackTrace) {
      unawaited(
        LoggingService.logError(
          'OptionalUpdateDialog: Failed to open store',
          e,
          stackTrace,
        ),
      );
    }
  }
}
