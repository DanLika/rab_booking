import 'package:flutter/material.dart';

class BookingStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const BookingStepIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(steps.length, (index) {
          final bool isActive = index == currentStep;
          final bool isCompleted = index < currentStep;

          return Column(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isCompleted || isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 12,
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
