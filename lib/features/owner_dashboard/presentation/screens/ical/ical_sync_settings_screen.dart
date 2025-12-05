import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_color_extensions.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/config/router_owner.dart';
import '../../../domain/models/ical_feed.dart';
import '../../providers/ical_feeds_provider.dart';
import '../../providers/owner_properties_provider.dart';
import '../../widgets/owner_app_drawer.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

/// AppBar preferred height
const double _kAppBarHeight = 56.0;

/// Gradient colors for header
const Color _kGradientStart = Color(0xFF6B4CE6); // Purple
const Color _kGradientEnd = Color(0xFF7E5FEE); // Lighter purple

/// Status indicator colors (matching BookingStatus badge colors)
const Color _kStatusActiveColor = Color(0xFF66BB6A); // Green
const Color _kStatusPausedColor = Color(0xFFFFA726); // Orange
const Color _kStatusErrorColor = Color(0xFFEF5350); // Red

/// Card colors
const Color _kCardColorDark = Color(0xFF2D2D2D);

/// Content padding
const EdgeInsets _kContentPadding = EdgeInsets.fromLTRB(24, 100, 24, 24);

/// Dialog width constraints
const double _kDialogMaxWidth = 500.0;
const double _kDialogWidthFactor = 0.9;

/// Screen for managing iCal calendar sync feeds
class IcalSyncSettingsScreen extends ConsumerStatefulWidget {
  const IcalSyncSettingsScreen({super.key});

  @override
  ConsumerState<IcalSyncSettingsScreen> createState() => _IcalSyncSettingsScreenState();
}

