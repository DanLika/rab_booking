import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../shared/providers/repository_providers.dart' as repos;
import '../../../../widget/domain/models/widget_settings.dart';
import 'package:go_router/go_router.dart';

/// iCal Export Settings Card
///
/// Extracted from widget_advanced_settings_screen.dart to reduce nesting.
/// Contains:
/// - Master toggle for enabling/disabling iCal export
/// - Export URL display (if exists)
/// - Last generated timestamp
/// - Test iCal Export button
/// - Info message
class IcalExportCard extends ConsumerWidget {
  final String propertyId;
  final String unitId;
  final WidgetSettings settings;
  final bool icalExportEnabled;
  final ValueChanged<bool> onEnabledChanged;

  const IcalExportCard({
    super.key,
    required this.propertyId,
    required this.unitId,
    required this.settings,
    required this.icalExportEnabled,
    required this.onEnabledChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        initiallyExpanded: icalExportEnabled,
        leading: _buildLeadingIcon(),
        title: const Text(
          'iCal Export',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          icalExportEnabled ? 'Enabled' : 'Disabled',
          style: TextStyle(
            fontSize: 13,
            color: icalExportEnabled
                ? AppColors.success
                : AppColors.textSecondary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Master toggle
                _buildMasterToggle(),

                if (icalExportEnabled) ...[
                  const Divider(height: 24),
                  const Text(
                    'Export Information',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // Export URL display (if exists)
                  if (settings.icalExportUrl != null)
                    _buildExportUrlDisplay(theme),

                  // Last generated timestamp
                  if (settings.icalExportLastGenerated != null)
                    _buildLastGeneratedInfo(theme),

                  // Test iCal Export Button
                  _buildTestExportButton(context, ref),

                  // Info message
                  _buildInfoMessage(theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withAlpha((0.15 * 255).toInt()),
            AppColors.info.withAlpha((0.08 * 255).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.calendar_today,
        color: AppColors.info,
        size: 20,
      ),
    );
  }

  Widget _buildMasterToggle() {
    return SwitchListTile(
      value: icalExportEnabled,
      onChanged: onEnabledChanged,
      title: const Text('Enable iCal Export'),
      subtitle: const Text(
        'Generate public iCal URL for external calendar sync',
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildExportUrlDisplay(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha(
                (0.2 * 255).toInt(),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Export URL',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                settings.icalExportUrl!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(
                    (0.7 * 255).toInt(),
                  ),
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLastGeneratedInfo(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.update,
              size: 16,
              color: theme.colorScheme.onSurface.withAlpha(
                (0.6 * 255).toInt(),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Last generated: ${_formatLastGenerated(settings.icalExportLastGenerated!)}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.6 * 255).toInt(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTestExportButton(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            try {
              // Load unit data from property's units subcollection
              final units = await ref
                  .read(repos.unitRepositoryProvider)
                  .fetchUnitsByProperty(propertyId);
              final unit = units
                  .where((u) => u.id == unitId)
                  .firstOrNull;

              if (unit != null && context.mounted) {
                await context.push(
                  OwnerRoutes.icalExport,
                  extra: {
                    'unit': unit,
                    'propertyId': propertyId,
                  },
                );
              }
            } catch (e) {
              if (context.mounted) {
                ErrorDisplayUtils.showErrorSnackBar(
                  context,
                  e,
                  userMessage: 'Failed to load unit data',
                );
              }
            }
          },
          icon: const Icon(Icons.bug_report, size: 18),
          label: const Text('Test iCal Export'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.info,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'iCal export will be auto-generated when bookings change. Use the generated URL to sync with external calendars.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.7 * 255).toInt(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastGenerated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
