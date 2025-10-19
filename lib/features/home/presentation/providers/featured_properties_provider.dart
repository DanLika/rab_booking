import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/property_model.dart';
import '../../../search/data/repositories/property_search_repository.dart';

part 'featured_properties_provider.g.dart';

/// Featured properties provider - fetches real data from Supabase
@riverpod
Future<List<PropertyModel>> featuredProperties(Ref ref) async {
  final repository = ref.watch(propertySearchRepositoryProvider);

  // Fetch featured properties from database
  // If there's an error, AsyncValue will handle it as error state
  return await repository.getFeaturedProperties(limit: 6);
}
