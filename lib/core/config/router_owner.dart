import 'dart:async';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../utils/page_transitions.dart';
import '../../features/auth/presentation/screens/enhanced_login_screen.dart';
import '../services/logging_service.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/enhanced_register_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/privacy_policy_screen.dart';
import '../../features/auth/presentation/screens/terms_conditions_screen.dart';
import '../../features/owner_dashboard/presentation/providers/owner_properties_provider.dart';
import '../../features/owner_dashboard/presentation/screens/analytics_screen.dart';
import '../../features/owner_dashboard/presentation/screens/overview_screen.dart';
import '../../features/owner_dashboard/presentation/screens/owner_timeline_calendar_screen.dart';
import '../../features/owner_dashboard/presentation/screens/owner_bookings_screen.dart';
import '../../features/owner_dashboard/presentation/screens/property_form_screen.dart';
import '../../features/owner_dashboard/presentation/screens/unit_form_screen.dart';
import '../../features/owner_dashboard/presentation/screens/unit_pricing_screen.dart';
import '../../features/owner_dashboard/presentation/screens/widget_settings_screen.dart';
import '../../features/owner_dashboard/presentation/screens/unified_unit_hub_screen.dart';
import '../../features/owner_dashboard/presentation/screens/unit_wizard/unit_wizard_screen.dart';
import '../../features/owner_dashboard/presentation/screens/notifications_screen.dart';
import '../../features/owner_dashboard/presentation/screens/profile_screen.dart';
import '../../features/owner_dashboard/presentation/screens/edit_profile_screen.dart';
import '../../features/owner_dashboard/presentation/screens/bank_account_screen.dart';
import '../../features/owner_dashboard/presentation/screens/change_password_screen.dart';
import '../../features/owner_dashboard/presentation/screens/notification_settings_screen.dart';
import '../../features/owner_dashboard/presentation/screens/about_screen.dart';
import '../../features/owner_dashboard/presentation/screens/stripe_connect_setup_screen.dart';
import '../../features/owner_dashboard/presentation/screens/ical/ical_sync_settings_screen.dart';
import '../../features/owner_dashboard/presentation/screens/ical/ical_export_list_screen.dart';
import '../../features/owner_dashboard/presentation/screens/guides/embed_widget_guide_screen.dart';
import '../../features/owner_dashboard/presentation/screens/guides/faq_screen.dart';
import '../../features/auth/presentation/screens/cookies_policy_screen.dart';
import '../../features/widget/presentation/screens/booking_widget_screen.dart';
import '../../features/widget/presentation/screens/booking_view_screen.dart';
import '../../features/widget/presentation/screens/booking_details_screen.dart';
import '../../shared/presentation/screens/not_found_screen.dart';
import '../../shared/providers/repository_providers.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../providers/enhanced_auth_provider.dart';

/// Helper class to convert Stream to Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((dynamic _) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Routes for Owner App + Public Widget Embed
class OwnerRoutes {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsConditions = '/terms-conditions';
  static const String cookiesPolicy = '/cookies-policy';

