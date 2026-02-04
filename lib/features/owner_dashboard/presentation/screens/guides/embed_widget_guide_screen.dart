import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/platform_scroll_physics.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../../../shared/models/property_model.dart';
import '../../../../../shared/models/unit_model.dart';

import '../../providers/owner_properties_provider.dart';
import '../../widgets/owner_app_drawer.dart';
import 'embed_help_screen.dart';

/// Embed Widget Guide Screen
/// Simplified: just embed codes + 3 simple steps + links to help
class EmbedWidgetGuideScreen extends ConsumerStatefulWidget {
  const EmbedWidgetGuideScreen({super.key});

  @override
  ConsumerState<EmbedWidgetGuideScreen> createState() =>
      _EmbedWidgetGuideScreenState();
}

class _EmbedWidgetGuideScreenState
    extends ConsumerState<EmbedWidgetGuideScreen> {
  static const String _subdomainBaseDomain = 'view.bookbed.io';

  /// Selected unit for live preview testing
  UnitModel? _selectedPreviewUnit;
  PropertyModel? _selectedPreviewProperty;

  /// Generate direct iframe embed code for a unit
  /// Works on any website - just copy and paste
  /// Responsive height using aspect-ratio with min/max constraints
  /// Always uses view.bookbed.io (no subdomain) - property/unit IDs are sufficient
  String _generateEmbedCode(
    String propertyId,
    UnitModel unit,
    String? subdomain,
  ) {
    // Always use base domain for iframe embeds - no subdomain needed
    // Subdomains are optional and may not be configured for all properties
    const baseUrl = 'https://$_subdomainBaseDomain';
    final url = '$baseUrl/?property=$propertyId&unit=${unit.id}&embed=true';
    return '''<iframe
  src="$url"
  style="width: 100%; border: none; aspect-ratio: 1/1.4; min-height: 500px; max-height: 850px;"
  title="${unit.name}"
></iframe>''';
  }

  /// Show quick help bottom sheet - simplified overview with link to full help
  void _showHelpBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.embedGuideQuickHelpTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.embedGuideSimpleStepsTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Simplified steps as compact list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildCompactStep(
                    number: '1',
                    text: l10n.embedGuideSimpleStep1,
                    theme: theme,
                  ),
                  _buildCompactStep(
                    number: '2',
                    text: l10n.embedGuideSimpleStep2,
                    theme: theme,
                  ),
                  _buildCompactStep(
                    number: '3',
                    text: l10n.embedGuideSimpleStep3,
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // CTA Button to full help
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EmbedHelpScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: Text(l10n.embedGuideInstallationGuide),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a compact step item for the quick help bottom sheet
  Widget _buildCompactStep({
    required String number,
    required String text,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const OwnerAppDrawer(currentRoute: 'guides/embed-widget'),
      appBar: CommonAppBar(
        title: l10n.embedGuideTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: l10n.embedGuideQuickHelp,
            onPressed: () => _showHelpBottomSheet(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: ListView(
            physics: PlatformScrollPhysics.adaptive,
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Section - Premium
              _buildHeroSection(isDark),

              const SizedBox(height: 16),

              // Responsive layout: Steps + Test side by side on desktop
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;

                  if (isWide) {
                    // Desktop: side by side
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Installation Steps
                        Expanded(child: _buildInstallationStepsSection()),
                        const SizedBox(width: 16),
                        // Right: Test Widget
                        Expanded(child: _buildTestWidgetSection()),
                      ],
                    );
                  }

                  // Mobile: stacked
                  return Column(
                    children: [
                      _buildInstallationStepsSection(),
                      const SizedBox(height: 16),
                      _buildTestWidgetSection(),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Developer Customization Info
              _buildDeveloperInfoSection(),

              const SizedBox(height: 24),

              // Your Embed Codes - The main content
              _buildYourEmbedCodesSection(),

              const SizedBox(height: 24),

              // Help Links
              _buildHelpLinks(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: context.gradients.brandPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern/decoration
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.code,
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
                        Icons.integration_instructions_outlined,
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
                            l10n.embedGuideHeaderTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.embedGuideHeaderSubtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w400,
                              height: 1.4,
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
        ],
      ),
    );
  }

  /// New: Installation Steps Section directly in the main UI
  Widget _buildInstallationStepsSection() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(
            l10n.embedGuideQuickHelpTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.gradients.sectionBorder),
            boxShadow: AppShadows.getElevation(
              1,
              isDark: theme.brightness == Brightness.dark,
            ),
          ),
          child: Column(
            children: [
              _buildModernStep(
                number: '1',
                text: l10n.embedGuideSimpleStep1,
                theme: theme,
                isLast: false,
              ),
              _buildModernStep(
                number: '2',
                text: l10n.embedGuideSimpleStep2,
                theme: theme,
                isLast: false,
              ),
              _buildModernStep(
                number: '3',
                text: l10n.embedGuideSimpleStep3,
                theme: theme,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a modern step item with a connecting line
  Widget _buildModernStep({
    required String number,
    required String text,
    required ThemeData theme,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: context.gradients.brandPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 20),
                  child: Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Developer customization info section
  Widget _buildDeveloperInfoSection() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: AppShadows.getElevation(1, isDark: isDark),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.developer_mode,
                  color: theme.colorScheme.tertiary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.embedGuideDeveloperInfoTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.embedGuideDeveloperInfoDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF12121A) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDevInfoItem(
                  icon: Icons.aspect_ratio,
                  label: l10n.embedGuideDeveloperWidth,
                  example: 'width: 600px; height: 800px;',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildDevInfoItem(
                  icon: Icons.rounded_corner,
                  label: l10n.embedGuideDeveloperBorder,
                  example: 'border: 1px solid #ccc; border-radius: 8px;',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _buildDevInfoItem(
                  icon: Icons.fit_screen,
                  label: l10n.embedGuideDeveloperResponsive,
                  example: 'width: 100%; height: 100vh;',
                  theme: theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.embedGuideDeveloperWarning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevInfoItem({
    required IconData icon,
    required String label,
    required String example,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                example,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Test Widget Section - preview before embedding
  Widget _buildTestWidgetSection() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final unitsAsync = ref.watch(ownerUnitsProvider);

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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.embedGuideTestLinksTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Unit selector + Preview button
          propertiesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (properties) => unitsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (units) {
                if (units.isEmpty || properties.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Build dropdown items with property grouping
                final items = <DropdownMenuItem<UnitModel>>[];
                for (final property in properties) {
                  final propertyUnits = units
                      .where((u) => u.propertyId == property.id)
                      .toList();
                  if (propertyUnits.isEmpty) continue;

                  // Property header (disabled)
                  if (properties.length > 1) {
                    items.add(
                      DropdownMenuItem<UnitModel>(
                        enabled: false,
                        child: Text(
                          property.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    );
                  }

                  for (final unit in propertyUnits) {
                    items.add(
                      DropdownMenuItem<UnitModel>(
                        value: unit,
                        child: Text(
                          properties.length > 1 ? '  ${unit.name}' : unit.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }
                }

                // Auto-select first unit if nothing selected
                if (_selectedPreviewUnit == null && units.isNotEmpty) {
                  _selectedPreviewUnit = units.first;
                  _selectedPreviewProperty = properties.firstWhere(
                    (p) => p.id == units.first.propertyId,
                    orElse: () => properties.first,
                  );
                }

                return Column(
                  children: [
                    // Dropdown
                    DropdownButtonFormField<UnitModel>(
                      initialValue: _selectedPreviewUnit,
                      dropdownColor: InputDecorationHelper.getDropdownColor(
                        context,
                      ),
                      borderRadius: InputDecorationHelper.dropdownBorderRadius,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: l10n.embedGuideSelectUnitHint,
                        prefixIcon: const Icon(Icons.apartment_outlined),
                        context: context,
                      ),
                      items: items,
                      onChanged: (unit) {
                        if (unit == null) return;
                        setState(() {
                          _selectedPreviewUnit = unit;
                          _selectedPreviewProperty = properties.firstWhere(
                            (p) => p.id == unit.propertyId,
                            orElse: () => properties.first,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Preview button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _selectedPreviewUnit != null &&
                                _selectedPreviewProperty != null
                            ? () {
                                final url =
                                    'https://$_subdomainBaseDomain/?property=${_selectedPreviewProperty!.id}&unit=${_selectedPreviewUnit!.id}';
                                _launchUrl(url, l10n);
                              }
                            : null,
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(l10n.embedGuidePreviewLive),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Live demo link (kept as secondary option)
          _buildTestLinkCard(
            icon: Icons.apartment_outlined,
            title: l10n.embedGuideLiveExampleTitle,
            description: l10n.embedGuideLiveExampleDesc,
            url: 'https://bookbed.io/widget',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// Build a test link card
  Widget _buildTestLinkCard({
    required IconData icon,
    required String title,
    required String description,
    required String url,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
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
        child: InkWell(
          onTap: () => _launchUrl(url, l10n),
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
                  child: Icon(icon, size: 22, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
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
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 20,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Launch URL in browser
  Future<void> _launchUrl(String url, AppLocalizations l10n) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, l10n.errorOpeningLink);
      }
    }
  }

  Widget _buildHelpLinks() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          Text(
            l10n.embedGuideNeedHelp,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          _buildHelpLinkButton(
            icon: Icons.menu_book_rounded,
            label: l10n.embedGuideInstallationGuide,
            tab: EmbedHelpTab.installation,
          ),
          const SizedBox(height: 12),
          _buildHelpLinkButton(
            icon: Icons.tune_rounded,
            label: l10n.embedGuideAdvancedOptions,
            tab: EmbedHelpTab.advanced,
          ),
          const SizedBox(height: 12),
          _buildHelpLinkButton(
            icon: Icons.build_circle_outlined,
            label: l10n.embedGuideTroubleshooting,
            tab: EmbedHelpTab.troubleshooting,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpLinkButton({
    required IconData icon,
    required String label,
    required EmbedHelpTab tab,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EmbedHelpScreen(initialTab: tab),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the "Your Embed Codes" section with auto-generated codes for all units
  Widget _buildYourEmbedCodesSection() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final unitsAsync = ref.watch(ownerUnitsProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: AppShadows.getElevation(2, isDark: isDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.code_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.embedGuideYourEmbedCodes,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.embedGuideCopyIframe,
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
              ],
            ),

            const SizedBox(height: 16),

            // Language info note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.translate,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.embedGuideLanguageNote,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Content based on data state
            propertiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('${l10n.error}: $e'),
              data: (properties) {
                if (properties.isEmpty) {
                  return _buildEmptyState(l10n.embedGuideNoProperties);
                }

                return unitsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('${l10n.error}: $e'),
                  data: (units) {
                    if (units.isEmpty) {
                      return _buildEmptyState(l10n.embedGuideNoUnits);
                    }

                    // Group units by property
                    return Column(
                      children: properties.map((property) {
                        final propertyUnits = units
                            .where((u) => u.propertyId == property.id)
                            .toList();
                        if (propertyUnits.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return _buildPropertyUnitsSection(
                          property,
                          propertyUnits,
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build section for a single property with its units
  Widget _buildPropertyUnitsSection(
    PropertyModel property,
    List<UnitModel> units,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Icon + Property name
                Row(
                  children: [
                    Icon(
                      Icons.apartment,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        property.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                // Row 2: Subdomain link (if available)
                if (property.subdomain != null &&
                    property.subdomain!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${property.subdomain}.$_subdomainBaseDomain',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Units list
          ...units.map(
            (unit) =>
                _buildUnitEmbedCard(property.id, unit, property.subdomain),
          ),
        ],
      ),
    );
  }

  /// Build embed card for a single unit
  Widget _buildUnitEmbedCard(
    String propertyId,
    UnitModel unit,
    String? subdomain,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final embedCode = _generateEmbedCode(propertyId, unit, subdomain);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit name and copy button
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  unit.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: embedCode));
                    ErrorDisplayUtils.showSuccessSnackBar(
                      context,
                      l10n.embedGuideCodeCopied,
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    l10n.embedCodeCopy,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Code block - with highlighted IDs for easy identification
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF12121A) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: _buildHighlightedEmbedCode(
              embedCode: embedCode,
              propertyId: propertyId,
              unitId: unit.id,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  /// Build embed code with highlighted property_id and unit_id
  /// Visual only - copy still gets plain text
  Widget _buildHighlightedEmbedCode({
    required String embedCode,
    required String propertyId,
    required String unitId,
    required ThemeData theme,
  }) {
    final normalStyle = TextStyle(
      fontSize: 12,
      fontFamily: 'monospace',
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
      height: 1.5,
    );

    final boldStyle = TextStyle(
      fontSize: 12,
      fontFamily: 'monospace',
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w900,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      height: 1.5,
    );

    // Split embed code around property and unit IDs to create highlighted spans
    final spans = <TextSpan>[];
    var remaining = embedCode;

    // Find and highlight property ID
    final propertyMarker = 'property=$propertyId';
    final propertyIndex = remaining.indexOf(propertyMarker);
    if (propertyIndex != -1) {
      // Text before property
      spans.add(
        TextSpan(
          text: remaining.substring(0, propertyIndex + 9),
          style: normalStyle,
        ),
      ); // "property="
      // Property ID (bold)
      spans.add(TextSpan(text: propertyId, style: boldStyle));
      remaining = remaining.substring(propertyIndex + propertyMarker.length);
    }

    // Find and highlight unit ID
    final unitMarker = 'unit=$unitId';
    final unitIndex = remaining.indexOf(unitMarker);
    if (unitIndex != -1) {
      // Text before unit
      spans.add(
        TextSpan(
          text: remaining.substring(0, unitIndex + 5),
          style: normalStyle,
        ),
      ); // "unit="
      // Unit ID (bold)
      spans.add(TextSpan(text: unitId, style: boldStyle));
      remaining = remaining.substring(unitIndex + unitMarker.length);
    }

    // Remaining text
    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining, style: normalStyle));
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  /// Build empty state widget
  Widget _buildEmptyState(String message) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
