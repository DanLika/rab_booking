import 'package:flutter/material.dart';

/// Premium gradient button for auth screens with animations
class GradientAuthButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const GradientAuthButton({super.key, required this.text, this.onPressed, this.isLoading = false, this.icon});

  @override
  State<GradientAuthButton> createState() => _GradientAuthButtonState();
}

class _GradientAuthButtonState extends State<GradientAuthButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.75)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withAlpha((0.25 * 255).toInt()),
                blurRadius: _isHovered ? 16 : 10,
                offset: Offset(0, _isHovered ? 6 : 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Shimmer effect when loading
                  if (widget.isLoading)
                    AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: [
                                _shimmerAnimation.value - 0.3,
                                _shimmerAnimation.value,
                                _shimmerAnimation.value + 0.3,
                              ],
                              colors: [
                                Colors.transparent,
                                theme.colorScheme.onPrimary.withAlpha((0.3 * 255).toInt()),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Button content
                  Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
