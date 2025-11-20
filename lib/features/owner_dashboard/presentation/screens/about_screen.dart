import 'package:flutter/material.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/owner_app_drawer.dart';

/// About screen - App information, version, and credits
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      drawer: const OwnerAppDrawer(currentRoute: 'about'),
      appBar: CommonAppBar(
        title: 'About',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo & Name Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.elevation2Dark,
                          AppColors.elevation1Dark,
                        ],
                      )
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : AppColors.primary.withOpacity(0.3),
                    blurRadius: isMobile ? 15 : 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.all(isMobile ? 32 : 48),
              child: Column(
                children: [
                  // App Icon
                  Container(
                    width: isMobile ? 80 : 100,
                    height: isMobile ? 80 : 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: isMobile ? 50 : 60,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  
                  // App Name
                  Text(
                    'Rab Booking',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  
                  // App Tagline
                  Text(
                    'Property Management System',
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 17,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  
                  // Version Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 20,
                      vertical: isMobile ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),

            // What is Rab Booking
            _InfoCard(
              title: 'What is Rab Booking?',
              icon: Icons.info_outline,
              isDark: isDark,
              isMobile: isMobile,
              child: Text(
                'Rab Booking is a comprehensive property management system designed for vacation rental owners. '
                'Manage your properties, bookings, calendar, and integrations all in one place. '
                'Our embedded booking widget makes it easy for guests to book directly on your website.',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Key Features
            _InfoCard(
              title: 'Key Features',
              icon: Icons.star_outline,
              isDark: isDark,
              isMobile: isMobile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureItem(
                    icon: Icons.calendar_today,
                    title: 'Smart Calendar',
                    description: 'Manage availability across multiple properties',
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.book_online,
                    title: 'Online Bookings',
                    description: 'Embedded booking widget for your website',
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.sync,
                    title: 'iCal Integration',
                    description: 'Sync with Booking.com, Airbnb, and more',
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.payment,
                    title: 'Payment Processing',
                    description: 'Stripe integration for secure payments',
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    description: 'Track bookings, revenue, and occupancy',
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Technology Stack
            _InfoCard(
              title: 'Built With',
              icon: Icons.code,
              isDark: isDark,
              isMobile: isMobile,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TechChip('Flutter', isMobile),
                  _TechChip('Firebase', isMobile),
                  _TechChip('Stripe', isMobile),
                  _TechChip('Resend', isMobile),
                  _TechChip('Cloud Functions', isMobile),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),

            // Contact & Support
            _InfoCard(
              title: 'Contact & Support',
              icon: Icons.contact_support_outlined,
              isDark: isDark,
              isMobile: isMobile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContactItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'support@rabbooking.com',
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 12),
                  _ContactItem(
                    icon: Icons.language,
                    label: 'Website',
                    value: 'www.rabbooking.com',
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),

            // Copyright
            Center(
              child: Text(
                '© 2025 Rab Booking. All rights reserved.',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Info Card Widget
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final bool isMobile;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.isMobile,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevation1Dark : Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark.withOpacity(0.5)
              : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: isMobile ? 20 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          child,
        ],
      ),
    );
  }
}

/// Feature Item Widget
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isMobile;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isMobile ? 20 : 22,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tech Chip Widget
class _TechChip extends StatelessWidget {
  final String label;
  final bool isMobile;

  const _TechChip(this.label, this.isMobile);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isMobile ? 12 : 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Contact Item Widget
class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMobile;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: isMobile ? 18 : 20,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
