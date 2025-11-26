import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/theme/app_color_extensions.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../auth/presentation/widgets/auth_logo_icon.dart';

/// Premium Owner App Navigation Drawer
class OwnerAppDrawer extends ConsumerWidget {
  final String currentRoute;

  const OwnerAppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final authState = ref.watch(enhancedAuthProvider);

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: context.gradients.pageBackground,
        ),
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
              title: 'Pregled',
              isSelected: currentRoute == 'overview',
              onTap: () => context.go(OwnerRoutes.overview),
            ),

            const SizedBox(height: 4),

            // Kalendar
            _DrawerItem(
              icon: Icons.calendar_view_month,
              title: 'Kalendar',
              isSelected: currentRoute.startsWith('calendar'),
              onTap: () => context.go(OwnerRoutes.calendarTimeline),
            ),

            const SizedBox(height: 4),

            // Rezervacije
            _DrawerItem(
              icon: Icons.book_online,
              title: 'Rezervacije',
              isSelected: currentRoute == 'bookings',
              onTap: () => context.go(OwnerRoutes.bookings),
            ),

            const SizedBox(height: 4),

            // Analytics
            _DrawerItem(
              icon: Icons.analytics_outlined,
              title: 'Analitika',
              isSelected: currentRoute == 'analytics',
              onTap: () => context.go(OwnerRoutes.analytics),
            ),

            const SizedBox(height: 4),

            // Smještajne Jedinice
            _DrawerItem(
              icon: Icons.home_work_outlined,
              title: 'Smještajne Jedinice',
              isSelected: currentRoute == 'unit-hub',
              onTap: () => context.go(OwnerRoutes.unitHub),
            ),

            const SizedBox(height: 4),

            // Unified Integracije Expansion (iCal + Plaćanja)
            _PremiumExpansionTile(
              icon: Icons.extension_outlined,
              title: 'Integracije',
              isExpanded: currentRoute.startsWith('integrations'),
              children: [
                // iCal Section Header
                const _DrawerSectionHeader(title: 'iCal'),
                _DrawerSubItem(
                  title: 'Import Rezervacija',
                  subtitle: 'Sync sa booking.com',
                  icon: Icons.download,
                  isSelected: currentRoute == 'integrations/ical/import',
                  onTap: () => context.go(OwnerRoutes.icalImport),
                ),
                _DrawerSubItem(
                  title: 'Export Kalendara',
                  subtitle: 'iCal feed URL',
                  icon: Icons.upload,
                  isSelected: currentRoute == 'integrations/ical/export-list',
                  onTap: () => context.go(OwnerRoutes.icalExportList),
                ),

                const SizedBox(height: 8),

                // Plaćanja Section Header
                const _DrawerSectionHeader(title: 'Plaćanja'),
                _DrawerSubItem(
                  title: 'Stripe Plaćanja',
                  subtitle: 'Obrada kartica',
                  icon: Icons.credit_card,
                  isSelected: currentRoute == 'integrations/stripe',
                  onTap: () => context.go(OwnerRoutes.stripeIntegration),
                ),
                _DrawerSubItem(
                  title: 'Bankovni Račun',
                  subtitle: 'Podaci za uplate',
                  icon: Icons.account_balance,
                  isSelected: currentRoute == 'integrations/payments/bank-account',
                  onTap: () => context.go(OwnerRoutes.bankAccount),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Uputstva Expansion
            _PremiumExpansionTile(
              icon: Icons.menu_book,
              title: 'Uputstva',
              isExpanded: currentRoute.startsWith('guides'),
              children: [
                _DrawerSubItem(
                  title: 'Embed Widget',
                  subtitle: 'Dodavanje na sajt',
                  icon: Icons.code,
                  isSelected: currentRoute == 'guides/embed-widget',
                  onTap: () => context.go(OwnerRoutes.guideEmbedWidget),
                ),
                _DrawerSubItem(
                  title: 'Česta Pitanja',
                  subtitle: 'FAQ',
                  icon: Icons.question_answer,
                  isSelected: currentRoute == 'guides/faq',
                  onTap: () => context.go(OwnerRoutes.guideFaq),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(
                height: 1,
                color: context.borderColor.withValues(alpha: 0.5),
              ),
            ),

            // Settings & Profile
            _DrawerItem(
              icon: Icons.notifications_outlined,
              title: 'Obavještenja',
              isSelected: currentRoute == 'notifications',
              onTap: () => context.go(OwnerRoutes.notifications),
            ),

            const SizedBox(height: 4),

            _DrawerItem(
              icon: Icons.person_outline,
              title: 'Profil',
              isSelected: currentRoute == 'profile',
              onTap: () => context.go(OwnerRoutes.profile),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(
                height: 1,
                color: context.borderColor.withValues(alpha: 0.5),
              ),
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _LogoutButton(
                onLogout: () async {
                  await ref.read(enhancedAuthProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(OwnerRoutes.login);
                  }
                },
              ),
            ),

            const SizedBox(height: 16),
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
            color: GradientTokens.brandPrimaryStart.withAlpha((0.3 * 255).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo - White variant for dark background
          const Center(child: AuthLogoIcon(size: 70, isWhite: true)),
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
                  boxShadow: AppShadows.getElevation(2, isDark: theme.brightness == Brightness.dark),
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
                        color: Colors.white.withAlpha((0.9 * 255).toInt()),
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
    final selectedTextColor = isDark ? _lightPurple : theme.colorScheme.brandPurple;
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
                ? theme.colorScheme.brandPurple.withAlpha((selectedBgAlpha * 255).toInt())
                : _isHovered
                ? theme.colorScheme.brandPurple.withAlpha((hoverBgAlpha * 255).toInt())
                : Colors.transparent,
          ),
          child: ListTile(
            leading: Icon(
              widget.icon,
              color: widget.isSelected
                  ? selectedTextColor
                  : theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
              size: 24,
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
              color: theme.colorScheme.primary.withAlpha((0.6 * 255).toInt()),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
              letterSpacing: 0.5,
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
    final selectedTextColor =
        isDark ? _lightPurple : theme.colorScheme.brandPurple;
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
                ? theme.colorScheme.brandPurple
                    .withAlpha((selectedBgAlpha * 255).toInt())
                : _isHovered
                    ? theme.colorScheme.brandPurple
                        .withAlpha((hoverBgAlpha * 255).toInt())
                    : Colors.transparent,
          ),
          child: ListTile(
            dense: true,
            leading: widget.icon != null
                ? Icon(
                    widget.icon,
                    size: 18,
                    color: widget.isSelected
                        ? selectedTextColor
                        : theme.colorScheme.onSurface.withAlpha(
                            (0.5 * 255).toInt(),
                          ),
                  )
                : const SizedBox(width: 18),
            title: Text(
              widget.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: widget.isSelected
                    ? selectedTextColor
                    : theme.colorScheme.onSurface.withAlpha(
                        (0.85 * 255).toInt(),
                      ),
              ),
            ),
            subtitle: widget.subtitle != null
                ? Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withAlpha(
                        (0.5 * 255).toInt(),
                      ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: theme.colorScheme.brandPurple.withAlpha(
            (0.06 * 255).toInt(),
          ),
          highlightColor: theme.colorScheme.brandPurple.withAlpha(
            (0.06 * 255).toInt(),
          ),
        ),
        child: ExpansionTile(
          leading: Icon(
            icon,
            color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
            size: 24,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
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

/// Premium Logout Button
class _LogoutButton extends StatefulWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _isHovered
              ? theme.colorScheme.danger.withAlpha((0.08 * 255).toInt())
              : Colors.transparent,
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.danger.withAlpha((0.3 * 255).toInt())
                : theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt()),
            width: 1.5,
          ),
        ),
        child: ListTile(
          leading: Icon(
            Icons.logout_rounded,
            color: theme.colorScheme.danger,
            size: 22,
          ),
          title: Text(
            'Odjavi se',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.danger,
            ),
          ),
          onTap: widget.onLogout,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

