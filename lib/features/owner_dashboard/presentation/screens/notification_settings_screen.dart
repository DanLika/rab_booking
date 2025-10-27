import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/notification_preferences_model.dart';
import '../providers/user_profile_provider.dart';

/// Notification Settings Screen
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  NotificationPreferences? _currentPreferences;
  bool _isSaving = false;

  Future<void> _toggleMasterSwitch(bool value) async {
    if (_currentPreferences == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final updated = _currentPreferences!.copyWith(masterEnabled: value);
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateNotificationPreferences(updated);

      if (mounted) {
        setState(() {
          _currentPreferences = updated;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateCategory(
    String category,
    NotificationChannels channels,
  ) async {
    if (_currentPreferences == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      NotificationCategories updatedCategories;

      switch (category) {
        case 'bookings':
          updatedCategories =
              _currentPreferences!.categories.copyWith(bookings: channels);
          break;
        case 'payments':
          updatedCategories =
              _currentPreferences!.categories.copyWith(payments: channels);
          break;
        case 'calendar':
          updatedCategories =
              _currentPreferences!.categories.copyWith(calendar: channels);
          break;
        case 'marketing':
          updatedCategories =
              _currentPreferences!.categories.copyWith(marketing: channels);
          break;
        default:
          return;
      }

      final updated =
          _currentPreferences!.copyWith(categories: updatedCategories);

      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateNotificationPreferences(updated);

      if (mounted) {
        setState(() {
          _currentPreferences = updated;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: preferencesAsync.when(
        data: (preferences) {
          // Initialize with default preferences if none exist
          _currentPreferences ??= preferences ??
              NotificationPreferences(
                userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              );

          final masterEnabled = _currentPreferences!.masterEnabled;
          final categories = _currentPreferences!.categories;

          return ListView(
            children: [
              // Master Switch
              Card(
                margin: const EdgeInsets.all(16),
                color: masterEnabled ? Colors.blue.shade50 : Colors.grey.shade100,
                child: SwitchListTile(
                  value: masterEnabled,
                  onChanged: _isSaving ? null : _toggleMasterSwitch,
                  title: const Text(
                    'Enable All Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Master switch for all notification types',
                  ),
                  secondary: Icon(
                    masterEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: masterEnabled ? Colors.blue : Colors.grey,
                  ),
                ),
              ),

              // Info message when disabled
              if (!masterEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Notifications are disabled. Enable the master switch to receive notifications.',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Notification Categories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),

              // Bookings Category
              _buildCategoryCard(
                context: context,
                title: 'Bookings',
                description:
                    'New bookings, cancellations, and booking updates',
                icon: Icons.event_note,
                iconColor: Colors.blue,
                channels: categories.bookings,
                enabled: masterEnabled,
                onChanged: (channels) =>
                    _updateCategory('bookings', channels),
              ),

              // Payments Category
              _buildCategoryCard(
                context: context,
                title: 'Payments',
                description: 'Payment confirmations and transaction updates',
                icon: Icons.payment,
                iconColor: Colors.green,
                channels: categories.payments,
                enabled: masterEnabled,
                onChanged: (channels) =>
                    _updateCategory('payments', channels),
              ),

              // Calendar Category
              _buildCategoryCard(
                context: context,
                title: 'Calendar',
                description:
                    'Availability changes, blocked dates, and price updates',
                icon: Icons.calendar_today,
                iconColor: Colors.orange,
                channels: categories.calendar,
                enabled: masterEnabled,
                onChanged: (channels) =>
                    _updateCategory('calendar', channels),
              ),

              // Marketing Category
              _buildCategoryCard(
                context: context,
                title: 'Marketing',
                description: 'Promotional offers, tips, and platform news',
                icon: Icons.campaign,
                iconColor: Colors.purple,
                channels: categories.marketing,
                enabled: masterEnabled,
                onChanged: (channels) =>
                    _updateCategory('marketing', channels),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading preferences: $error'),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required NotificationChannels channels,
    required bool enabled,
    required Function(NotificationChannels) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        children: [
          const Divider(height: 1),
          SwitchListTile(
            value: enabled && channels.email,
            onChanged: enabled && !_isSaving
                ? (value) {
                    onChanged(channels.copyWith(email: value));
                  }
                : null,
            title: const Text('Email'),
            subtitle: const Text('Receive notifications via email'),
            secondary: Icon(
              Icons.email_outlined,
              color: enabled ? Colors.blue : Colors.grey,
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: enabled && channels.push,
            onChanged: enabled && !_isSaving
                ? (value) {
                    onChanged(channels.copyWith(push: value));
                  }
                : null,
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive push notifications on your device'),
            secondary: Icon(
              Icons.notifications_outlined,
              color: enabled ? Colors.orange : Colors.grey,
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: enabled && channels.sms,
            onChanged: enabled && !_isSaving
                ? (value) {
                    onChanged(channels.copyWith(sms: value));
                  }
                : null,
            title: const Text('SMS'),
            subtitle: const Text('Receive notifications via SMS'),
            secondary: Icon(
              Icons.sms_outlined,
              color: enabled ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
