import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PremiumLoadingIndicator extends StatelessWidget {
  const PremiumLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .scale(
            duration: 600.ms,
            delay: (index * 200).ms,
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.2, 1.2),
            curve: Curves.easeInOut,
          )
          .fade(
            duration: 600.ms,
            delay: (index * 200).ms,
            begin: 0.5,
            end: 1.0,
          )
          .then()
          .scale(
             duration: 600.ms,
             begin: const Offset(1.2, 1.2),
             end: const Offset(0.5, 0.5),
             curve: Curves.easeInOut,
          )
          .fade(
            duration: 600.ms,
            begin: 1.0,
            end: 0.5,
          );
        }),
      ),
    );
  }
}
