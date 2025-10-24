import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_state_provider.dart';
import '../utils/navigation_helpers.dart';
// import '../../features/home/presentation/screens/home_screen.dart'; // DELETED - AirBnb feature
// import '../../features/search/presentation/screens/search_results_screen.dart'; // DELETED - AirBnb feature
// import '../../features/search/presentation/screens/saved_searches_screen.dart'; // DELETED - AirBnb feature
import '../../features/property/presentation/screens/property_details_screen.dart'; // Using regular version
// import '../../features/property/presentation/screens/property_details_screen_redesigned.dart'; // DISABLED - not MVP
import '../../features/property/presentation/screens/review_form_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
// import '../../features/booking/presentation/screens/wizard/booking_wizard_screen.dart'; // DISABLED - using simpler flow
import '../../features/booking/presentation/screens/booking_review_screen.dart';
import '../../features/booking/presentation/screens/user_bookings_screen.dart';
import '../../features/booking/presentation/screens/booking_detail_screen.dart';
import '../../features/booking/presentation/screens/booking_success_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/owner_dashboard/presentation/screens/owner_dashboard_screen.dart';
import '../../features/owner/presentation/screens/property_management_screen.dart';
import '../../features/payment/presentation/screens/payment_confirmation_screen.dart';
import '../../features/payment/presentation/screens/payment_success_screen.dart';
import '../../features/payment/presentation/screens/payment_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
// import '../../features/favorites/presentation/screens/favorites_screen.dart'; // DELETED - AirBnb feature
import '../../features/property/data/repositories/reviews_repository.dart'; // For PropertyReview type
import '../../shared/presentation/widgets/app_scaffold_with_nav.dart';
import '../../shared/presentation/screens/not_found_screen.dart';
// import '../../features/design_system_demo/design_system_demo_screen.dart'; // DELETED - Demo feature
import '../../features/legal/presentation/screens/terms_conditions_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
// import '../../features/support/presentation/screens/help_faq_screen.dart'; // DELETED - Support feature
// import '../../features/support/presentation/screens/contact_screen.dart'; // DELETED - Support feature
// import '../../features/about/presentation/screens/about_us_screen.dart'; // DELETED - About feature
// import '../../features/about/presentation/screens/how_it_works_screen.dart'; // DELETED - About feature
import '../../features/property/presentation/screens/all_reviews_screen.dart';
import '../../features/calendar/presentation/screens/embed_calendar_screen.dart';
import '../../features/calendar/presentation/screens/embed_booking_screen.dart';
import '../../features/booking/presentation/screens/payment_confirmation_screen.dart' as booking_payment;

// Admin screens - DELETED (not part of MVP)
// import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
// import '../../features/admin/presentation/screens/admin_users_screen.dart';
// import '../../features/admin/presentation/screens/admin_properties_screen.dart';
// import '../../features/admin/presentation/screens/admin_bookings_screen.dart';
// import '../../features/admin/presentation/screens/admin_analytics_screen.dart';


