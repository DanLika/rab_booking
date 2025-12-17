import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/providers/widget_repository_providers.dart';
import '../../domain/use_cases/submit_booking_use_case.dart';

part 'submit_booking_provider.g.dart';

/// Provider for SubmitBookingUseCase.
@riverpod
SubmitBookingUseCase submitBookingUseCase(Ref ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  return SubmitBookingUseCase(bookingService);
}
