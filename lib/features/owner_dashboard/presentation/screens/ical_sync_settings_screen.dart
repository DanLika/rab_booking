import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/config/router_owner.dart';
import '../../domain/models/ical_feed.dart';
import '../providers/ical_feeds_provider.dart';
import '../providers/owner_properties_provider.dart';
import '../widgets/owner_app_drawer.dart';

/// Screen for managing iCal calendar sync feeds
class IcalSyncSettingsScreen extends ConsumerStatefulWidget {
  const IcalSyncSettingsScreen({super.key});

  @override
  ConsumerState<IcalSyncSettingsScreen> createState() => _IcalSyncSettingsScreenState();
}

class _IcalSyncSettingsScreenState extends ConsumerState<IcalSyncSettingsScreen> {
  final Set<String> _syncingFeedIds = {};
  String? _deletingFeedId;

  @override
  Widget build(BuildContext context) {
    final feedsAsync = ref.watch(icalFeedsStreamProvider);
    final statsAsync = ref.watch(icalStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('iCal Sinhronizacija'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.go(OwnerRoutes.guideIcal),
            tooltip: 'Pomoć',
          ),
        ],
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'ical-sync'),
      body: Column(
        children: [
          // Statistics card
          statsAsync.when(
            data: (stats) => _buildStatisticsCard(stats),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),

          const Divider(),

          // Feeds list
          Expanded(
            child: feedsAsync.when(
              data: (feeds) {
                if (feeds.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: feeds.length,
                  itemBuilder: (context, index) {
                    return _buildFeedCard(feeds[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Greška: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFeedDialog(context),
        backgroundColor: const Color(0xFF6B4CE6),
        tooltip: 'Dodaj iCal Feed',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> stats) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B4CE6), Color(0xFF4A90E2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sync, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Statistika Sinhronizacije',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Ukupno',
                  stats['total_feeds']?.toString() ?? '0',
                  Icons.feed,
                  const Color(0xFF6B4CE6), // Purple
                ),
                _buildStatItem(
                  'Aktivno',
                  stats['active_feeds']?.toString() ?? '0',
                  Icons.check_circle,
                  const Color(0xFF10B981), // Green
                ),
                _buildStatItem(
                  'Greška',
                  stats['error_feeds']?.toString() ?? '0',
                  Icons.error,
                  const Color(0xFFEF4444), // Red
                ),
                _buildStatItem(
                  'Eventi',
                  stats['total_events']?.toString() ?? '0',
                  Icons.event,
                  const Color(0xFF3B82F6), // Blue
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(IcalFeed feed) {
    if (_deletingFeedId == feed.id) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircularProgressIndicator(),
          title: Text('Brisanje u toku...'),
        ),
      );
    }

    final statusColor = _getStatusColor(feed.status);
    final statusIcon = _getStatusIcon(feed.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withValues(alpha: 0.8),
                statusColor,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: Colors.white, size: 24),
        ),
        title: Text(
          feed.platformDisplayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Zadnje sinhronizovano: ${feed.getTimeSinceLastSync()}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (feed.hasError && feed.lastError != null)
              Text(
                'Greška: ${feed.lastError}',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            Text(
              '${feed.eventCount} rezervacija • ${feed.syncCount} sinhronizacija',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: _syncingFeedIds.contains(feed.id)
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              )
            : PopupMenuButton<String>(
                onSelected: (value) => _handleFeedAction(value, feed),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'sync',
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 18),
                        SizedBox(width: 8),
                        Text('Sinhronizuj sada'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: feed.isActive ? 'pause' : 'resume',
                    child: Row(
                      children: [
                        Icon(feed.isActive ? Icons.pause : Icons.play_arrow, size: 18),
                        const SizedBox(width: 8),
                        Text(feed.isActive ? 'Pauziraj' : 'Nastavi'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Uredi'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Obriši', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern icon with background
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6B4CE6).withAlpha((0.1 * 255).toInt()),
                    const Color(0xFF6B4CE6).withAlpha((0.05 * 255).toInt()),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF6B4CE6).withAlpha((0.2 * 255).toInt()),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.sync_disabled,
                size: 70,
                color: Color(0xFF6B4CE6),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Nema iCal Feedova',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Dodajte iCal feed da sinhronizujete rezervacije sa Booking.com, Airbnb i drugim platformama.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Modern button
            ElevatedButton.icon(
              onPressed: () => _showAddFeedDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4CE6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                'Dodaj Prvi Feed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success; // Green for active
      case 'error':
        return AppColors.error; // Red for errors
      case 'paused':
        return AppColors.warning; // Orange for paused
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'paused':
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }

  void _handleFeedAction(String action, IcalFeed feed) {
    switch (action) {
      case 'sync':
        _syncFeedNow(feed);
        break;
      case 'pause':
        _pauseFeed(feed);
        break;
      case 'resume':
        _resumeFeed(feed);
        break;
      case 'edit':
        _showEditFeedDialog(context, feed);
        break;
      case 'delete':
        _confirmDeleteFeed(context, feed);
        break;
    }
  }

  void _syncFeedNow(IcalFeed feed) async {
    // Prevent starting a sync if one is already in progress for this feed
    if (_syncingFeedIds.contains(feed.id)) return;

    setState(() {
      _syncingFeedIds.add(feed.id);
    });

    ErrorDisplayUtils.showInfoSnackBar(
      context,
      'Sinhronizacija pokrenuta za ${feed.platformDisplayName}...',
    );

    try {
      // Call Cloud Function to sync this specific feed
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('syncIcalFeedNow');

      final result = await callable.call({
        'feedId': feed.id,
      });

      if (mounted) {
        final data = result.data as Map<String, dynamic>?;
        final success = data?['success'] ?? false;
        final message = data?['message'] as String?;
        final bookingsCreated = data?['bookingsCreated'] as int? ?? 0;

        if (success) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            'Sinhronizacija uspješna! Kreirano rezervacija: $bookingsCreated',
          );
        } else {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            message ?? "Nepoznata greška",
            userMessage: 'Greška prilikom sinhronizacije',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška prilikom sinhronizacije',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _syncingFeedIds.remove(feed.id);
        });
      }
    }
  }

  void _pauseFeed(IcalFeed feed) async {
    try {
      final repository = ref.read(icalRepositoryProvider);
      await repository.updateFeedStatus(feed.id, 'paused');

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(context, 'Feed pauziran');
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška prilikom pauziranja feeda',
        );
      }
    }
  }

  void _resumeFeed(IcalFeed feed) async {
    try {
      final repository = ref.read(icalRepositoryProvider);
      await repository.updateFeedStatus(feed.id, 'active');

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(context, 'Feed nastavljen');
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška prilikom nastavljanja feeda',
        );
      }
    }
  }

  void _confirmDeleteFeed(BuildContext context, IcalFeed feed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši Feed?'),
        content: Text(
          'Da li ste sigurni da želite obrisati ${feed.platformDisplayName} feed? '
          'Ova akcija će obrisati ${feed.eventCount} sinhronizovanih rezervacija.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _deletingFeedId = feed.id;
              });
              try {
                final repository = ref.read(icalRepositoryProvider);
                await repository.deleteIcalFeed(feed.id);

                if (mounted) {
                  ErrorDisplayUtils.showSuccessSnackBar(context, 'Feed obrisan');
                }
              } catch (e) {
                if (mounted) {
                  ErrorDisplayUtils.showErrorSnackBar(
                    context,
                    e,
                    userMessage: 'Greška prilikom brisanja feeda',
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _deletingFeedId = null;
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
  }

  void _showAddFeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddIcalFeedDialog(),
    );
  }

  void _showEditFeedDialog(BuildContext context, IcalFeed feed) {
    showDialog(
      context: context,
      builder: (context) => AddIcalFeedDialog(existingFeed: feed),
    );
  }

}

/// Dialog for adding/editing iCal feed
class AddIcalFeedDialog extends ConsumerStatefulWidget {
  final IcalFeed? existingFeed;

  const AddIcalFeedDialog({super.key, this.existingFeed});

  @override
  ConsumerState<AddIcalFeedDialog> createState() => _AddIcalFeedDialogState();
}

class _AddIcalFeedDialogState extends ConsumerState<AddIcalFeedDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _icalUrlController;

  String? _selectedUnitId;
  String _selectedPlatform = 'booking_com';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _icalUrlController = TextEditingController(
      text: widget.existingFeed?.icalUrl ?? '',
    );

    if (widget.existingFeed != null) {
      _selectedUnitId = widget.existingFeed!.unitId;
      _selectedPlatform = widget.existingFeed!.platform;
    }
  }

