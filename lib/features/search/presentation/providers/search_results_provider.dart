import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/property_model.dart';
import '../../data/repositories/property_search_repository.dart';
import 'search_state_provider.dart';

part 'search_results_provider.g.dart';

/// Search results provider
@riverpod
Future<List<PropertyModel>> searchResults(SearchResultsRef ref) async {
  final filters = ref.watch(searchFiltersNotifierProvider);
  final repository = ref.watch(propertySearchRepositoryProvider);

  return await repository.searchProperties(filters);
}

/// Search results count provider
@riverpod
Future<int> searchResultsCount(SearchResultsCountRef ref) async {
  final results = await ref.watch(searchResultsProvider.future);
  return results.length;
}
