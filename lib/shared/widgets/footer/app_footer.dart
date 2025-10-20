import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../core/utils/navigation_helpers.dart';
import '../../../features/home/data/marketing_content_repository.dart';

/// Premium app footer with links, newsletter, and social media
/// Features: Multi-column responsive layout, newsletter subscription, social icons
class AppFooter extends ConsumerStatefulWidget {
  const AppFooter({super.key});

  @override
  ConsumerState<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends ConsumerState<AppFooter> {
  final _newsletterController = TextEditingController();
  bool _isSubmitting = false;
  bool _subscribed = false;

  @override
  void dispose() {
    _newsletterController.dispose();
    super.dispose();
  }

  Future<void> _subscribeToNewsletter() async {
    final email = _newsletterController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Please enter a valid email address', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(marketingContentRepositoryProvider);
      final success = await repository.subscribeToNewsletter(email);

      if (success) {
        setState(() {
          _subscribed = true;
          _newsletterController.clear();
        });
        _showMessage('Thank you for subscribing!', isError: false);
      } else {
        _showMessage('This email is already subscribed', isError: true);
      }
    } catch (e) {
      _showMessage('Failed to subscribe. Please try again.', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? context.errorColor : context.successColor,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Main footer content
          MaxWidthContainer(
            maxWidth: AppDimensions.containerXXL,
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding,
              vertical: context.isMobile ? AppDimensions.spaceXXL : AppDimensions.sectionPaddingVerticalDesktop,
            ),
            child: ResponsiveBuilder(
              mobile: (context, constraints) => _buildMobileLayout(context, isDark),
              tablet: (context, constraints) => _buildTabletLayout(context, isDark),
              desktop: (context, constraints) => _buildDesktopLayout(context, isDark),
            ),
          ),

          // Copyright bar
          _buildCopyrightBar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAboutColumn(context, isDark),
        const SizedBox(height: AppDimensions.spaceXL),
        _buildQuickLinksColumn(context, isDark),
        const SizedBox(height: AppDimensions.spaceXL),
        _buildLegalColumn(context, isDark),
        const SizedBox(height: AppDimensions.spaceXL),
        _buildNewsletterColumn(context, isDark),
        const SizedBox(height: AppDimensions.spaceXL),
        _buildSocialIcons(context, isDark),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildAboutColumn(context, isDark)),
            const SizedBox(width: AppDimensions.spaceXL),
            Expanded(child: _buildQuickLinksColumn(context, isDark)),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceXXL),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildLegalColumn(context, isDark)),
            const SizedBox(width: AppDimensions.spaceXL),
            Expanded(child: _buildNewsletterColumn(context, isDark)),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceXL),
        _buildSocialIcons(context, isDark),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildAboutColumn(context, isDark)),
        const SizedBox(width: AppDimensions.spaceXXL),
        Expanded(child: _buildQuickLinksColumn(context, isDark)),
        const SizedBox(width: AppDimensions.spaceXXL),
        Expanded(child: _buildLegalColumn(context, isDark)),
        const SizedBox(width: AppDimensions.spaceXXL),
        Expanded(flex: 2, child: _buildNewsletterColumn(context, isDark)),
      ],
    );
  }

  Widget _buildAboutColumn(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Row(
          children: [
            const Icon(
              Icons.villa,
              color: AppColors.primary,
              size: AppDimensions.iconXL,
            ),
            const SizedBox(width: AppDimensions.spaceS),
            Text(
              'Rab Booking',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceM),

        Text(
          'Your trusted partner for finding the perfect vacation rental on the beautiful island of Rab, Croatia.',
          style: AppTypography.bodyMedium.copyWith(
            color: context.textColorSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),

        _buildSocialIcons(context, isDark),
      ],
    );
  }

  Widget _buildQuickLinksColumn(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Links',
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),

        _FooterLink(label: 'Search Properties', onTap: () => context.goToSearch()),
        _FooterLink(label: 'About Us', onTap: () => context.goToAboutUs()),
        _FooterLink(label: 'How It Works', onTap: () => context.goToHowItWorks()),
        _FooterLink(label: 'Contact', onTap: () => context.goToContact()),
        _FooterLink(label: 'FAQs', onTap: () => context.goToHelpFaq()),
        _FooterLink(label: 'Help Center', onTap: () => context.goToHelpFaq()),
      ],
    );
  }

  Widget _buildLegalColumn(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legal',
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),

        _FooterLink(label: 'Terms & Conditions', onTap: () => context.goToTermsConditions()),
        _FooterLink(label: 'Privacy Policy', onTap: () => context.goToPrivacyPolicy()),
        _FooterLink(label: 'Cookie Policy', onTap: () => context.goToPrivacyPolicy()),
        _FooterLink(label: 'Cancellation Policy', onTap: () => context.goToTermsConditions()),
      ],
    );
  }

  Widget _buildNewsletterColumn(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stay Updated',
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),

        Text(
          'Subscribe to our newsletter for exclusive deals and travel tips.',
          style: AppTypography.bodyMedium.copyWith(
            color: context.textColorSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),

        if (!_subscribed) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newsletterController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceM,
                      vertical: AppDimensions.spaceS,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _subscribeToNewsletter(),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceS),
              FilledButton(
                onPressed: _isSubmitting ? null : _subscribeToNewsletter,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceL,
                    vertical: AppDimensions.spaceM,
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Subscribe'),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            decoration: BoxDecoration(
              color: context.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: context.successColor),
                const SizedBox(width: AppDimensions.spaceS),
                Text(
                  'You are subscribed!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialIcons(BuildContext context, bool isDark) {
    final iconColor = context.textColorSecondary;

    return Row(
      children: [
        _SocialIconButton(
          icon: Icons.facebook,
          color: iconColor,
          onTap: () => _launchUrl('https://facebook.com'),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        _SocialIconButton(
          icon: Icons.camera_alt, // Instagram icon placeholder
          color: iconColor,
          onTap: () => _launchUrl('https://instagram.com'),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        _SocialIconButton(
          icon: Icons.alternate_email, // Twitter/X icon placeholder
          color: iconColor,
          onTap: () => _launchUrl('https://twitter.com'),
        ),
      ],
    );
  }

  Widget _buildCopyrightBar(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: AppDimensions.spaceM,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
      ),
      child: MaxWidthContainer(
        maxWidth: AppDimensions.containerXXL,
        child: Text(
          '© ${DateTime.now().year} Rab Booking. All rights reserved.',
          style: AppTypography.bodySmall.copyWith(
            color: context.textColorSecondary,
          ),
          textAlign: context.isMobile ? TextAlign.center : TextAlign.left,
        ),
      ),
    );
  }
}

/// Footer link widget
class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXS),
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: context.textColorSecondary,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// Social icon button widget
class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceS),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(
          icon,
          size: AppDimensions.iconM,
          color: color,
        ),
      ),
    );
  }
}
