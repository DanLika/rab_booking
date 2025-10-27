import 'package:flutter/material.dart';
import '../theme/bedbooking_theme.dart';

/// Progress indicator showing booking steps (matching BedBooking screenshots)
class BookingProgressIndicator extends StatelessWidget {
  final int currentStep; // 1, 2, or 3

  const BookingProgressIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: [
          _buildStep(
            number: 1,
            label: 'THE OFFER',
            isActive: currentStep == 1,
            isCompleted: currentStep > 1,
          ),
          _buildArrow(),
          _buildStep(
            number: 2,
            label: 'DETAILS AND PAYMENT',
            isActive: currentStep == 2,
            isCompleted: currentStep > 2,
          ),
          _buildArrow(),
          _buildStep(
            number: 3,
            label: 'CONFIRMATION',
            isActive: currentStep == 3,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    final color = isActive || isCompleted
        ? BedBookingColors.primaryGreen
        : BedBookingColors.textGrey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Number circle
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted
                ? BedBookingColors.primaryGreen
                : Colors.white,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : color,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        // Label
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 40,
                color: BedBookingColors.primaryGreen,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Icon(
        Icons.chevron_right,
        size: 20,
        color: BedBookingColors.textGrey,
      ),
    );
  }
}
