import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/theme/app_color_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../../shared/models/unit_model.dart';
import '../providers/owner_properties_provider.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';

// UI Constants
const double _kUnitImageHeight = 160.0;
const double _kCardBorderRadius = 16.0;
const double _kHeaderCardPadding = 20.0;
const double _kContentPadding = 16.0;
const double _kIconSize = 24.0;
const double _kEmptyStateIconSize = 64.0;

/// Widget Settings List Screen
/// Shows all units with quick access to their widget settings
class WidgetSettingsListScreen extends ConsumerWidget {
  const WidgetSettingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(ownerUnitsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Widget Podešavanja',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'widget-settings'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [theme.colorScheme.veryDarkGray, theme.colorScheme.mediumDarkGray]
                : [theme.colorScheme.veryLightGray, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: unitsAsync.when(
          data: (units) {
            if (units.isEmpty) {
              return _buildEmptyState(context);
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(_kHeaderCardPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [theme.colorScheme.darkGray, theme.colorScheme.mediumDarkGray]
                                : [theme.colorScheme.brandPurple, theme.colorScheme.brandBlue],
                          ),
                          borderRadius: BorderRadius.circular(_kCardBorderRadius),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: theme.colorScheme.brandPurple.withAlpha((0.2 * 255).toInt()),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha((0.2 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.widgets,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Widget Podešavanja',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Prilagodite izgled booking widget-a za svaku jedinicu',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withAlpha((0.9 * 255).toInt()),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.15 * 255).toInt()),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Kliknite na jedinicu da podesite boje, branding i generišete embed kod',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withAlpha((0.95 * 255).toInt()),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Row
                      Container(
                        padding: const EdgeInsets.all(_kContentPadding),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withAlpha((0.1 * 255).toInt()),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              icon: Icons.apartment,
                              label: 'Ukupno jedinica',
                              value: '${units.length}',
                              color: theme.colorScheme.brandPurple,
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: theme.colorScheme.onSurface.withAlpha((0.1 * 255).toInt()),
                            ),
                            _StatItem(
                              icon: Icons.check_circle_outline,
                              label: 'Dostupne',
                              value: '${units.where((u) => u.isAvailable).length}',
                              color: theme.colorScheme.success,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),

                // Units List - Using SliverList.builder for performance
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: units.length,
                    itemBuilder: (context, index) => _UnitWidgetCard(unit: units[index]),
                  ),
                ),

                // Bottom spacing
                const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
              ],
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.brandPurple,
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: _kEmptyStateIconSize,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Greška pri učitavanju jedinica',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => ref.refresh(ownerUnitsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Pokušaj ponovo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.brandPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.brandPurple.withAlpha((0.1 * 255).toInt()),
              ),
              child: Icon(
                Icons.widgets_outlined,
                size: _kEmptyStateIconSize,
                color: theme.colorScheme.brandPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nema smještajnih jedinica',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Prvo kreirajte smještajnu jedinicu da biste mogli podesiti widget',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push(OwnerRoutes.properties),
              icon: const Icon(Icons.add),
              label: const Text('Dodaj jedinicu'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.brandPurple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: _kIconSize),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
          ),
        ),
      ],
    );
  }
}

/// Unit Widget Card
class _UnitWidgetCard extends ConsumerWidget {
  final UnitModel unit;

  const _UnitWidgetCard({required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_kCardBorderRadius),
        border: Border.all(
          color: theme.colorScheme.onSurface.withAlpha((0.1 * 255).toInt()),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha((0.04 * 255).toInt()),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Header with image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(_kCardBorderRadius)),
            child: unit.images.isNotEmpty
                ? Image.network(
                    unit.images.first,
                    height: _kUnitImageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    cacheHeight: (_kUnitImageHeight * MediaQuery.of(context).devicePixelRatio).round(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: _kUnitImageHeight,
                        color: theme.colorScheme.brandPurple.withAlpha((0.05 * 255).toInt()),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: theme.colorScheme.brandPurple,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: _kUnitImageHeight,
                        color: theme.colorScheme.brandPurple.withAlpha((0.1 * 255).toInt()),
                        child: Icon(
                          Icons.apartment,
                          size: 48,
                          color: theme.colorScheme.onSurface.withAlpha((0.3 * 255).toInt()),
                        ),
                      );
                    },
                  )
                : Container(
                    height: _kUnitImageHeight,
                    color: theme.colorScheme.brandPurple.withAlpha((0.1 * 255).toInt()),
                    child: Icon(
                      Icons.apartment,
                      size: 48,
                      color: theme.colorScheme.onSurface.withAlpha((0.3 * 255).toInt()),
                    ),
                  ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(_kHeaderCardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unit Name & Status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unit.id.isEmpty
                                ? 'ID: N/A'
                                : (unit.id.length > 8
                                    ? 'ID: ${unit.id.substring(0, 8)}...'
                                    : 'ID: ${unit.id}'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: unit.isAvailable
                            ? theme.colorScheme.success.withAlpha((0.1 * 255).toInt())
                            : theme.colorScheme.onSurface.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        unit.isAvailable ? 'Dostupna' : 'Nedostupna',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: unit.isAvailable
                              ? theme.colorScheme.success
                              : theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Info
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 380;
                    return Wrap(
                      spacing: isSmallScreen ? 8 : 16,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.people_outline,
                          label: '${unit.maxGuests} gostiju',
                        ),
                        _InfoChip(
                          icon: Icons.bed_outlined,
                          label: '${unit.bedrooms} spavaća soba',
                        ),
                        _InfoChip(
                          icon: Icons.euro,
                          label: '${unit.pricePerNight.toStringAsFixed(0)} €/noć',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    // Copy URL Button
                    Tooltip(
                      message: 'Kopiraj Widget URL',
                      child: IconButton.outlined(
                        onPressed: () {
                          // Validate unit ID
                          if (unit.id.isEmpty) {
                            ErrorDisplayUtils.showErrorSnackBar(
                              context,
                              Exception('Invalid unit ID'),
                              userMessage: 'Greška: ID jedinice nije validan',
                            );
                            return;
                          }

                          // Generate widget URL (same logic as embed_code_generator_dialog)
                          const widgetBaseUrl = 'https://rab-booking-widget.web.app';
                          String embedUrl;

                          if (unit.slug != null && unit.slug!.isNotEmpty) {
                            // Use hybrid slug URL (SEO-friendly)
                            final hybridSlug = generateHybridSlug(unit.slug!, unit.id);
                            embedUrl = '$widgetBaseUrl/booking/$hybridSlug';
                          } else {
                            // Fallback to query param URL
                            embedUrl = '$widgetBaseUrl?unit=${unit.id}';
                          }

                          Clipboard.setData(ClipboardData(text: embedUrl));
                          ErrorDisplayUtils.showSuccessSnackBar(
                            context,
                            'Widget URL kopiran u clipboard',
                          );
                        },
                        icon: const Icon(Icons.link, size: 20),
                        style: IconButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
                          padding: const EdgeInsets.all(12),
                          minimumSize: const Size(48, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Settings Button
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push(
                            OwnerRoutes.unitWidgetSettings.replaceAll(':id', unit.id),
                          );
                        },
                        icon: const Icon(Icons.tune, size: 20),
                        label: const Text('Podesi Widget'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
}

/// Info Chip Widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
          ),
        ),
      ],
    );
  }
}