class _IcalSyncSettingsScreenState extends ConsumerState<IcalSyncSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final feedsAsync = ref.watch(icalFeedsStreamProvider);
    final statsAsync = ref.watch(icalStatisticsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(_kAppBarHeight),
        child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [_kGradientStart, _kGradientEnd])),
          child: AppBar(
            title: Text(
              AppLocalizations.of(context).icalSyncTitle,
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
      drawer: const OwnerAppDrawer(currentRoute: 'integrations/ical'),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [_kGradientStart, _kGradientEnd])),
        child: statsAsync.when(
          data: (stats) => _buildContent(context, feedsAsync, stats, theme),
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (error, stackTrace) => _buildContent(context, feedsAsync, null, theme),
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
      padding: _kContentPadding,
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
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppLocalizations.of(context).icalErrorLoadingFeeds,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Add feed card section
          _buildAddFeedCard(),

          const SizedBox(height: 16),

          // Help link
          TextButton.icon(
            onPressed: () => context.go(OwnerRoutes.icalGuide),
            icon: const Icon(Icons.help_outline, color: Colors.white),
            label: Text(AppLocalizations.of(context).icalHowItWorks, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic>? stats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeFeeds = stats?['active_feeds'] as int? ?? 0;
    final errorFeeds = stats?['error_feeds'] as int? ?? 0;
    final totalFeeds = stats?['total_feeds'] as int? ?? 0;

    // Determine status
    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusDescription;

    final l10n = AppLocalizations.of(context);
    if (totalFeeds == 0) {
      statusColor = AppColors.textTertiaryLight;
      statusIcon = Icons.sync_disabled;
      statusTitle = l10n.icalNoFeeds;
      statusDescription = l10n.icalNoFeedsDescription;
    } else if (errorFeeds > 0) {
      statusColor = _kStatusErrorColor;
      statusIcon = Icons.error;
      statusTitle = l10n.icalSyncError;
      statusDescription = l10n.icalSyncErrorCount(errorFeeds, totalFeeds);
    } else if (activeFeeds > 0) {
      statusColor = _kStatusActiveColor;
      statusIcon = Icons.check_circle;
      statusTitle = l10n.icalSyncActive;
      statusDescription = l10n.icalSyncActiveCount(activeFeeds);
    } else {
      statusColor = _kStatusPausedColor;
      statusIcon = Icons.pause_circle;
      statusTitle = l10n.icalAllFeedsPaused;
      statusDescription = l10n.icalNoActiveFeeds;
    }

    final cardColor = isDark ? _kCardColorDark : AppColors.surfaceLight;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? Colors.white70 : AppColors.textSecondaryLight;

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withAlpha((0.3 * 255).toInt()), width: 2),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(statusDescription, style: TextStyle(fontSize: 13, color: textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.icalWhySync,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _buildInfoItem(Icons.sync_rounded, l10n.icalAutoSync, l10n.icalAutoSyncDesc),
        _buildInfoItem(Icons.calendar_today_rounded, l10n.icalPreventDoubleBooking, l10n.icalPreventDoubleBookingDesc),
        _buildInfoItem(Icons.check_circle_outline_rounded, l10n.icalCompatibility, l10n.icalCompatibilityDesc),
        _buildInfoItem(Icons.security_rounded, l10n.icalSecure, l10n.icalSecureDesc),
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.white.withAlpha((0.85 * 255).toInt()))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeedsCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? _kCardColorDark : AppColors.surfaceLight;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? Colors.white70 : AppColors.textSecondaryLight;
    final iconColor = isDark ? _kStatusActiveColor : AppColors.primary;
    final iconBgColor = isDark
        ? _kStatusActiveColor.withAlpha((0.15 * 255).toInt())
        : AppColors.primary.withAlpha((0.1 * 255).toInt());

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark
            ? BorderSide(color: _kStatusActiveColor.withAlpha((0.3 * 255).toInt()), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: iconBgColor),
              child: Icon(Icons.sync_disabled, size: 40, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).icalNoFeedsTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).icalNoFeedsSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFeedCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? _kCardColorDark : AppColors.surfaceLight;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? Colors.white70 : AppColors.textSecondaryLight;
    final iconColor = isDark ? _kStatusActiveColor : AppColors.primary;
    final iconBgColor = isDark
        ? _kStatusActiveColor.withAlpha((0.15 * 255).toInt())
        : AppColors.primary.withAlpha((0.1 * 255).toInt());
    final buttonBgColor = isDark ? _kStatusActiveColor : AppColors.primary;

    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark
            ? BorderSide(color: _kStatusActiveColor.withAlpha((0.3 * 255).toInt()), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle, color: iconBgColor),
              child: Icon(Icons.add_circle_outline, size: 28, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).icalAddFeed,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).icalAddFeedSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showAddFeedDialog(context),
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                AppLocalizations.of(context).icalAddFeedButton,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: buttonBgColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        Text(
          AppLocalizations.of(context).icalYourFeeds,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        ...feeds.map((feed) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildFeedCard(feed))),
      ],
    );
  }

  Widget _buildFeedCard(IcalFeed feed) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(feed.status, theme);
    final statusIcon = _getStatusIcon(feed.status);

    final cardColor = isDark ? _kCardColorDark : AppColors.surfaceLight;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimaryLight;
    final textSecondary = isDark ? Colors.white70 : AppColors.textSecondaryLight;
    final textTertiary = isDark ? Colors.white54 : AppColors.textTertiaryLight;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [statusColor.withValues(alpha: 0.8), statusColor]),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: Colors.white, size: 24),
        ),
        title: Text(
          feed.platformDisplayName,
          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).icalLastSynced(feed.getTimeSinceLastSync()),
              style: TextStyle(fontSize: 12, color: textSecondary),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (feed.hasError && feed.lastError != null)
              Text(
                AppLocalizations.of(context).icalErrorPrefix(feed.lastError!),
                style: const TextStyle(fontSize: 12, color: AppColors.error),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            Text(
              AppLocalizations.of(context).icalReservationsAndSyncs(feed.eventCount, feed.syncCount),
              style: TextStyle(fontSize: 12, color: textTertiary),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleFeedAction(value, feed),
          itemBuilder: (popupContext) {
            final l10n = AppLocalizations.of(context);
            return [
              PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [const Icon(Icons.sync, size: 18), const SizedBox(width: 8), Text(l10n.icalSyncNow)],
                ),
              ),
              PopupMenuItem(
                value: feed.isActive ? 'pause' : 'resume',
                child: Row(
                  children: [
                    Icon(feed.isActive ? Icons.pause : Icons.play_arrow, size: 18),
                    const SizedBox(width: 8),
                    Text(feed.isActive ? l10n.icalPause : l10n.icalResume),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 8), Text(l10n.edit)]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
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
        return _kStatusActiveColor;
      case 'error':
        return _kStatusErrorColor;
      case 'paused':
        return _kStatusPausedColor;
      default:
        return theme.colorScheme.outline;
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
    final l10n = AppLocalizations.of(context);
    ErrorDisplayUtils.showInfoSnackBar(context, l10n.icalSyncStarted(feed.platformDisplayName));

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
          ErrorDisplayUtils.showSuccessSnackBar(context, l10n.icalSyncSuccess(bookingsCreated));
        } else {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            message ?? l10n.icalUnknownError,
            userMessage: l10n.icalSyncErrorMessage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.icalSyncErrorMessage);
      }
    }
  }

  void _pauseFeed(IcalFeed feed) async {
    final l10n = AppLocalizations.of(context);
    try {
      final repository = ref.read(icalRepositoryProvider);
      await repository.updateFeedStatus(feed.id, 'paused');

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(context, l10n.icalFeedPaused);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.icalFeedPauseError);
      }
    }
  }

  void _resumeFeed(IcalFeed feed) async {
    final l10n = AppLocalizations.of(context);
    try {
      final repository = ref.read(icalRepositoryProvider);
      await repository.updateFeedStatus(feed.id, 'active');

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(context, l10n.icalFeedResumed);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: l10n.icalFeedResumeError);
      }
    }
  }

  void _confirmDeleteFeed(BuildContext context, IcalFeed feed) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.icalDeleteFeedTitle),
        content: Text(l10n.icalDeleteFeedMessage(feed.platformDisplayName, feed.eventCount)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              try {
                final repository = ref.read(icalRepositoryProvider);
                await repository.deleteIcalFeed(feed.id);

                // Invalidate providers to refresh UI immediately
                ref.invalidate(icalFeedsStreamProvider);
                ref.invalidate(icalStatisticsProvider);

                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.icalFeedDeleted), backgroundColor: theme.colorScheme.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.icalFeedDeleteError), backgroundColor: theme.colorScheme.danger),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showAddFeedDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddIcalFeedDialog());
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
    _icalUrlController = TextEditingController(text: widget.existingFeed?.icalUrl ?? '');

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
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > _kDialogMaxWidth ? _kDialogMaxWidth : screenWidth * _kDialogWidthFactor;

    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.authSecondary]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sync, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.existingFeed == null
                  ? AppLocalizations.of(context).icalAddFeedTitle
                  : AppLocalizations.of(context).icalEditFeedTitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimaryLight),
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
                    final l10n = AppLocalizations.of(context);
                    if (units.isEmpty) {
                      return Text(l10n.icalNoUnitsCreated, style: const TextStyle(color: AppColors.error));
                    }

                    // Validate that selected unit exists in the list
                    final validUnitId = units.any((u) => u.id == _selectedUnitId) ? _selectedUnitId : null;

                    return DropdownButtonFormField<String>(
                      initialValue: validUnitId,
                      decoration: InputDecoration(labelText: l10n.icalSelectUnit, border: const OutlineInputBorder()),
                      items: units.map((unit) {
                        return DropdownMenuItem(value: unit.id, child: Text(unit.name));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUnitId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.icalSelectUnitRequired;
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stackTrace) => Text(AppLocalizations.of(context).icalErrorLoadingUnits),
                ),

                const SizedBox(height: 16),

                // Platform selector
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    const validPlatforms = ['booking_com', 'airbnb', 'other'];
                    final validPlatform = validPlatforms.contains(_selectedPlatform)
                        ? _selectedPlatform
                        : 'booking_com';

                    return DropdownButtonFormField<String>(
                      initialValue: validPlatform,
                      decoration: InputDecoration(labelText: l10n.icalPlatform, border: const OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 'booking_com', child: Text(l10n.icalPlatformBookingCom)),
                        DropdownMenuItem(value: 'airbnb', child: Text(l10n.icalPlatformAirbnb)),
                        DropdownMenuItem(value: 'other', child: Text(l10n.icalPlatformOther)),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPlatform = value!;
                        });
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // iCal URL input
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return TextFormField(
                      controller: _icalUrlController,
                      decoration: InputDecoration(
                        labelText: l10n.icalUrlLabel,
                        hintText: l10n.icalUrlHint,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste),
                          onPressed: () async {
                            final clipboardData = await Clipboard.getData('text/plain');
                            if (clipboardData?.text != null) {
                              _icalUrlController.text = clipboardData!.text!;
                            }
                          },
                          tooltip: l10n.icalPasteFromClipboard,
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.icalUrlRequired;
                        }
                        if (!value.startsWith('http://') && !value.startsWith('https://')) {
                          return l10n.icalUrlInvalid;
                        }
                        return null;
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Info box with modern design
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.authSecondary]),
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
                                  l10n.icalAutoSyncInfo,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.icalAutoSyncInfoDesc,
                                  style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.8)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveFeed,
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  widget.existingFeed == null
                      ? AppLocalizations.of(context).icalAdd
                      : AppLocalizations.of(context).save,
                ),
        ),
      ],
    );
  }

  /// Trigger initial sync for newly added feed
  Future<void> _triggerInitialSync(String feedId, String platform) async {
    final l10n = AppLocalizations.of(context);
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
            l10n.icalInitialSyncSuccess(bookingsCreated),
            duration: const Duration(seconds: 4),
          );
        } else {
          ErrorDisplayUtils.showWarningSnackBar(
            context,
            l10n.icalInitialSyncFailed,
            duration: const Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showWarningSnackBar(context, l10n.icalInitialSyncError, duration: const Duration(seconds: 5));
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

      final l10n = AppLocalizations.of(context);
      String feedId;
      if (widget.existingFeed == null) {
        feedId = await repository.createIcalFeed(feed);

        // Invalidate providers to refresh UI immediately
        ref.invalidate(icalFeedsStreamProvider);
        ref.invalidate(icalStatisticsProvider);

        if (mounted) {
          Navigator.pop(context);
          ErrorDisplayUtils.showSuccessSnackBar(context, l10n.icalInitialSyncStarting);

          // Trigger initial sync automatically for new feeds
          unawaited(_triggerInitialSync(feedId, _selectedPlatform));
        }
      } else {
        await repository.updateIcalFeed(feed);

        // Invalidate providers to refresh UI immediately
        ref.invalidate(icalFeedsStreamProvider);
        ref.invalidate(icalStatisticsProvider);

        if (mounted) {
          Navigator.pop(context);
          ErrorDisplayUtils.showSuccessSnackBar(context, l10n.icalFeedUpdated);
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: AppLocalizations.of(context).icalFeedSaveError);
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
