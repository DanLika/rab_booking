import 'dart:async';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../features/owner_dashboard/presentation/screens/properties_screen.dart';
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
import '../../features/owner_dashboard/presentation/screens/onboarding_welcome_screen.dart';
import '../../features/owner_dashboard/presentation/screens/onboarding_wizard_screen.dart';
import '../../features/owner_dashboard/presentation/screens/onboarding_success_screen.dart';
import '../../features/owner_dashboard/presentation/screens/stripe_connect_setup_screen.dart';
import '../../features/owner_dashboard/presentation/screens/guides/stripe_guide_screen.dart';
import '../../features/owner_dashboard/presentation/screens/ical/guides/ical_guide_screen.dart';
import '../../features/owner_dashboard/presentation/screens/ical/ical_sync_settings_screen.dart';
import '../../features/owner_dashboard/presentation/screens/ical/ical_export_screen.dart';
import '../../features/owner_dashboard/presentation/screens/ical/ical_export_list_screen.dart';
import '../../features/owner_dashboard/presentation/screens/guides/embed_widget_guide_screen.dart';
import '../../features/owner_dashboard/presentation/screens/guides/faq_screen.dart';
import '../../features/auth/presentation/screens/cookies_policy_screen.dart';
import '../../features/widget/presentation/screens/booking_widget_screen.dart';
import '../../features/widget/presentation/screens/booking_view_screen.dart';
import '../../features/widget/presentation/screens/booking_details_screen.dart';
import '../../shared/presentation/screens/not_found_screen.dart';
import '../../shared/providers/repository_providers.dart';
import '../../shared/models/unit_model.dart';
import '../../shared/widgets/animations/skeleton_loader.dart';
import '../providers/enhanced_auth_provider.dart';