/// GoRouter provider with auth integration
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateNotifierProvider);

  // Create a stream controller to listen to auth state changes
  final streamController = StreamController<AuthState>();
  ref.listen(authStateNotifierProvider, (previous, next) {
    streamController.add(next);
  });
  ref.onDispose(() => streamController.close());

  return GoRouter(
    initialLocation: Routes.ownerDashboard, // Changed from home (deleted feature)
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(
      streamController.stream,
    ),
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final userRole = authState.role;
      final currentPath = state.uri.path;

      // Embed routes - always public (no authentication required)
      if (currentPath.startsWith('/embed/')) {
        return null; // Allow public access to embed routes
      }

      // Auth pages - redirect authenticated users away
      if (currentPath.startsWith('/auth/')) {
        if (isAuthenticated) {
          // Check if there's a redirect query parameter
          final redirectTo = state.uri.queryParameters['redirect'];
          return redirectTo ?? Routes.home;
        }
        return null; // Allow access to auth pages
      }

      // Protected routes - require authentication
      final protectedRoutes = [
        '/booking/',
        '/bookings/',
        '/payment/',
        // '/favorites', // DELETED - AirBnb feature
        '/notifications',
        // '/saved-searches', // DELETED - AirBnb feature
        Routes.paymentConfirm,
        Routes.profile,
        Routes.myBookings,
      ];

      final isProtectedRoute = protectedRoutes.any(
        (route) => currentPath.startsWith(route),
      );

      if (isProtectedRoute && !isAuthenticated) {
        // Save intended destination and redirect to login
        return '${Routes.authLogin}?redirect=${Uri.encodeComponent(currentPath)}';
      }

      // Owner/Admin routes - require specific role
      if (currentPath.startsWith('/owner/')) {
        if (!isAuthenticated) {
          return '${Routes.authLogin}?redirect=${Uri.encodeComponent(currentPath)}';
        }

        final hasAccess = userRole == UserRole.owner || userRole == UserRole.admin;
        if (!hasAccess) {
          // Redirect to home if user doesn't have owner/admin role
          return Routes.home;
        }
      }

      // Admin routes - require admin role
      if (currentPath.startsWith('/admin/')) {
        if (!isAuthenticated) {
          return '${Routes.authLogin}?redirect=${Uri.encodeComponent(currentPath)}';
        }

        if (userRole != UserRole.admin) {
          // Redirect to home if user is not admin
          return Routes.home;
        }
      }

      return null; // No redirect needed
    },
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      // Shell route with bottom navigation (for main app sections)
      ShellRoute(
        builder: (context, state, child) {
          // Determine if we should show bottom nav based on route
          final showBottomNav = _shouldShowBottomNav(state.uri.path);

          if (showBottomNav) {
            return AppScaffoldWithNav(child: child);
          }

          return child;
        },
        routes: [
          // Public routes
          // DELETED - Home route (AirBnb feature)
          // GoRoute(
          //   path: Routes.home,
          //   name: 'home',
          //   pageBuilder: (context, state) => CustomTransitionPage(
          //     key: state.pageKey,
          //     child: const HomeScreen(),
          //     transitionsBuilder: _fadeTransition,
          //   ),
          // ),

          // DELETED - Search route (AirBnb feature)
          // GoRoute(
          //   path: Routes.search,
          //   name: 'search',
          //   pageBuilder: (context, state) {
          //     final location = state.uri.queryParameters['location'];
          //     final guestsStr = state.uri.queryParameters['guests'];
          //     final checkIn = state.uri.queryParameters['checkIn'];
          //     final checkOut = state.uri.queryParameters['checkOut'];
          //
          //     final guests = guestsStr != null ? int.tryParse(guestsStr) : null;
          //
          //     return CustomTransitionPage(
          //       key: state.pageKey,
          //       child: SearchResultsScreen(
          //         location: location,
          //         guests: guests,
          //         checkIn: checkIn,
          //         checkOut: checkOut,
          //       ),
          //       transitionsBuilder: _slideTransition,
          //     );
          //   },
          // ),
          GoRoute(
            path: Routes.myBookings,
            name: 'myBookings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const UserBookingsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: Routes.profile,
            name: 'profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const NotificationsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),

          // DELETED - Favorites route (AirBnb feature)
          // GoRoute(
          //   path: '/favorites',
          //   name: 'favorites',
          //   pageBuilder: (context, state) => CustomTransitionPage(
          //     key: state.pageKey,
          //     child: const FavoritesScreen(),
          //     transitionsBuilder: _fadeTransition,
          //   ),
          // ),

          // DELETED - Saved searches route (AirBnb feature)
          // GoRoute(
          //   path: '/saved-searches',
          //   name: 'savedSearches',
          //   pageBuilder: (context, state) => CustomTransitionPage(
          //     key: state.pageKey,
          //     child: const SavedSearchesScreen(),
          //     transitionsBuilder: _fadeTransition,
          //   ),
          // ),
        ],
      ),

      // Property details (outside shell for full-screen)
      GoRoute(
        path: Routes.propertyDetails,
        name: 'propertyDetails',
        pageBuilder: (context, state) {
          final propertyId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PropertyDetailsScreen(propertyId: propertyId), // Using regular version
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // All reviews for a property
      GoRoute(
        path: '/property/:propertyId/reviews',
        name: 'allReviews',
        pageBuilder: (context, state) {
          final propertyId = state.pathParameters['propertyId']!;
          final extra = state.extra as Map<String, dynamic>?;

          return CustomTransitionPage(
            key: state.pageKey,
            child: AllReviewsScreen(
              propertyId: propertyId,
              propertyName: extra?['propertyName'] ?? 'Property',
              rating: extra?['rating'] ?? 0.0,
              reviewCount: extra?['reviewCount'] ?? 0,
            ),
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // Booking flow - Simple booking screen
      GoRoute(
        path: Routes.booking,
        name: 'booking',
        pageBuilder: (context, state) {
          final unitId = state.pathParameters['unitId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BookingScreen(unitId: unitId), // Using simple flow
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // DISABLED - Wizard booking flow (complex 6-step process)
      // GoRoute(
      //   path: '/booking/wizard/:unitId',
      //   name: 'bookingWizard',
      //   pageBuilder: (context, state) {
      //     final unitId = state.pathParameters['unitId']!;
      //     return CustomTransitionPage(
      //       key: state.pageKey,
      //       child: BookingWizardScreen(unitId: unitId),
      //       transitionsBuilder: _slideTransition,
      //     );
      //   },
      // ),

      // Booking review
      GoRoute(
        path: Routes.bookingReview,
        name: 'bookingReview',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BookingReviewScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // Booking detail
      GoRoute(
        path: '/bookings/:id',
        name: 'bookingDetail',
        pageBuilder: (context, state) {
          final bookingId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BookingDetailScreen(bookingId: bookingId),
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // Booking success
      GoRoute(
        path: '/booking/success/:bookingReference',
        name: 'bookingSuccess',
        pageBuilder: (context, state) {
          final bookingReference = state.pathParameters['bookingReference']!;
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Invalid booking data')),
              ),
              transitionsBuilder: _fadeTransition,
            );
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: BookingSuccessScreen(
              bookingReference: bookingReference,
              propertyName: extra['propertyName'] as String,
              propertyImage: extra['propertyImage'] as String?,
              propertyLocation: extra['propertyLocation'] as String,
              checkIn: DateTime.parse(extra['checkIn'] as String),
              checkOut: DateTime.parse(extra['checkOut'] as String),
              guests: extra['guests'] as int,
              nights: extra['nights'] as int,
              totalAmount: (extra['totalAmount'] as num).toDouble(),
              currencySymbol: extra['currencySymbol'] as String? ?? '\$',
              confirmationEmail: extra['confirmationEmail'] as String,
            ),
            transitionsBuilder: _scaleTransition,
          );
        },
      ),

      // Review form
      GoRoute(
        path: '/booking/:bookingId/review',
        name: 'reviewForm',
        pageBuilder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Invalid review form data')),
              ),
              transitionsBuilder: _slideTransition,
            );
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: ReviewFormScreen(
              bookingId: bookingId,
              propertyId: extra['propertyId'] as String,
              propertyName: extra['propertyName'] as String,
              existingReview: extra['existingReview'] as PropertyReview?,
            ),
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // Payment screen (Stripe payment)
      GoRoute(
        path: '/payment/:bookingId',
        name: 'payment',
        pageBuilder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PaymentScreen(bookingId: bookingId),
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // Payment confirmation
      GoRoute(
        path: Routes.paymentConfirm,
        name: 'paymentConfirm',
        pageBuilder: (context, state) {
          final bookingId = state.uri.queryParameters['bookingId'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: PaymentConfirmationScreen(bookingId: bookingId),
            transitionsBuilder: _scaleTransition,
          );
        },
      ),

      // Payment success
      GoRoute(
        path: '/payment/success/:bookingId',
        name: 'paymentSuccess',
        pageBuilder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PaymentSuccessScreen(bookingId: bookingId),
            transitionsBuilder: _scaleTransition,
          );
        },
      ),

      // Auth routes
      GoRoute(
        path: Routes.authLogin,
        name: 'login',
        pageBuilder: (context, state) {
          final redirectTo = state.uri.queryParameters['redirect'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: LoginScreen(redirectTo: redirectTo),
            transitionsBuilder: _fadeTransition,
          );
        },
      ),
      GoRoute(
        path: Routes.authRegister,
        name: 'register',
        pageBuilder: (context, state) {
          final redirectTo = state.uri.queryParameters['redirect'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: RegisterScreen(redirectTo: redirectTo),
            transitionsBuilder: _fadeTransition,
          );
        },
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: 'forgotPassword',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/auth/reset-password',
        name: 'resetPassword',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ResetPasswordScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/auth/verify-email',
        name: 'emailVerification',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: EmailVerificationScreen(email: email),
            transitionsBuilder: _fadeTransition,
          );
        },
      ),

      // Owner routes
      GoRoute(
        path: Routes.ownerDashboard,
        name: 'ownerDashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OwnerDashboardScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: Routes.ownerProperty,
        name: 'ownerProperty',
        pageBuilder: (context, state) {
          final propertyId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PropertyManagementScreen(propertyId: propertyId),
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // DELETED - Admin routes (not part of MVP)
      // GoRoute(
      //   path: Routes.adminDashboard,
      //   name: 'adminDashboard',
      //   pageBuilder: (context, state) => CustomTransitionPage(
      //     key: state.pageKey,
      //     child: const AdminDashboardScreen(),
      //     transitionsBuilder: _slideTransition,
      //   ),
      // ),
      // GoRoute(
      //   path: '/admin/users',
      //   name: 'adminUsers',
      //   pageBuilder: (context, state) => CustomTransitionPage(
      //     key: state.pageKey,
      //     child: const AdminUsersScreen(),
      //     transitionsBuilder: _slideTransition,
      //   ),
      // ),
      // GoRoute(
      //   path: '/admin/properties',
      //   name: 'adminProperties',
      //   pageBuilder: (context, state) => CustomTransitionPage(
      //     key: state.pageKey,
      //     child: const AdminPropertiesScreen(),
      //     transitionsBuilder: _slideTransition,
      //   ),
      // ),
      // GoRoute(
      //   path: '/admin/bookings',
      //   name: 'adminBookings',
      //   pageBuilder: (context, state) => CustomTransitionPage(
      //     key: state.pageKey,
      //     child: const AdminBookingsScreen(),
      //     transitionsBuilder: _slideTransition,
      //   ),
      // ),
      // GoRoute(
      //   path: '/admin/analytics',
      //   name: 'adminAnalytics',
      //   pageBuilder: (context, state) => CustomTransitionPage(
      //     key: state.pageKey,
      //     child: const AdminAnalyticsScreen(),
      //     transitionsBuilder: _slideTransition,
      //   ),
      // ),

      // DELETED - Design System Demo (not needed)
      // GoRoute(
      //   path: '/design-system-demo',
      //   name: 'designSystemDemo',
      //   pageBuilder: (context, state) => CustomTransitionPage(
      //     key: state.pageKey,
      //     child: const DesignSystemDemoScreen(),
      //     transitionsBuilder: _rotationTransition,
      //   ),
      // ),

      // Legal & Support routes
      GoRoute(
        path: Routes.termsConditions,
        name: 'termsConditions',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TermsConditionsScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: Routes.privacyPolicy,
        name: 'privacyPolicy',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      // DELETED - Support routes (not part of MVP)
      // GoRoute(
      //   path: Routes.helpFaq,
      //   name: 'helpFaq',
      //   pageBuilder: (context, state) => CustomTransitionPage(
      //     key: state.pageKey,
      //     child: const HelpFaqScreen(),
      //     transitionsBuilder: _fadeTransition,
      //   ),
      // ),
      // GoRoute(
      //   path: Routes.contact,
      //   name: 'contact',
      //   pageBuilder: (context, state) => CustomTransitionPage(
      //     key: state.pageKey,
      //     child: const ContactScreen(),
      //     transitionsBuilder: _slideTransition,
      //   ),
      // ),

      // DELETED - About routes (not part of MVP)
      // GoRoute(
      //   path: Routes.aboutUs,
      //   name: 'aboutUs',
      //   pageBuilder: (context, state) => CustomTransitionPage(
      //     key: state.pageKey,
      //     child: const AboutUsScreen(),
      //     transitionsBuilder: _fadeTransition,
      //   ),
      // ),
      // GoRoute(
      //   path: Routes.howItWorks,
      //   name: 'howItWorks',
      //   pageBuilder: (context, state) => CustomTransitionPage(
      //     key: state.pageKey,
      //     child: const HowItWorksScreen(),
      //     transitionsBuilder: _slideTransition,
      //   ),
      // ),

      // Note: /notifications, /favorites, and /saved-searches are registered
      // inside the ShellRoute to show bottom navigation

      // Embed routes (for iframe on jasko-rab.com) - Public routes
      GoRoute(
        path: '/embed/:unitId',
        name: 'embedCalendar',
        pageBuilder: (context, state) {
          final unitId = state.pathParameters['unitId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: EmbedCalendarScreen(unitId: unitId),
            transitionsBuilder: _fadeTransition,
          );
        },
      ),
      GoRoute(
        path: '/embed/:unitId/booking',
        name: 'embedBooking',
        pageBuilder: (context, state) {
          final unitId = state.pathParameters['unitId']!;
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Invalid booking data')),
              ),
              transitionsBuilder: _fadeTransition,
            );
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: EmbedBookingScreen(
              unitId: unitId,
              unitName: extra['unitName'] as String,
              selectedDates: extra['selectedDates'] as List<DateTime>,
              totalPrice: extra['totalPrice'] as double,
            ),
            transitionsBuilder: _slideTransition,
          );
        },
      ),
      GoRoute(
        path: '/embed/:unitId/payment/:bookingId',
        name: 'embedPayment',
        pageBuilder: (context, state) {
          // unitId is in path but not used in this route
          final bookingId = state.pathParameters['bookingId']!;
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Invalid payment data')),
              ),
              transitionsBuilder: _fadeTransition,
            );
          }

          final booking = extra['booking'];
          final unitName = extra['unitName'] as String;

          return CustomTransitionPage(
            key: state.pageKey,
            child: booking_payment.PaymentConfirmationScreen(
              bookingId: bookingId,
              booking: booking,
              unitName: unitName,
            ),
            transitionsBuilder: _scaleTransition,
          );
        },
      ),

      // 404 route
      GoRoute(
        path: Routes.notFound,
        name: 'notFound',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotFoundScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
    ],
  );
});

