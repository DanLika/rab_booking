import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Hero section with parallax effect
class HeroSectionWidget extends StatelessWidget {
  const HeroSectionWidget({
    required this.scrollOffset,
    super.key,
  });

  final double scrollOffset;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final heroHeight = isMobile ? 600.0 : 800.0;

    // Parallax effect
    final parallaxOffset = scrollOffset * 0.5;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with parallax
          Transform.translate(
            offset: Offset(0, parallaxOffset),
            child: Image.network(
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=2340',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.blue[900],
                  child: const Center(
                    child: Icon(Icons.villa, size: 100, color: Colors.white54),
                  ),
                );
              },
            ),
          ),

          // Gradient overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 48,
                vertical: 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),

                  // Main heading
                  Text(
                    'Pronađite savršen\nsmještaj na Rabu',
                    style: TextStyle(
                      fontSize: isMobile ? 48 : 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tagline
                  Text(
                    'Vile, apartmani i kuće za odmor u srcu Jadrana',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 24,
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w400,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
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
