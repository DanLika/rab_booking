import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Centralized page transition system for consistent navigation animations.
///
/// Usage in router:
/// ```dart
/// GoRoute(
///   path: '/overview',
///   pageBuilder: (context, state) => PageTransitions.fade(
///     key: state.pageKey,
///     child: const OverviewScreen(),
///   ),
/// ),
/// ```
///
/// Transition Categories:
/// - **Fade**: Main drawer pages, auth flow (sibling pages)
/// - **Slide Right**: Sub-pages, detail screens (hierarchy depth)
/// - **Slide Up**: Forms, wizards, modals (temporary actions)
/// - **None**: Instant swap (special cases)
class PageTransitions {
  PageTransitions._();

  // ============================================================
  // DURATION CONSTANTS
  // ============================================================

  /// Fast transition for main navigation (drawer pages)
  static const Duration durationFast = Duration(milliseconds: 200);

  /// Standard transition for most navigations
  static const Duration durationStandard = Duration(milliseconds: 280);

  /// Slow transition for forms/modals
  static const Duration durationSlow = Duration(milliseconds: 350);

  // ============================================================
  // CURVE CONSTANTS
  // ============================================================

  /// Standard easing curve for forward navigation
  static const Curve curveForward = Curves.easeOutCubic;

  /// Standard easing curve for reverse navigation
  static const Curve curveReverse = Curves.easeInCubic;

  /// Decelerate curve for slide-up modals
  static const Curve curveModal = Curves.easeOutQuart;

  // ============================================================
  // FADE TRANSITION
  // Best for: Drawer navigation, auth flow, sibling pages
  // ============================================================

  /// Creates a fade transition page.
  ///
  /// Use for:
  /// - Main drawer pages (Overview, Calendar, Bookings, etc.)
  /// - Auth flow (Login, Register, Forgot Password)
  /// - Tab switching
  static CustomTransitionPage<T> fade<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Duration duration = durationFast,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curveForward,
            reverseCurve: curveReverse,
          ),
          child: child,
        );
      },
    );
  }

  // ============================================================
  // SLIDE RIGHT TRANSITION
  // Best for: Sub-pages, detail screens, "going deeper"
  // ============================================================

  /// Creates a slide-from-right transition page.
  ///
  /// Use for:
  /// - Profile → Edit Profile, Change Password
  /// - Unit Hub → Unit Edit, Unit Pricing
  /// - Any "push" navigation that goes deeper in hierarchy
  static CustomTransitionPage<T> slideRight<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Duration duration = durationStandard,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide in from right
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: curveForward,
                reverseCurve: curveReverse,
              ),
            );

        // Fade in for smoothness
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.3, end: 1.0).animate(fadeAnimation),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // SLIDE UP TRANSITION
  // Best for: Forms, wizards, modal-like screens
  // ============================================================

  /// Creates a slide-from-bottom transition page.
  ///
  /// Use for:
  /// - New Property form
  /// - Unit Wizard
  /// - Any form/creation flow
  static CustomTransitionPage<T> slideUp<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Duration duration = durationSlow,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide in from bottom (only 30% of screen height for subtlety)
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0.0, 0.15),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: curveModal,
                reverseCurve: curveReverse,
              ),
            );

        // Fade in
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: curveForward,
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  // ============================================================
  // SCALE FADE TRANSITION
  // Best for: Dialogs, overlays, emphasis
  // ============================================================

  /// Creates a scale + fade transition page.
  ///
  /// Use for:
  /// - Important screens that need emphasis
  /// - Notification center
  /// - Settings sections
  static CustomTransitionPage<T> scaleFade<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Duration duration = durationStandard,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Scale from 95% to 100%
        final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: curveForward,
            reverseCurve: curveReverse,
          ),
        );

        // Fade in
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: curveForward,
        );

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  // ============================================================
  // NO TRANSITION (INSTANT)
  // Best for: Special cases, redirects
  // ============================================================

  /// Creates an instant page swap with no animation.
  ///
  /// Use for:
  /// - Redirect destinations
  /// - Error pages
  /// - Loading states
  static CustomTransitionPage<T> none<T>({
    required Widget child,
    LocalKey? key,
    String? name,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    );
  }

  // ============================================================
  // SHARED AXIS HORIZONTAL (Material 3 style)
  // Best for: Lateral navigation between related screens
  // ============================================================

  /// Creates a shared axis horizontal transition (Material 3 style).
  ///
  /// Use for:
  /// - Tab navigation
  /// - Horizontal paging
  static CustomTransitionPage<T> sharedAxisHorizontal<T>({
    required Widget child,
    LocalKey? key,
    String? name,
    Duration duration = durationStandard,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Incoming page slides and fades in
        final slideIn = Tween<Offset>(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: curveForward));

        final fadeIn = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
        );

        // Outgoing page slides and fades out
        final slideOut =
            Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(
              CurvedAnimation(parent: secondaryAnimation, curve: curveForward),
            );

        final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: const Interval(0.0, 0.75, curve: Curves.easeIn),
          ),
        );

        return SlideTransition(
          position: slideOut,
          child: FadeTransition(
            opacity: fadeOut,
            child: SlideTransition(
              position: slideIn,
              child: FadeTransition(opacity: fadeIn, child: child),
            ),
          ),
        );
      },
    );
  }
}