  @override
  void dispose() {
    _icalUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(ownerUnitsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B4CE6), Color(0xFF4A90E2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sync, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(widget.existingFeed == null ? 'Dodaj iCal Feed' : 'Uredi iCal Feed'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unit selector
                unitsAsync.when(
                  data: (units) {
                    if (units.isEmpty) {
                      return const Text(
                        'Nemate kreiranih jedinica. Prvo kreirajte apartman.',
                        style: TextStyle(color: Colors.red),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedUnitId,
                      decoration: const InputDecoration(
                        labelText: 'Odaberi jedinicu *',
                        border: OutlineInputBorder(),
                      ),
                      items: units.map((unit) {
                        return DropdownMenuItem(
                          value: unit.id,
                          child: Text(unit.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnitId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Molimo odaberite jedinicu';
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => const Text('Greška učitavanja jedinica'),
                ),

                const SizedBox(height: 16),

                // Platform selector
                DropdownButtonFormField<String>(
                  initialValue: _selectedPlatform,
                  decoration: const InputDecoration(
                    labelText: 'Platforma *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'booking_com', child: Text('Booking.com')),
                    DropdownMenuItem(value: 'airbnb', child: Text('Airbnb')),
                    DropdownMenuItem(value: 'expedia', child: Text('Expedia')),
                    DropdownMenuItem(value: 'vrbo', child: Text('VRBO')),
                    DropdownMenuItem(value: 'homeaway', child: Text('HomeAway')),
                    DropdownMenuItem(value: 'other', child: Text('Druga')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPlatform = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // iCal URL input
                TextFormField(
                  controller: _icalUrlController,
                  decoration: InputDecoration(
                    labelText: 'iCal URL *',
                    hintText: 'https://...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste),
                      onPressed: () async {
                        final clipboardData = await Clipboard.getData('text/plain');
                        if (clipboardData?.text != null) {
                          _icalUrlController.text = clipboardData!.text!;
                        }
                      },
                      tooltip: 'Zalijepi iz clipboard-a',
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Molimo unesite iCal URL';
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'URL mora početi sa http:// ili https://';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Info box with modern design
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.1),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B4CE6), Color(0xFF4A90E2)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Automatska sinhronizacija',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rezervacije će se automatski sinhronizovati svakih 60 minuta. Inicijalna sinhronizacija će se pokrenuti odmah nakon dodavanja.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary.withValues(alpha: 0.8),
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
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Otkaži'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveFeed,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingFeed == null ? 'Dodaj' : 'Sačuvaj'),
        ),
      ],
    );
  }

  /// Trigger initial sync for newly added feed
  Future<void> _triggerInitialSync(String feedId, String platform) async {
    try {
      // Call Cloud Function to sync immediately
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('syncIcalFeedNow');

      final result = await callable.call({'feedId': feedId});

      if (mounted) {
        final data = result.data as Map<String, dynamic>?;
        final success = data?['success'] ?? false;
        final bookingsCreated = data?['bookingsCreated'] as int? ?? 0;

        if (success) {
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            'Inicijalna sinhronizacija završena! Uvezeno: $bookingsCreated rezervacija',
            duration: const Duration(seconds: 4),
          );
        } else {
          ErrorDisplayUtils.showWarningSnackBar(
            context,
            'Feed je dodan, ali inicijalna sinhronizacija nije uspjela. Sinhronizacija će se automatski pokrenuti za 60 minuta.',
            duration: const Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showWarningSnackBar(
          context,
          'Feed je dodan, ali automatska sinhronizacija nije uspjela. Možete ručno pokrenuti sinhronizaciju kasnije.',
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  Future<void> _saveFeed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final units = await ref.read(ownerUnitsProvider.future);
      final unit = units.firstWhere((u) => u.id == _selectedUnitId);

      final feed = IcalFeed(
        id: widget.existingFeed?.id ?? '',
        unitId: _selectedUnitId!,
        propertyId: unit.propertyId,
        platform: _selectedPlatform,
        icalUrl: _icalUrlController.text.trim(),
        syncIntervalMinutes: 60,
        status: 'active',
        createdAt: widget.existingFeed?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repository = ref.read(icalRepositoryProvider);

      String feedId;
      if (widget.existingFeed == null) {
        feedId = await repository.createIcalFeed(feed);

        if (mounted) {
          Navigator.pop(context);
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            'Feed uspješno dodan! Pokrećem inicijalnu sinhronizaciju...',
          );

          // Trigger initial sync automatically for new feeds
          _triggerInitialSync(feedId, _selectedPlatform);
        }
      } else {
        await repository.updateIcalFeed(feed);

        if (mounted) {
          Navigator.pop(context);
          ErrorDisplayUtils.showSuccessSnackBar(
            context,
            'Feed ažuriran',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška prilikom čuvanja feeda',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
