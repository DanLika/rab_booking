import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/marketing_content_models.dart';

part 'marketing_content_repository.g.dart';

/// Repository for fetching marketing content from Supabase
/// Replaces hardcoded data with database-driven content
class MarketingContentRepository {
  final SupabaseClient _supabase;

  MarketingContentRepository(this._supabase);

  /// Get active popular destinations ordered by display_order
  Future<List<DestinationData>> getPopularDestinations() async {
    try {
      final response = await _supabase
          .from('popular_destinations')
          .select()
          .eq('is_active', true)
          .order('display_order');

      return (response as List).map((json) {
        return DestinationData(
          name: json['name'] as String,
          location: json['location'] as String,
          imageUrl: json['image_url'] as String,
          propertyCount: json['property_count'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      // Return empty list on error, widgets will handle empty state
      return [];
    }
  }

  /// Get active how it works steps ordered by step_number
  Future<List<HowItWorksStep>> getHowItWorksSteps() async {
    try {
      final response = await _supabase
          .from('how_it_works_steps')
          .select()
          .eq('is_active', true)
          .order('step_number');

      return (response as List).map((json) {
        return HowItWorksStep.fromIconName(
          stepNumber: json['step_number'] as int,
          title: json['title'] as String,
          description: json['description'] as String,
          iconName: json['icon_name'] as String,
        );
      }).toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Get active testimonials
  /// If [featuredOnly] is true, only return featured testimonials
  Future<List<TestimonialData>> getTestimonials({
    bool featuredOnly = true,
  }) async {
    try {
      var query = _supabase
          .from('testimonials')
          .select()
          .eq('is_active', true);

      if (featuredOnly) {
        query = query.eq('is_featured', true);
      }

      final response = await query.order('display_order');

      return (response as List).map((json) {
        return TestimonialData(
          name: json['customer_name'] as String,
          avatarUrl: json['customer_avatar_url'] as String?,
          location: json['customer_location'] as String,
          rating: (json['rating'] as num).toDouble(),
          quote: json['quote'] as String,
          propertyStayedAt: json['property_stayed_at'] as String?,
        );
      }).toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Subscribe to newsletter
  Future<bool> subscribeToNewsletter(String email) async {
    try {
      await _supabase.from('newsletter_subscribers').insert({
        'email': email,
        'subscribed_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });
      return true;
    } catch (e) {
      // Return false if already subscribed or other error
      return false;
    }
  }
}

/// Provider for marketing content repository
@riverpod
MarketingContentRepository marketingContentRepository(Ref ref) {
  return MarketingContentRepository(Supabase.instance.client);
}
