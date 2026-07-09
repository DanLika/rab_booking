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
import '../../../../../core/design/tokens.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/config/environment.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../../../shared/widgets/redesign.dart';
import '../../widgets/ical/ical_export_premium_header.dart';
import '../../widgets/owner_app_drawer.dart';
import '../../providers/owner_properties_provider.dart';
import '../../providers/ical_feeds_provider.dart';
import '../../../domain/models/ical_feed.dart';

/// Screen that lists all units for iCal export selection.
///
/// Redesigned onto the Bb* premium foundation (`lib/shared/widgets/redesign/`):
/// page background is `context.gradients.pageBackground` (FLAT solid fill since
/// CHANGELOG 7.23 — the `LinearGradient` API is retained but renders a solid
/// fill); section surfaces use `sectionBackground` (likewise a FLAT raised
/// fill) + a `sectionBorder` hairline + elevation shadow; interactive chrome is
/// Bb* primitives (BbButton / BbDropdown / BbIcon / BBType / BBColor / BBSpace /
/// BBRadius).
///
/// The `widget_secrets` write in [_showDynamicLinkDialog] (5-field `hasOnly`
/// rule, firestore.rules) is FROZEN — only chrome was migrated, never the
/// write payload.
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

  /// Section surface — FLAT `sectionBackground` raised fill (the gradient stops
  /// were retired in CHANGELOG 7.23; the `LinearGradient` API renders a solid
  /// theme-aware fill) + hairline `sectionBorder` + elevation shadow.
  BoxDecoration _sectionDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: context.gradients.sectionBackground,
      borderRadius: BBRadius.lgAll,
      border: Border.all(color: context.gradients.sectionBorder),
      boxShadow: BBShadow.elevated(context),
    );
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

    LoggingService.log(
      'Generating dynamic iCal link for unit: ${unit.id}',
      tag: 'ICAL_EXPORT',
    );

    // Show loading dialog
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: BbSpinner(size: 36)),
      ),
    );

    try {
      // Direct Firestore access to bypass model limitations.
      //
      // Token is stored in `widget_secrets/{unitId}` (owner-only read) so it
      // can't be exfiltrated from the publicly-readable widget_settings doc.
      // Public flag `ical_export_enabled` stays on widget_settings since the
      // iCal-export Cloud Function checks it before authenticating with the
      // token. Legacy reads fall back to widget_settings.ical_export_token
      // during the migration window.
      final propertyRef = FirebaseFirestore.instance
          .collection('properties')
          .doc(propertyId);
      final settingsRef = propertyRef
          .collection('widget_settings')
          .doc(unit.id);
      final secretsRef = propertyRef.collection('widget_secrets').doc(unit.id);

      final secretsDoc = await secretsRef.get();
      String? token;

      if (secretsDoc.exists && secretsDoc.data() != null) {
        token = secretsDoc.data()!['ical_export_token'] as String?;
      }

      // Legacy fallback: token might still live on widget_settings for
      // unmigrated units. Treat it as authoritative once, then we'll move it
      // to widget_secrets below.
      bool legacyTokenSeen = false;
      if (token == null || token.isEmpty) {
        final legacyDoc = await settingsRef.get();
        if (legacyDoc.exists && legacyDoc.data() != null) {
          final legacy = legacyDoc.data()!['ical_export_token'] as String?;
          if (legacy != null && legacy.isNotEmpty) {
            token = legacy;
            legacyTokenSeen = true;
          }
        }
      }

      // If token is missing, generate one
      if (token == null || token.isEmpty) {
        token = const Uuid().v4();
      }

      // Ensure we have ownerId (required for security rules)
      final String ownerId = unit.ownerId ?? '';

      // Write token to private widget_secrets doc
      await secretsRef.set({
        'ical_export_token': token,
        'property_id': propertyId,
        'owner_id': ownerId.isNotEmpty ? ownerId : null,
        'unit_id': unit.id,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Write the public flag (and any legacy-token cleanup) on widget_settings
      await settingsRef.set({
        'ical_export_enabled': true,
        'updated_at': FieldValue.serverTimestamp(),
        'property_id': propertyId,
        'owner_id': ownerId.isNotEmpty ? ownerId : null,
        'id': unit.id,
        // Scrub: never persist the token on the public doc again.
        if (legacyTokenSeen) 'ical_export_token': FieldValue.delete(),
      }, SetOptions(merge: true));

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
      final projectId = EnvironmentConfig.firebaseProjectId;
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

      // Build dropdown options from feeds. Each carries a Material Symbol icon
      // *name* (string) for BbDropdownItem.
      final dropdownOptions =
          <({String label, String? excludeValue, String iconName})>[];
      dropdownOptions.add((
        label: l10n.icalExportOtherCalendar,
        excludeValue: null,
        iconName: 'calendar_month',
      ));
      for (final feed in uniqueFeeds) {
        dropdownOptions.add((
          label: feed.platformDisplayName,
          excludeValue: _getExcludeValue(feed),
          iconName: _getPlatformIconName(
            feed.platform,
            feed.customPlatformName,
          ),
        ));
      }
      // Default to first platform-specific option if available
      var selectedIndex = uniqueFeeds.isNotEmpty ? 1 : 0;

      final dialogWidth = ResponsiveDialogUtils.getDialogWidth(context);
      final contentPadding = ResponsiveDialogUtils.getContentPadding(context);
      final screenHeight = MediaQuery.of(context).size.height;

      // Show dialog with per-platform URL cards
      unawaited(
        showDialog(
          context: context,
          builder: (dialogContext) {
            final c = BBColor.of(dialogContext);
            return Dialog(
              backgroundColor: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(
                dialogContext,
              ),
              shape: const RoundedRectangleBorder(borderRadius: BBRadius.lgAll),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: screenHeight * 0.85,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: dialogContext.gradients.sectionBackground,
                    borderRadius: BBRadius.lgAll,
                    border: Border.all(
                      color: dialogContext.gradients.sectionBorder,
                    ),
                    boxShadow: BBShadow.modal(dialogContext),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header — brand bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BBSpace.sm,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(color: c.primary),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(BBSpace.xs),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BBRadius.xsAll,
                              ),
                              child: const BbIcon(
                                name: 'link',
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.icalExportLinkTitle,
                                style: BBType.h3(dialogContext).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            BbButton(
                              asIcon: true,
                              size: BbButtonSize.sm,
                              variant: BbButtonVariant.onGradient,
                              iconLeft: 'close',
                              semanticLabel: l10n.close,
                              onPressed: () => Navigator.pop(dialogContext),
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
                                    style: BBType.body(
                                      ctx,
                                    ).copyWith(color: c.textSecondary),
                                  ),
                                  const SizedBox(height: BBSpace.sm),

                                  // Platform dropdown
                                  BbDropdown<int>(
                                    label: l10n.icalExportSelectPlatform,
                                    value: selectedIndex,
                                    items: [
                                      for (
                                        var i = 0;
                                        i < dropdownOptions.length;
                                        i++
                                      )
                                        BbDropdownItem<int>(
                                          value: i,
                                          label: dropdownOptions[i].label,
                                          icon: dropdownOptions[i].iconName,
                                        ),
                                    ],
                                    onChanged: (val) {
                                      setDialogState(() {
                                        selectedIndex = val ?? 0;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: BBSpace.sm),

                                  // URL display with copy button
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: c.surface,
                                      borderRadius: BBRadius.smAll,
                                      border: Border.all(
                                        color: c.primary.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: SelectableText(
                                            currentUrl,
                                            style: BBType.mono(ctx).copyWith(
                                              fontSize: 11,
                                              color: c.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: BBSpace.xs),
                                        BbButton(
                                          asIcon: true,
                                          size: BbButtonSize.sm,
                                          variant: BbButtonVariant.secondary,
                                          iconLeft: 'content_copy',
                                          semanticLabel:
                                              l10n.icalExportCopyLink,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      BbIcon(
                                        name: selected.excludeValue != null
                                            ? 'filter_alt'
                                            : 'warning',
                                        size: 14,
                                        color: selected.excludeValue != null
                                            ? c.primary
                                            : c.error,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          selected.excludeValue != null
                                              ? '${l10n.icalExportExcludesFrom} ${selected.label}'
                                              : l10n.icalExportGenericUrlWarning,
                                          style: BBType.caption(ctx).copyWith(
                                            color: selected.excludeValue != null
                                                ? c.textSecondary
                                                : c.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (uniqueFeeds.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    _InfoNote(
                                      icon: 'info',
                                      text: l10n.icalExportHubSpokeNote,
                                      tone: c.primary,
                                      background: c.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ],

                                  if (uniqueFeeds.isEmpty) ...[
                                    const SizedBox(height: 14),
                                    _InfoNote(
                                      icon: 'lightbulb',
                                      text: l10n.icalExportNoPlatformFeeds,
                                      tone: c.textTertiary,
                                      background: c.surfaceVariant,
                                    ),
                                  ],

                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      BbIcon(
                                        name: 'lock',
                                        size: 13,
                                        color: c.error.withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          l10n.icalExportTokenWarning,
                                          style: BBType.caption(ctx).copyWith(
                                            color: c.error.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontStyle: FontStyle.italic,
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
                          horizontal: BBSpace.sm,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: dialogContext.gradients.sectionBorder,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            BbButton(
                              label: l10n.close,
                              variant: BbButtonVariant.tertiary,
                              size: BbButtonSize.sm,
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
            ? const Center(child: BbSpinner(size: 36))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 900;
                  final isTablet = constraints.maxWidth > 600;
                  final horizontalPadding = isDesktop
                      ? BBSpace.xl
                      : (isTablet ? BBSpace.lg : BBSpace.sm);

                  return SingleChildScrollView(
                    physics: PlatformScrollPhysics.adaptive,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 1000, // page clamp — center tablet+desktop
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            IcalExportPremiumHeader(
                              unitCount: _allUnits.length,
                            ),
                            const SizedBox(height: 20),
                            // Hero Card
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isDesktop ? 800.0 : double.infinity,
                              ),
                              child: _buildHeroCard(context),
                            ),
                            const SizedBox(height: BBSpace.md),

                            // Desktop: Benefits + HowItWorks side by side, Units below
                            if (isDesktop) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildBenefitsSection(context),
                                  ),
                                  const SizedBox(width: BBSpace.md),
                                  Expanded(
                                    child: _buildHowItWorksSection(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: BBSpace.md),
                              if (_allUnits.isNotEmpty)
                                _buildUnitsSection(context),
                            ] else ...[
                              // Mobile/Tablet: Stack vertically
                              _buildBenefitsSection(context),
                              const SizedBox(height: BBSpace.md),
                              if (_allUnits.isNotEmpty) ...[
                                _buildUnitsSection(context),
                                const SizedBox(height: BBSpace.md),
                              ],
                              _buildHowItWorksSection(context),
                            ],
                            const SizedBox(height: BBSpace.lg),
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

  /// Circle-icon + title row shared by the section cards.
  Widget _sectionTitle(
    BuildContext context,
    String iconName,
    String title, {
    Widget? trailing,
  }) {
    final c = BBColor.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: BbIcon(name: iconName, color: c.primary, size: 24),
        ),
        const SizedBox(width: BBSpace.sm),
        Expanded(
          child: Text(
            title,
            style: BBType.h3(
              context,
            ).copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);

    final hasUnits = _allUnits.isNotEmpty;

    return DecoratedBox(
      decoration: _sectionDecoration(context),
      child: ClipRRect(
        borderRadius: BBRadius.lgAll,
        child: Stack(
          children: [
            // Pattern overlay
            Positioned(
              right: -10,
              top: -10,
              child: BbIcon(
                name: 'sync',
                size: 100,
                color: c.primary.withValues(alpha: 0.06),
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
                          color: c.primary.withValues(alpha: 0.10),
                          borderRadius: BBRadius.smAll,
                        ),
                        child: BbIcon(
                          name: 'calendar_today',
                          size: 24,
                          color: c.primary,
                        ),
                      ),
                      const SizedBox(width: BBSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.icalExportListTitle,
                              style: BBType.h2(context).copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: BBSpace.xxs),
                            _StatusPill(hasUnits: hasUnits),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BBSpace.sm),
                  Text(
                    hasUnits
                        ? l10n.icalExportHeroDesc
                        : l10n.icalExportListNoUnitsDesc,
                    style: BBType.body(
                      context,
                    ).copyWith(color: c.textSecondary),
                  ),
                  if (!hasUnits) ...[
                    const SizedBox(height: BBSpace.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BbButton(
                        label: l10n.icalExportListAddProperty,
                        iconLeft: 'add',
                        size: BbButtonSize.lg,
                        onPressed: () => context.push(OwnerRoutes.propertyNew),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final benefits = [
      (
        'calendar_month',
        l10n.icalExportBenefit1Title,
        l10n.icalExportBenefit1Desc,
      ),
      ('sync', l10n.icalExportBenefit2Title, l10n.icalExportBenefit2Desc),
      ('devices', l10n.icalExportBenefit3Title, l10n.icalExportBenefit3Desc),
      (
        'notifications_active',
        l10n.icalExportBenefit4Title,
        l10n.icalExportBenefit4Desc,
      ),
    ];

    return Container(
      decoration: _sectionDecoration(context),
      padding: const EdgeInsets.all(BBSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'star', l10n.icalExportWhyExport),
          const SizedBox(height: BBSpace.md),
          ...benefits.map((b) => _buildBenefitItem(context, b.$1, b.$2, b.$3)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    String iconName,
    String title,
    String description,
  ) {
    final c = BBColor.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(BBSpace.xs),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.1),
              borderRadius: BBRadius.xsAll,
            ),
            child: BbIcon(name: iconName, color: c.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BBType.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600, color: c.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitsSection(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: _sectionDecoration(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(BBSpace.md),
            child: _sectionTitle(
              context,
              'apartment',
              l10n.icalExportSelectUnit,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: BBSpace.xxs,
                ),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  borderRadius: BBRadius.smAll,
                ),
                child: Text(
                  '${_allUnits.length}',
                  style: BBType.bodyNum(
                    context,
                  ).copyWith(color: c.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          if (_allUnits.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BBSpace.md,
                0,
                BBSpace.md,
                BBSpace.md,
              ),
              child: Container(
                padding: const EdgeInsets.all(BBSpace.lg),
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: BBRadius.mdAll,
                ),
                child: Column(
                  children: [
                    BbIcon(name: 'apartment', size: 48, color: c.textTertiary),
                    const SizedBox(height: BBSpace.sm),
                    Text(
                      l10n.icalExportListNoUnits,
                      style: BBType.body(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: BBSpace.xxs),
                    Text(
                      l10n.icalExportListNoUnitsDesc,
                      style: BBType.caption(
                        context,
                      ).copyWith(color: c.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BBSpace.md,
                0,
                BBSpace.md,
                BBSpace.md,
              ),
              child: Column(
                children: _allUnits
                    .map((item) => _buildUnitItem(context, item))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnitItem(BuildContext context, Map<String, dynamic> item) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final unit = item['unit'];
    final property = item['property'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(BBSpace.sm),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BBRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.name ?? l10n.icalExportListUnknownUnit,
                  style: BBType.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  property.name ?? l10n.icalExportListUnknownProperty,
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          // Copy Link Button
          Tooltip(
            message: l10n.icalExportCopyLink,
            child: BbButton(
              asIcon: true,
              variant: BbButtonVariant.secondary,
              iconLeft: 'link',
              semanticLabel: l10n.icalExportCopyLink,
              onPressed: () => _showDynamicLinkDialog(unit, property.id),
            ),
          ),
          const SizedBox(width: BBSpace.xs),
          // Download Button
          if (_generatingUnitId == unit.id)
            const SizedBox(
              width: 44,
              height: 44,
              child: Center(child: BbSpinner(size: 22)),
            )
          else
            Tooltip(
              message: 'Download',
              child: BbButton(
                asIcon: true,
                iconLeft: 'download',
                semanticLabel: 'Download',
                onPressed: () => _generateAndDownloadIcal(unit, property.id),
              ),
            ),
        ],
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

  /// Material Symbol icon *name* for a feed's platform (BbDropdownItem.icon).
  String _getPlatformIconName(IcalPlatform platform, String? customName) {
    return switch (platform) {
      IcalPlatform.bookingCom => 'business',
      IcalPlatform.airbnb => 'apartment',
      IcalPlatform.other => _getOtherPlatformIconName(customName),
    };
  }

  String _getOtherPlatformIconName(String? name) {
    final lower = name?.toLowerCase() ?? '';
    if (lower.contains('adriagate')) return 'beach_access';
    if (lower.contains('holiday')) return 'home';
    if (lower.contains('atraveo')) return 'villa';
    return 'link';
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);

    final steps = [
      l10n.icalExportStep1,
      l10n.icalExportStep2,
      l10n.icalExportStep3,
      l10n.icalExportStep4,
    ];

    return Container(
      decoration: _sectionDecoration(context),
      padding: const EdgeInsets.all(BBSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'help', l10n.icalExportHowItWorks),
          const SizedBox(height: BBSpace.md),
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
                      color: c.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.key + 1}',
                      style: BBType.caption(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: BBSpace.sm),
                  Expanded(
                    child: Text(
                      e.value,
                      style: BBType.body(
                        context,
                      ).copyWith(color: c.textSecondary),
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

/// Status chip on the hero card — green "ready" when the owner has units,
/// neutral "no units" otherwise.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.hasUnits});

  final bool hasUnits;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final Color tone = hasUnits ? c.success : c.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: BBSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BBRadius.smAll,
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BbIcon(
            name: hasUnits ? 'check_circle' : 'info',
            size: 14,
            color: tone,
          ),
          const SizedBox(width: 6),
          Text(
            hasUnits ? l10n.icalExportReady : l10n.icalExportListNoUnits,
            style: BBType.caption(
              context,
            ).copyWith(color: tone, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Tinted info/hint note used inside the link dialog (icon + body text).
class _InfoNote extends StatelessWidget {
  const _InfoNote({
    required this.icon,
    required this.text,
    required this.tone,
    required this.background,
  });

  final String icon;
  final String text;
  final Color tone;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BBRadius.smAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BbIcon(name: icon, size: 16, color: tone),
          const SizedBox(width: BBSpace.xs),
          Expanded(
            child: Text(
              text,
              style: BBType.caption(context).copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
