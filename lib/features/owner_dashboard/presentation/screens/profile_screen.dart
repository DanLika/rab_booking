import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/config/router_owner.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/language_selection_bottom_sheet.dart';
import '../widgets/theme_selection_bottom_sheet.dart';

/// Profile screen for owner dashboard
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);
    final currentLocale = ref.watch(currentLocaleProvider);
    final currentThemeMode = ref.watch(currentThemeModeProvider);

    // Get language display name
    final languageName = currentLocale.languageCode == 'hr' ? 'Hrvatski' : 'English';

    // Get theme display name
    final themeName = currentThemeMode == ThemeMode.light
        ? 'Light'
        : currentThemeMode == ThemeMode.dark
            ? 'Dark'
            : 'System default';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: user == null
          ? const Center(child: Text('Not authenticated'))
          : userProfileAsync.when(
              data: (profile) {
                final displayName = profile?.displayName ?? user.displayName ?? 'Owner';
                final email = user.email ?? '';

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Profile header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                displayName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 16),

                    // Account settings
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Edit Profile'),
                            subtitle: const Text('Update your personal information'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              context.push(OwnerRoutes.profileEdit);
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.lock_outline),
                            title: const Text('Change Password'),
                            subtitle: const Text('Update your password'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              context.push(OwnerRoutes.profileChangePassword);
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: const Text('Notification Settings'),
                            subtitle: const Text('Manage your notifications'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              context.push(OwnerRoutes.profileNotifications);
                            },
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 16),

                    // App settings
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.language),
                            title: const Text('Language'),
                            subtitle: Text(languageName),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              showLanguageSelectionBottomSheet(context, ref);
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.brightness_6_outlined),
                            title: const Text('Theme'),
                            subtitle: Text(themeName),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              showThemeSelectionBottomSheet(context, ref);
                            },
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 16),

                    // Account actions
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.help_outline),
                            title: const Text('Help & Support'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Help & Support coming soon'),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: const Text('About'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('About coming soon'),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.red),
                            title: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () async {
                              await ref.read(authProvider.notifier).signOut();
                              if (context.mounted) {
                                context.go(OwnerRoutes.login);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading profile: $error'),
              ),
            ),
    );
  }
}
