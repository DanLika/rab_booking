import 'package:flutter/material.dart';
import '../../../../../features/auth/presentation/widgets/auth_logo_icon.dart';
import '../../theme/minimalist_colors.dart';

/// Custom BookBed loader with logo, progress bar, and percentage
///
/// Displays animated BookBed logo with progress indication.
/// No text labels - just visual elements.
///
/// Usage:
/// ```dart
/// BookBedLoader(
///   isDarkMode: false,
///   progress: 0.45, // 45%
/// )
/// ```
class BookBedLoader extends StatelessWidget {
  /// Whether dark mode is active
  final bool isDarkMode;

  /// Loading progress (0.0 to 1.0)
  /// If null, shows indeterminate progress
  final double? progress;

  /// Logo size
  final double logoSize;

  const BookBedLoader({super.key, required this.isDarkMode, this.progress, this.logoSize = 80});

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated BookBed logo (uses theme colors by default)
        AuthLogoIcon(size: logoSize),

        const SizedBox(height: 32),

        // Progress bar
        SizedBox(
          width: 200,
          child: Column(
            children: [
              // Progress bar track
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    children: [
                      // Background track
                      Container(color: colors.primary.withValues(alpha: 0.2)),
                      // Progress fill
                      if (progress != null)
                        FractionallySizedBox(
                          widthFactor: progress!.clamp(0.0, 1.0),
                          alignment: Alignment.centerLeft,
                          child: Container(color: colors.primary),
                        )
                      else
                        // Indeterminate progress
                        _IndeterminateProgress(color: colors.primary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Percentage text
              if (progress != null)
                Text(
                  '${(progress! * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                    fontFamily: 'Manrope',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Indeterminate progress animation
class _IndeterminateProgress extends StatefulWidget {
  final Color color;

  const _IndeterminateProgress({required this.color});

  @override
  State<_IndeterminateProgress> createState() => _IndeterminateProgressState();
}

class _IndeterminateProgressState extends State<_IndeterminateProgress> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FractionallySizedBox(
          widthFactor: 0.3,
          alignment: Alignment(_animation.value, 0),
          child: Container(color: widget.color),
        );
      },
    );
  }
}
