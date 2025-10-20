import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/property_model.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/owner_properties_repository.dart';

part 'owner_properties_provider.g.dart';

/// Owner properties provider
@riverpod
Future<List<PropertyModel>> ownerProperties(Ref ref) async {
  final authState = ref.watch(authNotifierProvider);
  final ownerId = authState.user?.id;

  if (ownerId == null) {
    return [];
  }

  final repository = ref.watch(ownerPropertiesRepositoryProvider);
  return await repository.getOwnerProperties(ownerId);
}

/// Owner properties count
@riverpod
Future<int> ownerPropertiesCount(Ref ref) async {
  final properties = await ref.watch(ownerPropertiesProvider.future);
  return properties.length;
}
