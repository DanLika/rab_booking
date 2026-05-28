import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// Loading-state primitives.
///
/// Use these instead of [CircularProgressIndicator] for predictable layout
/// (content has a shape and reserved space before data arrives — no jump-cut
/// when it lands).
///
/// Reduced-motion: shimmer collapses to a static grey block.
enum BBSkeletonVariant { line, card, listRow, statTile }

class BBSkeleton extends StatefulWidget {
  const BBSkeleton({
    super.key,
    this.variant = BBSkeletonVariant.line,
    this.width,
    this.height,
  });

  final BBSkeletonVariant variant;
  final double? width;
  final double? height;

  @override
  State<BBSkeleton> createState() => _BBSkeletonState();
}

class _BBSkeletonState extends State<BBSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box({double? w, double? h, double radius = BBRadius.sm}) {
    return _ShimmerBox(controller: _ctrl, width: w, height: h, radius: radius);
  }

  @override
  Widget build(BuildContext context) {
    if (BBMotion.reduced(context)) {
      // Static grey: no animation, same shape.
      return _staticVariant(context);
    }
    switch (widget.variant) {
      case BBSkeletonVariant.line:
        return _box(w: widget.width, h: widget.height ?? 14);
      case BBSkeletonVariant.card:
        return _box(
          w: widget.width,
          h: widget.height ?? 160,
          radius: BBRadius.md,
        );
      case BBSkeletonVariant.listRow:
        return Row(
          children: <Widget>[
            _box(w: 40, h: 40, radius: BBRadius.full),
            const SizedBox(width: BBSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _box(w: 180, h: 14),
                  const SizedBox(height: BBSpace.xs),
                  _box(w: 120, h: 12),
                ],
              ),
            ),
          ],
        );
      case BBSkeletonVariant.statTile:
        return _box(
          w: widget.width ?? 140,
          h: widget.height ?? 80,
          radius: BBRadius.md,
        );
    }
  }

  Widget _staticVariant(BuildContext context) {
    final Color c = BBColor.of(context).surfaceVariant;
    Widget plain(double? w, double h, double r) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.all(Radius.circular(r)),
      ),
    );
    switch (widget.variant) {
      case BBSkeletonVariant.line:
        return plain(widget.width, widget.height ?? 14, BBRadius.sm);
      case BBSkeletonVariant.card:
        return plain(widget.width, widget.height ?? 160, BBRadius.md);
      case BBSkeletonVariant.listRow:
        return Row(
          children: <Widget>[
            plain(40, 40, BBRadius.full),
            const SizedBox(width: BBSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  plain(180, 14, BBRadius.sm),
                  const SizedBox(height: BBSpace.xs),
                  plain(120, 12, BBRadius.sm),
                ],
              ),
            ),
          ],
        );
      case BBSkeletonVariant.statTile:
        return plain(widget.width ?? 140, widget.height ?? 80, BBRadius.md);
    }
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.controller,
    required this.radius,
    this.width,
    this.height,
  });

  final AnimationController controller;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    final Color base = c.surfaceVariant;
    final Color highlight = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.4),
      base,
    );
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext ctx, Widget? child) {
        final double t = controller.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * t, 0),
              end: Alignment(0.0 + 2.0 * t, 0),
              colors: <Color>[base, highlight, base],
              stops: const <double>[0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
