import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/theme/app_color_extensions.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../auth/presentation/widgets/auth_logo_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/notifications_provider.dart';
import '../providers/owner_bookings_provider.dart';

/// Premium Owner App Navigation Drawer
class OwnerAppDrawer extends ConsumerWidget {
  final String currentRoute;

  const OwnerAppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final authState = ref.watch(enhancedAuthProvider);
    final l10n = AppLocalizations.of(context);

    return Drawer(
      child: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Premium Header with Logo
            _buildPremiumHeader(context, user, authState),

            const SizedBox(height: 8),

            // Navigation items
            _DrawerItem(
              icon: Icons.dashboard_outlined,
              title: l10n.ownerDrawerOverview,
              isSelected: currentRoute == 'overview',
              onTap: () => context.go(OwnerRoutes.overview),
            ),

            const SizedBox(height: 4),

            // Kalendar (expandable with Timeline + Month Calendar)
            _PremiumExpansionTile(
              icon: Icons.calendar_today_outlined,
              title: l10n.ownerDrawerCalendar,
              isExpanded: currentRoute.startsWith('calendar'),
              children: [
                _DrawerSubItem(
                  title: l10n.ownerDrawerTimelineCalendar,
                  icon: Icons.view_timeline_outlined,
                  isSelected: currentRoute == 'calendar/timeline',
                  onTap: () => context.go(OwnerRoutes.calendarTimeline),
                ),
                _DrawerSubItem(
                  title: l10n.ownerDrawerMonthCalendar,
                  icon: Icons.calendar_month_outlined,
                  isSelected: currentRoute == 'calendar/month',
                  onTap: () => context.go(OwnerRoutes.calendarMonth),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Rezervacije with pending count badge
            _DrawerItemWithBadge(
              icon: Icons.receipt_long_outlined,
              title: l10n.ownerDrawerBookings,
              isSelected: currentRoute == 'bookings',
              onTap: () => context.go(OwnerRoutes.bookings),
            ),

            const SizedBox(height: 4),

            // Smještajne Jedinice
            _DrawerItem(
              icon: Icons.bed_outlined,
              title: l10n.ownerDrawerUnits,
              isSelected: currentRoute == 'unit-hub',
              onTap: () => context.go(OwnerRoutes.unitHub),
            ),

            const SizedBox(height: 4),

            // Unified Integracije Expansion (iCal + Plaćanja)
            _PremiumExpansionTile(
              icon: Icons.extension_outlined,
              title: l10n.ownerDrawerIntegrations,
              isExpanded: currentRoute.startsWith('integrations'),
              children: [
                // iCal Section Header
                _DrawerSectionHeader(title: l10n.ownerDrawerIcal),
                _DrawerSubItem(
                  title: l10n.ownerDrawerImportBookings,
                  subtitle: l10n.ownerDrawerSyncBookingCom,
                  icon: Icons.system_update_alt_rounded,
                  isSelected: currentRoute == 'integrations/ical/import',
                  onTap: () => context.go(OwnerRoutes.icalImport),
                ),
                _DrawerSubItem(
                  title: l10n.ownerDrawerExportCalendar,
                  subtitle: l10n.ownerDrawerIcalFeedUrl,
                  icon: Icons.ios_share_rounded,
                  isSelected: currentRoute == 'integrations/ical/export-list',
                  onTap: () => context.go(OwnerRoutes.icalExportList),
                ),

                const SizedBox(height: 8),

                // Plaćanja Section Header
                _DrawerSectionHeader(title: l10n.ownerDrawerPayments),
                _DrawerSubItem(
                  title: l10n.ownerDrawerStripePayments,
                  subtitle: l10n.ownerDrawerCardProcessing,
                  icon: Icons.payments_outlined,
                  isSelected: currentRoute == 'integrations/stripe',
                  onTap: () => context.go(OwnerRoutes.stripeIntegration),
                ),
                _DrawerSubItem(
                  title: l10n.ownerDrawerBankAccount,
                  subtitle: l10n.ownerDrawerBankAccountData,
                  icon: Icons.account_balance,
                  isSelected:
                      currentRoute == 'integrations/payments/bank-account',
                  onTap: () => context.go(OwnerRoutes.bankAccount),
                ),

                const SizedBox(height: 8),

                // Widget Section Header
                _DrawerSectionHeader(title: l10n.ownerDrawerWidgetSection),
                _DrawerSubItem(
                  title: l10n.ownerDrawerEmbedWidget,
                  subtitle: l10n.ownerDrawerAddToSite,
                  icon: Icons.integration_instructions_outlined,
                  isSelected: currentRoute == 'guides/embed-widget',
                  onTap: () => context.go(OwnerRoutes.guideEmbedWidget),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(height: 1, color: context.gradients.sectionBorder),
            ),

            // FAQ & Support - Placed here for better visibility
            _DrawerItem(
              icon: Icons.quiz_outlined,
              title: l10n.ownerDrawerFaq,
              isSelected: currentRoute == 'guides/faq',
              onTap: () => context.go(OwnerRoutes.guideFaq),
            ),

            const SizedBox(height: 4),

            // Settings & Profile
            _DrawerItemWithNotificationBadge(
              icon: Icons.notifications_outlined,
              title: l10n.ownerDrawerNotifications,
              isSelected: currentRoute == 'notifications',
              onTap: () => context.go(OwnerRoutes.notifications),
            ),

            const SizedBox(height: 4),

            _DrawerItem(
              icon: Icons.person_outline,
              title: l10n.ownerDrawerProfile,
              isSelected: currentRoute == 'profile',
              onTap: () => context.go(OwnerRoutes.profile),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(
    BuildContext context,
    User? user,
    dynamic authState,
  ) {
    final theme = Theme.of(context);
    final displayName =
        authState.userModel?.firstName != null &&
            authState.userModel?.lastName != null
        ? '${authState.userModel!.firstName} ${authState.userModel!.lastName}'
        : user?.displayName ?? 'Owner';

    final email = user?.email ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      decoration: BoxDecoration(
        gradient: GradientTokens.brandPrimary,
        boxShadow: [
          BoxShadow(
            color: GradientTokens.brandPrimaryStart.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo - White variant for dark background
          // Note: animate=false to prevent potential rendering issues in drawer
          const Center(
            child: AuthLogoIcon(size: 70, isWhite: true, animate: false),
          ),
          const SizedBox(height: 20),

          // User Info
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: AppShadows.getElevation(
                    2,
                    isDark: theme.brightness == Brightness.dark,
                  ),
                ),
                child:
                    authState.userModel?.avatarUrl != null &&
                        authState.userModel!.avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          authState.userModel!.avatarUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.brandPurple,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.brandPurple,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Premium Drawer Item with hover effect
class _DrawerItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _isHovered = false;

  // Light purple for dark theme text (lightened version of brandPurple)
  static const _lightPurple = Color(0xFFB794F6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // In dark mode, use lighter purple text and stronger purple background
    final selectedTextColor = isDark
        ? _lightPurple
        : theme.colorScheme.brandPurple;
    final selectedBgAlpha = isDark ? 0.15 : 0.12;
    final hoverBgAlpha = isDark ? 0.08 : 0.06;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.isSelected
                ? theme.colorScheme.brandPurple.withValues(
                    alpha: selectedBgAlpha,
                  )
                : _isHovered
                ? theme.colorScheme.brandPurple.withValues(alpha: hoverBgAlpha)
                : Colors.transparent,
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? selectedTextColor.withValues(alpha: 0.12)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: widget.isSelected
                    ? selectedTextColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                size: 20,
              ),
            ),
            title: Text(
              widget.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: widget.isSelected
                    ? selectedTextColor
                    : theme.colorScheme.onSurface,
              ),
            ),
            onTap: widget.onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium Drawer Item with Badge (for showing pending count)
class _DrawerItemWithBadge extends ConsumerStatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItemWithBadge({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  ConsumerState<_DrawerItemWithBadge> createState() =>
      _DrawerItemWithBadgeState();
}

class _DrawerItemWithBadgeState extends ConsumerState<_DrawerItemWithBadge> {
  bool _isHovered = false;

  // Light purple for dark theme text (lightened version of brandPurple)
  static const _lightPurple = Color(0xFFB794F6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get pending bookings count using optimized provider (dedicated query)
    final pendingCountAsync = ref.watch(pendingBookingsCountProvider);
    final pendingCount = pendingCountAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    // In dark mode, use lighter purple text and stronger purple background
    final selectedTextColor = isDark
        ? _lightPurple
        : theme.colorScheme.brandPurple;
    final selectedBgAlpha = isDark ? 0.15 : 0.12;
    final hoverBgAlpha = isDark ? 0.08 : 0.06;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.isSelected
                ? theme.colorScheme.brandPurple.withValues(
                    alpha: selectedBgAlpha,
                  )
                : _isHovered
                ? theme.colorScheme.brandPurple.withValues(alpha: hoverBgAlpha)
                : Colors.transparent,
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? selectedTextColor.withValues(alpha: 0.12)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: widget.isSelected
                    ? selectedTextColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: widget.isSelected
                          ? selectedTextColor
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (pendingCount > 0)
                  Semantics(
                    label:
                        '$pendingCount ${l10n.ownerStatusPending.toLowerCase()}',
                    excludeSemantics: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.danger,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pendingCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onTap: widget.onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium Drawer Item with Notification Badge (amber/yellow color)
class _DrawerItemWithNotificationBadge extends ConsumerStatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItemWithNotificationBadge({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  ConsumerState<_DrawerItemWithNotificationBadge> createState() =>
      _DrawerItemWithNotificationBadgeState();
}

class _DrawerItemWithNotificationBadgeState
    extends ConsumerState<_DrawerItemWithNotificationBadge> {
  bool _isHovered = false;

  // Light purple for dark theme text (lightened version of brandPurple)
  static const _lightPurple = Color(0xFFB794F6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get unread notifications count
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);
    final unreadCount = unreadCountAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    // In dark mode, use lighter purple text and stronger purple background
    final selectedTextColor = isDark
        ? _lightPurple
        : theme.colorScheme.brandPurple;
    final selectedBgAlpha = isDark ? 0.15 : 0.12;
    final hoverBgAlpha = isDark ? 0.08 : 0.06;

    // Amber badge color - slightly darker for better contrast
    final badgeColor = isDark ? Colors.amber.shade600 : Colors.amber.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.isSelected
                ? theme.colorScheme.brandPurple.withValues(
                    alpha: selectedBgAlpha,
                  )
                : _isHovered
                ? theme.colorScheme.brandPurple.withValues(alpha: hoverBgAlpha)
                : Colors.transparent,
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? selectedTextColor.withValues(alpha: 0.12)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: widget.isSelected
                    ? selectedTextColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: widget.isSelected
                          ? selectedTextColor
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Semantics(
                    label:
                        '$unreadCount ${l10n.ownerDrawerNotifications.toLowerCase()}',
                    excludeSemantics: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onTap: widget.onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section Header for grouping drawer items
class _DrawerSectionHeader extends StatelessWidget {
  final String title;

  const _DrawerSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 12, top: 8, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium Sub Item
class _DrawerSubItem extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerSubItem({
    required this.title,
    this.subtitle,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DrawerSubItem> createState() => _DrawerSubItemState();
}

class _DrawerSubItemState extends State<_DrawerSubItem> {
  bool _isHovered = false;

  // Light purple for dark theme text (lightened version of brandPurple)
  static const _lightPurple = Color(0xFFB794F6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // In dark mode, use lighter purple text and stronger purple background
    final selectedTextColor = isDark
        ? _lightPurple
        : theme.colorScheme.brandPurple;
    final selectedBgAlpha = isDark ? 0.15 : 0.12;
    final hoverBgAlpha = isDark ? 0.08 : 0.06;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 12, top: 2, bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: widget.isSelected
                ? theme.colorScheme.brandPurple.withValues(
                    alpha: selectedBgAlpha,
                  )
                : _isHovered
                ? theme.colorScheme.brandPurple.withValues(alpha: hoverBgAlpha)
                : Colors.transparent,
          ),
          child: ListTile(
            dense: true,
            leading: widget.icon != null
                ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? selectedTextColor.withValues(alpha: 0.12)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 16,
                      color: widget.isSelected
                          ? selectedTextColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  )
                : const SizedBox(width: 32),
            title: Text(
              widget.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: widget.isSelected
                    ? selectedTextColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            subtitle: widget.subtitle != null
                ? Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  )
                : null,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

/// Premium Expansion Tile
class _PremiumExpansionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isExpanded;
  final List<Widget> children;

  const _PremiumExpansionTile({
    required this.icon,
    required this.title,
    required this.isExpanded,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Light purple for dark theme text (matching _DrawerItem)
    const lightPurple = Color(0xFFB794F6);

    // Colors matching _DrawerItem styling
    final selectedTextColor = isDark
        ? lightPurple
        : theme.colorScheme.brandPurple;
    final normalTextColor = theme.colorScheme.onSurface;
    final iconColor = isExpanded
        ? (isDark ? lightPurple : theme.colorScheme.brandPurple)
        : theme.colorScheme.onSurface.withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: theme.colorScheme.brandPurple.withValues(alpha: 0.06),
          highlightColor: theme.colorScheme.brandPurple.withValues(alpha: 0.06),
        ),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isExpanded
                  ? selectedTextColor.withValues(alpha: 0.12)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isExpanded
                  ? selectedTextColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          iconColor: iconColor,
          collapsedIconColor: iconColor,
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              // Match _DrawerItem: w600 when expanded/selected, w500 otherwise
              fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
              color: isExpanded ? selectedTextColor : normalTextColor,
            ),
          ),
          initiallyExpanded: isExpanded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: children,
        ),
      ),
    );
  }
}
