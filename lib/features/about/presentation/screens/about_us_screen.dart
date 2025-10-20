import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';

/// About Us screen
/// Provides information about the platform, mission, and team
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceXL * 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.villa,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppDimensions.spaceL),
                  Text(
                    'RAB Booking',
                    style: AppTypography.h1.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceM),
                  Text(
                    'Your Gateway to Island Paradise',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content Sections
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Our Story
                  _buildSection(
                    title: 'Our Story',
                    content:
                        'RAB Booking was founded with a simple mission: to connect travelers with authentic '
                        'island experiences on the beautiful island of Rab, Croatia. We believe that the best '
                        'vacations are those where you feel at home, and our platform makes it easy to find '
                        'the perfect accommodation for your island getaway.\n\n'
                        'Since our launch, we\'ve helped thousands of travelers discover hidden gems and create '
                        'unforgettable memories on one of the Adriatic\'s most stunning islands.',
                  ),

                  const SizedBox(height: AppDimensions.spaceXL),

                  // Our Mission
                  _buildSection(
                    title: 'Our Mission',
                    content:
                        'To provide a seamless, trustworthy platform that connects property owners with travelers '
                        'seeking authentic island experiences. We are committed to:\n\n'
                        '• Offering a diverse selection of quality accommodations\n'
                        '• Ensuring transparent pricing and secure bookings\n'
                        '• Supporting local property owners and the community\n'
                        '• Delivering exceptional customer service\n'
                        '• Promoting sustainable tourism practices',
                  ),

                  const SizedBox(height: AppDimensions.spaceXL),

                  // Why Choose Us
                  _buildSection(
                    title: 'Why Choose RAB Booking?',
                    content:
                        '🏝️ Local Expertise\n'
                        'We know Rab inside and out. Our team provides insider tips and recommendations to make your stay unforgettable.\n\n'
                        '✓ Verified Properties\n'
                        'Every property on our platform is verified and meets our quality standards.\n\n'
                        '💳 Secure Payments\n'
                        'Your financial information is protected with industry-leading security.\n\n'
                        '🤝 24/7 Support\n'
                        'Our dedicated support team is always ready to assist you before, during, and after your stay.\n\n'
                        '⭐ Best Price Guarantee\n'
                        'We work directly with property owners to offer you competitive rates.',
                  ),

                  const SizedBox(height: AppDimensions.spaceXL),

                  // Our Values
                  _buildSection(
                    title: 'Our Values',
                    content:
                        'Trust & Transparency\n'
                        'We believe in honest communication and clear expectations.\n\n'
                        'Quality & Excellence\n'
                        'We maintain high standards for all properties on our platform.\n\n'
                        'Community & Sustainability\n'
                        'We support the local community and promote responsible tourism.\n\n'
                        'Innovation & Improvement\n'
                        'We continuously enhance our platform based on user feedback.',
                  ),

                  const SizedBox(height: AppDimensions.spaceXL),

                  // Contact CTA
                  Center(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.spaceXL),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 48,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: AppDimensions.spaceM),
                            Text(
                              'Get in Touch',
                              style: AppTypography.h3.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spaceS),
                            Text(
                              'Have questions or suggestions?',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimensions.spaceM),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/support/contact');
                              },
                              icon: const Icon(Icons.send),
                              label: const Text('Contact Us'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spaceXL),

                  // Version info
                  Center(
                    child: Text(
                      'Version 1.0.0',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Text(
          content,
          style: AppTypography.bodyLarge.copyWith(
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
