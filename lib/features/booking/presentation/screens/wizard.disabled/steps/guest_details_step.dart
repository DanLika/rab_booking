import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../providers/booking_flow_notifier.dart';
import '../../../widgets/guest_details_form.dart';

/// Step 1: Guest Details
///
/// Collects guest information including:
/// - First Name, Last Name
/// - Email (for receipt)
/// - Phone (with country code)
/// - Special Requests (optional)
class GuestDetailsStep extends ConsumerWidget {
  const GuestDetailsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingFlowNotifierProvider);
    final bookingNotifier = ref.read(bookingFlowNotifierProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.horizontalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: GuestDetailsForm(
            initialFirstName: bookingState.guestFirstName,
            initialLastName: bookingState.guestLastName,
            initialEmail: bookingState.guestEmail,
            initialPhone: bookingState.guestPhone,
            initialSpecialRequests: bookingState.specialRequests,
            showSaveButton: false, // Navigation handled by wizard
            onSubmit: ({
              required String firstName,
              required String lastName,
              required String email,
              required String phone,
              required String countryCode,
              String? specialRequests,
            }) {
              // Update booking state with guest details
              bookingNotifier.updateGuestDetails(
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: '$countryCode$phone', // Combine country code and phone
                specialRequests: specialRequests,
              );

              // Automatically move to next step after saving
              bookingNotifier.nextStep();
            },
          ),
        ),
      ),
    );
  }
}
