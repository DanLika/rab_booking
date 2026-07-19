import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../shared/models/user_model.dart' show AccountType, UserModel;
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/design/responsive.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/language_selection_bottom_sheet.dart';
import '../widgets/theme_selection_bottom_sheet.dart';
import '../widgets/notification_settings_bottom_sheet.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/premium_list_tile.dart';
import '../../../../shared/widgets/logout_tile.dart';
import '../../../../shared/widgets/delete_account_dialog.dart';
import '../../../../shared/widgets/redesign.dart';
import '../providers/user_profile_provider.dart';

/// Calculate profile completion from UserModel (fallback when UserProfile doesn't exist)
/// This handles existing users who registered before profile subdocument was created
int _calculateCompletionFromUserModel(UserModel? userModel) {
  if (userModel == null) return 0;

  int filled = 0;
  const total = 7; // Same fields as UserProfile.completionPercentage

  // Check fields that map to UserProfile fields
  final hasName =
      userModel.firstName.isNotEmpty || userModel.lastName.isNotEmpty;
  if (hasName) filled++; // displayName
  if (userModel.email.isNotEmpty) filled++; // emailContact
  if (userModel.phone?.isNotEmpty == true) filled++; // phoneE164
  // address.city - not available in UserModel, skip
  // address.country - not available in UserModel, skip
  // propertyType - not available in UserModel, skip
  // logoUrl - not available in UserModel, skip

  return ((filled / total) * 100).round();
}