  // Owner dashboard routes
  static const String overview = '/owner/overview';
  static const String properties = '/owner/properties';
  static const String calendarTimeline = '/owner/calendar/timeline';
  static const String bookings = '/owner/bookings';
  static const String analytics = '/owner/analytics';
  static const String propertyNew = '/owner/properties/new';
  static const String propertyEdit = '/owner/properties/:id/edit';
  static const String units = '/owner/units';
  static const String unitNew = '/owner/units/new';
  static const String unitEdit = '/owner/units/:id/edit';
  static const String unitPricing = '/owner/units/:id/pricing';
  static const String unitWidgetSettings = '/owner/units/:id/widget-settings';
  static const String unitHub = '/owner/unit-hub';
  static const String unitWizard = '/owner/units/wizard';
  static const String unitWizardEdit = '/owner/units/wizard/:id';
  static const String notifications = '/owner/notifications';
  static const String profile = '/owner/profile';
  static const String profileEdit = '/owner/profile/edit';
  static const String profileChangePassword = '/owner/profile/change-password';
  static const String profileNotifications = '/owner/profile/notifications';
  static const String about = '/owner/about';
  static const String widgetSettings = '/owner/widget-settings';
  // Integrations
  static const String stripeIntegration = '/owner/integrations/stripe';
  static const String bankAccount = '/owner/integrations/payments/bank-account';
  // iCal routes (NEW structure - organized under /ical/)
  static const String icalImport = '/owner/integrations/ical/import'; // iCal Sync Settings (Import)
  static const String icalExportList =
      '/owner/integrations/ical/export-list'; // iCal Export List (for owners to export all bookings)
  static const String icalGuide = '/owner/guides/ical'; // iCal Guide
  // DEPRECATED routes - will be removed in future versions
  @Deprecated('Use icalImport instead')
  static const String icalIntegration = '/owner/integrations/ical';
  @Deprecated('Use icalGuide instead')
  static const String guideIcal = '/owner/guides/ical'; // Same path as icalGuide
  // Guides
  static const String guideEmbedWidget = '/owner/guides/embed-widget';
  static const String guideFaq = '/owner/guides/faq';
  static const String notFound = '/404';
}

