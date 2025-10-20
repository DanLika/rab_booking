import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/property_model.dart';
import '../../../search/data/repositories/property_search_repository.dart';

part 'featured_properties_provider.g.dart';

/// Featured properties provider - fetches real data from Supabase
@riverpod
Future<List<PropertyModel>> featuredProperties(Ref ref) async {
  print('🔍 [FeaturedProperties] Starting fetch...');

  final repository = ref.watch(propertySearchRepositoryProvider);

  try {
    print('🔍 [FeaturedProperties] Calling repository.getFeaturedProperties()...');
    final properties = await repository.getFeaturedProperties(limit: 6);

    print('✅ [FeaturedProperties] Success! Fetched ${properties.length} properties');
    for (var i = 0; i < properties.length; i++) {
      print('  ${i + 1}. ${properties[i].name} - \$${properties[i].pricePerNight}/night');
    }

    return properties;
  } catch (e, stackTrace) {
    print('❌ [FeaturedProperties] ERROR: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}
