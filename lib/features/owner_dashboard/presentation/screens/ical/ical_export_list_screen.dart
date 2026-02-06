import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/services/logging_service.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/platform_scroll_physics.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../widgets/owner_app_drawer.dart';
import '../../providers/owner_properties_provider.dart';
import '../../providers/ical_feeds_provider.dart';
import '../../../domain/models/ical_feed.dart';

/// Screen that lists all units for iCal export selection
/// Redesigned: Premium feel with consistent theme support
class IcalExportListScreen extends ConsumerStatefulWidget {
  const IcalExportListScreen({super.key});

  @override
  ConsumerState<IcalExportListScreen> createState() =>
      _IcalExportListScreenState();
}

class _IcalExportListScreenState extends ConsumerState<IcalExportListScreen> {
  List<Map<String, dynamic>> _allUnits = [];
  bool _isLoading = true;
  String? _generatingUnitId; // Track which unit is currently generating

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _generateAndDownloadIcal(dynamic unit, String propertyId) async {
    setState(() => _generatingUnitId = unit.id);

    LoggingService.log(
      'Generating iCal export for unit: ${unit.id} (property: $propertyId)',
      tag: 'ICAL_EXPORT',
    );

    final l10n = AppLocalizations.of(context);
    try {
      // Generate iCal content and get download URL
      final downloadUrl = await ref
          .read(icalExportServiceProvider)
          .generateAndUploadIcal(
            propertyId: propertyId,
            unitId: unit.id,
            unit: unit,
          );

      // Trigger download by opening the URL
      // Firebase Storage URLs with ?alt=media download the file directly
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      LoggingService.log(
        'iCal export generated successfully for unit: ${unit.id}',
        tag: 'ICAL_EXPORT',
      );

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(context, l10n.icalExportSuccess);
      }
    } catch (e, stack) {
      unawaited(
        LoggingService.logError(
          'iCal export failed for unit: ${unit.id}',
          e,
          stack,
        ),
      );
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generatingUnitId = null);
      }
    }
  }

  /// Load units with their properties
  /// OPTIMIZED: Uses ownerUnitsProvider (single query) instead of N+1 queries
  /// Previously: O(P) queries where P = number of properties
  /// Now: 2 queries total (properties + units via collection group query)
  Future<void> _loadUnits() async {
    try {
      // Both providers use efficient queries (properties stream + collection group for units)
      final properties = await ref.read(ownerPropertiesProvider.future);
      final units = await ref.read(ownerUnitsProvider.future);

      // Create property lookup map for O(1) access
      final propertyMap = {for (final p in properties) p.id: p};

      // Join units with properties
      final List<Map<String, dynamic>> unitsList = [];
      for (final unit in units) {
        final property = propertyMap[unit.propertyId];
        if (property != null) {
          unitsList.add({'unit': unit, 'property': property});
        }
      }

      if (mounted) {
        setState(() {
          _allUnits = unitsList;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      unawaited(
        LoggingService.logError(
          'Failed to load units for iCal export',
          e,
          stack,
        ),
      );
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _showDynamicLinkDialog(dynamic unit, String propertyId) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    LoggingService.log(
      'Generating dynamic iCal link for unit: ${unit.id}',
      tag: 'ICAL_EXPORT',
    );

    // Show loading dialog
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      // Direct Firestore access to bypass model limitations
      final docRef = FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId)
          .collection('widget_settings')
          .doc(unit.id);

      final doc = await docRef.get();
      String? token;

      if (doc.exists && doc.data() != null) {
        token = doc.data()!['ical_export_token'] as String?;
      }

      // If token is missing, generate one and enable export
      if (token == null || token.isEmpty) {
        token = const Uuid().v4();

        // Ensure we have ownerId (required for security rules)
        final String ownerId = unit.ownerId ?? '';

        // Merge with existing or create new with minimal fields
        await docRef.set({
          'ical_export_token': token,
          'ical_export_enabled': true,
          'updated_at': FieldValue.serverTimestamp(),
          // Ensure required fields for new doc
          'property_id': propertyId,
          'owner_id': ownerId.isNotEmpty ? ownerId : null,
          'id': unit.id,
        }, SetOptions(merge: true));
      }

      // Fetch feeds BEFORE closing loading dialog (await ensures data is ready)
      List<IcalFeed> allFeeds;
      try {
        allFeeds = await ref.read(icalFeedsStreamProvider.future);
      } catch (_) {
        allFeeds = [];
      }

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading
      }

      // Construct Cloud Function URL (generic - works for ALL platforms)
      const projectId = 'rab-booking-248fc';
      const region = 'us-central1';
      final icalUrl =
          'https://$region-$projectId.cloudfunctions.net/getUnitIcalFeed/$propertyId/${unit.id}/$token.ics';

      if (!mounted) return;

      // Filter feeds for this unit and deduplicate
      final unitFeeds = allFeeds.where((f) => f.unitId == unit.id).toList();
      final seenExclude = <String>{};
      final uniqueFeeds = <IcalFeed>[];
      for (final feed in unitFeeds) {
        final exclude = _getExcludeValue(feed);
        if (seenExclude.add(exclude)) {
          uniqueFeeds.add(feed);
        }
      }

      // Build dropdown options from feeds
      final dropdownOptions =
          <
            ({String label, String? excludeValue, IconData icon, Color color})
          >[];
      dropdownOptions.add((
        label: l10n.icalExportOtherCalendar,
        excludeValue: null,
        icon: Icons.calendar_month,
        color: theme.colorScheme.primary,
      ));
      for (final feed in uniqueFeeds) {
        dropdownOptions.add((
          label: feed.platformDisplayName,
          excludeValue: _getExcludeValue(feed),
          icon: _getPlatformIcon(feed.platform, feed.customPlatformName),
          color: _getPlatformColor(feed.platform, feed.customPlatformName),
        ));
      }
      // Default to first platform-specific option if available
      var selectedIndex = uniqueFeeds.isNotEmpty ? 1 : 0;

      final isDark = theme.brightness == Brightness.dark;
      final dialogWidth = ResponsiveDialogUtils.getDialogWidth(context);
      final contentPadding = ResponsiveDialogUtils.getContentPadding(context);
      final headerPadding = ResponsiveDialogUtils.getHeaderPadding(context);
      final screenHeight = MediaQuery.of(context).size.height;

      // Show dialog with per-platform URL cards
      unawaited(
        showDialog(
          context: context,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
              decoration: BoxDecoration(
                gradient: context.gradients.sectionBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.gradients.sectionBorder.withValues(alpha: 0.5),
                ),
                boxShadow: isDark
                    ? AppShadows.elevation4Dark
                    : AppShadows.elevation4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    height: ResponsiveDialogUtils.kHeaderHeight,
                    padding: EdgeInsets.symmetric(
                      horizontal: headerPadding + 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.link,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.icalExportLinkTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(contentPadding),
                      child: StatefulBuilder(
                        builder: (ctx, setDialogState) {
                          final selected = dropdownOptions[selectedIndex];
                          final currentUrl = selected.excludeValue != null
                              ? '$icalUrl?exclude=${selected.excludeValue}'
                              : icalUrl;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.icalExportPlatformUrlDesc,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 16),

                              // Platform dropdown
                              Text(
                                l10n.icalExportSelectPlatform,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.colorScheme.onSurface.withValues(
                                          alpha: 0.08,
                                        )
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.04,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.15),
                                  ),
                                ),
                                child: DropdownButton<int>(
                                  value: selectedIndex,
                                  isExpanded: true,
                                  underline: const SizedBox.shrink(),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                  dropdownColor: isDark
                                      ? const Color(0xFF2D2D2D)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  items: dropdownOptions
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => DropdownMenuItem<int>(
                                          value: e.key,
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: e.value.color
                                                      .withValues(
                                                        alpha: isDark
                                                            ? 0.2
                                                            : 0.1,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  e.value.icon,
                                                  size: 16,
                                                  color: e.value.color,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Flexible(
                                                child: Text(
                                                  e.value.label,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      selectedIndex = val ?? 0;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 16),

                              // URL display with copy button
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.colorScheme.onSurface.withValues(
                                          alpha: 0.06,
                                        )
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.03,
                                        ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        currentUrl,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.8),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      tooltip: l10n.icalExportCopyLink,
                                      style: IconButton.styleFrom(
                                        backgroundColor: theme
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1),
                                        foregroundColor:
                                            theme.colorScheme.primary,
                                      ),
                                      onPressed: () async {
                                        try {
                                          await Clipboard.setData(
                                            ClipboardData(text: currentUrl),
                                          );
                                          if (ctx.mounted) {
                                            ErrorDisplayUtils.showSuccessSnackBar(
                                              ctx,
                                              l10n.icalExportLinkCopied,
                                            );
                                          }
                                        } catch (e) {
                                          if (ctx.mounted) {
                                            ErrorDisplayUtils.showErrorSnackBar(
                                              ctx,
                                              e,
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Description based on selection
                              Row(
                                children: [
                                  Icon(
                                    selected.excludeValue != null
                                        ? Icons.filter_alt_outlined
                                        : Icons.warning_amber_rounded,
                                    size: 14,
                                    color: selected.excludeValue != null
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      selected.excludeValue != null
                                          ? '${l10n.icalExportExcludesFrom} ${selected.label}'
                                          : l10n.icalExportGenericUrlWarning,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: selected.excludeValue != null
                                                ? theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.7)
                                                : theme.colorScheme.error
                                                      .withValues(alpha: 0.9),
                                            fontSize: 12,
                                          ),
                                    ),
                                  ),
                                ],
                              ),

                              if (uniqueFeeds.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: isDark ? 0.1 : 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(
                                            alpha: isDark ? 0.25 : 0.15,
                                          ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n.icalExportHubSpokeNote,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.7),
                                                fontSize: 11,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (uniqueFeeds.isEmpty) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.onSurface
                                        .withValues(
                                          alpha: isDark ? 0.06 : 0.03,
                                        ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        size: 16,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          l10n.icalExportNoPlatformFeeds,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                                fontSize: 11,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 13,
                                    color: theme.colorScheme.error.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.icalExportTokenWarning,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.error
                                                .withValues(alpha: 0.7),
                                            fontStyle: FontStyle.italic,
                                            fontSize: 11,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.dialogFooterDark
                          : AppColors.dialogFooterLight,
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? AppColors.sectionDividerDark
                              : AppColors.sectionDividerLight,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(l10n.close),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e, stack) {
      unawaited(
        LoggingService.logError(
          'Failed to generate dynamic iCal link for unit: ${unit.id}',
          e,
          stack,
        ),
      );
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) ErrorDisplayUtils.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.icalExportListTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(
        currentRoute: 'integrations/ical/export-list',
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 900;
                  final isTablet = constraints.maxWidth > 600;
                  final horizontalPadding = isDesktop
                      ? 48.0
                      : (isTablet ? 32.0 : 16.0);

                  return SingleChildScrollView(
                    physics: PlatformScrollPhysics.adaptive,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 1200.0 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Hero Card
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isDesktop ? 800.0 : double.infinity,
                              ),
                              child: _buildHeroCard(context),
                            ),
                            const SizedBox(height: 24),

                            // Desktop: Benefits + HowItWorks side by side, Units below
                            if (isDesktop) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildBenefitsSection(context),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildHowItWorksSection(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              if (_allUnits.isNotEmpty)
                                _buildUnitsSection(context),
                            ] else ...[
                              // Mobile/Tablet: Stack vertically
                              _buildBenefitsSection(context),
                              const SizedBox(height: 24),
                              if (_allUnits.isNotEmpty) ...[
                                _buildUnitsSection(context),
                                const SizedBox(height: 24),
                              ],
                              _buildHowItWorksSection(context),
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

    final hasUnits = _allUnits.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: context.gradients.brandPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(4, isDark: isDark),
      ),
      child: Stack(
        children: [
          // Pattern overlay
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.sync_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.icalExportListTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: hasUnits
                                  ? const Color(
                                      0xFF4CAF50,
                                    ).withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasUnits
                                      ? Icons.check_circle_rounded
                                      : Icons.info_outline_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  hasUnits
                                      ? l10n.icalExportReady
                                      : l10n.icalExportListNoUnits,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  hasUnits
                      ? l10n.icalExportHeroDesc
                      : l10n.icalExportListNoUnitsDesc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (!hasUnits) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push(OwnerRoutes.propertyNew),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      l10n.icalExportListAddProperty,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final benefits = [
      (
        Icons.calendar_month_rounded,
        l10n.icalExportBenefit1Title,
        l10n.icalExportBenefit1Desc,
      ),
      (
        Icons.sync_rounded,
        l10n.icalExportBenefit2Title,
        l10n.icalExportBenefit2Desc,
      ),
      (
        Icons.devices_rounded,
        l10n.icalExportBenefit3Title,
        l10n.icalExportBenefit3Desc,
      ),
      (
        Icons.notifications_active_rounded,
        l10n.icalExportBenefit4Title,
        l10n.icalExportBenefit4Desc,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: AppShadows.getElevation(2, isDark: isDark),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.icalExportWhyExport,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...benefits.map((b) => _buildBenefitItem(context, b.$1, b.$2, b.$3)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: AppShadows.getElevation(2, isDark: isDark),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.icalExportSelectUnit,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_allUnits.length}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_allUnits.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.apartment_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.icalExportListNoUnits,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.icalExportListNoUnitsDesc,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: _allUnits
                    .map((item) => _buildUnitItem(context, item))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitItem(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final unit = item['unit'];
    final property = item['property'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        // InkWell without onTap disables card tap to prevent accidental actions
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.name ?? l10n.icalExportListUnknownUnit,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        property.name ?? l10n.icalExportListUnknownProperty,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Copy Link Button
                IconButton(
                  onPressed: () => _showDynamicLinkDialog(unit, property.id),
                  icon: const Icon(Icons.link, size: 22),
                  tooltip: l10n.icalExportCopyLink,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                // Download Button
                if (_generatingUnitId == unit.id)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: () =>
                        _generateAndDownloadIcal(unit, property.id),
                    icon: const Icon(Icons.download_rounded, size: 22),
                    tooltip: 'Download',
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sanitize platform name to match Cloud Functions source format.
  /// Must mirror: functions/src/icalSync.ts sanitizeSource()
  /// "Adriagate" → "adriagate", "Holiday-Home" → "holiday-home"
  String _sanitizeSource(String name) {
    final result = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return result.isEmpty ? 'other' : result;
  }

  /// Get the ?exclude= parameter value for a feed.
  /// Matches how Cloud Functions derive the source field.
  String _getExcludeValue(IcalFeed feed) {
    if (feed.platform == IcalPlatform.other &&
        feed.customPlatformName != null &&
        feed.customPlatformName!.isNotEmpty) {
      return _sanitizeSource(feed.customPlatformName!);
    }
    return feed.platform.toFirestoreValue();
  }

  IconData _getPlatformIcon(IcalPlatform platform, String? customName) {
    return switch (platform) {
      IcalPlatform.bookingCom => Icons.business,
      IcalPlatform.airbnb => Icons.apartment,
      IcalPlatform.other => _getOtherPlatformIcon(customName),
    };
  }

  IconData _getOtherPlatformIcon(String? name) {
    final lower = name?.toLowerCase() ?? '';
    if (lower.contains('adriagate')) return Icons.beach_access;
    if (lower.contains('holiday')) return Icons.home;
    if (lower.contains('atraveo')) return Icons.villa;
    return Icons.link;
  }

  Color _getPlatformColor(IcalPlatform platform, String? customName) {
    return switch (platform) {
      IcalPlatform.bookingCom => const Color(0xFF003580),
      IcalPlatform.airbnb => const Color(0xFFFF5A5F),
      IcalPlatform.other => _getOtherPlatformColor(customName),
    };
  }

  Color _getOtherPlatformColor(String? name) {
    final lower = name?.toLowerCase() ?? '';
    if (lower.contains('adriagate')) return const Color(0xFF0088CC);
    if (lower.contains('holiday')) return const Color(0xFF4CAF50);
    if (lower.contains('atraveo')) return const Color(0xFF9C27B0);
    return const Color(0xFF607D8B);
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final steps = [
      l10n.icalExportStep1,
      l10n.icalExportStep2,
      l10n.icalExportStep3,
      l10n.icalExportStep4,
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: AppShadows.getElevation(2, isDark: isDark),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.icalExportHowItWorks,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...steps.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: context.gradients.brandPrimary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                        height: 1.5,
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
}
