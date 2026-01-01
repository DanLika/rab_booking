import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_flow_provider.dart';
import 'enhanced_room_selection_screen.dart';
import 'enhanced_summary_screen.dart';
import 'enhanced_payment_screen.dart';
import 'enhanced_confirmation_screen.dart';

/// Main Enhanced Booking Flow Screen - Coordinator for all steps
///
/// Flow B - Multi-step booking process:
/// Step 0: Room Selection (with integrated calendar)
/// Step 1: Summary & Additional Services
/// Step 2: Guest Details & Payment
/// Step 3: Confirmation
class EnhancedBookingFlowScreen extends ConsumerWidget {
  final String? propertyId;

  const EnhancedBookingFlowScreen({
    super.key,
    this.propertyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(bookingStepProvider);

    return PopScope(
      canPop: currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentStep > 0) {
          // Handle back navigation
          ref.read(bookingStepProvider.notifier).state = currentStep - 1;
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        child: _buildCurrentStep(currentStep),
      ),
    );
  }

  Widget _buildCurrentStep(int step) {
    switch (step) {
      case 0:
        return EnhancedRoomSelectionScreen(propertyId: propertyId);
      case 1:
        return const EnhancedSummaryScreen();
      case 2:
        return const EnhancedPaymentScreen();
      case 3:
        return const EnhancedConfirmationScreen();
      default:
        return EnhancedRoomSelectionScreen(propertyId: propertyId);
    }
  }
}
