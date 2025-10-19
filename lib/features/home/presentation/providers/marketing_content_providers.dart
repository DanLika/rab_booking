import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/marketing_content_repository.dart';
import '../../domain/models/marketing_content_models.dart';

part 'marketing_content_providers.g.dart';

/// Provider for popular destinations from Supabase
/// Falls back to default destinations if database is empty or unavailable
@riverpod
Future<List<DestinationData>> popularDestinations(Ref ref) async {
  final repository = ref.watch(marketingContentRepositoryProvider);
  final destinations = await repository.getPopularDestinations();

  // Fallback to default destinations if database returns empty
  if (destinations.isEmpty) {
    return defaultDestinations;
  }

  return destinations;
}

/// Provider for How It Works steps from Supabase
/// Falls back to default steps if database is empty or unavailable
@riverpod
Future<List<HowItWorksStep>> howItWorksSteps(Ref ref) async {
  final repository = ref.watch(marketingContentRepositoryProvider);
  final steps = await repository.getHowItWorksSteps();

  // Fallback to default steps if database returns empty
  if (steps.isEmpty) {
    return defaultSteps;
  }

  return steps;
}

/// Provider for featured testimonials from Supabase
/// Falls back to default testimonials if database is empty or unavailable
@riverpod
Future<List<TestimonialData>> featuredTestimonials(Ref ref) async {
  final repository = ref.watch(marketingContentRepositoryProvider);
  final testimonials = await repository.getTestimonials(featuredOnly: true);

  // Fallback to default testimonials if database returns empty
  if (testimonials.isEmpty) {
    return defaultTestimonials;
  }

  return testimonials;
}

/// Provider for all active testimonials (not just featured)
@riverpod
Future<List<TestimonialData>> allTestimonials(Ref ref) async {
  final repository = ref.watch(marketingContentRepositoryProvider);
  return repository.getTestimonials(featuredOnly: false);
}
