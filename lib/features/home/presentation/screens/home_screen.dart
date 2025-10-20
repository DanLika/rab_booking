import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/featured_properties_section.dart';
import '../widgets/recently_viewed_section.dart';
import '../widgets/popular_destinations_section.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/testimonials_section.dart';
import '../widgets/cta_section.dart';
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
            // 1. Premium Hero Section with integrated search
            HomeHeroSection(
              title: 'Discover Your Perfect Getaway',
              subtitle:
                  'Browse thousands of premium vacation rentals in stunning destinations around the world',
              backgroundImage:
                  'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1600',
              showSearch: true,
              onSearchPressed: () => context.goToSearch(),
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

            // 2.5. Recently Viewed Section (only for logged-in users, with scroll reveal)
            const SectionReveal(
              delay: Duration(milliseconds: 100),
              child: RecentlyViewedSection(
                title: 'Recently Viewed',
                subtitle: 'Properties you have viewed recently',
                maxProperties: 10,
              ),
            ),

            // 3. Popular Destinations Section (with scroll reveal)
            SectionReveal(
              delay: const Duration(milliseconds: 200),
              child: PopularDestinationsSection(
                title: 'Popular Destinations',
                subtitle: 'Explore the most sought-after vacation spots',
                onDestinationTapped: (destination) {
                  // Navigate to search with destination filter
                  context.goToSearch();
                },
              ),
            ),

            // 4. How It Works Section (with scroll reveal)
            const SectionReveal(
              delay: Duration(milliseconds: 100),
              child: HowItWorksSection(
                title: 'How It Works',
                subtitle: 'Book your dream vacation in three simple steps',
              ),
            ),

            // 5. Testimonials Section (with scroll reveal)
            const SectionReveal(
              delay: Duration(milliseconds: 150),
              child: TestimonialsSection(
                title: 'What Our Guests Say',
                subtitle: 'Real experiences from real travelers',
                autoPlay: true,
              ),
            ),

            // 6. Call-to-Action Section (with scroll reveal)
            SectionReveal(
              delay: const Duration(milliseconds: 100),
              child: CtaSectionPresets.getStarted(
                onGetStarted: () => context.goToSearch(),
                onLearnMore: () => context.goToAboutUs(),
              ),
            ),

            // 7. Footer Section
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
