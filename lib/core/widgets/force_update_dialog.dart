import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../design_tokens/spacing_tokens.dart';
import '../models/app_config.dart';
import '../services/logging_service.dart';

/// Force update dialog - cannot be dismissed
/// User must update the app to continue
class ForceUpdateDialog extends StatelessWidget {
  final AppConfig config;

  const ForceUpdateDialog({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false, // Cannot dismiss with back button
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.system_update_alt, color: colorScheme.primary, size: 28),
            const SizedBox(width: SpacingTokens.m),
            Expanded(
              child: Text(
                t.forceUpdateTitle,
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
              config.updateMessage ?? t.forceUpdateMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: SpacingTokens.l),
            Container(
              padding: const EdgeInsets.all(SpacingTokens.m),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingTokens.s),
                  Expanded(
                    child: Text(
                      t.forceUpdateRequiredVersion(config.minRequiredVersion),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openStore(context, config),
              icon: const Icon(Icons.download),
              label: Text(t.forceUpdateButton),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.m),
              ),
            ),
          ),
        ],
      ),
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
      } else {
        unawaited(
          LoggingService.logError(
            'ForceUpdateDialog: Cannot launch URL',
            Exception('URL cannot be launched: $storeUrl'),
            StackTrace.current,
          ),
        );
      }
    } catch (e, stackTrace) {
      unawaited(
        LoggingService.logError(
          'ForceUpdateDialog: Failed to open store',
          e,
          stackTrace,
        ),
      );
    }
  }
}
