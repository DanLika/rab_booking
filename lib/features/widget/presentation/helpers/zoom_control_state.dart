import 'package:flutter/widgets.dart';

/// Owns the `TransformationController`, sizing key and current scale value
/// for the booking-widget calendar zoom feature.
///
/// Used by:
/// * `InteractiveViewer` — bind [controller] and attach
///   [interactiveViewerKey] to read the viewport size for centered zoom.
/// * `ZoomControlButtons` — read [scale], drive changes via
///   [applyCenteredZoom].
/// * Scroll-wheel `Listener` — call [panByScroll] when zoomed.
///
/// Mutations do not call setState by themselves. Callers wrap their
/// changes in `setState((){})` so the surrounding widget tree (including
/// `panEnabled` evaluation) rebuilds.
class ZoomControlState {
  ZoomControlState();

  final TransformationController controller = TransformationController();
  final GlobalKey interactiveViewerKey = GlobalKey();

  double scale = 1.0;

  bool get isZoomed => scale > 1.0;

  /// Apply [newScale] centered on the InteractiveViewer's viewport.
  ///
  /// When the viewport's render box is available, computes a translation
  /// that keeps the view centered on the same point as scale changes:
  /// `translate = (1 - scale) * size / 2`. If the render box isn't laid
  /// out yet (first frame), falls back to origin-anchored zoom.
  void applyCenteredZoom(double newScale) {
    scale = newScale;
    final renderBox =
        interactiveViewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final dx = (1 - newScale) * size.width / 2;
      final dy = (1 - newScale) * size.height / 2;
      final matrix = Matrix4.identity()
        ..setEntry(0, 0, newScale)
        ..setEntry(1, 1, newScale)
        ..setEntry(0, 3, dx)
        ..setEntry(1, 3, dy);
      controller.value = matrix;
    } else {
      controller.value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
    }
  }

  /// Apply a scroll-wheel pan when zoomed. No-op when [isZoomed] is false
  /// (parent should fall through to native scroll).
  void panByScroll(Offset scrollDelta) {
    if (!isZoomed) return;
    final matrix = controller.value.clone();
    matrix.setEntry(0, 3, matrix.entry(0, 3) - scrollDelta.dx);
    matrix.setEntry(1, 3, matrix.entry(1, 3) - scrollDelta.dy);
    controller.value = matrix;
  }

  void dispose() {
    controller.dispose();
  }
}
