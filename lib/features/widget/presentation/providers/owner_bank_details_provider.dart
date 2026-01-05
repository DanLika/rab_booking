import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../shared/models/user_profile_model.dart';
import '../../../../shared/repositories/user_profile_repository.dart';

part 'owner_bank_details_provider.g.dart';

/// Provider to fetch owner's bank details by ownerId
/// Used in booking widget to display bank transfer payment info
@riverpod
Future<CompanyDetails?> ownerBankDetails(Ref ref, String ownerId) async {
  if (ownerId.isEmpty) {
    LoggingService.logWarning(
      'OwnerBankDetailsProvider: Empty ownerId provided, returning null',
    );
    return null;
  }

  try {
    final repository = UserProfileRepository();
    return await repository.getCompanyDetails(ownerId);
  } catch (e, stackTrace) {
    // Log error and return null for graceful degradation
    // Bank details are optional - widget can still function without them
    await LoggingService.logError(
      'OwnerBankDetailsProvider: Failed to fetch bank details for owner $ownerId',
      e,
      stackTrace,
    );
    return null;
  }
}
