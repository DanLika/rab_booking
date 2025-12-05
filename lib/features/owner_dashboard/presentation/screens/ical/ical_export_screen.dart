import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/ical_generator.dart';
import '../../../../../core/services/ical_export_service.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../core/utils/error_display_utils.dart';

/// Screen for exporting iCal calendar to external calendar apps
///
/// Features:
/// - Manual trigger for iCal generation
/// - Preview of generated .ics content
/// - Copy URL to clipboard
/// - Test instructions for Google/Apple/Outlook calendars
class IcalExportScreen extends ConsumerStatefulWidget {
  final UnitModel unit;
  final String propertyId;

  const IcalExportScreen({super.key, required this.unit, required this.propertyId});

  @override
  ConsumerState<IcalExportScreen> createState() => _IcalExportScreenState();
}

class _IcalExportScreenState extends ConsumerState<IcalExportScreen> {
  bool _isGenerating = false;
  String? _icsPreview;
  String? _exportUrl;
  DateTime? _lastGenerated;

  @override
  void initState() {
    super.initState();
    _loadExistingExport();
  }

  Future<void> _loadExistingExport() async {
    try {
      final settings = await ref
          .read(widgetSettingsRepositoryProvider)
          .getWidgetSettings(propertyId: widget.propertyId, unitId: widget.unit.id);

      if (settings != null && mounted) {
        setState(() {
          _exportUrl = settings.icalExportUrl;
          _lastGenerated = settings.icalExportLastGenerated;
        });
      }
    } catch (e) {
      // Ignore error - will show empty state
    }
  }

  Future<void> _generateIcal() async {
    setState(() {
      _isGenerating = true;
      _icsPreview = null;
    });

    try {
      // 1. Fetch bookings
      final bookings = await ref.read(bookingRepositoryProvider).fetchUnitBookings(widget.unit.id);

      // 2. Generate .ics content
      final icsContent = IcalGenerator.generateUnitCalendar(unit: widget.unit, bookings: bookings);

      // 3. Upload to Firebase Storage
      final exportService = IcalExportService(
        bookingRepository: ref.read(bookingRepositoryProvider),
        settingsRepository: ref.read(widgetSettingsRepositoryProvider),
      );

      final downloadUrl = await exportService.generateAndUploadIcal(
        propertyId: widget.propertyId,
        unitId: widget.unit.id,
        unit: widget.unit,
      );

      if (mounted) {
        setState(() {
          _icsPreview = icsContent;
          _exportUrl = downloadUrl;
          _lastGenerated = DateTime.now();
          _isGenerating = false;
        });

        final l10nSuccess = AppLocalizations.of(context);
        ErrorDisplayUtils.showSuccessSnackBar(context, l10nSuccess.icalExportSuccess);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        final l10nError = AppLocalizations.of(context);
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10nError.icalExportError);
      }
    }
  }

  Future<void> _copyUrlToClipboard() async {
    if (_exportUrl == null) return;

    await Clipboard.setData(ClipboardData(text: _exportUrl!));

    if (mounted) {
      final l10nCopy = AppLocalizations.of(context);
      ErrorDisplayUtils.showSuccessSnackBar(context, l10nCopy.icalExportUrlCopied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.icalExportTitle),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          children: [
            // Unit info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.apartment, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.icalExportUnit,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              Text(widget.unit.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Generate button
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generateIcal,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isGenerating ? l10n.icalExportGenerating : l10n.icalExportGenerate),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Export URL
            if (_exportUrl != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.link, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(l10n.icalExportUrl, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outline.withAlpha((0.2 * 255).toInt())),
                        ),
                        child: SelectableText(
                          _exportUrl!,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _copyUrlToClipboard,
                              icon: const Icon(Icons.copy, size: 18),
                              label: Text(l10n.icalExportCopyUrl),
                            ),
                          ),
                        ],
                      ),
                      if (_lastGenerated != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.icalExportLastGenerated(_formatDateTime(_lastGenerated!, l10n)),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // .ics Preview
            if (_icsPreview != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.code, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.icalExportPreview,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 300,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outline.withAlpha((0.2 * 255).toInt())),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _icsPreview!,
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Test instructions
            Card(
              color: AppColors.info.withAlpha((0.05 * 255).toInt()),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20, color: AppColors.info),
                        const SizedBox(width: 8),
                        Text(
                          l10n.icalExportHowToTest,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTestInstruction(l10n.icalExportGoogleCalendar, l10n.icalExportGoogleInstructions),
                    const SizedBox(height: 8),
                    _buildTestInstruction(l10n.icalExportAppleCalendar, l10n.icalExportAppleInstructions),
                    const SizedBox(height: 8),
                    _buildTestInstruction(l10n.icalExportOutlook, l10n.icalExportOutlookInstructions),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.icalExportSyncNote,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestInstruction(String title, String instruction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(instruction, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return l10n.icalExportJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.icalExportMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.icalExportHoursAgo(difference.inHours);
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
