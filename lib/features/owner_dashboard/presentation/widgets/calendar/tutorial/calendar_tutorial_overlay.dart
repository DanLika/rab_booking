import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../l10n/app_localizations.dart';

class CalendarTutorialOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const CalendarTutorialOverlay({
    super.key,
    required this.onDismiss,
  });

  @override
  State<CalendarTutorialOverlay> createState() => _CalendarTutorialOverlayState();
}

class _CalendarTutorialOverlayState extends State<CalendarTutorialOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _handAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _handAnimation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Semi-transparent background
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
        ),

        // Scroll Instruction (Centered)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _handAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_handAnimation.value, 0),
                      child: const Icon(
                        Icons.touch_app,
                        size: 64,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  // Use a similar generic message if specific ones aren't available yet
                  // Or use static text for now if strictly no ARB modification allowed
                  // Ideally: l10n.tutorialScrollHorizontal
                  "Scroll horizontal to view dates",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Interaction Instruction (Bottom Center)
        Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D3A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        // Ideally: l10n.tutorialLongPress
                        "Long press on grid to add booking",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(l10n.ok), // Use existing 'ok' string
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
