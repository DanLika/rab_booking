import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/config/router_owner.dart';
import '../../../auth/presentation/widgets/auth_logo_icon.dart';

/// Premium Owner App Navigation Drawer
class OwnerAppDrawer extends ConsumerWidget {
  final String currentRoute;

  const OwnerAppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final authState = ref.watch(enhancedAuthProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          // Dark mode: subtle gradient, Light mode: beige to white
          gradient: isDarkMode
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface,
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFAF8F3), // Beige
                    Color(0xFFFFFFFF), // White
                  ],
                  stops: [0.0, 0.3],
                ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Premium Header with Logo
            _buildPremiumHeader(context, user, authState),

            const SizedBox(height: 8),

            // Navigation items
            _DrawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Pregled',
              isSelected: currentRoute == 'overview',
              onTap: () {
                Navigator.pop(context);
                context.go(OwnerRoutes.overview);
              },
            ),

            const SizedBox(height: 4),

            _DrawerItem(
              icon: Icons.calendar_view_month,
              title: 'Kalendar',
              isSelected: currentRoute.startsWith('calendar'),
              onTap: () {
                Navigator.pop(context);
                context.go(OwnerRoutes.calendarTimeline);
              },
            ),

            const SizedBox(height: 4),

            // Rezervacije Expansion
            _PremiumExpansionTile(
              icon: Icons.book_online,
              title: 'Rezervacije',
              isExpanded: currentRoute.startsWith('bookings'),
              children: [
                _DrawerSubItem(
                  title: 'Sve rezervacije',
                  isSelected: currentRoute == 'bookings',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(OwnerRoutes.bookings);
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Konfiguracija Expansion
            _PremiumExpansionTile(
              icon: Icons.settings_outlined,
              title: 'Konfiguracija',
              isExpanded: currentRoute.startsWith('properties') ||
                  currentRoute.startsWith('units') ||
                  currentRoute == 'price-list',
              children: [
                _DrawerSubItem(
                  title: 'Smještajne jedinice',
                  isSelected: currentRoute == 'properties',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(OwnerRoutes.properties);
                  },
                ),
                _DrawerSubItem(
                  title: 'Cjenovnik',
                  isSelected: currentRoute == 'price-list',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(OwnerRoutes.priceList);
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Integracije Expansion
            _PremiumExpansionTile(
              icon: Icons.extension_outlined,
              title: 'Integracije',
              isExpanded: currentRoute.startsWith('integrations'),
              children: [
                _DrawerSubItem(
                  title: 'Stripe Plaćanja',
                  subtitle: 'Obrada kartica',
                  icon: Icons.payment,
                  isSelected: currentRoute == 'integrations/stripe',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(OwnerRoutes.stripeIntegration);
                  },
                ),
                _DrawerSubItem(
                  title: 'iCal Sinhronizacija',
                  subtitle: 'Booking.com, Airbnb...',
                  icon: Icons.sync,
                  isSelected: currentRoute == 'integrations/ical',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(OwnerRoutes.icalIntegration);
                  },
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
                  onTap: () {
                    Navigator.pop(context);
                    context.go(OwnerRoutes.guideEmbedWidget);
                  },
                ),
                _DrawerSubItem(
                  title: 'Česta Pitanja',
                  subtitle: 'FAQ',
                  icon: Icons.question_answer,
                  isSelected: currentRoute == 'guides/faq',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(OwnerRoutes.guideFaq);
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Pravni Dokumenti Expansion
            _PremiumExpansionTile(
              icon: Icons.gavel,
              title: 'Pravni Dokumenti',
              isExpanded: currentRoute.startsWith('privacy') ||
                  currentRoute.startsWith('terms') ||
                  currentRoute.startsWith('cookies'),
              children: [
                _DrawerSubItem(
                  title: 'Uslovi Korištenja',
                  icon: Icons.description,
                  isSelected: currentRoute == 'terms-conditions',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(OwnerRoutes.termsConditions);
                  },
                ),
                _DrawerSubItem(
                  title: 'Politika Privatnosti',
                  icon: Icons.privacy_tip,
                  isSelected: currentRoute == 'privacy-policy',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(OwnerRoutes.privacyPolicy);
                  },
                ),
                _DrawerSubItem(
                  title: 'Cookies Politika',
                  icon: Icons.cookie,
                  isSelected: currentRoute == 'cookies-policy',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(OwnerRoutes.cookiesPolicy);
                  },
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(height: 1),
            ),

            // Settings & Profile
            _DrawerItem(
              icon: Icons.notifications_outlined,
              title: 'Obavještenja',
              isSelected: currentRoute == 'notifications',
              onTap: () {
                Navigator.pop(context);
                context.go(OwnerRoutes.notifications);
              },
            ),

            const SizedBox(height: 4),

            _DrawerItem(
              icon: Icons.person_outline,
              title: 'Profil',
              isSelected: currentRoute == 'profile',
              onTap: () {
                Navigator.pop(context);
                context.go(OwnerRoutes.profile);
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Divider(height: 1),
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
    final displayName = authState.userModel?.firstName != null &&
            authState.userModel?.lastName != null
        ? '${authState.userModel!.firstName} ${authState.userModel!.lastName}'
        : user?.displayName ?? 'Owner';

    final email = user?.email ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B4CE6), // Purple
            Color(0xFF4A90E2), // Blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4CE6).withAlpha((0.3 * 255).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo - White variant for dark background
          const Center(
            child: AuthLogoIcon(size: 70, isWhite: true),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).toInt()),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: authState.userModel?.avatarUrl != null &&
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
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B4CE6),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B4CE6),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                ? const Color(0xFF6B4CE6).withAlpha((0.12 * 255).toInt())
                : _isHovered
                    ? const Color(0xFF6B4CE6).withAlpha((0.06 * 255).toInt())
                    : Colors.transparent,
          ),
          child: ListTile(
            leading: Icon(
              widget.icon,
              color: widget.isSelected
                  ? const Color(0xFF6B4CE6)
                  : theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
              size: 24,
            ),
            title: Text(
              widget.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                color: widget.isSelected
                    ? const Color(0xFF6B4CE6)
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                ? const Color(0xFF6B4CE6).withAlpha((0.12 * 255).toInt())
                : _isHovered
                    ? const Color(0xFF6B4CE6).withAlpha((0.06 * 255).toInt())
                    : Colors.transparent,
          ),
          child: ListTile(
            dense: true,
            leading: widget.icon != null
                ? Icon(
                    widget.icon,
                    size: 18,
                    color: widget.isSelected
                        ? const Color(0xFF6B4CE6)
                        : theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
                  )
                : const SizedBox(width: 18),
            title: Text(
              widget.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                color: widget.isSelected
                    ? const Color(0xFF6B4CE6)
                    : theme.colorScheme.onSurface.withAlpha((0.85 * 255).toInt()),
              ),
            ),
            subtitle: widget.subtitle != null
                ? Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withAlpha((0.5 * 255).toInt()),
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
          splashColor: const Color(0xFF6B4CE6).withAlpha((0.06 * 255).toInt()),
          highlightColor: const Color(0xFF6B4CE6).withAlpha((0.06 * 255).toInt()),
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
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
              ? const Color(0xFFEF4444).withAlpha((0.08 * 255).toInt())
              : Colors.transparent,
          border: Border.all(
            color: _isHovered
                ? const Color(0xFFEF4444).withAlpha((0.3 * 255).toInt())
                : theme.colorScheme.onSurface.withAlpha((0.2 * 255).toInt()),
            width: 1.5,
          ),
        ),
        child: ListTile(
          leading: const Icon(
            Icons.logout_rounded,
            color: Color(0xFFEF4444),
            size: 22,
          ),
          title: const Text(
            'Odjavi se',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEF4444),
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