/// Helper to determine if bottom nav should be shown
bool _shouldShowBottomNav(String path) {
  final bottomNavRoutes = [
    // Routes.home, // DELETED - AirBnb feature
    // Routes.search, // DELETED - AirBnb feature
    Routes.myBookings,
    Routes.profile,
    Routes.ownerDashboard, // Added for MVP
  ];

  return bottomNavRoutes.any((route) => path == route);
}

/// Custom page transitions with premium effects
/// Duration: 300ms, Curve: easeInOut (as per spec)

/// Enhanced fade transition with subtle slide
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  // Fade with subtle slide from bottom (300ms, easeInOut)
  const curve = Curves.easeInOut;

  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: curve,
  );

  final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
  final slideAnimation = Tween<Offset>(
    begin: const Offset(0.0, 0.05),
    end: Offset.zero,
  ).animate(curvedAnimation);

  return FadeTransition(
    opacity: fadeAnimation,
    child: SlideTransition(
      position: slideAnimation,
      child: child,
    ),
  );
}

/// Enhanced slide transition with fade (from right) - 300ms, easeInOut
Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(0.3, 0.0); // Reduced from 1.0 for smoother feel
  const end = Offset.zero;
  const curve = Curves.easeInOut; // As per spec

  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: curve,
  );

  final slideTween = Tween(begin: begin, end: end);
  final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

  // Secondary animation for page being exited (fade out slightly)
  final secondaryCurvedAnimation = CurvedAnimation(
    parent: secondaryAnimation,
    curve: curve,
  );

  final secondaryFadeTween = Tween<double>(begin: 1.0, end: 0.9);

  return FadeTransition(
    opacity: secondaryCurvedAnimation.drive(secondaryFadeTween),
    child: FadeTransition(
      opacity: curvedAnimation.drive(fadeTween),
      child: SlideTransition(
        position: curvedAnimation.drive(slideTween),
        child: child,
      ),
    ),
  );
}

