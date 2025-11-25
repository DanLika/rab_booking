import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: 'iCal Export - Odaberi Jedinicu',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'integrations/ical/export-list'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: GradientTokens.brandPrimary,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : _allUnits.isEmpty
                  ? _buildEmptyState(context)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                      children: [
                  // Info card
                  Card(
                    color: AppColors.surfaceLight,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Odaberite smještajnu jedinicu za generisanje i pregled iCal export fajla.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Units list
                  ..._allUnits.map((item) {
                    final unit = item['unit'];
                    final property = item['property'];

                    return Card(
                      color: AppColors.surfaceLight,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.apartment,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          unit.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              property.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: 14,
                                  color: AppColors.textTertiaryLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Max ${unit.maxGuests} gostiju',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: FilledButton.icon(
                          onPressed: () {
                            context.push(
                              OwnerRoutes.icalExport,
                              extra: {
                                'unit': unit,
                                'propertyId': property.id,
                              },
                            );
                          },
                          icon: const Icon(Icons.upload, size: 18),
                          label: const Text('Export'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                Icons.apartment_outlined,
                size: 64,
                color: AppColors.textTertiaryLight,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nema smještajnih jedinica',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prvo kreirajte nekretninu i dodajte smještajne jedinice.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
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
