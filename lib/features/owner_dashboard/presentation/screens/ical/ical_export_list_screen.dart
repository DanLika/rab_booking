import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/platform_scroll_physics.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../widgets/owner_app_drawer.dart';
import '../../providers/owner_properties_provider.dart';

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
  bool _showFaq = false;
  String? _generatingUnitId; // Track which unit is currently generating

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _generateAndDownloadIcal(dynamic unit, String propertyId) async {
    setState(() => _generatingUnitId = unit.id);

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

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(context, l10n.icalExportSuccess);
      }
    } catch (e) {
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

                            // Desktop: Benefits + Units/HowItWorks side by side
                            if (isDesktop) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildBenefitsSection(context),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _allUnits.isNotEmpty
                                        ? _buildUnitsSection(context)
                                        : _buildHowItWorksSection(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Show FAQ only if has units
                              if (_allUnits.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildHowItWorksSection(context),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildFaqSection(context)),
                                  ],
                                ),
                              ],
                            ] else ...[
                              // Mobile/Tablet: Stack vertically
                              _buildBenefitsSection(context),
                              const SizedBox(height: 24),
                              if (_allUnits.isNotEmpty) ...[
                                _buildUnitsSection(context),
                                const SizedBox(height: 24),
                              ],
                              _buildHowItWorksSection(context),
                              const SizedBox(height: 24),
                              if (_allUnits.isNotEmpty)
                                _buildFaqSection(context),
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
    final statusColor = hasUnits
        ? const Color(0xFF66BB6A)
        : theme.colorScheme.outline;
    final statusIcon = hasUnits ? Icons.check_circle : Icons.sync_disabled;
    final statusTitle = hasUnits
        ? l10n.icalExportReady
        : l10n.icalExportListNoUnits;
    final statusDescription = hasUnits
        ? l10n.icalExportUnitsAvailable(_allUnits.length)
        : l10n.icalExportListNoUnitsDesc;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 700;

        return Container(
          decoration: BoxDecoration(
            gradient: context.gradients.brandPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? AppShadows.elevation3Dark
                : AppShadows.elevation3,
          ),
          padding: const EdgeInsets.all(24),
          child: isDesktop
              ? Row(
                  children: [
                    // Status icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(statusIcon, size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    // Status info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            statusDescription,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // CTA Button - fixed width on desktop, only show if no units
                    if (!hasUnits) ...[
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 200,
                        child: FilledButton.icon(
                          onPressed: () =>
                              context.push(OwnerRoutes.propertyNew),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(
                            l10n.icalExportListAddProperty,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            statusIcon,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                statusDescription,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!hasUnits) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              context.push(OwnerRoutes.propertyNew),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(
                            l10n.icalExportListAddProperty,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final benefits = [
      (
        Icons.calendar_month,
        l10n.icalExportBenefit1Title,
        l10n.icalExportBenefit1Desc,
      ),
      (
        Icons.sync_rounded,
        l10n.icalExportBenefit2Title,
        l10n.icalExportBenefit2Desc,
      ),
      (
        Icons.devices,
        l10n.icalExportBenefit3Title,
        l10n.icalExportBenefit3Desc,
      ),
      (
        Icons.notifications_active,
        l10n.icalExportBenefit4Title,
        l10n.icalExportBenefit4Desc,
      ),
    ];

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
              Icon(Icons.star, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.icalExportWhyExport,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                Icon(
                  Icons.apartment,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.icalExportSelectUnit,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_allUnits.length}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_allUnits.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.apartment_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.icalExportListNoUnits,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.icalExportListNoUnitsDesc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Divider(
              height: 1,
              color: isDark
                  ? AppColors.sectionDividerDark
                  : AppColors.sectionDividerLight,
            ),
            ..._allUnits.map((item) => _buildUnitItem(context, item)),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitItem(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final unit = item['unit'];
    final property = item['property'];

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.apartment,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            unit.name ?? l10n.icalExportListUnknownUnit,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            property.name ?? l10n.icalExportListUnknownProperty,
            style: theme.textTheme.bodySmall,
          ),
          trailing: _generatingUnitId == unit.id
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.download, color: theme.colorScheme.primary),
          onTap: _generatingUnitId == null
              ? () => _generateAndDownloadIcal(unit, property.id)
              : null,
        ),
        Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: theme.brightness == Brightness.dark
              ? AppColors.sectionDividerDark
              : AppColors.sectionDividerLight,
        ),
      ],
    );
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
              Icon(
                Icons.help_outline,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.icalExportHowItWorks,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.value,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
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

  Widget _buildFaqSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final faqs = [
      (l10n.icalExportFaq1Q, l10n.icalExportFaq1A),
      (l10n.icalExportFaq2Q, l10n.icalExportFaq2A),
      (l10n.icalExportFaq3Q, l10n.icalExportFaq3A),
    ];

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
            onTap: () => setState(() => _showFaq = !_showFaq),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.question_answer,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.icalExportFaqTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _showFaq ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_showFaq) ...[
            Divider(
              height: 1,
              color: isDark
                  ? AppColors.sectionDividerDark
                  : AppColors.sectionDividerLight,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: faqs
                    .map(
                      (faq) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '❓ ${faq.$1}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              faq.$2,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
