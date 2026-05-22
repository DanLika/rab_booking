import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Small "Powered by BookBed" link with a hover-color effect.
///
/// Tapping opens `https://bookbed.io` in an external browser. The URL is
/// intentionally hardcoded — see `.claude/rules/widget.md` § "Hardcoded
/// `bookbed.io` exceptions" for the rationale (embed-snippet copy must
/// always resolve to prod).
class PoweredByBadge extends StatefulWidget {
  final String text;
  final Color color;

  const PoweredByBadge({super.key, required this.text, required this.color});

  @override
  State<PoweredByBadge> createState() => _PoweredByBadgeState();
}

class _PoweredByBadgeState extends State<PoweredByBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _isHovered
        ? widget.color
        : widget.color.withValues(alpha: 0.85);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse('https://bookbed.io'),
          mode: LaunchMode.externalApplication,
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: 11,
            color: effectiveColor,
            decoration: TextDecoration.underline,
            decorationColor: effectiveColor,
          ),
        ),
      ),
    );
  }
}
