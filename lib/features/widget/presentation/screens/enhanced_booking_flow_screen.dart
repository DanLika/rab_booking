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
class EnhancedBookingFlowScreen extends ConsumerStatefulWidget {
  final String? propertyId;

  const EnhancedBookingFlowScreen({
    super.key,
    this.propertyId,
  });

  @override
  ConsumerState<EnhancedBookingFlowScreen> createState() => _EnhancedBookingFlowScreenState();
}

class _EnhancedBookingFlowScreenState extends ConsumerState<EnhancedBookingFlowScreen> {
  // Performance Optimization: Cache the screen widgets to avoid re-creating them on every build.
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      EnhancedRoomSelectionScreen(propertyId: widget.propertyId),
      const EnhancedSummaryScreen(),
      const EnhancedPaymentScreen(),
      const EnhancedConfirmationScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(bookingStepProvider);

    return PopScope(
      canPop: currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentStep > 0) {
          // Handle back navigation
          ref.read(bookingStepProvider.notifier).state = currentStep - 1;
        }
      },
      child: _screens[currentStep],
    );
  }
}
