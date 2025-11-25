import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../../shared/repositories/user_profile_repository.dart';

part 'owner_bank_details_provider.g.dart';

/// Provider to fetch owner's bank details by ownerId
/// Used in booking widget to display bank transfer payment info
@riverpod
Future<CompanyDetails?> ownerBankDetails(Ref ref, String ownerId) async {
  if (ownerId.isEmpty) {
    return null;
  }

  final repository = UserProfileRepository();
  return repository.getCompanyDetails(ownerId);
}
