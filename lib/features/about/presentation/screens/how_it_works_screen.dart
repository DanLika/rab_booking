import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/navigation_helpers.dart';

/// How It Works screen
/// Explains the booking process for both guests and property owners
class HowItWorksScreen extends StatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How It Works'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'For Guests', icon: Icon(Icons.person_outline)),
            Tab(text: 'For Owners', icon: Icon(Icons.villa_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGuestsTab(),
          _buildOwnersTab(),
        ],
      ),
    );
  }

  Widget _buildGuestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.beach_access,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppDimensions.spaceL),
                Text(
                  'Book Your Perfect Island Getaway',
                  style: AppTypography.h2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Text(
                  'Four simple steps to your dream vacation',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceXL * 2),

          // Steps
          _buildStep(
            stepNumber: 1,
            icon: Icons.search,
            title: 'Search & Discover',
            description:
                'Browse our curated collection of properties on the island of Rab. Use filters to narrow down your search by location, price, amenities, and more.',
            tips: [
              'Use the map view to see properties in your preferred area',
              'Check availability calendar before booking',
              'Read reviews from previous guests',
              'Save your favorite properties for later',
            ],
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          _buildStep(
            stepNumber: 2,
            icon: Icons.calendar_month,
            title: 'Choose Your Dates',
            description:
                'Select your check-in and check-out dates. Our calendar shows real-time availability and pricing. See the total cost upfront with no hidden fees.',
            tips: [
              'Prices may vary by season',
              'Some properties offer discounts for longer stays',
              'Check the cancellation policy before booking',
              'Consider booking early for peak season',
            ],
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          _buildStep(
            stepNumber: 3,
            icon: Icons.payment,
            title: 'Secure Payment',
            description:
                'Complete your booking with our secure payment system. We accept major credit cards and ensure your information is protected with industry-standard encryption.',
            tips: [
              'All payments are processed securely',
              'You\'ll receive instant booking confirmation',
              'Payment details are never shared with property owners',
              'Refunds follow the property\'s cancellation policy',
            ],
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          _buildStep(
            stepNumber: 4,
            icon: Icons.check_circle,
            title: 'Enjoy Your Stay',
            description:
                'Receive your booking confirmation with all details via email. The property owner will contact you with check-in instructions. Enjoy your island vacation!',
            tips: [
              'Save your booking confirmation',
              'Contact the host if you have questions',
              'Check-in times are typically 14:00-20:00',
              'Leave a review after your stay to help others',
            ],
          ),

          const SizedBox(height: AppDimensions.spaceXL * 2),

          // CTA
          Center(
            child: Column(
              children: [
                FilledButton.icon(
                  onPressed: () {
                    context.goToSearch();
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Start Searching'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceXL,
                      vertical: AppDimensions.spaceL,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                TextButton.icon(
                  onPressed: () {
                    context.goToHelpFaq();
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('View FAQs'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spaceXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.home_work,
                  size: 80,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: AppDimensions.spaceL),
                Text(
                  'List Your Property & Earn Income',
                  style: AppTypography.h2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Text(
                  'Start hosting in four easy steps',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceXL * 2),

          // Steps
          _buildStep(
            stepNumber: 1,
            icon: Icons.add_home,
            title: 'Create Your Listing',
            description:
                'Sign up and create your property listing. Add high-quality photos, detailed descriptions, and amenities. Our easy-to-use dashboard makes it simple.',
            tips: [
              'Use professional photos for best results',
              'Write detailed, accurate descriptions',
              'List all available amenities',
              'Set competitive pricing based on market rates',
            ],
            color: AppColors.secondary,
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          _buildStep(
            stepNumber: 2,
            icon: Icons.calendar_today,
            title: 'Manage Availability',
            description:
                'Control your calendar with our intuitive booking system. Set your available dates, minimum stay requirements, and pricing. Update anytime.',
            tips: [
              'Keep your calendar up to date',
              'Block out dates when unavailable',
              'Set seasonal pricing for peak periods',
              'Offer discounts for longer bookings',
            ],
            color: AppColors.secondary,
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          _buildStep(
            stepNumber: 3,
            icon: Icons.notifications_active,
            title: 'Receive Bookings',
            description:
                'Get instant notifications when guests book your property. Review booking details and communicate with guests through our platform.',
            tips: [
              'Respond to inquiries quickly',
              'Confirm bookings promptly',
              'Send check-in instructions in advance',
              'Be available for guest questions',
            ],
            color: AppColors.secondary,
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          _buildStep(
            stepNumber: 4,
            icon: Icons.attach_money,
            title: 'Get Paid',
            description:
                'Receive secure payments directly to your account. Track your earnings, view analytics, and grow your hosting business with our comprehensive dashboard.',
            tips: [
              'Payments are processed securely',
              'View detailed earning reports',
              'Track occupancy and performance metrics',
              'Optimize pricing based on analytics',
            ],
            color: AppColors.secondary,
          ),

          const SizedBox(height: AppDimensions.spaceXL * 2),

          // Benefits section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Host with RAB Booking?',
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceL),
                  _buildBenefit(Icons.verified, 'Verified Guest Reviews'),
                  _buildBenefit(Icons.security, 'Secure Payment Processing'),
                  _buildBenefit(Icons.support_agent, '24/7 Support Team'),
                  _buildBenefit(Icons.analytics, 'Advanced Analytics Dashboard'),
                  _buildBenefit(Icons.stars, 'Premium Listing Features'),
                  _buildBenefit(Icons.people, 'Growing Guest Community'),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.spaceXL * 2),

          // CTA
          Center(
            child: Column(
              children: [
                FilledButton.icon(
                  onPressed: () {
                    context.goToRegister();
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Become a Host'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceXL,
                      vertical: AppDimensions.spaceL,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                TextButton.icon(
                  onPressed: () {
                    context.goToContact();
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Contact Us for More Info'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required IconData icon,
    required String title,
    required String description,
    required List<String> tips,
    Color? color,
  }) {
    final stepColor = color ?? AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number circle
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                stepColor,
                stepColor.withValues(alpha: 0.7),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: AppTypography.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: AppDimensions.spaceL),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: stepColor, size: 24),
                  const SizedBox(width: AppDimensions.spaceS),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: stepColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceM),
              Text(
                description,
                style: AppTypography.bodyLarge.copyWith(
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceM),
                decoration: BoxDecoration(
                  color: stepColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: stepColor,
                        ),
                        const SizedBox(width: AppDimensions.spaceS),
                        Text(
                          'Tips:',
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.bold,
                            color: stepColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    ...tips.map((tip) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppDimensions.spaceS,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: AppTypography.caption.copyWith(
                                  color: stepColor,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: AppTypography.caption,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceM),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
