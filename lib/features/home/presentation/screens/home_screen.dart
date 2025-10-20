import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/home_hero_section_premium.dart';
import '../widgets/featured_properties_section.dart';
import '../widgets/recently_viewed_section_premium.dart';
import '../widgets/popular_destinations_section_premium.dart';
import '../widgets/how_it_works_section_premium.dart';
import '../widgets/testimonials_section_premium.dart';
import '../widgets/cta_section_premium.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/animations/scroll_reveal.dart';

/// Premium home screen with all sections + scroll reveal animations (2025 UX)
/// Phase 4: Complete premium home screen implementation
/// Phase 5: Added scroll-triggered reveal animations
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Premium Hero Section with Functional Search
            const HomeHeroSectionPremium(
              title: 'Discover Your Perfect Getaway on Rab Island',
              subtitle: 'Premium villas, apartments & vacation homes in the heart of the Adriatic',
              backgroundImage: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1600',
            ),

            // 2. Featured Properties Section (with scroll reveal)
            SectionReveal(
              child: FeaturedPropertiesSection(
                title: 'Featured Properties',
                subtitle: 'Hand-picked properties for your perfect stay',
                maxProperties: 6,
                onPropertyTapped: (PropertyModel property) {
                  context.goToPropertyDetails(property.id);
                },
                onSeeAllTapped: () => context.goToSearch(),
              ),
            ),

            // 2.5. Recently Viewed Section (Premium) - only for logged-in users
            const SectionReveal(
              delay: Duration(milliseconds: 100),
              child: RecentlyViewedSectionPremium(
                title: 'Recently Viewed',
                subtitle: 'Properties you have viewed recently',
                maxProperties: 10,
              ),
            ),

            // 3. Popular Destinations Section Premium (with scroll reveal)
            SectionReveal(
              delay: const Duration(milliseconds: 200),
              child: PopularDestinationsSectionPremium(
                title: 'Popular Destinations',
                subtitle: 'Explore the most sought-after vacation spots on Rab Island',
                onDestinationTapped: (destination) {
                  // Navigate to search with destination filter
                  context.goToSearch();
                },
              ),
            ),

            // 4. How It Works Section Premium (with scroll reveal)
            const SectionReveal(
              delay: Duration(milliseconds: 100),
              child: HowItWorksSectionPremium(
                title: 'How It Works',
                subtitle: 'Book your dream vacation in three simple steps',
              ),
            ),

            // 5. Testimonials Section Premium (with scroll reveal)
            const SectionReveal(
              delay: Duration(milliseconds: 150),
              child: TestimonialsSectionPremium(
                title: 'What Our Guests Say',
                subtitle: 'Real experiences from real travelers',
                autoPlay: true,
              ),
            ),

            // 6. Call-to-Action Section Premium (with scroll reveal)
            SectionReveal(
              delay: const Duration(milliseconds: 100),
              child: CtaSectionPresetsPremium.getStarted(
                onGetStarted: () => context.goToSearch(),
                onLearnMore: () => context.goToAboutUs(),
              ),
            ),

            // Bottom padding to account for BottomNavigationBar
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
