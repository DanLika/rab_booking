import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
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
  final bool isMobile;

  const IcalExportCard({
    super.key,
    required this.propertyId,
    required this.unitId,
    required this.settings,
    required this.icalExportEnabled,
    required this.onEnabledChanged,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: theme.brightness == Brightness.dark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            // TIP 1: JEDNOSTAVNI DIJAGONALNI GRADIENT (2 boje, 2 stops)
            // topRight → bottomLeft za section
            gradient: context.gradients.sectionBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.borderColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: icalExportEnabled,
            leading: _buildLeadingIcon(theme),
            title: Text(
              'iCal Export',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              icalExportEnabled ? 'Enabled' : 'Disabled',
              style: theme.textTheme.bodySmall?.copyWith(
                color: icalExportEnabled
                    ? AppColors.success
                    : context.textColorSecondary,
              ),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Master toggle
                    _buildMasterToggle(),

                    if (icalExportEnabled) ...[
                      const Divider(height: 24),
                      Text(
                        'Export Information',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(
          (0.12 * 255).toInt(),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.calendar_today,
        color: theme.colorScheme.primary,
        size: 18,
      ),
    );
  }

  Widget _buildMasterToggle() {
    return SwitchListTile(
      value: icalExportEnabled,
      onChanged: (value) async {
        // Call parent's onEnabledChanged first
        onEnabledChanged(value);

        // If enabling, generate URL and token
        if (value && settings.icalExportUrl == null) {
          await _generateIcalUrl();
        }
      },
      title: const Text('Enable iCal Export'),
      subtitle: const Text(
        'Generate public iCal URL for external calendar sync',
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _generateIcalUrl() async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateIcalExportUrl');

      await callable.call({'propertyId': propertyId, 'unitId': unitId});

      // Success - URL will be loaded on next widget refresh
    } catch (e) {
      debugPrint('Error generating iCal URL: $e');
      // Error handling - parent widget will handle via stream
    }
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
              color: theme.colorScheme.outline.withAlpha((0.2 * 255).toInt()),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Export URL',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                settings.icalExportUrl!,
                style: theme.textTheme.bodySmall?.copyWith(
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
              color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
            ),
            const SizedBox(width: 8),
            Text(
              'Last generated: ${_formatLastGenerated(settings.icalExportLastGenerated!)}',
              style: theme.textTheme.bodySmall?.copyWith(
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
              final unit = units.where((u) => u.id == unitId).firstOrNull;

              if (unit != null && context.mounted) {
                await context.push(
                  OwnerRoutes.icalExport,
                  extra: {'unit': unit, 'propertyId': propertyId},
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          const Icon(Icons.info_outline, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'iCal export will be auto-generated when bookings change. Use the generated URL to sync with external calendars.',
              style: theme.textTheme.bodySmall?.copyWith(
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