/// Helper class to convert Stream to Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
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
  // Onboarding routes
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingWizard = '/onboarding/wizard';
  static const String onboardingSuccess = '/onboarding/success';

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
  static const String icalImport =
      '/owner/integrations/ical/import'; // iCal Sync Settings (Import)
  static const String icalExportList =
      '/owner/integrations/ical/export-list'; // iCal Export List (select unit)
  static const String icalExport =
      '/owner/integrations/ical/export'; // iCal Export (Debug)
  static const String icalGuide = '/owner/guides/ical'; // iCal Guide
  // DEPRECATED routes - will be removed in future versions
  @Deprecated('Use icalImport instead')
  static const String icalIntegration = '/owner/integrations/ical';
  @Deprecated('Use icalExport instead')
  static const String icalDebug = '/owner/debug/ical';
  @Deprecated('Use icalGuide instead')
  static const String guideIcal = '/owner/guides/ical'; // Same path as icalGuide
  // Guides
  static const String guideStripe = '/owner/guides/stripe';
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
    refreshListenable: GoRouterRefreshStream(
      ref.watch(firebaseAuthProvider).authStateChanges(),
    ),
    redirect: (context, state) {
      // Use the watched authState from above
      final isAuthenticated = authState.isAuthenticated;
      final requiresOnboarding = authState.requiresOnboarding;
      final isLoading = authState.isLoading;
      final isLoggingIn =
          state.matchedLocation == OwnerRoutes.login ||
          state.matchedLocation == OwnerRoutes.register ||
          state.matchedLocation == OwnerRoutes.forgotPassword;

      // Debug logging (only in debug mode)
      if (kDebugMode) {
        LoggingService.log('redirect called:', tag: 'ROUTER');
        LoggingService.log(
          '  - matchedLocation: ${state.matchedLocation}',
          tag: 'ROUTER',
        );
        LoggingService.log(
          '  - isAuthenticated: $isAuthenticated',
          tag: 'ROUTER',
        );
        LoggingService.log(
          '  - requiresOnboarding: $requiresOnboarding',
          tag: 'ROUTER',
        );
        LoggingService.log(
          '  - isLoading: $isLoading',
          tag: 'ROUTER',
        );
        LoggingService.log(
          '  - firebaseUser: ${authState.firebaseUser?.uid}',
          tag: 'ROUTER',
        );
        LoggingService.log(
          '  - userModel: ${authState.userModel?.id}',
          tag: 'ROUTER',
        );
      }

      // FIX Q4: Don't redirect while auth operation is in progress
      // (prevents Register → Login flash during async registration)
      if (isLoading) {
        if (kDebugMode) {
          LoggingService.log(
            '  → Waiting for auth operation to complete (isLoading=true)',
            tag: 'ROUTER',
          );
        }
        return null; // Stay on current route
      }

      // Allow public access to embed, booking, calendar, and view routes (no auth required)
      // Also allow root path OR /login with widget query params (property, unit, confirmation)
      // This handles Stripe return URLs which may have #/login hash but widget params in query string
      final hasWidgetParams = state.uri.queryParameters.containsKey('property') ||
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
          LoggingService.log('  → Allowing public route (hasWidgetParams: $hasWidgetParams, matchedLocation: ${state.matchedLocation})', tag: 'ROUTER');
        }
        return null; // Allow access
      }

      // Allow access to onboarding welcome screen (public - shown before auth)
      final isOnboardingWelcome =
          state.matchedLocation == OwnerRoutes.onboardingWelcome;
      if (isOnboardingWelcome) {
        if (kDebugMode) {
          LoggingService.log(
            '  → Allowing onboarding welcome (public)',
            tag: 'ROUTER',
          );
        }
        return null; // Allow access
      }

      // Redirect root to appropriate page
      if (state.matchedLocation == '/') {
        // Case 1: Authenticated + needs onboarding → wizard
        if (isAuthenticated && requiresOnboarding) {
          if (kDebugMode) {
            LoggingService.log(
              '  → Redirecting / to onboarding wizard (authenticated, needs onboarding)',
              tag: 'ROUTER',
            );
          }
          return OwnerRoutes.onboardingWizard;
        }

        // Case 2: Authenticated + no onboarding → overview
        if (isAuthenticated) {
          if (kDebugMode) {
            LoggingService.log(
              '  → Redirecting / to overview (authenticated)',
              tag: 'ROUTER',
            );
          }
          return OwnerRoutes.overview;
        }

        // Case 3: Not authenticated → login
        if (kDebugMode) {
          LoggingService.log(
            '  → Redirecting / to login (not authenticated)',
            tag: 'ROUTER',
          );
        }
        return OwnerRoutes.login;
      }

      // If authenticated and requires onboarding, redirect to wizard (except if already on wizard/success)
      final isOnboardingRoute =
          state.matchedLocation == OwnerRoutes.onboardingWizard ||
          state.matchedLocation == OwnerRoutes.onboardingSuccess;
      if (isAuthenticated && requiresOnboarding && !isOnboardingRoute) {
        if (kDebugMode) {
          LoggingService.log(
            '  → Redirecting to onboarding wizard (needs onboarding)',
            tag: 'ROUTER',
          );
        }
        return OwnerRoutes.onboardingWizard;
      }

      // Redirect to login if not authenticated and trying to access protected routes
      if (!isAuthenticated && !isLoggingIn && !isOnboardingWelcome) {
        if (kDebugMode) {
          LoggingService.log(
            '  → Redirecting to login (not authenticated)',
            tag: 'ROUTER',
          );
        }
        return OwnerRoutes.login;
      }

      // Redirect to overview if authenticated, doesn't need onboarding, and trying to access login
      if (isAuthenticated && !requiresOnboarding && isLoggingIn) {
        if (kDebugMode) {
          LoggingService.log(
            '  → Redirecting to overview (authenticated, was on login)',
            tag: 'ROUTER',
          );
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
          final hasWidgetParams = state.uri.queryParameters.containsKey('property') ||
              state.uri.queryParameters.containsKey('unit') ||
              state.uri.queryParameters.containsKey('confirmation');

          if (hasWidgetParams) {
            // Show booking widget for embed URLs and Stripe return URLs
            return const BookingWidgetScreen();
          }

          // Show skeleton loader while redirect determines where to go
          // (prevents 404 flash during Login → Dashboard transition)
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: StatsCardsSkeleton(),
              ),
            ),
          );
        },
      ),

      // PUBLIC ROUTES (No authentication required)
      // Public booking widget (for iframe embedding)
      // URL: /?property=PROPERTY_ID&unit=UNIT_ID#/calendar
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const BookingWidgetScreen(),
      ),

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
                return BookingDetailsScreen(
                  booking: booking as dynamic,
                  widgetSettings: widgetSettings as dynamic,
                );
              } else {
                // Old format: BookingDetailsModel directly
                return BookingDetailsScreen(booking: extra as dynamic);
              }
            },
          ),
        ],
      ),

      // Onboarding routes (public - shown BEFORE auth)
      GoRoute(
        path: OwnerRoutes.onboardingWelcome,
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.onboardingWizard,
        builder: (context, state) => const OnboardingWizardScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.onboardingSuccess,
        builder: (context, state) => const OnboardingSuccessScreen(),
      ),

      // Auth routes
      GoRoute(
        path: OwnerRoutes.login,
        builder: (context, state) {
          // Check if this is a Stripe return URL with widget params
          // URL: /?property=...&confirmation=...#/login
          // In this case, show the booking widget instead of login
          final hasWidgetParams = state.uri.queryParameters.containsKey('property') ||
              state.uri.queryParameters.containsKey('unit') ||
              state.uri.queryParameters.containsKey('confirmation');

          if (hasWidgetParams) {
            // Show booking widget for Stripe return URLs
            return const BookingWidgetScreen();
          }

          return const EnhancedLoginScreen();
        },
      ),
      GoRoute(
        path: OwnerRoutes.register,
        builder: (context, state) => const EnhancedRegisterScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.termsConditions,
        builder: (context, state) => const TermsConditionsScreen(),
      ),

      // Owner main screens
      GoRoute(
        path: OwnerRoutes.overview,
        builder: (context, state) => const OverviewScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.properties,
        builder: (context, state) => const PropertiesScreen(),
      ),
      // Calendar route
      GoRoute(
        path: OwnerRoutes.calendarTimeline,
        builder: (context, state) => const OwnerTimelineCalendarScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.bookings,
        builder: (context, state) {
          final bookingId = state.uri.queryParameters['bookingId'];
          return OwnerBookingsScreen(initialBookingId: bookingId);
        },
      ),
      GoRoute(
        path: OwnerRoutes.analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),

      // Property management routes
      GoRoute(
        path: OwnerRoutes.propertyNew,
        builder: (context, state) => const PropertyFormScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.propertyEdit,
        builder: (context, state) {
          final propertyId = state.pathParameters['id'] ?? '';
          return PropertyEditLoader(propertyId: propertyId);
        },
      ),

      // Unit management routes
      GoRoute(
        path: OwnerRoutes.units,
        builder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'];
          return UnifiedUnitHubScreen(
            initialPropertyFilter: propertyId,
          );
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitNew,
        builder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'] ?? '';
          return UnitFormScreen(propertyId: propertyId);
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitEdit,
        builder: (context, state) {
          final unitId = state.pathParameters['id'] ?? '';
          return UnitEditLoader(unitId: unitId);
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitPricing,
        builder: (context, state) {
          final unitId = state.pathParameters['id'] ?? '';
          return UnitPricingLoader(unitId: unitId);
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitWidgetSettings,
        builder: (context, state) {
          final unitId = state.pathParameters['id'] ?? '';
          return WidgetSettingsLoader(unitId: unitId);
        },
      ),

      // Unified Unit Hub route
      GoRoute(
        path: OwnerRoutes.unitHub,
        builder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'];
          return UnifiedUnitHubScreen(
            initialPropertyFilter: propertyId,
          );
        },
      ),

      // Unit Wizard routes (new/edit)
      GoRoute(
        path: OwnerRoutes.unitWizard,
        builder: (context, state) => const UnitWizardScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.unitWizardEdit,
        builder: (context, state) {
          final unitId = state.pathParameters['id'];
          return UnitWizardScreen(unitId: unitId);
        },
      ),

      // Notifications route
      GoRoute(
        path: OwnerRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Profile routes
      GoRoute(
        path: OwnerRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.profileEdit,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.profileChangePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.profileNotifications,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),


      // Integrations routes
      GoRoute(
        path: OwnerRoutes.stripeIntegration,
        builder: (context, state) => const StripeConnectSetupScreen(),
      ),
      // Bank Account (for bank transfer payments)
      GoRoute(
        path: OwnerRoutes.bankAccount,
        builder: (context, state) => const BankAccountScreen(),
      ),
      // iCal Sync Settings (Import) - NEW
      GoRoute(
        path: OwnerRoutes.icalImport,
        builder: (context, state) => const IcalSyncSettingsScreen(),
      ),
      // iCal Export List (select unit) - NEW
      GoRoute(
        path: OwnerRoutes.icalExportList,
        builder: (context, state) => const IcalExportListScreen(),
      ),
      // iCal Export (Debug) - NEW
      // NOTE: This route requires 'extra' params (unit, propertyId)
      // It should only be accessed via context.push() from Widget Settings
      GoRoute(
        path: OwnerRoutes.icalExport,
        builder: (context, state) {
          // Handle missing extra params (direct navigation)
          if (state.extra == null) {
            LoggingService.log(
              'icalExport: Missing required params, redirecting to widget settings',
              tag: 'ROUTER',
            );
            // Redirect to widget settings list instead of crashing
            return const NotFoundScreen();
          }

          final extra = state.extra as Map<String, dynamic>;
          final unit = extra['unit'] as UnitModel?;
          final propertyId = extra['propertyId'] as String?;

          // Validate required params
          if (unit == null || propertyId == null) {
            LoggingService.log(
              'icalExport: Invalid params, redirecting',
              tag: 'ROUTER',
            );
            return const NotFoundScreen();
          }

          return IcalExportScreen(unit: unit, propertyId: propertyId);
        },
      ),

      // Guide routes
      GoRoute(
        path: OwnerRoutes.guideStripe,
        builder: (context, state) => const StripeGuideScreen(),
      ),
      // iCal Guide - NEW
      GoRoute(
        path: OwnerRoutes.icalGuide,
        builder: (context, state) => const IcalGuideScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.guideEmbedWidget,
        builder: (context, state) => const EmbedWidgetGuideScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.guideFaq,
        builder: (context, state) => const FAQScreen(),
      ),

      // Cookies Policy route
      GoRoute(
        path: OwnerRoutes.cookiesPolicy,
        builder: (context, state) => const CookiesPolicyScreen(),
      ),

      // 404
      GoRoute(
        path: OwnerRoutes.notFound,
        builder: (context, state) => const NotFoundScreen(),
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
      loading: () => const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: PropertyCardSkeleton(),
        ),
      ),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error loading property: $error'))),
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
      loading: () => const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: PropertyCardSkeleton(),
        ),
      ),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error loading unit: $error'))),
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
      loading: () => const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: CalendarSkeleton(),
        ),
      ),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error loading unit: $error'))),
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
        return WidgetSettingsScreen(
          propertyId: unit.propertyId,
          unitId: unitId,
        );
      },
      loading: () => const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: PropertyCardSkeleton(),
        ),
      ),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error loading unit: $error'))),
    );
  }
}