/// Profile screen for owner dashboard — redesigned onto Bb* foundation
/// (PR redesign/phase2-profil). Identity card with hero accent strip,
/// verified status chips, completion radial gauge, optional Pro card,
/// settings groups via BbCard + BbSectionHeader. Parent Scaffold/drawer/
/// app-bar untouched per audit/104 §3 (deferred to shell-swap PR).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    // OPTIMIZED: Removed watchUserProfileProvider - displayName already available in authState.userModel
    // This eliminates 1 Firestore read (profiles/{userId}) per page load
    final authState = ref.watch(enhancedAuthProvider);
    final userDataAsync = ref.watch(userDataProvider);
    final currentLocale = ref.watch(currentLocaleProvider);
    final currentThemeMode = ref.watch(currentThemeModeProvider);
    final theme = Theme.of(context);

    // Get language display name from localization
    final languageName = currentLocale.languageCode == 'hr'
        ? l10n.ownerProfileLanguageCroatian
        : l10n.ownerProfileLanguageEnglish;

    // Get theme display name
    final themeName = currentThemeMode == ThemeMode.light
        ? l10n.ownerProfileThemeLight
        : currentThemeMode == ThemeMode.dark
        ? l10n.ownerProfileThemeDark
        : l10n.ownerProfileThemeSystem;

    return Scaffold(
      drawer: const OwnerAppDrawer(currentRoute: 'profile'),
      appBar: CommonAppBar(
        title: l10n.ownerProfileTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: user == null
          ? Center(child: Text(l10n.ownerProfileNotAuthenticated))
          : Builder(
              builder: (context) {
                final rd = BbRedesignTokens.of(context);
                final c = BBColor.of(context);
                // OPTIMIZED: Use authState.userModel directly instead of separate Firestore query
                final isAnonymous = authState.isAnonymous;
                // Check if user signed in with social provider (Google/Apple)
                // These users don't have a password to change
                final lastProvider = authState.userModel?.lastProvider;
                final isSocialSignIn =
                    lastProvider == 'google.com' || lastProvider == 'apple.com';
                // Calculate effective account type (admin override takes precedence)
                final effectiveAccountType =
                    authState.userModel?.adminOverrideAccountType ??
                    authState.userModel?.accountType ??
                    AccountType.trial;
                final isTrial = effectiveAccountType == AccountType.trial;
                final displayName =
                    authState.userModel?.displayName ??
                    authState.userModel?.fullName ??
                    user.displayName ??
                    (isAnonymous
                        ? l10n.ownerProfileGuestUser
                        : l10n.ownerProfileOwner);
                final email =
                    user.email ??
                    (isAnonymous
                        ? l10n.ownerProfileAnonymousAccount
                        : l10n.ownerProfileNoEmail);
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 600;
                // Column-count reflow (single vs 2-col settings), NOT a
                // typography/padding pivot — so this stays a local reflow const,
                // not the canonical 1200 desktop breakpoint (content is clamped
                // to 1100 via BBContentMaxWidth, so 1200 would never trigger the
                // 2-col layout the handoff wants). Per audit/breakpoint-decide.
                const kProfileTwoColReflow = 1024.0;
                final isDesktop = screenWidth >= kProfileTwoColReflow;
                final completionPercentage =
                    userDataAsync.value?.profile.completionPercentage ??
                    _calculateCompletionFromUserModel(authState.userModel);

                // Phone presence (no separate verified flag in UserProfile)
                final phoneFilled =
                    (userDataAsync.value?.profile.phoneE164.isNotEmpty ??
                        false) ||
                    (authState.userModel?.phone?.isNotEmpty ?? false);
                // Address city/country derived from profile (read-only access)
                final city = userDataAsync.value?.profile.address.city ?? '';
                final country =
                    userDataAsync.value?.profile.address.country ?? '';
                final avatarUrl = authState.userModel?.avatarUrl;

                // Outer panel gutter — handoff floating console pattern.
                final EdgeInsets gutterPadding = isMobile
                    ? const EdgeInsets.fromLTRB(8, 4, 8, 16)
                    : EdgeInsets.fromLTRB(16, 4, isDesktop ? 28 : 18, 24);

                return Container(
                  decoration: BoxDecoration(
                    gradient: context.gradients.pageBackground,
                  ),
                  // Content clamp — center + cap width on tablet/desktop web.
                  child: BBContentMaxWidth(
                    maxWidth: 1100,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Padding(
                          padding: gutterPadding,
                          child: Container(
                            decoration: BoxDecoration(
                              color: rd.panelBg,
                              borderRadius: BorderRadius.circular(
                                isMobile ? BBRadius.lg : 28,
                              ),
                              border: Border.all(color: rd.panelBorder),
                              boxShadow: rd.panelShadow,
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                isMobile ? 16 : (isDesktop ? 28 : 22),
                                isMobile ? 16 : 22,
                                isMobile ? 16 : (isDesktop ? 28 : 22),
                                isMobile ? 20 : 28,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Eyebrow + headline (handoff §394 PFPEyebrow + h1)
                                  _ProfilHeader(
                                    l10n: l10n,
                                    isMobile: isMobile,
                                    isAnonymous: isAnonymous,
                                  ),
                                  SizedBox(
                                    height: isMobile ? BBSpace.sm : BBSpace.md,
                                  ),

                                  // Identity command card
                                  _ProfilIdentityCard(
                                    displayName: displayName,
                                    email: email,
                                    city: city,
                                    country: country,
                                    avatarUrl: avatarUrl,
                                    memberSinceYear:
                                        user.metadata.creationTime?.year,
                                    emailVerified: user.emailVerified,
                                    phoneFilled: phoneFilled,
                                    isAnonymous: isAnonymous,
                                    completionPercentage: completionPercentage,
                                    isMobile: isMobile,
                                  ),
                                  SizedBox(
                                    height: isMobile ? BBSpace.sm : BBSpace.md,
                                  ),

                                  // Host-trust KPI strip — profile-premium.jsx
                                  // §405 PFP_STATS row (rating / response rate /
                                  // response time / completed bookings). Behind a
                                  // kDebug + env-flag gate because 3 of 4 metrics
                                  // (rating, response rate, response time) have
                                  // no backend source yet. Whole strip is gated
                                  // together so production never renders a
                                  // partial 1-tile row that looks broken.
                                  if (!isAnonymous) ...[
                                    const _ProfilStatStrip(),
                                    SizedBox(
                                      height: isMobile
                                          ? BBSpace.sm
                                          : BBSpace.md,
                                    ),
                                  ],

                                  // Subscription banner — trial-only (unchanged condition)
                                  if (authState.userModel?.hideSubscription !=
                                          true &&
                                      isTrial) ...[
                                    _ProfilProCard(
                                      l10n: l10n,
                                      isMobile: isMobile,
                                    ),
                                    SizedBox(
                                      height: isMobile
                                          ? BBSpace.sm
                                          : BBSpace.md,
                                    ),
                                  ],

                                  // Settings groups — desktop = 2-col, mobile/tablet = single column.
                                  _ProfilSettingsLayout(
                                    isMobile: isMobile,
                                    isDesktop: isDesktop,
                                    account: _buildAccountGroup(
                                      context: context,
                                      ref: ref,
                                      l10n: l10n,
                                      theme: theme,
                                      isAnonymous: isAnonymous,
                                      isSocialSignIn: isSocialSignIn,
                                      hideSubscription:
                                          authState
                                              .userModel
                                              ?.hideSubscription ==
                                          true,
                                      isTrial: isTrial,
                                      languageName: languageName,
                                      themeName: themeName,
                                      primary: c.primary,
                                    ),
                                    app: _buildAppGroup(
                                      context: context,
                                      l10n: l10n,
                                      theme: theme,
                                    ),
                                    legal: _buildLegalGroup(
                                      context: context,
                                      l10n: l10n,
                                      theme: theme,
                                    ),
                                    danger: _buildDangerGroup(
                                      context: context,
                                      ref: ref,
                                      l10n: l10n,
                                      theme: theme,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Group builders — kept as helpers so the build() reads top-down.
  // ---------------------------------------------------------------------------

  Widget _buildAccountGroup({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ThemeData theme,
    required bool isAnonymous,
    required bool isSocialSignIn,
    required bool hideSubscription,
    required bool isTrial,
    required String languageName,
    required String themeName,
    required Color primary,
  }) {
    final rows = <Widget>[
      PremiumListTile(
        icon: Icons.person_outline,
        title: l10n.ownerProfileEditProfile,
        subtitle: isAnonymous
            ? l10n.ownerProfileEditProfileSubtitleAnonymous
            : l10n.ownerProfileEditProfileSubtitle,
        onTap: isAnonymous ? null : () => context.push(OwnerRoutes.profileEdit),
      ),
      if (!isAnonymous && !isSocialSignIn) ...[
        Divider(height: 1, indent: 72, color: theme.dividerColor),
        PremiumListTile(
          icon: Icons.lock_outline,
          title: l10n.ownerProfileChangePassword,
          subtitle: l10n.ownerProfileChangePasswordSubtitle,
          onTap: () => context.push(OwnerRoutes.profileChangePassword),
        ),
      ],
      Divider(height: 1, indent: 72, color: theme.dividerColor),
      PremiumListTile(
        icon: Icons.notifications_outlined,
        title: l10n.ownerProfileNotificationSettings,
        subtitle: l10n.ownerProfileNotificationSettingsSubtitle,
        onTap: () => showNotificationSettingsBottomSheet(context, ref),
      ),
      if (!hideSubscription) ...[
        Divider(height: 1, indent: 72, color: theme.dividerColor),
        PremiumListTile(
          icon: Icons.workspace_premium,
          title: isTrial
              ? l10n.ownerDrawerSubscription
              : l10n.profileManageSubscription,
          subtitle: isTrial
              ? l10n.profileSubscriptionSubtitle
              : l10n.profileManageSubscriptionSubtitle,
          onTap: () => context.push(OwnerRoutes.subscription),
        ),
      ],
      Divider(height: 1, indent: 56, color: theme.dividerColor),
      PremiumListTile(
        icon: Icons.language,
        title: l10n.ownerProfileLanguage,
        subtitle: languageName,
        onTap: () => showLanguageSelectionBottomSheet(context, ref),
      ),
      Divider(height: 1, indent: 56, color: theme.dividerColor),
      PremiumListTile(
        icon: Icons.brightness_6_outlined,
        title: l10n.ownerProfileTheme,
        subtitle: themeName,
        onTap: () => showThemeSelectionBottomSheet(context, ref),
        isLast: true,
      ),
    ];

    return _ProfilSettingsGroup(
      icon: 'manage_accounts',
      title: l10n.ownerProfileTitle,
      rows: rows,
    );
  }

  Widget _buildAppGroup({
    required BuildContext context,
    required AppLocalizations l10n,
    required ThemeData theme,
  }) {
    final rows = <Widget>[
      PremiumListTile(
        icon: Icons.help_outline,
        title: l10n.ownerProfileHelpSupport,
        subtitle: l10n.ownerProfileHelpSupportSubtitle,
        onTap: () async {
          final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
          final subject = Uri.encodeComponent('BookBed Support Request');
          final body = Uri.encodeComponent('User: $userEmail\n\n');
          final Uri emailUri = Uri.parse(
            'mailto:dusko@book-bed.com?subject=$subject&body=$body',
          );
          try {
            await launchUrl(emailUri);
          } catch (e) {
            if (context.mounted) {
              ErrorDisplayUtils.showErrorSnackBar(
                context,
                'Could not open email client',
              );
            }
          }
        },
      ),
      Divider(height: 1, indent: 56, color: theme.dividerColor),
      PremiumListTile(
        icon: Icons.info_outline,
        title: l10n.ownerProfileAbout,
        subtitle: l10n.ownerProfileAboutSubtitle,
        onTap: () => context.push(OwnerRoutes.about),
        isLast: true,
      ),
    ];

    return _ProfilSettingsGroup(
      icon: 'apps',
      title: l10n.ownerProfileGroupApp,
      rows: rows,
    );
  }

  Widget _buildLegalGroup({
    required BuildContext context,
    required AppLocalizations l10n,
    required ThemeData theme,
  }) {
    final rows = <Widget>[
      PremiumListTile(
        icon: Icons.description_outlined,
        title: l10n.ownerProfileTermsConditions,
        subtitle: l10n.ownerProfileTermsConditionsSubtitle,
        onTap: () => context.push(OwnerRoutes.termsConditions),
      ),
      Divider(height: 1, indent: 56, color: theme.dividerColor),
      PremiumListTile(
        icon: Icons.privacy_tip_outlined,
        title: l10n.ownerProfilePrivacyPolicy,
        subtitle: l10n.ownerProfilePrivacyPolicySubtitle,
        onTap: () => context.push(OwnerRoutes.privacyPolicy),
      ),
      Divider(height: 1, indent: 56, color: theme.dividerColor),
      PremiumListTile(
        icon: Icons.cookie_outlined,
        title: l10n.ownerProfileCookiesPolicy,
        subtitle: l10n.ownerProfileCookiesPolicySubtitle,
        onTap: () => context.push(OwnerRoutes.cookiesPolicy),
        isLast: true,
      ),
    ];

    return _ProfilSettingsGroup(
      icon: 'gavel',
      title: l10n.ownerProfileGroupLegal,
      rows: rows,
    );
  }

  Widget _buildDangerGroup({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              const BbIcon(name: 'warning', size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                l10n.dangerZone.toUpperCase(),
                style: BBType.eyebrow(context).copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
        BbCard(
          padded: false,
          child: Column(
            children: [
              LogoutTile(
                title: l10n.ownerProfileLogout,
                subtitle: l10n.ownerProfileLogoutSubtitle,
                onLogout: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => BbDialog(
                      title: l10n.logoutConfirmTitle,
                      body: l10n.logoutConfirmMessage,
                      secondary: BbDialogAction(
                        label: l10n.cancel,
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                      primary: BbDialogAction(
                        label: l10n.logout,
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ),
                  );
                  if (confirmed != true) return;
                  await ref
                      .read(enhancedAuthProvider.notifier)
                      .signOut(clearSavedEmail: true);
                  if (context.mounted) {
                    context.go(OwnerRoutes.login);
                  }
                },
              ),
              Divider(height: 1, indent: 56, color: theme.dividerColor),
              PremiumListTile(
                icon: Icons.delete_forever_outlined,
                iconColor: AppColors.error,
                title: l10n.deleteAccount,
                subtitle: l10n.deleteAccountWarning,
                onTap: () async {
                  final result = await showDeleteAccountDialog(context);
                  if (result == true && context.mounted) {
                    context.go(OwnerRoutes.login);
                  }
                },
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Header — eyebrow ("RAČUN · VLASNIK") + h1 ("Profil") + optional CTA.
// ============================================================================
class _ProfilHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isMobile;
  final bool isAnonymous;

  const _ProfilHeader({
    required this.l10n,
    required this.isMobile,
    required this.isAnonymous,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final headlineStyle =
        (isMobile ? BBType.h1(context) : BBType.display(context)).copyWith(
          letterSpacing: -0.6,
          fontWeight: FontWeight.w800,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ownerProfileEyebrow.toUpperCase(),
                style: BBType.eyebrow(context).copyWith(color: c.primary),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.ownerProfileTitle,
                style: headlineStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        if (!isMobile && !isAnonymous)
          OutlinedButton.icon(
            onPressed: () => context.push(OwnerRoutes.profileEdit),
            icon: const Icon(Icons.edit, size: 16),
            label: Text(l10n.ownerProfileEditProfile),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.primary,
              side: BorderSide(color: c.primary.withValues(alpha: 0.40)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BBRadius.sm),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// Identity card — hero gradient strip + avatar + name/email/location +
// verified chips + completion radial gauge.
// ============================================================================
class _ProfilIdentityCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String city;
  final String country;
  final String? avatarUrl;
  final int? memberSinceYear;
  final bool emailVerified;
  final bool phoneFilled;
  final bool isAnonymous;
  final int completionPercentage;
  final bool isMobile;

  const _ProfilIdentityCard({
    required this.displayName,
    required this.email,
    required this.city,
    required this.country,
    required this.avatarUrl,
    required this.memberSinceYear,
    required this.emailVerified,
    required this.phoneFilled,
    required this.isAnonymous,
    required this.completionPercentage,
    required this.isMobile,
  });

  String _locationLabel() {
    if (city.isEmpty && country.isEmpty) return '';
    if (city.isEmpty) return country;
    if (country.isEmpty) return city;
    return '$city, $country';
  }

  @override
  Widget build(BuildContext context) {
    final rd = BbRedesignTokens.of(context);
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final location = _locationLabel();

    final identity = Row(
      children: [
        // Avatar halo ring — flat primary since audit F3.5 (heroGradient on
        // structural chrome violates the 2026-06-16 flat-chrome decision).
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.primary,
            shape: BoxShape.circle,
            boxShadow: rd.purpleGlow,
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
            child: BbAvatar(
              name: displayName,
              imageUrl: avatarUrl,
              size: isMobile ? BbAvatarSize.lg : BbAvatarSize.xl,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name + role chip
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    displayName,
                    style: (isMobile ? BBType.h2(context) : BBType.h1(context))
                        .copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: c.textPrimary,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (!isAnonymous)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(BBRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BbIcon(name: 'verified', size: 14, color: c.primary),
                          const SizedBox(width: 4),
                          Text(
                            l10n.ownerProfileHostBadge,
                            style: BBType.caption(context).copyWith(
                              color: c.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Email · location · member-since meta row
              _MetaRow(
                items: [
                  if (email.isNotEmpty) _MetaItem(icon: 'mail', label: email),
                  if (location.isNotEmpty)
                    _MetaItem(icon: 'place', label: location),
                  if (memberSinceYear != null)
                    _MetaItem(
                      icon: 'calendar_month',
                      label: l10n.ownerProfileMemberSince(memberSinceYear!),
                    ),
                ],
              ),
              // Verified chips
              if (!isAnonymous) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _VerifyChip(
                      label: l10n.ownerProfileEmailVerified,
                      state: emailVerified
                          ? _VerifyState.done
                          : _VerifyState.pending,
                    ),
                    _VerifyChip(
                      label: phoneFilled
                          ? l10n.ownerProfilePhoneAdded
                          : l10n.ownerProfilePhoneMissing,
                      state: phoneFilled
                          ? _VerifyState.done
                          : _VerifyState.pending,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final completion = _CompletionPanel(
      percentage: completionPercentage,
      isMobile: isMobile,
    );

    final child = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              if (completionPercentage < 100) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: c.border.withValues(alpha: 0.6)),
                const SizedBox(height: 16),
                completion,
              ],
            ],
          )
        : Row(
            children: [
              Expanded(child: identity),
              if (completionPercentage < 100) ...[
                const SizedBox(width: 24),
                Container(
                  width: 1,
                  height: 110,
                  color: c.border.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 24),
                completion,
              ],
            ],
          );

    return BbCard(
      padded: false,
      child: ClipRRect(
        borderRadius: BBRadius.mdAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent strip — flat primary since audit F3.5 (flat-chrome).
            Container(height: 6, color: c.primary),
            Padding(padding: EdgeInsets.all(isMobile ? 18 : 24), child: child),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final List<_MetaItem> items;

  const _MetaRow({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 14, runSpacing: 4, children: items);
  }
}

class _MetaItem extends StatelessWidget {
  final String icon;
  final String label;

  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BbIcon(name: icon, size: 14, color: c.textTertiary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: BBType.body(context).copyWith(color: c.textSecondary),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

enum _VerifyState { done, pending }

class _VerifyChip extends StatelessWidget {
  final String label;
  final _VerifyState state;

  const _VerifyChip({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final rd = BbRedesignTokens.of(context);
    final isDone = state == _VerifyState.done;
    final bg = isDone ? rd.statusConfirmedTint : rd.statusPendingTint;
    final fg = isDone ? rd.statusConfirmedDeep : rd.statusPendingDeep;
    final icon = isDone ? 'check_circle' : 'error';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(BBRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BbIcon(name: icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: BBType.caption(
              context,
            ).copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Completion radial — circular progress gauge with percentage + CTA.
// ============================================================================
class _CompletionPanel extends StatelessWidget {
  final int percentage;
  final bool isMobile;

  const _CompletionPanel({required this.percentage, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final stepsLeft = math.max(0, ((100 - percentage) / 14).ceil());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RadialGauge(
          percentage: percentage,
          size: isMobile ? 96 : 116,
          stroke: isMobile ? 11 : 12,
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.ownerProfileCompleteHeading,
                style: BBType.h3(context).copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  stepsLeft == 0
                      ? l10n.ownerProfileSuggestionPhone
                      : l10n.ownerProfileCompleteRemaining(stepsLeft),
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: FilledButton.icon(
                  onPressed: () => context.push(OwnerRoutes.profileEdit),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(l10n.ownerProfileCompleteCta),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BBRadius.sm),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadialGauge extends StatelessWidget {
  final int percentage;
  final double size;
  final double stroke;

  const _RadialGauge({
    required this.percentage,
    required this.size,
    required this.stroke,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RadialGaugePainter(
              progress: (percentage / 100).clamp(0.0, 1.0),
              stroke: stroke,
              track: c.surfaceVariant,
              arc: c.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: BBType.h1Num(context).copyWith(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: c.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context).ownerProfileCompleteFilledLabel,
                style: BBType.caption(context).copyWith(color: c.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color track;

  /// Flat arc colour since audit F3.5 (was a heroGradient shader —
  /// flat-chrome violation, and gradient identity made shouldRepaint
  /// effectively always-true).
  final Color arc;

  _RadialGaugePainter({
    required this.progress,
    required this.stroke,
    required this.track,
    required this.arc,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..color = arc
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter old) =>
      old.progress != progress ||
      old.stroke != stroke ||
      old.track != track ||
      old.arc != arc;
}

// ============================================================================
// BookBed Pro card — handoff §248 accent-left gradient with workspace_premium
// icon + benefits + CTA. Trial-only.
// ============================================================================
/// Seam builder for the BookBed Pro trial card — lets golden/unit tests pump
/// the real card (benefits grid + price + CTA) without providers or auth.
@visibleForTesting
Widget buildProCardForTest({
  required AppLocalizations l10n,
  required bool isMobile,
}) => _ProfilProCard(l10n: l10n, isMobile: isMobile);

class _ProfilProCard extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isMobile;

  const _ProfilProCard({required this.l10n, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final rd = BbRedesignTokens.of(context);
    final c = BBColor.of(context);

    return BbCard(
      padded: false,
      variant: BbCardVariant.accentLeft,
      accentTone: BbCardAccentTone.primary,
      onTap: () => context.push(OwnerRoutes.subscription),
      hoverable: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 20 : 24,
          isMobile ? 18 : 22,
          isMobile ? 20 : 24,
          isMobile ? 18 : 22,
        ),
        child: Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: isMobile
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: isMobile ? 0 : 1,
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    // Flat primary since audit F3.5 (flat-chrome).
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: rd.purpleGlow,
                    ),
                    alignment: Alignment.center,
                    child: const BbIcon(
                      name: 'workspace_premium',
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title + "Probni period" pill flow into a second row
                        // when the title is wide. `Row(Flexible(title), pill)`
                        // previously truncated to "Nadogradite n…" on 402-px
                        // screens — `Wrap` lets the pill drop instead.
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              l10n.subscriptionBannerTitle,
                              style: BBType.h3(context).copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: rd.statusPendingTint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.ownerProfileTrialBadge,
                                style: BBType.caption(context).copyWith(
                                  color: rd.statusPendingDeep,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.subscriptionBannerSubtitle,
                          style: BBType.body(
                            context,
                          ).copyWith(color: c.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: _kProBenefitsTopGap),
                        // Benefit grid — profile-premium.jsx §270. Static
                        // feature copy (all l10n); 2-col mobile, wraps on
                        // desktop. The handoff's trial-progress bar is
                        // intentionally omitted: no trial-day-count field
                        // exists on the model, so rendering "12 of 14 days"
                        // would be fabricated data.
                        _ProProBenefits(l10n: l10n, isMobile: isMobile),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isMobile) const SizedBox(height: 14),
            if (!isMobile) const SizedBox(width: 16),
            Column(
              crossAxisAlignment: isMobile
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price — profile-premium.jsx §296 (€19 / mjesečno).
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      l10n.subscriptionProPrice,
                      style: BBType.h1(context).copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${l10n.subscriptionProPeriod}',
                      style: BBType.caption(
                        context,
                      ).copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: isMobile ? double.infinity : null,
                  child: BbButton(
                    label: l10n.ownerDrawerSubscription,
                    iconLeft: 'arrow_forward',
                    onPressed: () => context.push(OwnerRoutes.subscription),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Benefit chips inside the BookBed Pro card — profile-premium.jsx §270.
/// Four static feature labels, each with a `check_circle` success mark.
/// 2-column grid on mobile; free-wrapping row on desktop.
const double _kProBenefitsTopGap = 16;

class _ProProBenefits extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isMobile;

  const _ProProBenefits({required this.l10n, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final labels = <String>[
      l10n.subscriptionFeatureUnlimitedProperties,
      l10n.subscriptionFeatureAdvancedAnalytics,
      l10n.subscriptionFeatureAiAssistant,
      l10n.subscriptionFeaturePrioritySupport,
    ];

    Widget chip(String label, {bool tight = false}) => Row(
      mainAxisSize: tight ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: BbIcon(name: 'check_circle', size: 16, color: c.success),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BBType.body(
              context,
            ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );

    if (isMobile) {
      // 2-column grid — handoff compact layout. LayoutBuilder gives the true
      // in-card width so labels get their full share instead of a guessed
      // constant; 2-line chips prevent mid-word truncation on narrow phones.
      return LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = (constraints.maxWidth - _kProBenefitColGap) / 2;
          return Wrap(
            spacing: _kProBenefitColGap,
            runSpacing: 8,
            children: labels
                .map(
                  (l) =>
                      SizedBox(width: cellWidth, child: chip(l, tight: true)),
                )
                .toList(),
          );
        },
      );
    }

    // Desktop — free-wrapping single row (repeat(4, auto)).
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: labels.map(chip).toList(),
    );
  }
}

const double _kProBenefitColGap = 18;

// ============================================================================
// Settings group wrapper — section header + BbCard with rows.
// ============================================================================
class _ProfilSettingsGroup extends StatelessWidget {
  final String icon;
  final String title;
  final List<Widget> rows;

  const _ProfilSettingsGroup({
    required this.icon,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              BbIcon(name: icon, size: 16, color: c.textTertiary),
              const SizedBox(width: 8),
              Text(title.toUpperCase(), style: BBType.eyebrow(context)),
            ],
          ),
        ),
        BbCard(padded: false, child: Column(children: rows)),
      ],
    );
  }
}

// ============================================================================
// Two-column desktop layout / single-column mobile layout for settings groups.
// Mirrors handoff §412 desktop layout.
// ============================================================================
class _ProfilSettingsLayout extends StatelessWidget {
  final bool isMobile;
  final bool isDesktop;
  final Widget account;
  final Widget app;
  final Widget legal;
  final Widget danger;

  const _ProfilSettingsLayout({
    required this.isMobile,
    required this.isDesktop,
    required this.account,
    required this.app,
    required this.legal,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: account),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                app,
                const SizedBox(height: 18),
                legal,
                const SizedBox(height: 18),
                danger,
              ],
            ),
          ),
        ],
      );
    }
    // Tablet + mobile = single column.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        account,
        const SizedBox(height: 16),
        app,
        const SizedBox(height: 16),
        legal,
        const SizedBox(height: 16),
        danger,
      ],
    );
  }
}

// ============================================================================
// Host-trust KPI strip — profile-premium.jsx §204 PFP_STATS.
//
// 4 metric tiles (rating · response rate · response time · completed
// bookings), each with: tinted icon tile, eyebrow label, large bb-tnum
// value, optional delta chip + sparkline. Renders 4-col on wide layouts,
// 2x2 on tablet/mobile.
//
// GATED on `bool.fromEnvironment('PROFILE_HOST_STATS')` OR `kDebugMode` to
// avoid shipping placeholder metrics in prod. 3 of 4 fields (rating /
// response rate / response time) have no backend source yet; the 4th
// (completed bookings) exists in `firebase_property_performance_repository`
// but is not wired into a `UserModel` aggregate. Whole strip gates together
// to avoid a partial-data 1-tile row that reads as broken in production.
// ============================================================================
class _ProfilStatStrip extends StatelessWidget {
  const _ProfilStatStrip();

  static const bool _enabled = bool.fromEnvironment('PROFILE_HOST_STATS');

  static const List<_ProfilStat> _stats = <_ProfilStat>[
    _ProfilStat(
      icon: 'star',
      tone: _StatTone.tertiary,
      label: 'OCJENA DOMAĆINA',
      value: '4,9',
      delta: '+0,2',
      spark: <double>[4.5, 4.6, 4.6, 4.7, 4.8, 4.8, 4.9],
    ),
    _ProfilStat(
      icon: 'mark_chat_read',
      tone: _StatTone.success,
      label: 'STOPA ODGOVORA',
      value: '98%',
      delta: '+3%',
      spark: <double>[88, 90, 92, 94, 95, 97, 98],
    ),
    _ProfilStat(
      icon: 'schedule',
      tone: _StatTone.info,
      label: 'VRIJEME ODGOVORA',
      value: '~1 h',
      sub: 'prosjek zadnjih 30 dana',
    ),
    _ProfilStat(
      icon: 'task_alt',
      tone: _StatTone.primary,
      label: 'ZAVRŠENE REZERVACIJE',
      value: '48',
      delta: '+6',
      spark: <double>[30, 34, 37, 40, 43, 45, 48],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_enabled && !kDebugMode) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isWide = screenWidth >= 900;

    if (isWide) {
      return Row(
        children: List<Widget>.generate(_stats.length, (int i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 12),
              child: _ProfilStatTile(stat: _stats[i], compact: false),
            ),
          );
        }),
      );
    }
    // Tablet + mobile: 2 columns.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ProfilStatTile(stat: _stats[0], compact: isMobile),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfilStatTile(stat: _stats[1], compact: isMobile),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ProfilStatTile(stat: _stats[2], compact: isMobile),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfilStatTile(stat: _stats[3], compact: isMobile),
            ),
          ],
        ),
      ],
    );
  }
}

enum _StatTone { primary, success, info, tertiary }

class _ProfilStat {
  final String icon;
  final _StatTone tone;
  final String label;
  final String value;
  final String? delta;
  final String? sub;
  final List<double>? spark;

  const _ProfilStat({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
    this.delta,
    this.sub,
    this.spark,
  });
}

class _ProfilStatTile extends StatelessWidget {
  final _ProfilStat stat;
  final bool compact;

  const _ProfilStatTile({required this.stat, required this.compact});

  ({Color bg, Color fg}) _resolveTone(BBColorSet c, BbRedesignTokens rd) {
    switch (stat.tone) {
      case _StatTone.primary:
        return (bg: c.primary.withValues(alpha: 0.10), fg: c.primary);
      case _StatTone.success:
        return (bg: rd.statusConfirmedTint, fg: rd.statusConfirmedDeep);
      case _StatTone.info:
        return (bg: c.info.withValues(alpha: 0.10), fg: c.info);
      case _StatTone.tertiary:
        return (bg: rd.statusPendingTint, fg: rd.statusPendingDeep);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final rd = BbRedesignTokens.of(context);
    // Minimalist pass 3: light collapses every stat tile to a single primary
    // tint+glyph+spark; dark keeps the per-tone (status) resolution.
    final bool isLight = Theme.of(context).brightness != Brightness.dark;
    final tone = isLight
        ? (bg: c.primary.withValues(alpha: 0.10), fg: c.primary)
        : _resolveTone(c, rd);
    final hasDelta = stat.delta != null;
    final hasSpark = stat.spark != null && stat.spark!.isNotEmpty;

    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tone.bg,
                  borderRadius: BorderRadius.circular(BBRadius.sm),
                ),
                alignment: Alignment.center,
                child: BbIcon(name: stat.icon, size: 19, color: tone.fg),
              ),
              const Spacer(),
              if (hasDelta)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BbIcon(name: 'trending_up', size: 14, color: c.success),
                    const SizedBox(width: 3),
                    Text(
                      stat.delta!,
                      style: BBType.caption(
                        context,
                      ).copyWith(color: c.success, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            stat.label,
            style: BBType.eyebrow(
              context,
            ).copyWith(color: c.textTertiary, fontSize: 10, letterSpacing: 0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  stat.value,
                  style: BBType.h1Num(context).copyWith(
                    fontSize: compact ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: c.textPrimary,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasSpark)
                BbSparkline(
                  data: stat.spark!,
                  width: compact ? 50 : 70,
                  height: 26,
                  color: tone.fg,
                  showDot: false,
                ),
            ],
          ),
          if (stat.sub != null) ...[
            const SizedBox(height: 8),
            Text(
              stat.sub!,
              style: BBType.caption(
                context,
              ).copyWith(color: c.textTertiary, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
