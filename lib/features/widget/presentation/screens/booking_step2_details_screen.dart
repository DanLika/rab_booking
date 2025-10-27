import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';
import '../widgets/booking_summary_sidebar.dart';
import '../widgets/guest_details_form.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/payment_option_selector.dart';
import '../widgets/progress_indicator_widget.dart';

/// Step 2: Guest Details & Payment screen
class BookingStep2DetailsScreen extends ConsumerStatefulWidget {
  const BookingStep2DetailsScreen({super.key});

  @override
  ConsumerState<BookingStep2DetailsScreen> createState() =>
      _BookingStep2DetailsScreenState();
}

class _BookingStep2DetailsScreenState
    extends ConsumerState<BookingStep2DetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(selectedRoomProvider);
    final total = ref.watch(bookingTotalProvider);

    if (room == null) {
      // Navigate back if no room selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bookingStepProvider.notifier).state = 0;
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: BedBookingColors.backgroundWhite,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          if (isMobile) {
            return _buildMobileLayout(context, ref, total);
          } else {
            return _buildDesktopLayout(context, ref, total);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, double total) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildContent(context, ref, total),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: const BookingSummarySidebar(
              showReserveButton: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref, double total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content
        Expanded(
          child: SingleChildScrollView(
            child: _buildContent(context, ref, total),
          ),
        ),

        // Sidebar
        Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          child: const BookingSummarySidebar(
            showReserveButton: false,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, double total) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            const BookingProgressIndicator(currentStep: 2),
            const SizedBox(height: 40),

            // Guest details form
            const GuestDetailsForm(),
            const SizedBox(height: 40),

            // Payment option selector
            const PaymentOptionSelector(),
            const SizedBox(height: 32),

            // Payment method selector
            const PaymentMethodSelector(),
            const SizedBox(height: 40),

            // Navigation buttons
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    ref.read(bookingStepProvider.notifier).state = 1;
                  },
                  style: BedBookingButtons.secondaryButton,
                  child: const Text('Back'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _onReserveAndPay(context, ref, total),
                  style: BedBookingButtons.primaryButton,
                  child: Text('Reserve and pay (\$${total.toStringAsFixed(2)} USD)'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Terms and conditions
            Center(
              child: Text(
                'By clicking on the "book and pay" button you confirm Regulations and the privacy policy',
                style: BedBookingTextStyles.small,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onReserveAndPay(BuildContext context, WidgetRef ref, double total) {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: BedBookingColors.error,
        ),
      );
      return;
    }

    // TODO: Submit booking to API

    // For now, just navigate to confirmation
    ref.read(bookingStepProvider.notifier).state = 3;
  }
}
