import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/profile/presentation/widgets/profile_header.dart';
import '../../../../features/profile/presentation/widgets/stats_cards.dart';
import '../../../../features/profile/presentation/widgets/settings_section.dart';
import '../../../../features/profile/presentation/widgets/edit_profile_dialog.dart';
import '../../../../features/profile/presentation/widgets/avatar_picker_dialog.dart';
import '../../../../features/profile/presentation/widgets/language_selection_dialog.dart';
import '../../../../features/profile/presentation/screens/change_password_screen.dart';
import '../../../../features/profile/data/profile_service.dart';
import '../../../../features/profile/presentation/providers/user_stats_provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium profile screen
/// Features: Profile header, stats cards, settings sections, edit functionality
class PremiumProfileScreen extends ConsumerStatefulWidget {
  const PremiumProfileScreen({super.key});

  @override
  ConsumerState<PremiumProfileScreen> createState() =>
      _PremiumProfileScreenState();
}

class _PremiumProfileScreenState extends ConsumerState<PremiumProfileScreen> {
  bool _isLoading = false;

  /// Convert Supabase User + profile to UserModel
  UserModel? _getUserModel(AuthState authState) {
    if (authState.user == null) return null;

    final profile = authState.profile;
    if (profile == null) {
      // Create minimal UserModel with just email
      return UserModel(
        id: authState.user!.id,
        email: authState.user!.email ?? '',
        firstName: '',
        lastName: '',
        role: _parseRole(authState.role),
        createdAt: _parseDateTime(authState.user!.createdAt) ?? DateTime.now(),
      );
    }

    return UserModel(
      id: authState.user!.id,
      email: authState.user!.email ?? '',
      firstName: profile['first_name'] as String? ?? '',
      lastName: profile['last_name'] as String? ?? '',
      role: _parseRole(profile['role'] as String? ?? authState.role),
      phone: profile['phone'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      createdAt: _parseDateTime(profile['created_at']) ?? _parseDateTime(authState.user!.createdAt) ?? DateTime.now(),
      updatedAt: _parseDateTime(profile['updated_at']),
    );
  }

  /// Safely parse DateTime from dynamic value (could be String or DateTime)
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Parse role string to UserRole enum
  UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      case 'guest':
      default:
        return UserRole.guest;
    }
  }

  Future<void> _handleEditProfile() async {
    final authState = ref.read(authNotifierProvider);
    final user = _getUserModel(authState);
    if (user == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumEditProfileDialog(
        user: user,
        onSave: ({String? fullName, String? phone, String? avatarUrl}) async {
          // Parse full name into first and last name
          String? firstName;
          String? lastName;
          if (fullName != null && fullName.isNotEmpty) {
            final parts = fullName.trim().split(' ');
            firstName = parts.first;
            lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }

          // Update profile in Supabase
          final profileService = ref.read(profileServiceProvider);
          await profileService.updateProfile(
            firstName: firstName,
            lastName: lastName,
            phone: phone,
          );
        },
        onAvatarUpload: () async {
          // Show avatar picker dialog
          final profileService = ref.read(profileServiceProvider);
          XFile? imageFile;

          await showDialog(
            context: context,
            builder: (context) => AvatarPickerDialog(
              onCameraSelected: () async {
                imageFile = await profileService.pickImageFromCamera();
              },
              onGallerySelected: () async {
                imageFile = await profileService.pickImageFromGallery();
              },
            ),
          );

          if (imageFile == null) return null;

          // Upload to Supabase Storage
          final avatarUrl = await profileService.uploadAvatar(imageFile!);
          return avatarUrl;
        },
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil uspešno ažuriran'),
          backgroundColor: AppColors.success,
        ),
      );
      // Refresh user data
      ref.invalidate(authNotifierProvider);
      ref.invalidate(userPreferencesNotifierProvider);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          PremiumButton.primary(
            label: 'Logout',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to logout: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userModel = _getUserModel(authState);

    if (userModel == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: AppDimensions.iconXL * 2,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(height: AppDimensions.spaceL),
              Text(
                'Not logged in',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              PremiumButton.primary(
                label: 'Login',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: PremiumProfileHeader(
                  user: userModel,
                  onAvatarTap: _handleEditProfile,
                  onEditTap: _handleEditProfile,
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.isMobile
                        ? AppDimensions.spaceM
                        : AppDimensions.spaceXL,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppDimensions.spaceXL),

                      // Stats cards
                      Consumer(
                        builder: (context, ref, child) {
                          final userId = userModel.id;
                          final bookingsCountAsync = ref.watch(userBookingsCountProvider(userId));
                          final favoritesCountAsync = ref.watch(userFavoritesCountProvider(userId));
                          final reviewsCountAsync = ref.watch(userReviewsCountProvider(userId));
                          final averageRatingAsync = ref.watch(userAverageRatingProvider(userId));

                          return PremiumStatsCards(
                            bookingsCount: bookingsCountAsync.value ?? 0,
                            favoritesCount: favoritesCountAsync.value ?? 0,
                            reviewsCount: reviewsCountAsync.value ?? 0,
                            averageRating: averageRatingAsync.value,
                            onBookingsTap: () => context.go('/bookings'),
                            onFavoritesTap: () => context.go('/favorites'),
                            onReviewsTap: () {
                              // Navigate to user's reviews (future feature)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Recenzije - uskoro')),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: AppDimensions.spaceXL),

                      // Account Settings
                      Consumer(
                        builder: (context, ref, child) {
                          final preferencesAsync = ref.watch(userPreferencesNotifierProvider);
                          final notificationsEnabled = preferencesAsync.value?.notificationsEnabled ?? true;

                          return PremiumSettingsSection(
                            title: 'ACCOUNT',
                            items: [
                              PremiumSettingsItem(
                                icon: Icons.person_outline,
                                title: 'Edit Profile',
                                subtitle: 'Update your personal information',
                                onTap: _handleEditProfile,
                              ),
                              PremiumSettingsItem(
                                icon: Icons.lock_outline,
                                title: 'Promena Lozinke',
                                subtitle: 'Ažurirajte vašu lozinku',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ChangePasswordScreen(),
                                    ),
                                  );
                                },
                              ),
                              // DISABLED - needs SearchFilters updates
                              // PremiumSettingsItem(
                              //   icon: Icons.bookmark_outlined,
                              //   title: 'Sačuvane pretrage',
                              //   subtitle: 'Upravljajte sačuvanim pretragama',
                              //   iconGradient: const LinearGradient(
                              //     colors: [AppColors.primary, AppColors.secondary],
                              //   ),
                              //   onTap: () => context.push('/saved-searches'),
                              // ),
                              PremiumSettingsItem(
                                icon: Icons.notifications_outlined,
                                title: 'Notifikacije',
                                subtitle: 'Upravljanje notifikacijama',
                                trailing: Switch(
                                  value: notificationsEnabled,
                                  onChanged: (value) async {
                                    await ref
                                        .read(userPreferencesNotifierProvider.notifier)
                                        .updateNotifications(value);
                                  },
                                  activeThumbColor: AppColors.primary,
                                ),
                                showArrow: false,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: AppDimensions.spaceXL),

                      // Preferences
                      Consumer(
                        builder: (context, ref, child) {
                          final currentLocale = ref.watch(currentLocaleProvider);
                          final currentLanguage = currentLocale.languageCode;
                          final preferencesAsync = ref.watch(userPreferencesNotifierProvider);
                          final currentTheme = preferencesAsync.value?.theme ?? 'light';
                          final isDark = currentTheme == 'dark';

                          // Get selected currency
                          final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
                          final currencyText = selectedCurrencyAsync.when(
                            data: (currency) => '${currency.code} (${currency.symbol})',
                            loading: () => 'Loading...',
                            error: (error, stackTrace) => 'EUR (€)',
                          );

                          // Language display names
                          final languageNames = {
                            'en': 'English',
                            'hr': 'Hrvatski',
                            'de': 'Deutsch',
                            'fr': 'Français',
                            'it': 'Italiano',
                            'es': 'Español',
                          };

                          return PremiumSettingsSection(
                            title: 'PREFERENCES',
                            items: [
                              PremiumSettingsItem(
                                icon: Icons.language_outlined,
                                title: 'Jezik',
                                subtitle: languageNames[currentLanguage] ?? 'English',
                                iconGradient: const LinearGradient(
                                  colors: [AppColors.info, AppColors.secondary],
                                ),
                                onTap: () async {
                                  await LanguageSelectionDialog.show(context);
                                },
                              ),
                              PremiumSettingsItem(
                                icon: Icons.dark_mode_outlined,
                                title: 'Tamna Tema',
                                subtitle: isDark ? 'Uključeno' : 'Isključeno',
                                iconGradient: const LinearGradient(
                                  colors: [AppColors.secondary, AppColors.primary],
                                ),
                                trailing: Switch(
                                  value: isDark,
                                  onChanged: (value) async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final themeCode = value ? 'dark' : 'light';
                                    await ref
                                        .read(userPreferencesNotifierProvider.notifier)
                                        .updateTheme(themeCode);
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(value ? 'Tamna tema aktivirana' : 'Svetla tema aktivirana'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  },
                                  activeThumbColor: AppColors.primary,
                                ),
                                showArrow: false,
                              ),
                              PremiumSettingsItem(
                                icon: Icons.currency_exchange_outlined,
                                title: 'Currency',
                                subtitle: currencyText,
                                iconGradient: const LinearGradient(
                                  colors: [AppColors.warning, AppColors.error],
                                ),
                                onTap: () {
                                  _showCurrencySelector(context);
                                },
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: AppDimensions.spaceXL),

                      // Support & Legal
                      PremiumSettingsSection(
                        title: 'SUPPORT & LEGAL',
                        items: [
                          PremiumSettingsItem(
                            icon: Icons.help_outline,
                            title: 'Help Center',
                            subtitle: 'Get help and support',
                            iconGradient: const LinearGradient(
                              colors: [AppColors.success, AppColors.info],
                            ),
                            onTap: () {
                              context.goToHelpFaq();
                            },
                          ),
                          PremiumSettingsItem(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'Read our privacy policy',
                            iconGradient: const LinearGradient(
                              colors: [AppColors.info, AppColors.primary],
                            ),
                            onTap: () {
                              context.goToPrivacyPolicy();
                            },
                          ),
                          PremiumSettingsItem(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            subtitle: 'Read our terms of service',
                            iconGradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            onTap: () {
                              context.goToTermsConditions();
                            },
                          ),
                          PremiumSettingsItem(
                            icon: Icons.info_outline,
                            title: 'About',
                            subtitle: 'Version 1.0.0',
                            iconGradient: const LinearGradient(
                              colors: [AppColors.secondary, AppColors.warning],
                            ),
                            onTap: () {
                              context.goToAboutUs();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: AppDimensions.spaceXL),

                      // Logout button
                      _buildLogoutButton(),

                      const SizedBox(height: AppDimensions.spaceXL),
                    ],
                  ),
                ),
              ),

              // Footer
              const SliverToBoxAdapter(
                child: AppFooter(),
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: context.scrimColor,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return PremiumCard.elevated(
      elevation: 2,
      child: InkWell(
        onTap: _handleLogout,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.error, AppColors.warning],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.logout,
                  size: AppDimensions.iconM,
                  color: context.iconColorInverted,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Text(
                'Logout',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show currency selector dialog
  void _showCurrencySelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);

          return selectedCurrencyAsync.when(
            data: (selectedCurrency) {
              return AlertDialog(
                title: const Text('Select Currency'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: Currency.values.length,
                    itemBuilder: (context, index) {
                      final currency = Currency.values[index];
                      final isSelected = currency == selectedCurrency;

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(AppDimensions.spaceS),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.warning, AppColors.error],
                            ),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          child: Text(
                            currency.symbol,
                            style: AppTypography.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(currency.name),
                        subtitle: Text(currency.code),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () async {
                          await ref.read(selectedCurrencyProvider.notifier).setCurrency(currency);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Currency changed to ${currency.code} (${currency.symbol})',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
            loading: () => const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to load currency settings'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Backwards compatibility typedef
typedef ProfileScreen = PremiumProfileScreen;
