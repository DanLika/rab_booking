import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/payment_option.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';

/// Step 3: Confirmation screen
class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guestDetails = ref.watch(guestDetailsProvider);
    final paymentMethod = ref.watch(paymentMethodProvider);
    final total = ref.watch(bookingTotalProvider);

    // Generate mock booking number
    final bookingNumber = DateTime.now().millisecondsSinceEpoch % 100000000;

    return Scaffold(
      backgroundColor: BedBookingColors.backgroundWhite,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Green success banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: const BoxDecoration(
                    color: BedBookingColors.primaryGreen,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Property name
                      const Text(
                        'Rocky Resort *DEMO*',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Thank you heading
                      const Text(
                        'Thank you',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Checkmark icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Booking number
                      Text(
                        'Reservation number $bookingNumber has been made!',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // White content area
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Email confirmation notice
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BedBookingColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              color: BedBookingColors.textGrey,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'The reservation confirmation has been sent to your email',
                                    style: BedBookingTextStyles.body,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    guestDetails.email,
                                    style: BedBookingTextStyles.bodyBold,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Payment info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BedBookingColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.payment,
                              color: BedBookingColors.textGrey,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${paymentMethod.label} (\$${total.toStringAsFixed(2)} USD)',
                                style: BedBookingTextStyles.bodyBold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Go to property button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to property page or close widget
                            debugPrint('Go to property');
                          },
                          style: BedBookingButtons.primaryButton,
                          child: const Text('Go to: Rocky Resort *DEMO*'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // BedBooking branding (optional)
                Text(
                  '© 2025 - Reservation system BedBooking',
                  style: BedBookingTextStyles.small,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