/// Scale transition (for modal-like pages)
Widget _scaleTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const curve = Curves.easeOutBack;

  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: curve,
  );

  final scaleTween = Tween<double>(begin: 0.8, end: 1.0);
  final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

  return FadeTransition(
    opacity: curvedAnimation.drive(fadeTween),
    child: ScaleTransition(
      scale: curvedAnimation.drive(scaleTween),
      child: child,
    ),
  );
}

/// DELETED - Rotation + fade transition (was used by design system demo)
// Widget _rotationTransition(
//   BuildContext context,
//   Animation<double> animation,
//   Animation<double> secondaryAnimation,
//   Widget child,
// ) {
//   const curve = Curves.easeInOutCubic;
//
//   final curvedAnimation = CurvedAnimation(
//     parent: animation,
//     curve: curve,
//   );
//
//   final rotationTween = Tween<double>(begin: -0.05, end: 0.0); // Slight rotation
//   final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
//   final scaleTween = Tween<double>(begin: 0.9, end: 1.0);
//
//   return FadeTransition(
//     opacity: curvedAnimation.drive(fadeTween),
//     child: ScaleTransition(
//       scale: curvedAnimation.drive(scaleTween),
//       child: RotationTransition(
//         turns: curvedAnimation.drive(rotationTween),
//         child: child,
//       ),
//     ),
//   );
// }

/// GoRouter refresh stream helper
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (data) => notifyListeners(),
        );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
