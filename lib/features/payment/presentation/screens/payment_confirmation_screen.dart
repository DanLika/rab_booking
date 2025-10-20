import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
// import '../../../../shared/repositories/booking_repository.dart'; // Unused
import '../../../../shared/providers/repository_providers.dart';
import '../../data/payment_service.dart';

/// Payment Confirmation Screen
/// Displays payment details and transaction confirmation
class PaymentConfirmationScreen extends ConsumerStatefulWidget {
  const PaymentConfirmationScreen({
    this.bookingId,
    super.key,
  });

  final String? bookingId;

  @override
  ConsumerState<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState
    extends ConsumerState<PaymentConfirmationScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _bookingData;
  List<Map<String, dynamic>>? _paymentRecords;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    if (widget.bookingId == null) {
      setState(() {
        _errorMessage = 'No booking ID provided';
        _isLoading = false;
      });
      return;
    }

    try {
      // Load booking details
      final booking = await ref
          .read(bookingRepositoryProvider)
          .fetchBookingById(widget.bookingId!);

      // Load payment records
      final paymentService = ref.read(paymentServiceProvider);
      final payments = await paymentService.getPaymentRecords(widget.bookingId!);

      setState(() {
        _bookingData = booking?.toJson();
        _paymentRecords = payments.map((p) => p.toJson()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Potvrda Plaćanja'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildConfirmationContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: context.errorColor,
            ),
            const SizedBox(height: AppDimensions.spaceL),
            Text(
              'Greška pri učitavanju',
              style: AppTypography.h2.copyWith(
                fontWeight: AppTypography.weightBold,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              _errorMessage ?? 'Unknown error',
              style: AppTypography.bodyMedium.copyWith(
                color: context.textColorSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home),
              label: const Text('Nazad na početnu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationContent() {
    if (_bookingData == null) {
      return _buildErrorState();
    }

    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success header
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceXL),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.success, AppColors.successDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceM),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 64,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Text(
                  'Plaćanje Uspješno!',
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  'Vaša rezervacija je potvrđena',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          // Booking details
          _buildSectionCard(
            title: 'Detalji Rezervacije',
            icon: Icons.event_note,
            children: [
              _buildDetailRow(
                'ID rezervacije',
                '#${widget.bookingId!.substring(0, 8).toUpperCase()}',
              ),
              _buildDetailRow(
                'Smještaj',
                _bookingData!['property_name'] ?? 'N/A',
              ),
              _buildDetailRow(
                'Check-in',
                dateFormat.format(DateTime.parse(_bookingData!['check_in_date'])),
              ),
              _buildDetailRow(
                'Check-out',
                dateFormat.format(DateTime.parse(_bookingData!['check_out_date'])),
              ),
              _buildDetailRow(
                'Broj gostiju',
                '${_bookingData!['guests']}',
              ),
              const Divider(height: AppDimensions.spaceL),
              _buildDetailRow(
                'Ukupna cijena',
                currencyFormat.format(_bookingData!['total_price']),
                isHighlight: true,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spaceL),

          // Payment details
          if (_paymentRecords != null && _paymentRecords!.isNotEmpty)
            _buildSectionCard(
              title: 'Detalji Plaćanja',
              icon: Icons.payment,
              children: [
                for (final payment in _paymentRecords!)
                  Column(
                    children: [
                      _buildDetailRow(
                        'Status',
                        _getPaymentStatusLabel(payment['status']),
                      ),
                      _buildDetailRow(
                        'Plaćeni iznos',
                        currencyFormat.format((payment['amount'] ?? 0) / 100),
                      ),
                      if (payment['stripe_payment_id'] != null)
                        _buildDetailRow(
                          'ID transakcije',
                          '${payment['stripe_payment_id'].toString().substring(0, 20)}...',
                        ),
                      _buildDetailRow(
                        'Datum plaćanja',
                        dateFormat.format(
                          DateTime.parse(payment['created_at']),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

          const SizedBox(height: AppDimensions.spaceXL),

          // Information box
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Text(
                    'Potvrdu rezervacije smo poslali na vašu email adresu. Možete je pronaći i u "Moje Rezervacije".',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/bookings'),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Moje Rezervacije'),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: const Text('Početna'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: context.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Row(
              children: [
                Icon(icon, color: context.primaryColor),
                const SizedBox(width: AppDimensions.spaceM),
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textColorSecondary,
              fontWeight: isHighlight ? AppTypography.weightBold : null,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isHighlight
                  ? AppTypography.weightBold
                  : AppTypography.weightMedium,
              color: isHighlight ? context.primaryColor : context.textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentStatusLabel(String? status) {
    switch (status) {
      case 'succeeded':
      case 'completed':
        return 'Uspješno';
      case 'pending':
        return 'Na čekanju';
      case 'failed':
        return 'Neuspješno';
      case 'refunded':
        return 'Refundirano';
      default:
        return status ?? 'N/A';
    }
  }
}