/// Owner app GoRouter
final ownerRouterProvider = Provider<GoRouter>((ref) {
  // Watch enhancedAuthProvider so router rebuilds when auth state changes
  final authState = ref.watch(enhancedAuthProvider);

  return GoRouter(
    // No initialLocation - let GoRouter read from URL (important for /calendar widget)
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref.watch(firebaseAuthProvider).authStateChanges()),
    redirect: (context, state) {
      // Use the watched authState from above
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isLoggingIn =
          state.matchedLocation == OwnerRoutes.login ||
          state.matchedLocation == OwnerRoutes.register ||
          state.matchedLocation == OwnerRoutes.forgotPassword;

      // Debug logging (only in debug mode)
      if (kDebugMode) {
        LoggingService.log('redirect called:', tag: 'ROUTER');
        LoggingService.log('  - matchedLocation: ${state.matchedLocation}', tag: 'ROUTER');
        LoggingService.log('  - isAuthenticated: $isAuthenticated', tag: 'ROUTER');
        LoggingService.log('  - isLoading: $isLoading', tag: 'ROUTER');
        LoggingService.log('  - firebaseUser: ${authState.firebaseUser?.uid}', tag: 'ROUTER');
        LoggingService.log('  - userModel: ${authState.userModel?.id}', tag: 'ROUTER');
      }

      // Allow public access to embed, booking, calendar, and view routes (no auth required)
      // Also allow root path OR /login with widget query params (property, unit, confirmation)
      // This handles Stripe return URLs which may have #/login hash but widget params in query string
      //
      // IMPORTANT: With hash-based routing, query params BEFORE the # are NOT in state.uri.queryParameters
      // URL: http://localhost:8181/?property=xxx#/login
      //      ^^^^^^^^^^^^^^^^^^^^^^^^ Uri.base  ^^^^^^ state.uri (GoRouter)
      // So we must check Uri.base for widget params from Stripe return URLs
      final browserUri = Uri.base;
      final hasWidgetParams =
          browserUri.queryParameters.containsKey('property') ||
          browserUri.queryParameters.containsKey('unit') ||
          browserUri.queryParameters.containsKey('confirmation') ||
          state.uri.queryParameters.containsKey('property') ||
          state.uri.queryParameters.containsKey('unit') ||
          state.uri.queryParameters.containsKey('confirmation');
      final isPublicRoute =
          state.matchedLocation.startsWith('/embed/') ||
          state.matchedLocation.startsWith('/booking') ||
          state.matchedLocation == '/calendar' ||
          state.matchedLocation.startsWith('/view') ||
          (state.matchedLocation == '/' && hasWidgetParams) ||
          (state.matchedLocation == '/login' && hasWidgetParams);
      if (isPublicRoute) {
        if (kDebugMode) {
          LoggingService.log(
            '  → Allowing public route (hasWidgetParams: $hasWidgetParams, matchedLocation: ${state.matchedLocation})',
            tag: 'ROUTER',
          );
        }
        return null; // Allow access
      }

      // Redirect root to appropriate page (ALWAYS, even during loading)
      // This ensures app.bookbed.io always redirects correctly
      if (state.matchedLocation == '/') {
        // Authenticated → overview (even if still loading, we know user is authenticated)
        if (isAuthenticated) {
          if (kDebugMode) {
            LoggingService.log('  → Redirecting / to overview (authenticated)', tag: 'ROUTER');
          }
          return OwnerRoutes.overview;
        }

        // Not authenticated → login (ALWAYS redirect, even during initial loading)
        // This fixes the issue where app.bookbed.io shows "page unavailable"
        if (kDebugMode) {
          LoggingService.log('  → Redirecting / to login (not authenticated, isLoading=$isLoading)', tag: 'ROUTER');
        }
        return OwnerRoutes.login;
      }

      // FIX Q4: Don't redirect while auth operation is in progress
      // (prevents Register → Login flash during async registration)
      // BUT: Only apply this to non-root routes (root is handled above)
      if (isLoading) {
        if (kDebugMode) {
          LoggingService.log(
            '  → Waiting for auth operation to complete (isLoading=true, route=${state.matchedLocation})',
            tag: 'ROUTER',
          );
        }
        return null; // Stay on current route
      }

      // Redirect to login if not authenticated and trying to access protected routes
      if (!isAuthenticated && !isLoggingIn) {
        if (kDebugMode) {
          LoggingService.log('  → Redirecting to login (not authenticated)', tag: 'ROUTER');
        }
        return OwnerRoutes.login;
      }

      // Redirect to overview if authenticated and trying to access login
      if (isAuthenticated && isLoggingIn) {
        if (kDebugMode) {
          LoggingService.log('  → Redirecting to overview (authenticated, was on login)', tag: 'ROUTER');
        }
        return OwnerRoutes.overview;
      }

      if (kDebugMode) {
        LoggingService.log('  → No redirect needed', tag: 'ROUTER');
      }
      return null;
    },
    routes: [
      // ROOT ROUTE - Shows widget if has params, otherwise loader for redirect
      GoRoute(
        path: '/',
        builder: (context, state) {
          // Check if this is a widget URL (has property/unit/confirmation params)
          // IMPORTANT: With hash routing, query params are BEFORE the #, so use Uri.base
          final browserUri = Uri.base;
          final hasWidgetParams =
              browserUri.queryParameters.containsKey('property') ||
              browserUri.queryParameters.containsKey('unit') ||
              browserUri.queryParameters.containsKey('confirmation') ||
              state.uri.queryParameters.containsKey('property') ||
              state.uri.queryParameters.containsKey('unit') ||
              state.uri.queryParameters.containsKey('confirmation');

          if (hasWidgetParams) {
            // Show booking widget for embed URLs and Stripe return URLs
            return const BookingWidgetScreen();
          }

          // Show loading overlay while redirect determines where to go
          // (prevents 404 flash during Login → Dashboard transition)
          return const Scaffold(body: LoadingOverlay(message: 'Loading...'));
        },
      ),

      // PUBLIC ROUTES (No authentication required)
      // Public booking widget (for iframe embedding)
      // URL: /?property=PROPERTY_ID&unit=UNIT_ID#/calendar
      GoRoute(path: '/calendar', builder: (context, state) => const BookingWidgetScreen()),

      // Public booking lookup (from email link)
      // URL: /view?ref=BOOKING_REF&email=EMAIL&token=TOKEN
      GoRoute(
        path: '/view',
        builder: (context, state) {
          final ref = state.uri.queryParameters['ref'];
          final email = state.uri.queryParameters['email'];
          final token = state.uri.queryParameters['token'];
          return BookingViewScreen(bookingRef: ref, email: email, token: token);
        },
        routes: [
          // Booking details sub-route
          GoRoute(
            path: 'details',
            builder: (context, state) {
              final extra = state.extra;
              if (extra == null) {
                return const NotFoundScreen();
              }

              // Support both old and new format for backwards compatibility
              if (extra is Map<String, dynamic>) {
                // New format: {booking: BookingDetailsModel, widgetSettings: WidgetSettings?}
                final booking = extra['booking'];
                final widgetSettings = extra['widgetSettings'];
                if (booking == null) {
                  return const NotFoundScreen();
                }
                return BookingDetailsScreen(booking: booking as dynamic, widgetSettings: widgetSettings as dynamic);
              } else {
                // Old format: BookingDetailsModel directly
                return BookingDetailsScreen(booking: extra as dynamic);
              }
            },
          ),
        ],
      ),

      // Auth routes - Fade transition for smooth auth flow
      GoRoute(
        path: OwnerRoutes.login,
        pageBuilder: (context, state) {
          // Check if this is a Stripe return URL with widget params
          // URL: /?property=...&confirmation=...#/login
          // In this case, show the booking widget instead of login
          //
          // IMPORTANT: With hash routing, query params are BEFORE the #, so use Uri.base
          final browserUri = Uri.base;
          final hasWidgetParams =
              browserUri.queryParameters.containsKey('property') ||
              browserUri.queryParameters.containsKey('unit') ||
              browserUri.queryParameters.containsKey('confirmation') ||
              state.uri.queryParameters.containsKey('property') ||
              state.uri.queryParameters.containsKey('unit') ||
              state.uri.queryParameters.containsKey('confirmation');

          if (hasWidgetParams) {
            // Show booking widget for Stripe return URLs
            return PageTransitions.none(key: state.pageKey, child: const BookingWidgetScreen());
          }

          return PageTransitions.fade(key: state.pageKey, child: const EnhancedLoginScreen());
        },
      ),
      GoRoute(
        path: OwnerRoutes.register,
        pageBuilder: (context, state) =>
            PageTransitions.fade(key: state.pageKey, child: const EnhancedRegisterScreen()),
      ),
      GoRoute(
        path: OwnerRoutes.forgotPassword,
        pageBuilder: (context, state) => PageTransitions.fade(key: state.pageKey, child: const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: OwnerRoutes.emailVerification,
        pageBuilder: (context, state) =>
            PageTransitions.fade(key: state.pageKey, child: const EmailVerificationScreen()),
      ),
      GoRoute(
        path: OwnerRoutes.privacyPolicy,
        pageBuilder: (context, state) =>
            PageTransitions.slideRight(key: state.pageKey, child: const PrivacyPolicyScreen()),
      ),
      GoRoute(
        path: OwnerRoutes.termsConditions,
        pageBuilder: (context, state) =>
            PageTransitions.slideRight(key: state.pageKey, child: const TermsConditionsScreen()),
      ),

      // Owner main screens - Fade transition for drawer navigation
      GoRoute(
        path: OwnerRoutes.overview,
        pageBuilder: (context, state) => PageTransitions.fade(key: state.pageKey, child: const OverviewScreen()),
      ),
      // Properties route redirects to unit-hub (property management is now in unit-hub)
      GoRoute(path: OwnerRoutes.properties, redirect: (context, state) => OwnerRoutes.unitHub),
      // Calendar route
      GoRoute(
        path: OwnerRoutes.calendarTimeline,
        pageBuilder: (context, state) =>
            PageTransitions.fade(key: state.pageKey, child: const OwnerTimelineCalendarScreen()),
      ),
      GoRoute(
        path: OwnerRoutes.bookings,
        pageBuilder: (context, state) {
          final bookingId = state.uri.queryParameters['bookingId'];
          return PageTransitions.fade(
            key: state.pageKey,
            child: OwnerBookingsScreen(initialBookingId: bookingId),
          );
        },
      ),
      GoRoute(
        path: OwnerRoutes.analytics,
        pageBuilder: (context, state) => PageTransitions.fade(key: state.pageKey, child: const AnalyticsScreen()),
      ),

      // Property management routes - SlideUp for new, SlideRight for edit
      GoRoute(
        path: OwnerRoutes.propertyNew,
        pageBuilder: (context, state) => PageTransitions.slideUp(key: state.pageKey, child: const PropertyFormScreen()),
      ),
      GoRoute(
        path: OwnerRoutes.propertyEdit,
        pageBuilder: (context, state) {
          final propertyId = state.pathParameters['id'] ?? '';
          return PageTransitions.slideRight(
            key: state.pageKey,
            child: PropertyEditLoader(propertyId: propertyId),
          );
        },
      ),

      // Unit management routes
      GoRoute(
        path: OwnerRoutes.units,
        pageBuilder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'];
          return PageTransitions.fade(
            key: state.pageKey,
            child: UnifiedUnitHubScreen(initialPropertyFilter: propertyId),
          );
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitNew,
        pageBuilder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'] ?? '';
          return PageTransitions.slideUp(
            key: state.pageKey,
            child: UnitFormScreen(propertyId: propertyId),
          );
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitEdit,
        pageBuilder: (context, state) {
          final unitId = state.pathParameters['id'] ?? '';
          return PageTransitions.slideRight(
            key: state.pageKey,
            child: UnitEditLoader(unitId: unitId),
          );
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitPricing,
        pageBuilder: (context, state) {
          final unitId = state.pathParameters['id'] ?? '';
          return PageTransitions.slideRight(
            key: state.pageKey,
            child: UnitPricingLoader(unitId: unitId),
          );
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitWidgetSettings,
        pageBuilder: (context, state) {
          final unitId = state.pathParameters['id'] ?? '';
          return PageTransitions.slideRight(
            key: state.pageKey,
            child: WidgetSettingsLoader(unitId: unitId),
          );
        },
      ),

      // Unified Unit Hub route - Fade for drawer navigation
      GoRoute(
        path: OwnerRoutes.unitHub,
        pageBuilder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'];
          return PageTransitions.fade(
            key: state.pageKey,
            child: UnifiedUnitHubScreen(initialPropertyFilter: propertyId),
          );
        },
      ),

      // Unit Wizard routes - SlideUp for modal-like wizard experience
      GoRoute(
        path: OwnerRoutes.unitWizard,
        pageBuilder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'];
          final duplicateFromId = state.uri.queryParameters['duplicateFromId'];
          return PageTransitions.slideUp(
            key: state.pageKey,
            child: UnitWizardScreen(propertyId: propertyId, duplicateFromId: duplicateFromId),
          );
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitWizardEdit,
        pageBuilder: (context, state) {
          final unitId = state.pathParameters['id'];
          return PageTransitions.slideUp(
            key: state.pageKey,
            child: UnitWizardScreen(unitId: unitId),
          );
        },
      ),

      // Notifications route - ScaleFade for emphasis
      GoRoute(
        path: OwnerRoutes.notifications,
        pageBuilder: (context, state) =>
            PageTransitions.scaleFade(key: state.pageKey, child: const NotificationsScreen()),
      ),

      // Profile routes - Fade for main, SlideRight for sub-pages
      GoRoute(
        path: OwnerRoutes.profile,
        pageBuilder: (context, state) => PageTransitions.fade(key: state.pageKey, child: const ProfileScreen()),
      ),
      GoRoute(
        path: OwnerRoutes.profileEdit,
        pageBuilder: (context, state) =>
            PageTransitions.slideRight(key: state.pageKey, child: const EditProfileScreen()),
      ),
      GoRoute(
        path: OwnerRoutes.profileChangePassword,
        pageBuilder: (context, state) =>
            PageTransitions.slideRight(key: state.pageKey, child: const ChangePasswordScreen()),
      ),
      GoRoute(
        path: OwnerRoutes.profileNotifications,
        pageBuilder: (context, state) =>
            PageTransitions.slideRight(key: state.pageKey, child: const NotificationSettingsScreen()),
      ),
      GoRoute(
        path: OwnerRoutes.about,
        pageBuilder: (context, state) => PageTransitions.slideRight(key: state.pageKey, child: const AboutScreen()),
      ),

      // Integrations routes - Fade for drawer navigation
      GoRoute(
        path: OwnerRoutes.stripeIntegration,
        pageBuilder: (context, state) =>
            PageTransitions.fade(key: state.pageKey, child: const StripeConnectSetupScreen()),
      ),
      // Bank Account (for bank transfer payments)
      GoRoute(
        path: OwnerRoutes.bankAccount,
        pageBuilder: (context, state) => PageTransitions.fade(key: state.pageKey, child: const BankAccountScreen()),
      ),
      // iCal Sync Settings (Import)
      GoRoute(
        path: OwnerRoutes.icalImport,
        pageBuilder: (context, state) =>
            PageTransitions.fade(key: state.pageKey, child: const IcalSyncSettingsScreen()),
      ),
      // iCal Export List (for owners to export all bookings)
      GoRoute(
        path: OwnerRoutes.icalExportList,
        pageBuilder: (context, state) => PageTransitions.fade(key: state.pageKey, child: const IcalExportListScreen()),
      ),

      // Guide routes - Fade for drawer navigation
      GoRoute(
        path: OwnerRoutes.guideEmbedWidget,
        pageBuilder: (context, state) =>
            PageTransitions.fade(key: state.pageKey, child: const EmbedWidgetGuideScreen()),
      ),
      GoRoute(
        path: OwnerRoutes.guideFaq,
        pageBuilder: (context, state) => PageTransitions.fade(key: state.pageKey, child: const FAQScreen()),
      ),

      // Cookies Policy route - SlideRight (linked from auth screens)
      GoRoute(
        path: OwnerRoutes.cookiesPolicy,
        pageBuilder: (context, state) =>
            PageTransitions.slideRight(key: state.pageKey, child: const CookiesPolicyScreen()),
      ),

      // 404 - No transition
      GoRoute(
        path: OwnerRoutes.notFound,
        pageBuilder: (context, state) => PageTransitions.none(key: state.pageKey, child: const NotFoundScreen()),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});

/// Property Edit Loader - Fetches property and loads edit form
class PropertyEditLoader extends ConsumerWidget {
  final String propertyId;

  const PropertyEditLoader({required this.propertyId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(propertyByIdProvider(propertyId));

    return propertyAsync.when(
      data: (property) {
        if (property == null) {
          return const NotFoundScreen();
        }
        return PropertyFormScreen(property: property);
      },
      loading: () => const Scaffold(body: LoadingOverlay(message: 'Loading property...')),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error loading property: $error'))),
    );
  }
}

/// Unit Edit Loader - Fetches unit and loads edit form
class UnitEditLoader extends ConsumerWidget {
  final String unitId;

  const UnitEditLoader({required this.unitId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(unitByIdAcrossPropertiesProvider(unitId));

    return unitAsync.when(
      data: (unit) {
        if (unit == null) {
          return const NotFoundScreen();
        }
        return UnitFormScreen(propertyId: unit.propertyId, unit: unit);
      },
      loading: () => const Scaffold(body: LoadingOverlay(message: 'Loading unit...')),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error loading unit: $error'))),
    );
  }
}

/// Unit Pricing Loader - Fetches unit and loads pricing screen
class UnitPricingLoader extends ConsumerWidget {
  final String unitId;

  const UnitPricingLoader({required this.unitId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(unitByIdAcrossPropertiesProvider(unitId));

    return unitAsync.when(
      data: (unit) {
        if (unit == null) {
          return const NotFoundScreen();
        }
        return UnitPricingScreen(unit: unit);
      },
      loading: () => const Scaffold(body: LoadingOverlay(message: 'Loading pricing...')),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error loading unit: $error'))),
    );
  }
}

/// Widget Settings Loader - Fetches unit and loads widget settings screen
class WidgetSettingsLoader extends ConsumerWidget {
  final String unitId;

  const WidgetSettingsLoader({required this.unitId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(unitByIdAcrossPropertiesProvider(unitId));

    return unitAsync.when(
      data: (unit) {
        if (unit == null) {
          return const NotFoundScreen();
        }
        return WidgetSettingsScreen(propertyId: unit.propertyId, unitId: unitId);
      },
      loading: () => const Scaffold(body: LoadingOverlay(message: 'Loading settings...')),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error loading unit: $error'))),
    );
  }
}
