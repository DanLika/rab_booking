import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../widgets/owner_app_drawer.dart';
import '../../providers/owner_properties_provider.dart';

/// Screen that lists all units for iCal export selection
class IcalExportListScreen extends ConsumerStatefulWidget {
  const IcalExportListScreen({super.key});

  @override
  ConsumerState<IcalExportListScreen> createState() => _IcalExportListScreenState();
}

class _IcalExportListScreenState extends ConsumerState<IcalExportListScreen> {
  List<Map<String, dynamic>> _allUnits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    try {
      final properties = await ref.read(ownerPropertiesProvider.future);
      final List<Map<String, dynamic>> units = [];

      for (final property in properties) {
        final propertyUnits = await ref
            .read(unitRepositoryProvider)
            .fetchUnitsByProperty(property.id);

        for (final unit in propertyUnits) {
          units.add({
            'unit': unit,
            'property': property,
          });
        }
      }

      if (mounted) {
        setState(() {
          _allUnits = units;
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

    // Hardcoded horizontal gradient colors (left → right)
    const gradientStart = Color(0xFF6B4CE6); // Purple
    const gradientEnd = Color(0xFF7E5FEE); // Lighter purple

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientStart, gradientEnd],
            ),
          ),
          child: AppBar(
            title: Text(
              'iCal Export - Odaberi Jedinicu',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
          ),
        ),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'integrations/ical/export-list'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : _allUnits.isEmpty
                  ? _buildEmptyState(context, theme)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                      children: [
                  // Info card
                  _buildInfoCard(theme),
                  const SizedBox(height: 16),

                  // Units list
                  ..._allUnits.map((item) {
                    final unit = item['unit'];
                    final property = item['property'];
                    return _buildUnitCard(unit, property, theme);
                  }),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    const cardColorDark = Color(0xFF2D2D2D);
    const confirmedGreen = Color(0xFF66BB6A);

    final cardColor = isDark ? cardColorDark : AppColors.surfaceLight;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? Colors.white70 : AppColors.textSecondaryLight;
    final borderColor = isDark
        ? confirmedGreen.withAlpha((0.3 * 255).toInt())
        : Colors.transparent;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: confirmedGreen.withAlpha((0.2 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline,
                color: confirmedGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'iCal Export',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Odaberite jedinicu za koju želite generirati iCal URL za sinkronizaciju kalendara.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
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

  Widget _buildUnitCard(dynamic unit, dynamic property, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    const cardColorDark = Color(0xFF2D2D2D);
    const confirmedGreen = Color(0xFF66BB6A);

    final cardColor = isDark ? cardColorDark : AppColors.surfaceLight;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? Colors.white70 : AppColors.textSecondaryLight;
    final borderColor = isDark
        ? confirmedGreen.withAlpha((0.3 * 255).toInt())
        : Colors.transparent;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((0.15 * 255).toInt()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.apartment,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          unit.name ?? 'Nepoznata jedinica',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Text(
          property.name ?? 'Nepoznata nekretnina',
          style: TextStyle(
            color: textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: textSecondary,
        ),
        onTap: () {
          context.push(
            OwnerRoutes.icalExport,
            extra: {
              'unit': unit,
              'propertyId': property.id,
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    const cardColorDark = Color(0xFF2D2D2D);

    final cardColor = isDark ? cardColorDark : AppColors.surfaceLight;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? Colors.white70 : AppColors.textSecondaryLight;
    final iconColor = isDark ? Colors.white54 : AppColors.textTertiaryLight;

    return Center(
      child: Card(
        color: cardColor,
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.apartment_outlined,
                size: 64,
                color: iconColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Nema smještajnih jedinica',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prvo kreirajte nekretninu i dodajte smještajne jedinice.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go(OwnerRoutes.properties),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj Nekretninu'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Card(
        color: AppColors.surfaceLight,
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Greška pri učitavanju',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
