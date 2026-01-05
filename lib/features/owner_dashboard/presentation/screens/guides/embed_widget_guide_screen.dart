import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/platform_scroll_physics.dart';
import '../../../../../core/theme/app_color_extensions.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/error_display_utils.dart';
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
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: ListView(
            physics: PlatformScrollPhysics.adaptive,
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Section - Simplified
              _buildHeroSection(isDark),

              const SizedBox(height: 24),

              // Your Embed Codes - The main content
              _buildYourEmbedCodesSection(),

              const SizedBox(height: 24),

              // Simple 3-Step Instructions
              _buildSimpleSteps(),

              const SizedBox(height: 24),

              // Help Links
              _buildHelpLinks(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.brandPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.code, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.embedGuideHeaderTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.embedGuideHeaderSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleSteps() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation1Dark : AppShadows.elevation1,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.success,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.embedGuideSimpleStepsTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSimpleStep(
            number: '1',
            text: l10n.embedGuideSimpleStep1,
            icon: Icons.content_copy,
          ),
          _buildSimpleStep(
            number: '2',
            text: l10n.embedGuideSimpleStep2,
            icon: Icons.code,
          ),
          _buildSimpleStep(
            number: '3',
            text: l10n.embedGuideSimpleStep3,
            icon: Icons.publish,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStep({
    required String number,
    required String text,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            size: 20,
            color: isDark
                ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                : Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpLinks() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.gradients.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation1Dark : AppShadows.elevation1,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.embedGuideNeedHelp,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          _buildHelpLinkButton(
            icon: Icons.menu_book,
            label: l10n.embedGuideInstallationGuide,
            tab: EmbedHelpTab.installation,
          ),
          const SizedBox(height: 8),
          _buildHelpLinkButton(
            icon: Icons.tune,
            label: l10n.embedGuideAdvancedOptions,
            tab: EmbedHelpTab.advanced,
          ),
          const SizedBox(height: 8),
          _buildHelpLinkButton(
            icon: Icons.build,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EmbedHelpScreen(initialTab: tab),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  )
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.gradients.sectionBorder),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.code,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.embedGuideYourEmbedCodes,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        l10n.embedGuideCopyIframe,
                        style: TextStyle(
                          fontSize: 12,
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withAlpha(50),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? theme.colorScheme.outline : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHigh
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
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
                if (property.subdomain != null &&
                    property.subdomain!.isNotEmpty)
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? theme.colorScheme.outline : Colors.grey.shade300,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit name and copy button
          Row(
            children: [
              Expanded(
                child: Text(
                  unit.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: embedCode));
                  ErrorDisplayUtils.showSuccessSnackBar(
                    context,
                    l10n.embedGuideCodeCopied,
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(l10n.embedCodeCopy),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Code block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: SelectableText(
              embedCode,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: theme.colorScheme.primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
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
