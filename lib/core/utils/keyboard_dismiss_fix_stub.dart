// Stub implementation for non-web platforms
//
// These functions are no-ops on native platforms since the keyboard
// dismiss bug only affects Flutter Web on Android Chrome.

/// Get visual viewport height - returns null on non-web platforms
double? getVisualViewportHeightImpl() => null;

/// Listen to viewport resize - returns no-op cleanup on non-web platforms
void Function() listenToVisualViewportImpl(void Function() onResize) => () {};

/// Force window resize - no-op on non-web platforms
void forceWindowResizeImpl() {}

/// Force canvas invalidate - no-op on non-web platforms
void forceCanvasInvalidateImpl() {}

/// Listen to window resize - returns no-op cleanup on non-web platforms
void Function() listenToWindowResizeImpl(void Function() onResize) => () {};
