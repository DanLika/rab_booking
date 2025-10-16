import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../../../booking/presentation/providers/booking_flow_notifier.dart';
import '../providers/payment_notifier.dart';

/// Payment screen with Stripe CardField integration
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    required this.bookingId,
    super.key,
  });

  final String bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  CardFieldInputDetails? _cardDetails;
  bool _isCardComplete = false;

  @override
  void initState() {
    super.initState();
    // Create payment intent when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createPaymentIntent();
    });
  }

  Future<void> _createPaymentIntent() async {
    final bookingFlow = ref.read(bookingFlowNotifierProvider);

    if (bookingFlow.totalPrice == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Greška: Nepoznat iznos plaćanja'),
            backgroundColor: Colors.red,
          ),
        );
        context.goBack();
      }
      return;
    }

    try {
      // Convert to cents for Stripe
      final amountInCents = (bookingFlow.advanceAmount * 100).round();

      await ref.read(paymentNotifierProvider.notifier).createPaymentIntent(
            bookingId: widget.bookingId,
            totalAmount: amountInCents,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        context.goBack();
      }
    }
  }

  Future<void> _handlePayment() async {
    if (!_isCardComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo unesite podatke o kartici'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bookingFlow = ref.read(bookingFlowNotifierProvider);

    try {
      // Create billing details
      final billingDetails = BillingDetails(
        email: bookingFlow.guestEmail,
        name:
            '${bookingFlow.guestFirstName ?? ''} ${bookingFlow.guestLastName ?? ''}'
                .trim(),
        phone: bookingFlow.guestPhone,
      );

      // Process payment
      await ref.read(paymentNotifierProvider.notifier).processPayment(
            bookingId: widget.bookingId,
            billingDetails: billingDetails,
          );

      // Check payment status
      final paymentState = ref.read(paymentNotifierProvider);

      if (paymentState.isSuccess) {
        // Navigate to success screen
        if (mounted) {
          context.goToPaymentSuccess(widget.bookingId);
        }
      } else if (paymentState.isFailed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(paymentState.error ?? 'Plaćanje nije uspjelo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingFlow = ref.watch(bookingFlowNotifierProvider);
    final paymentState = ref.watch(paymentNotifierProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plaćanje'),
        elevation: 0,
      ),
      body: paymentState.paymentIntent == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Payment amount card
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Iznos za plaćanje',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '€${bookingFlow.advanceAmount.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '(20% avansa od ukupnog iznosa)',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Card field section
                      Text(
                        'Podaci o kartici',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Stripe CardField
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: CardField(
                          onCardChanged: (card) {
                            setState(() {
                              _cardDetails = card;
                              _isCardComplete = card?.complete ?? false;
                            });
                          },
                          enablePostalCode: true,
                          countryCode: 'HR',
                          style: CardFieldInputStyle(
                            textColor: Colors.black,
                            fontSize: 16,
                            placeholderColor: Colors.grey[600],
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Unesite podatke o kartici',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Security info
                      Row(
                        children: [
                          Icon(Icons.lock_outline,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Vaši podaci su sigurni. Koristimo Stripe za sigurno plaćanje.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Payment summary
                      _buildPaymentSummary(bookingFlow),
                      const SizedBox(height: 32),

                      // Pay button
                      FilledButton(
                        onPressed: paymentState.isProcessing || !_isCardComplete
                            ? null
                            : _handlePayment,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: paymentState.isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Plati €${bookingFlow.advanceAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Test card info (for development)
                      if (true) // TODO: Only show in development mode
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 16, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Test kartica (razvoj):',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '4242 4242 4242 4242',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: Colors.blue[900],
                                ),
                              ),
                              Text(
                                'MM/GG: bilo koji budući datum',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Text(
                                'CVC: bilo koji 3-znamenkasti broj',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentSummary(BookingFlowState bookingFlow) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sažetak plaćanja',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            _buildSummaryRow('Osnovna cijena',
                '€${bookingFlow.basePrice.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildSummaryRow('Naknada za uslugu',
                '€${bookingFlow.serviceFee.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildSummaryRow('Naknada za čišćenje',
                '€${bookingFlow.cleaningFee.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildSummaryRow(
              'Ukupno',
              '€${bookingFlow.totalPrice.toStringAsFixed(2)}',
              isTotal: true,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Plaćate sada (20%)',
              '€${bookingFlow.advanceAmount.toStringAsFixed(2)}',
              isHighlighted: true,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Preostalo za platiti',
              '€${(bookingFlow.totalPrice - bookingFlow.advanceAmount).toStringAsFixed(2)}',
              isSubdued: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isHighlighted = false,
    bool isSubdued = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal || isHighlighted ? FontWeight.bold : null,
            fontSize: isTotal ? 16 : 14,
            color: isSubdued ? Colors.grey[600] : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal || isHighlighted ? FontWeight.bold : null,
            fontSize: isTotal ? 16 : 14,
            color: isHighlighted
                ? Theme.of(context).colorScheme.primary
                : isSubdued
                    ? Colors.grey[600]
                    : null,
          ),
        ),
      ],
    );
  }
}
