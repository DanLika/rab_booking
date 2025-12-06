import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/services/ical_generator.dart';
import '../../../../../core/services/ical_export_service.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../../../core/utils/error_display_utils.dart';

/// Status indicator colors
const Color _kStatusActiveColor = Color(0xFF66BB6A);
const Color _kStatusPendingColor = Color(0xFFFFA726);

/// Screen for exporting iCal calendar to external calendar apps
/// Redesigned: Premium feel with consistent theme support
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
  bool _showPreview = false;
  int? _expandedCalendar;

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
      final bookings = await ref.read(bookingRepositoryProvider).fetchUnitBookings(widget.unit.id);
      final icsContent = IcalGenerator.generateUnitCalendar(unit: widget.unit, bookings: bookings);

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

        ErrorDisplayUtils.showSuccessSnackBar(context, AppLocalizations.of(context).icalExportSuccess);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: AppLocalizations.of(context).icalExportError);
      }
    }
  }

  Future<void> _copyUrlToClipboard() async {
    if (_exportUrl == null) return;

    await Clipboard.setData(ClipboardData(text: _exportUrl!));

    if (mounted) {
      ErrorDisplayUtils.showSuccessSnackBar(context, AppLocalizations.of(context).icalExportUrlCopied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.icalExportTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (_) => Navigator.of(context).pop(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isDesktop ? 48.0 : (isTablet ? 32.0 : 16.0);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1200.0 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Card
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isDesktop ? 800.0 : double.infinity),
                        child: _buildHeroCard(context),
                      ),
                      const SizedBox(height: 24),

                      // Desktop: URL + Instructions side by side
                      if (isDesktop) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildExportUrlSection(context)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildCalendarInstructions(context)),
                          ],
                        ),
                        if (_icsPreview != null) ...[const SizedBox(height: 24), _buildPreviewSection(context)],
                      ] else ...[
                        // Mobile/Tablet: Stack vertically
                        _buildExportUrlSection(context),
                        const SizedBox(height: 24),
                        _buildCalendarInstructions(context),
                        if (_icsPreview != null) ...[const SizedBox(height: 24), _buildPreviewSection(context)],
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final hasUrl = _exportUrl != null;
    final statusColor = hasUrl ? _kStatusActiveColor : _kStatusPendingColor;
    final statusIcon = hasUrl ? Icons.check_circle : Icons.pending;
    final statusTitle = hasUrl ? l10n.icalExportUrlReady : l10n.icalExportUrlPending;
    final statusDescription = hasUrl ? l10n.icalExportUrlReadyDesc : l10n.icalExportUrlPendingDesc;

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.brandPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? AppShadows.elevation3Dark : AppShadows.elevation3,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apartment, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.icalExportUnit,
                      style: TextStyle(color: Colors.white.withAlpha((0.7 * 255).toInt()), fontSize: 12),
                    ),
                    Text(
                      widget.unit.name,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          // Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha((0.9 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusDescription,
                      style: TextStyle(color: Colors.white.withAlpha((0.9 * 255).toInt()), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isGenerating ? null : _generateIcal,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(hasUrl ? Icons.refresh : Icons.play_arrow, size: 20),
              label: Text(
                _isGenerating
                    ? l10n.icalExportGenerating
                    : (hasUrl ? l10n.icalExportRegenerate : l10n.icalExportGenerate),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                disabledBackgroundColor: Colors.white.withAlpha((0.5 * 255).toInt()),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportUrlSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(l10n.icalExportUrl, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          if (_exportUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline.withAlpha((0.2 * 255).toInt())),
              ),
              child: SelectableText(
                _exportUrl!,
                style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: theme.colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _copyUrlToClipboard,
                icon: const Icon(Icons.copy, size: 18),
                label: Text(l10n.icalExportCopyUrl),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_lastGenerated != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    l10n.icalExportLastGenerated(_formatDateTime(_lastGenerated!, l10n)),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((0.05 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.link_off, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(l10n.icalExportNoUrl, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    l10n.icalExportNoUrlDesc,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarInstructions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.help_outline, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.icalExportHowToTest,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildCalendarItem(context, 0, l10n.icalExportGoogleCalendar, Icons.event, l10n.icalExportGoogleInstructions),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildCalendarItem(context, 1, l10n.icalExportAppleCalendar, Icons.apple, l10n.icalExportAppleInstructions),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildCalendarItem(context, 2, l10n.icalExportOutlook, Icons.mail, l10n.icalExportOutlookInstructions),
          const SizedBox(height: 8),

          // Sync note
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726).withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: Color(0xFFFFA726)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.icalExportSyncNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarItem(BuildContext context, int index, String name, IconData icon, String instructions) {
    final theme = Theme.of(context);
    final isExpanded = _expandedCalendar == index;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expandedCalendar = isExpanded ? null : index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(instructions, style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showPreview = !_showPreview),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.code, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.icalExportPreview,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(_showPreview ? Icons.expand_less : Icons.expand_more, color: theme.colorScheme.outline),
                ],
              ),
            ),
          ),
          if (_showPreview && _icsPreview != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                height: 300,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outline.withAlpha((0.2 * 255).toInt())),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _icsPreview!,
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
