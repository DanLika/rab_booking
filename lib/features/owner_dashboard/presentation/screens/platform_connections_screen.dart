import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../domain/models/platform_connection.dart';
import '../providers/platform_connections_provider.dart';
import '../widgets/owner_app_drawer.dart';

/// Screen for managing platform connections (Booking.com, Airbnb API integrations)
class PlatformConnectionsScreen extends ConsumerStatefulWidget {
  final String? initialUnitId;
  const PlatformConnectionsScreen({super.key, this.initialUnitId});

  @override
  ConsumerState<PlatformConnectionsScreen> createState() =>
      _PlatformConnectionsScreenState();
}

class _PlatformConnectionsScreenState
    extends ConsumerState<PlatformConnectionsScreen> {
  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(platformConnectionsProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Platform Connections',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(
        currentRoute: 'integrations/platform-connections',
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(platformConnectionsProvider);
          },
          color: theme.colorScheme.primary,
          child: SingleChildScrollView(
            physics: PlatformScrollPhysics.adaptive,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(context, l10n),
                    const SizedBox(height: 24),

                    // Connections list
                    connectionsAsync.when(
                      data: (connections) =>
                          _buildConnectionsList(context, connections, l10n),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Error loading connections: $error'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Add connection buttons
                    _buildAddConnectionButtons(context, l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, size: 32, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Platform Connections',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Connect your Booking.com and Airbnb accounts to automatically block dates and prevent overbooking.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Warning about consequences
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50.withValues(
                  alpha: isDark ? 0.2 : 1.0,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Important: Automatic Date Blocking',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• When you create a booking in BookBed, dates will be automatically blocked on connected platforms.\n'
                    '• When a booking is completed, dates will be automatically unblocked.\n'
                    '• Cancelled bookings do NOT automatically unblock dates (to prevent accidental double-booking).\n'
                    '• Always verify sync status before making manual changes on external platforms.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade900,
                      height: 1.5,
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

  Widget _buildConnectionsList(
    BuildContext context,
    List<PlatformConnection> connections,
    AppLocalizations l10n,
  ) {
    if (connections.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.link_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No platform connections',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a connection to enable automatic date blocking',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: connections
          .map((connection) => _buildConnectionCard(context, connection, l10n))
          .toList(),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    PlatformConnection connection,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connection.platform == PlatformType.bookingCom
                      ? Icons.hotel
                      : Icons.home,
                  color: connection.status == ConnectionStatus.active
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection.platform.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SelectableText(
                        'Unit: ${connection.unitId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(connection.status.toFirestoreValue()),
                  backgroundColor: connection.status == ConnectionStatus.active
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _handleRemoveConnection(connection),
                ),
              ],
            ),
            if (connection.lastSyncedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last synced: ${connection.getTimeSinceLastSync()}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (connection.lastError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Error: ${connection.lastError}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddConnectionButtons(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Platform Connection',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _handleConnectBookingCom,
              icon: const Icon(Icons.hotel),
              label: const Text('Connect Booking.com'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _handleConnectAirbnb,
              icon: const Icon(Icons.home),
              label: const Text('Connect Airbnb'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConnectBookingCom() async {
    // Show warning dialog first
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Important Information'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By connecting your Booking.com account, you agree to the following:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '• Dates will be automatically blocked on Booking.com when you create bookings in BookBed.',
              ),
              SizedBox(height: 8),
              Text(
                '• Dates will be automatically unblocked when bookings are completed.',
              ),
              SizedBox(height: 8),
              Text(
                '• Cancelled bookings will NOT automatically unblock dates (to prevent double-booking).',
              ),
              SizedBox(height: 8),
              Text(
                '• You are responsible for verifying sync status and preventing conflicts.',
              ),
              SizedBox(height: 8),
              Text(
                '• BookBed is not responsible for double-booking caused by sync errors.',
              ),
              SizedBox(height: 16),
              Text(
                'Do you understand and agree to these terms?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('I Understand, Continue'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    // Show dialog to get hotel ID and room type ID
    final hotelIdController = TextEditingController();
    final roomTypeIdController = TextEditingController();
    final unitIdController = TextEditingController(
      text: widget.initialUnitId ?? '',
    );

    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connect Booking.com'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: unitIdController,
              decoration: const InputDecoration(
                labelText: 'Unit ID',
                hintText: 'Enter unit ID',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hotelIdController,
              decoration: const InputDecoration(
                labelText: 'Hotel ID',
                hintText: 'Enter Booking.com hotel ID',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: roomTypeIdController,
              decoration: const InputDecoration(
                labelText: 'Room Type ID',
                hintText: 'Enter Booking.com room type ID',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final connectAsync = await ref.read(
          connectBookingComProvider(
            unitId: unitIdController.text,
            hotelId: hotelIdController.text,
            roomTypeId: roomTypeIdController.text,
          ).future,
        );

        final authUrl = connectAsync['authorizationUrl'] as String?;
        if (authUrl != null && await canLaunchUrl(Uri.parse(authUrl))) {
          await launchUrl(
            Uri.parse(authUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(context, e);
        }
      }
    }
  }

  Future<void> _handleConnectAirbnb() async {
    // Show warning dialog first
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Important Information'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By connecting your Airbnb account, you agree to the following:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '• Dates will be automatically blocked on Airbnb when you create bookings in BookBed.',
              ),
              SizedBox(height: 8),
              Text(
                '• Dates will be automatically unblocked when bookings are completed.',
              ),
              SizedBox(height: 8),
              Text(
                '• Cancelled bookings will NOT automatically unblock dates (to prevent double-booking).',
              ),
              SizedBox(height: 8),
              Text(
                '• You are responsible for verifying sync status and preventing conflicts.',
              ),
              SizedBox(height: 8),
              Text(
                '• BookBed is not responsible for double-booking caused by sync errors.',
              ),
              SizedBox(height: 16),
              Text(
                'Do you understand and agree to these terms?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('I Understand, Continue'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    // Show dialog to get listing ID
    final listingIdController = TextEditingController();
    final unitIdController = TextEditingController(
      text: widget.initialUnitId ?? '',
    );

    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connect Airbnb'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: unitIdController,
              decoration: const InputDecoration(
                labelText: 'Unit ID',
                hintText: 'Enter unit ID',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: listingIdController,
              decoration: const InputDecoration(
                labelText: 'Listing ID',
                hintText: 'Enter Airbnb listing ID',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final connectAsync = await ref.read(
          connectAirbnbProvider(
            unitId: unitIdController.text,
            listingId: listingIdController.text,
          ).future,
        );

        final authUrl = connectAsync['authorizationUrl'] as String?;
        if (authUrl != null && await canLaunchUrl(Uri.parse(authUrl))) {
          await launchUrl(
            Uri.parse(authUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(context, e);
        }
      }
    }
  }

  Future<void> _handleRemoveConnection(PlatformConnection connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Connection'),
        content: Text(
          'Are you sure you want to remove the ${connection.platform.displayName} connection?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(removePlatformConnectionProvider(connection.id).future);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Connection removed')));
        }
      } catch (e) {
        if (mounted) {
          ErrorDisplayUtils.showErrorSnackBar(context, e);
        }
      }
    }
  }
}
