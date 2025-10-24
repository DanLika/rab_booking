import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:printing/printing.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../providers/booking_flow_notifier.dart';
import '../../../providers/receipt_provider.dart';

/// Step 6: Success
///
/// Celebrates successful booking with:
/// - Lottie success animation
/// - Confetti celebration
/// - Booking confirmation details
/// - E-receipt download/email options
/// - Next steps instructions
class SuccessStep extends ConsumerStatefulWidget {
  const SuccessStep({super.key});

  @override
  ConsumerState<SuccessStep> createState() => _SuccessStepState();
}

class _SuccessStepState extends ConsumerState<SuccessStep>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _fadeController;
  bool _receiptProcessed = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start animations after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _confettiController.play();
        _fadeController.forward();

        // Process receipt after animations start
        _processReceipt();
      }
    });
  }

  /// Generate PDF receipt, upload to storage, and send email
  Future<void> _processReceipt() async {
    if (_receiptProcessed) return;

    final bookingState = ref.read(bookingFlowNotifierProvider);

    // Validate we have all required data
    if (bookingState.bookingId == null ||
        bookingState.property == null ||
        bookingState.selectedUnit == null ||
        bookingState.guestFirstName == null ||
        bookingState.guestLastName == null ||
        bookingState.guestEmail == null ||
        bookingState.guestPhone == null) {
      debugPrint('Missing required data for receipt generation');
      return;
    }

    _receiptProcessed = true;

    try {
      // Fetch actual booking from database
      final bookingRepository = ref.read(bookingRepositoryProvider);
      final booking = await bookingRepository.fetchBookingById(bookingState.bookingId!);

      if (booking == null) {
        throw Exception('Booking not found in database');
      }

      final receiptProcessor = ref.read(receiptProcessorProvider.notifier);

      await receiptProcessor.processReceipt(
        booking: booking,
        property: bookingState.property!,
        unit: bookingState.selectedUnit!,
        guestFirstName: bookingState.guestFirstName!,
        guestLastName: bookingState.guestLastName!,
        guestEmail: bookingState.guestEmail!,
        guestPhone: bookingState.guestPhone!,
        basePrice: bookingState.basePrice,
        serviceFee: bookingState.serviceFee,
        cleaningFee: bookingState.cleaningFee,
        taxRate: bookingState.taxRate,
        taxAmount: bookingState.taxAmount,
        isFullPayment: bookingState.isFullPaymentSelected,
        refundPolicy: bookingState.currentRefundPolicy,
        specialRequests: bookingState.specialRequests,
      );

      // Update booking flow state with receipt info
      ref.read(bookingFlowNotifierProvider.notifier).updateReceiptStatus(
            receiptEmailSent: true,
          );
    } catch (error) {
      debugPrint('Failed to process receipt: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate receipt: $error'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    }
  }

  /// Download PDF receipt
  Future<void> _downloadReceipt(
    BuildContext context,
    BookingFlowState state,
  ) async {
    if (state.bookingId == null) return;

    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Preuzimanje računa...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Download receipt
      final receiptDownloader = ref.read(receiptDownloaderProvider.notifier);
      final pdfBytes = await receiptDownloader.downloadReceipt(
        bookingId: state.bookingId!,
      );

      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      // Print/share PDF using printing package
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Receipt-${state.bookingId!.substring(0, 8)}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Račun uspješno preuzet'),
            backgroundColor: AppColors.successLight,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $error'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingFlowNotifierProvider);

    return Stack(
      children: [
        // Main Content
        FadeTransition(
          opacity: _fadeController,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.horizontalPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    const SizedBox(height: AppDimensions.spaceXL),

                    // Success Animation
                    SizedBox(
                      height: 200,
                      child: Lottie.asset(
                        'assets/animations/success.json',
                        repeat: false,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback if Lottie file doesn't exist
                          return Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceXL),

                    // Success Title
                    Text(
                      'Rezervacija uspješna!',
                      style: context.isMobile
                          ? AppTypography.h2
                          : AppTypography.h1,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppDimensions.spaceM),

                    // Success Message
                    Text(
                      'Čestitamo! Vaša rezervacija je potvrđena.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppDimensions.spaceXL),

                    // Booking ID Card
                    if (bookingState.bookingId != null)
                      _buildBookingIdCard(bookingState.bookingId!),

                    const SizedBox(height: AppDimensions.spaceL),

                    // E-Receipt Information
                    _buildReceiptInfo(bookingState),

                    const SizedBox(height: AppDimensions.spaceXL),

                    // Next Steps
                    _buildNextSteps(),

                    const SizedBox(height: AppDimensions.spaceXL),

                    // Action Buttons
                    _buildActionButtons(context, bookingState),

                    const SizedBox(height: AppDimensions.spaceXL),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Confetti Overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3.14 / 2, // Down
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingIdCard(String bookingId) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            color: Colors.white,
            size: AppDimensions.iconXL,
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            'Broj rezervacije',
            style: AppTypography.small.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          SelectableText(
            bookingId,
            style: AppTypography.h2.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.weightBold,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            'Sačuvajte ovaj broj za referencu',
            style: AppTypography.small.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptInfo(BookingFlowState state) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                state.receiptEmailSent
                    ? Icons.mark_email_read_outlined
                    : Icons.email_outlined,
                color: AppColors.primary,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'E-račun poslan',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: AppTypography.weightBold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      'Potvrda rezervacije i račun poslani na: ${state.guestEmail ?? ''}',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.receiptPdfUrl != null) ...[
            const SizedBox(height: AppDimensions.spaceM),
            const Divider(height: 1),
            const SizedBox(height: AppDimensions.spaceM),
            OutlinedButton.icon(
              onPressed: () => _downloadReceipt(context, state),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Preuzmi PDF račun'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.infoLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.infoLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.infoLight,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Text(
                'Sljedeći koraci',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: AppTypography.weightBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          _buildStepItem(
            '1. Provjera emaila',
            'Provjerite svoju email adresu za potvrdu rezervacije i detalje.',
          ),
          const SizedBox(height: AppDimensions.spaceS),
          _buildStepItem(
            '2. Priprema za dolazak',
            'Kontaktirat ćemo vas 2 dana prije dolaska sa instrukcijama za prijavu.',
          ),
          const SizedBox(height: AppDimensions.spaceS),
          _buildStepItem(
            '3. Uživajte u boravku',
            'Vidimo se uskoro! Za pitanja nas kontaktirajte putem emaila ili telefona.',
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Text(
                description,
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingFlowState state) {
    return Column(
      children: [
        // View My Bookings Button
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigate to user bookings screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(Icons.calendar_today),
          label: const Text('Moje rezervacije'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingXL,
              vertical: AppDimensions.paddingM,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.spaceM),

        // Return to Home Button
        TextButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: const Text('Povratak na početnu'),
        ),
      ],
    );
  }
}
