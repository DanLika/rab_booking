import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../core/theme/theme_extensions.dart';

/// Hero section with enhanced multi-layer parallax effect
class HeroSectionWidget extends StatelessWidget {
  const HeroSectionWidget({
    required this.scrollOffset,
    this.opacity = 1.0,
    super.key,
  });

  final double scrollOffset;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final heroHeight = isMobile ? 600.0 : 800.0;

    // Multi-layer parallax offsets (different speeds for depth effect)
    final backgroundOffset = scrollOffset * 0.3; // Slowest (furthest back)
    final overlayOffset = scrollOffset * 0.5; // Medium speed
    final contentOffset = scrollOffset * 0.7; // Fastest (closest to viewer)

    // Scale effect based on scroll
    final scaleEffect = 1.0 + (scrollOffset / heroHeight * 0.1);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with parallax (slowest layer)
          Transform.translate(
            offset: Offset(0, backgroundOffset),
            child: Transform.scale(
              scale: scaleEffect,
              child: Image.network(
                'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=2340',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: context.surfaceColor,
                    child: Center(
                      child: Icon(Icons.villa, size: 100, color: context.textColor.withValues(alpha: 0.3)),
                    ),
                  );
                },
              ),
            ),
          ),

          // Animated gradient overlay (medium speed)
          Transform.translate(
            offset: Offset(0, overlayOffset),
            child: Opacity(
              opacity: opacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Content with parallax (fastest layer)
          Transform.translate(
            offset: Offset(0, contentOffset),
            child: Opacity(
              opacity: opacity,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 48,
                    vertical: 48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),

                      // Main heading with enhanced animation
                      AnimatedOpacity(
                        opacity: opacity,
                        duration: const Duration(milliseconds: 300),
                        child: Transform.scale(
                          scale: opacity,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pronađite savršen\nsmještaj na Rabu',
                            style: TextStyle(
                              fontSize: isMobile ? 36 : 64,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 4),
                                ),
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tagline with delayed animation
                      AnimatedOpacity(
                        opacity: (opacity * 1.2).clamp(0.0, 1.0),
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          'Vile, apartmani i kuće za odmor u srcu Jadrana',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 20,
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w400,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Backdrop blur widget (for search bar)
class BlurredBackdrop extends StatelessWidget {
  const BlurredBackdrop({
    required this.child,
    this.sigmaX = 10,
    this.sigmaY = 10,
    super.key,
  });

  final Widget child;
  final double sigmaX;
  final double sigmaY;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: child,
      ),
    );
  }
}
