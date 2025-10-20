import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../booking/presentation/providers/booking_flow_notifier.dart';
import '../../../booking/data/booking_notification_service.dart';

/// Payment success screen with booking confirmation
class PaymentSuccessScreen extends ConsumerStatefulWidget {
  const PaymentSuccessScreen({
    required this.bookingId,
    super.key,
  });

  final String bookingId;

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Success animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    // Load booking details
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await ref
          .read(bookingRepositoryProvider)
          .fetchBookingById(widget.bookingId);

      if (booking != null && mounted) {
        // Send booking confirmation email
        final notificationService = ref.read(bookingNotificationServiceProvider);
        final emailSent = await notificationService.sendBookingConfirmation(widget.bookingId);

        if (emailSent) {
          debugPrint('✅ Booking confirmation email sent successfully');
        } else {
          debugPrint('⚠️ Failed to send booking confirmation email (non-blocking)');
        }

        // Optionally update booking flow state with confirmed booking
      }
    } catch (e) {
      debugPrint('❌ Error loading booking: $e');
      // Handle error silently or show error
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingFlow = ref.watch(bookingFlowNotifierProvider);
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Potvrda rezervacije'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Breakpoints.getHorizontalPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success animation
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green[500],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Success message
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Plaćanje uspješno!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vaša rezervacija je potvrđena',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Booking confirmation card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.confirmation_number,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Broj rezervacije',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.bookingId,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.grey[700],
                        ),
                      ),
                      const Divider(height: 24),
                      if (bookingFlow.property != null) ...[
                        Text(
                          bookingFlow.property!.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bookingFlow.selectedUnit?.name ?? '',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Dolazak',
                          bookingFlow.checkInDate != null
                              ? dateFormat.format(bookingFlow.checkInDate!)
                              : '',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Odlazak',
                          bookingFlow.checkOutDate != null
                              ? dateFormat.format(bookingFlow.checkOutDate!)
                              : '',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.people,
                          'Gosti',
                          '${bookingFlow.numberOfGuests} ${bookingFlow.numberOfGuests == 1 ? 'gost' : 'gostiju'}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment info card
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payment,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Informacije o plaćanju',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildPaymentRow(
                        'Ukupan iznos',
                        '€${bookingFlow.totalPrice.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      _buildPaymentRow(
                        'Plaćeno sada',
                        '€${bookingFlow.advanceAmount.toStringAsFixed(2)}',
                        isHighlighted: true,
                      ),
                      const SizedBox(height: 8),
                      _buildPaymentRow(
                        'Preostalo za platiti',
                        '€${(bookingFlow.totalPrice - bookingFlow.advanceAmount).toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 20, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Preostali iznos će biti naplaćen prilikom dolaska',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Email confirmation notice
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined,
                        color: Colors.green[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Potvrda poslana na email',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Detalje rezervacije smo poslali na ${bookingFlow.guestEmail ?? 'vašu email adresu'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action buttons
              FilledButton.icon(
                onPressed: () => _navigateToBookingSuccess(),
                icon: const Icon(Icons.verified),
                label: const Text('Vidi potvrdu rezervacije'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.goToHome(),
                icon: const Icon(Icons.home),
                label: const Text('Povratak na početnu'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value,
      {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isHighlighted ? FontWeight.bold : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  /// Navigate to detailed booking success screen
  void _navigateToBookingSuccess() {
    final bookingFlow = ref.read(bookingFlowNotifierProvider);

    // Validate required data
    if (bookingFlow.property == null ||
        bookingFlow.selectedUnit == null ||
        bookingFlow.checkInDate == null ||
        bookingFlow.checkOutDate == null) {
      // Fallback to my bookings if data is missing
      context.goToMyBookings();
      return;
    }

    // Calculate nights
    final nights = bookingFlow.checkOutDate!
        .difference(bookingFlow.checkInDate!)
        .inDays;

    // Prepare booking details
    final bookingDetails = {
      'propertyName': bookingFlow.property!.name,
      'propertyImage': bookingFlow.property!.coverImage,
      'propertyLocation': bookingFlow.property!.location,
      'checkIn': bookingFlow.checkInDate!.toIso8601String(),
      'checkOut': bookingFlow.checkOutDate!.toIso8601String(),
      'guests': bookingFlow.numberOfGuests,
      'nights': nights,
      'totalAmount': bookingFlow.totalPrice,
      'currencySymbol': '€',
      'confirmationEmail': bookingFlow.guestEmail ?? '',
    };

    // Navigate to booking success screen
    context.goToBookingSuccess(
      bookingReference: widget.bookingId,
      bookingDetails: bookingDetails,
    );
  }
}
