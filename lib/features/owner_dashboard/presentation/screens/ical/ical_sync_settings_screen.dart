import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_color_extensions.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../domain/models/ical_feed.dart';
import '../../providers/ical_feeds_provider.dart';
import '../../providers/owner_properties_provider.dart';
import '../../widgets/owner_app_drawer.dart';
import '../../../../../shared/widgets/common_app_bar.dart';

/// Screen for managing iCal calendar sync feeds
class IcalSyncSettingsScreen extends ConsumerStatefulWidget {
  const IcalSyncSettingsScreen({super.key});

  @override
  ConsumerState<IcalSyncSettingsScreen> createState() =>
      _IcalSyncSettingsScreenState();
}

class _IcalSyncSettingsScreenState
    extends ConsumerState<IcalSyncSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final feedsAsync = ref.watch(icalFeedsStreamProvider);
    final statsAsync = ref.watch(icalStatisticsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: 'iCal Sinhronizacija',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'integrations/ical'),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.authSecondary],
          ),
        ),
        child: statsAsync.when(
          data: (stats) => _buildContent(context, feedsAsync, stats, theme),
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
          error: (error, stackTrace) =>
              _buildContent(context, feedsAsync, null, theme),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<List<IcalFeed>> feedsAsync,
    Map<String, dynamic>? stats,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status card
          _buildStatusCard(stats),

          const SizedBox(height: 24),

          // Info section
          _buildInfoSection(),

          const SizedBox(height: 32),

          // Feeds list section
          feedsAsync.when(
            data: (feeds) {
              if (feeds.isEmpty) {
                return _buildEmptyFeedsCard();
              }
              return _buildFeedsList(feeds);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
            error: (error, stack) => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Greška pri učitavanju feedova',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Add feed button
          FilledButton.icon(
            onPressed: () => _showAddFeedDialog(context),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Dodaj iCal Feed',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Help link
          TextButton.icon(
            onPressed: () => context.go(OwnerRoutes.icalGuide),
            icon: const Icon(
              Icons.help_outline,
              color: Colors.white,
            ),
            label: const Text(
              'Kako funkcionira iCal sinhronizacija?',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic>? stats) {
    final theme = Theme.of(context);
    final activeFeeds = stats?['active_feeds'] as int? ?? 0;
    final errorFeeds = stats?['error_feeds'] as int? ?? 0;
    final totalFeeds = stats?['total_feeds'] as int? ?? 0;

    // Determine status
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDescription;

    if (totalFeeds == 0) {
      statusColor = theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt());
      statusIcon = Icons.sync_disabled;
      statusTitle = 'Nema feedova';
      statusDescription = 'Dodajte prvi iCal feed da započnete sinhronizaciju';
    } else if (errorFeeds > 0) {
      statusColor = theme.colorScheme.danger;
      statusIcon = Icons.error;
      statusTitle = 'Greška u sinhronizaciji';
      statusDescription = '$errorFeeds od $totalFeeds feedova ima grešku';
    } else if (activeFeeds > 0) {
      statusColor = theme.colorScheme.success;
      statusIcon = Icons.check_circle;
      statusTitle = 'Sinhronizacija aktivna';
      statusDescription = '$activeFeeds feedova aktivno sinhronizovano';
    } else {
      statusColor = theme.colorScheme.warning;
      statusIcon = Icons.pause_circle;
      statusTitle = 'Svi feedovi pauzirani';
      statusDescription = 'Nema aktivnih feedova';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withAlpha((0.3 * 255).toInt()),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: statusColor.withAlpha((0.2 * 255).toInt()),
              child: Icon(statusIcon, color: statusColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withAlpha(
                        (0.6 * 255).toInt(),
                      ),
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

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Zašto iCal Sinhronizacija?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          Icons.sync_rounded,
          'Automatska Sinhronizacija',
          'Rezervacije se automatski uvozе sa booking platformi svakih 60 minuta',
        ),
        _buildInfoItem(
          Icons.calendar_today_rounded,
          'Sprečavanje Duplog Bukinga',
          'Blokirajte termine na svim platformama automatski',
        ),
        _buildInfoItem(
          Icons.check_circle_outline_rounded,
          'Kompatibilnost',
          'Podržava Booking.com, Airbnb, Expedia, VRBO i druge platforme',
        ),
        _buildInfoItem(
          Icons.security_rounded,
          'Sigurno i Pouzdano',
          'Enkriptovani podaci i automatski backup svih rezervacija',
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withAlpha((0.85 * 255).toInt()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeedsCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.brandPurple.withAlpha(
                  (0.1 * 255).toInt(),
                ),
              ),
              child: Icon(
                Icons.sync_disabled,
                size: 40,
                color: theme.colorScheme.brandPurple,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nema iCal Feedova',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Dodajte iCal feed da sinhronizujete rezervacije sa booking platformama',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.6 * 255).toInt(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedsList(List<IcalFeed> feeds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vaši Feedovi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...feeds.map(
          (feed) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFeedCard(feed),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedCard(IcalFeed feed) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(feed.status, theme);
    final statusIcon = _getStatusIcon(feed.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [statusColor.withValues(alpha: 0.8), statusColor],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: Colors.white, size: 24),
        ),
        title: Text(
          feed.platformDisplayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Zadnje sinhronizovano: ${feed.getTimeSinceLastSync()}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.6 * 255).toInt(),
                ),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (feed.hasError && feed.lastError != null)
              Text(
                'Greška: ${feed.lastError}',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            Text(
              '${feed.eventCount} rezervacija • ${feed.syncCount} sinhronizacija',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.6 * 255).toInt(),
                ),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleFeedAction(value, feed),
          itemBuilder: (popupContext) {
            final errorColor = Theme.of(popupContext).colorScheme.error;
            return [
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
                    Icon(
                      feed.isActive ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
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
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: errorColor),
                    const SizedBox(width: 8),
                    Text('Obriši', style: TextStyle(color: errorColor)),
                  ],
                ),
              ),
            ];
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'active':
        return theme.colorScheme.success; // Green for active
      case 'error':
        return theme.colorScheme.danger; // Red for errors
      case 'paused':
        return theme.colorScheme.warning; // Orange for paused
      default:
        return theme.colorScheme.outline; // Theme-aware neutral color
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
    ErrorDisplayUtils.showInfoSnackBar(
      context,
      'Sinhronizacija pokrenuta za ${feed.platformDisplayName}...',
    );

    try {
      // Call Cloud Function to sync this specific feed
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('syncIcalFeedNow');

      final result = await callable.call({'feedId': feed.id});

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
            message ?? 'Nepoznata greška',
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Obriši Feed?'),
        content: Text(
          'Da li ste sigurni da želite obrisati ${feed.platformDisplayName} feed? '
          'Ova akcija će obrisati ${feed.eventCount} sinhronizovanih rezervacija.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              try {
                final repository = ref.read(icalRepositoryProvider);
                await repository.deleteIcalFeed(feed.id);

                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Feed obrisan'),
                      backgroundColor: theme.colorScheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Greška prilikom brisanja feeda'),
                      backgroundColor: theme.colorScheme.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
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
    final theme = Theme.of(context);
    final unitsAsync = ref.watch(ownerUnitsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 500 ? 500.0 : screenWidth * 0.9;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.brandPurple,
                  theme.colorScheme.brandBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sync, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.existingFeed == null
                  ? 'Dodaj iCal Feed'
                  : 'Uredi iCal Feed',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
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
                      return Text(
                        'Nemate kreiranih jedinica. Prvo kreirajte apartman.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
                  error: (error, stackTrace) =>
                      const Text('Greška učitavanja jedinica'),
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
                    DropdownMenuItem(
                      value: 'booking_com',
                      child: Text('Booking.com'),
                    ),
                    DropdownMenuItem(value: 'airbnb', child: Text('Airbnb')),
                    DropdownMenuItem(value: 'expedia', child: Text('Expedia')),
                    DropdownMenuItem(value: 'vrbo', child: Text('VRBO')),
                    DropdownMenuItem(
                      value: 'homeaway',
                      child: Text('HomeAway'),
                    ),
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
                        final clipboardData = await Clipboard.getData(
                          'text/plain',
                        );
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
                    if (!value.startsWith('http://') &&
                        !value.startsWith('https://')) {
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
                        theme.colorScheme.brandPurple.withValues(alpha: 0.1),
                        theme.colorScheme.brandPurple.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.brandPurple.withValues(
                        alpha: 0.3,
                      ),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.brandPurple,
                              theme.colorScheme.brandBlue,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 16,
                        ),
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
                                color: theme.colorScheme.brandPurple.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rezervacije će se automatski sinhronizovati svakih 60 minuta. Inicijalna sinhronizacija će se pokrenuti odmah nakon dodavanja.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.brandPurple.withValues(
                                  alpha: 0.8,
                                ),
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
          unawaited(_triggerInitialSync(feedId, _selectedPlatform));
        }
      } else {
        await repository.updateIcalFeed(feed);

        if (mounted) {
          Navigator.pop(context);
          ErrorDisplayUtils.showSuccessSnackBar(context, 'Feed ažuriran');
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
