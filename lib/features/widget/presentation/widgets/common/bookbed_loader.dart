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
  // Layout constants
  static const double _defaultLogoSize = 80;
  static const double _logoToBarSpacing = 32;
  static const double _progressBarWidth = 200;
  static const double _progressBarHeight = 4;
  static const double _progressBarRadius = 2;
  static const double _barToTextSpacing = 12;
  static const double _percentageFontSize = 14;
  static const double _backgroundOpacity = 0.2;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Loading progress (0.0 to 1.0)
  /// If null, shows indeterminate progress
  final double? progress;

  /// Logo size
  final double logoSize;

  const BookBedLoader({super.key, required this.isDarkMode, this.progress, this.logoSize = _defaultLogoSize});

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthLogoIcon(size: logoSize),
        const SizedBox(height: _logoToBarSpacing),
        SizedBox(
          width: _progressBarWidth,
          child: Column(
            children: [
              _buildProgressBar(colors),
              const SizedBox(height: _barToTextSpacing),
              if (progress != null) _buildPercentageText(colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(MinimalistColorSchemeAdapter colors) {
    // Minimalistic: Use black in light mode, white in dark mode
    final progressColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode 
        ? Colors.white.withValues(alpha: _backgroundOpacity)
        : Colors.black.withValues(alpha: _backgroundOpacity);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(_progressBarRadius),
      child: SizedBox(
        height: _progressBarHeight,
        child: Stack(
          children: [
            Container(color: backgroundColor),
            if (progress != null)
              FractionallySizedBox(
                widthFactor: progress!.clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(color: progressColor),
              )
            else
              _IndeterminateProgress(color: progressColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageText(MinimalistColorSchemeAdapter colors) {
    // Minimalistic: Pure black in light mode, pure white in dark mode
    final textColor = isDarkMode ? Colors.white : Colors.black;
    
    return Text(
      '${(progress! * 100).toInt()}%',
      style: TextStyle(
        fontSize: _percentageFontSize,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: 'Manrope',
      ),
    );
  }
}

/// Indeterminate progress animation
class _IndeterminateProgress extends StatefulWidget {
  static const Duration _animationDuration = Duration(milliseconds: 1500);
  static const double _indicatorWidth = 0.3;

  final Color color;

  const _IndeterminateProgress({required this.color});

  @override
  State<_IndeterminateProgress> createState() => _IndeterminateProgressState();
}

class _IndeterminateProgressState extends State<_IndeterminateProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _IndeterminateProgress._animationDuration, vsync: this)..repeat();

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
          widthFactor: _IndeterminateProgress._indicatorWidth,
          alignment: Alignment(_animation.value, 0),
          child: Container(color: widget.color),
        );
      },
    );
  }
}
