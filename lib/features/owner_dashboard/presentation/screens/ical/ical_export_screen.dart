import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const IcalExportScreen({
    super.key,
    required this.unit,
    required this.propertyId,
  });

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
          .getWidgetSettings(
            propertyId: widget.propertyId,
            unitId: widget.unit.id,
          );

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
      final bookings = await ref
          .read(bookingRepositoryProvider)
          .fetchUnitBookings(widget.unit.id);

      // 2. Generate .ics content
      final icsContent = IcalGenerator.generateUnitCalendar(
        unit: widget.unit,
        bookings: bookings,
      );

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

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'iCal export generated successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Failed to generate iCal export',
        );
      }
    }
  }

  Future<void> _copyUrlToClipboard() async {
    if (_exportUrl == null) return;

    await Clipboard.setData(ClipboardData(text: _exportUrl!));

    if (mounted) {
      ErrorDisplayUtils.showSuccessSnackBar(context, 'URL copied to clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('iCal Export'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.authSecondary],
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
                          color: AppColors.primary.withAlpha(
                            (0.1 * 255).toInt(),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.apartment,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unit',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              widget.unit.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            label: Text(
              _isGenerating ? 'Generating...' : 'Generate iCal Export',
            ),
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
                    const Row(
                      children: [
                        Icon(Icons.link, size: 20, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Export URL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                      child: SelectableText(
                        _exportUrl!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyUrlToClipboard,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy URL'),
                          ),
                        ),
                      ],
                    ),
                    if (_lastGenerated != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Last generated: ${_formatDateTime(_lastGenerated!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.6 * 255).toInt(),
                          ),
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
                    const Row(
                      children: [
                        Icon(Icons.code, size: 20, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          '.ics File Preview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha(
                            (0.2 * 255).toInt(),
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _icsPreview!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
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
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: AppColors.info),
                      SizedBox(width: 8),
                      Text(
                        'How to Test',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTestInstruction(
                    '1. Google Calendar',
                    'Go to Settings → Add calendar → From URL → Paste the export URL',
                  ),
                  const SizedBox(height: 8),
                  _buildTestInstruction(
                    '2. Apple Calendar',
                    'File → New Calendar Subscription → Paste the export URL',
                  ),
                  const SizedBox(height: 8),
                  _buildTestInstruction(
                    '3. Outlook',
                    'Add calendar → Subscribe from web → Paste the export URL',
                  ),
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
                        const Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Note: Calendar apps may take 5-15 minutes to sync after subscribing',
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
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          instruction,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
