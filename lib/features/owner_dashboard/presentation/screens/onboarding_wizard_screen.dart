import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../domain/models/onboarding_state.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_property_step.dart';

/// Main onboarding wizard screen with stepper UI
class OnboardingWizardScreen extends ConsumerWidget {
  const OnboardingWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingNotifierProvider);

    return Scaffold(
      body: Container(
        color: Colors.black.withValues(alpha: 0.5), // Overlay background
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Stepper Header
                  _buildStepperHeader(context, onboardingState.currentStep),

                  const Divider(height: 1),

                  // Step Content
                  Expanded(
                    child: _buildCurrentStep(onboardingState.currentStep),
                  ),

                  const Divider(height: 1),

                  // Navigation Buttons
                  _buildNavigationButtons(context, ref, onboardingState),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader(BuildContext context, int currentStep) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepIndicator(
            number: 1,
            label: 'Podaci o Objektu',
            isActive: true,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(int currentStep) {
    // Only property step now - unit and pricing are done through main dashboard
    return const OnboardingPropertyStep();
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    WidgetRef ref,
    OnboardingState state,
  ) {
    final canGoNext = _canGoNext(state);
    final isLastStep = true; // Only 1 step now, always last

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Skip Button
          TextButton(
            onPressed: () => _showSkipDialog(context, ref),
            child: const Text('Preskoči'),
          ),

          const SizedBox(width: 16),

          // Finish Button (only 1 step now)
          ElevatedButton(
            onPressed: canGoNext ? () => _handleNext(context, ref, state, isLastStep) : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: AppColors.authPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Row(
              children: [
                Text(
                  'Završi',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 8),
                Icon(Icons.check),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canGoNext(OnboardingState state) {
    switch (state.currentStep) {
      case 0: // Property step - REQUIRED
        return state.propertyData != null;
      case 1: // Unit step - OPTIONAL
      case 2: // Pricing step - OPTIONAL
        return true; // Can skip
      default:
        return false;
    }
  }

  Future<void> _handleNext(
    BuildContext context,
    WidgetRef ref,
    OnboardingState state,
    bool isLastStep,
  ) async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    if (isLastStep) {
      // Complete wizard
      await _completeWizard(context, ref);
    } else {
      // Move to next step
      await notifier.nextStep();
    }
  }

  Future<void> _completeWizard(BuildContext context, WidgetRef ref) async {
    try {
      final notifier = ref.read(onboardingNotifierProvider.notifier);
      final state = ref.read(onboardingNotifierProvider);

      // Show loading
      if (context.mounted) {
        unawaited(showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        ));
      }

      // Create property (Step 1)
      final propertyId = await notifier.createProperty();

      // Create unit if provided (Step 2)
      if (state.unitData != null) {
        final ownerId = ref.read(enhancedAuthProvider).firebaseUser?.uid ?? '';
        await notifier.createUnit(propertyId, ownerId);
      }

      // Complete onboarding
      await notifier.complete();

      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Redirect to success screen
      if (context.mounted) {
        context.go(OwnerRoutes.onboardingSuccess);
      }
    } catch (e) {
      // Close loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error
      if (context.mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška prilikom završavanja početnog podešavanja',
        );
      }
    }
  }

  Future<void> _showSkipDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preskoči vodič?'),
        content: const Text(
          'Ako preskočite vodič, nećete završiti početno podešavanje. '
          'Morat ćete ručno dodati objekte i jedinice kasnije.\n\n'
          'Želite li nastaviti?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Preskoči'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(onboardingNotifierProvider.notifier).skip();
      if (context.mounted) {
        context.go(OwnerRoutes.calendarTimeline);
      }
    }
  }
}

// Step Indicator Widget
class _StepIndicator extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepIndicator({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.success
                : isActive
                    ? AppColors.authPrimary
                    : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.authPrimary : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
