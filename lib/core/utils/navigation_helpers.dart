import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Route names as constants for type-safety
class Routes {
  // Public routes
  static const home = '/';
  static const search = '/search';
  static const propertyDetails = '/property/:id';
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';

  // Protected routes (require authentication)
  static const booking = '/booking/:unitId';
  static const bookingReview = '/booking/review';
  static const payment = '/payment/:bookingId';
  static const paymentSuccess = '/payment/success/:bookingId';
  static const paymentConfirm = '/payment/confirm';
  static const profile = '/profile';
  static const myBookings = '/bookings';

  // Owner routes (require owner/admin role)
  static const ownerDashboard = '/owner/dashboard';
  static const ownerProperty = '/owner/property/:id';
  static const ownerPropertyCreate = '/owner/property/create';
  static const ownerBookings = '/owner/bookings';

  // Admin routes
  static const adminDashboard = '/admin/dashboard';

  // Error routes
  static const notFound = '/404';

  Routes._();
}

/// Route path builders for parameterized routes
class RoutePaths {
  static String propertyDetails(String propertyId) =>
      '/property/$propertyId';

  static String booking(String unitId) => '/booking/$unitId';

  static String payment(String bookingId) => '/payment/$bookingId';

  static String paymentSuccess(String bookingId) =>
      '/payment/success/$bookingId';

  static String ownerProperty(String propertyId) =>
      '/owner/property/$propertyId';

  static String search({
    String? query,
    String? location,
    int? maxGuests,
    String? checkIn,
    String? checkOut,
  }) {
    final params = <String, String>{};
    if (query != null) params['q'] = query;
    if (location != null) params['location'] = location;
    if (maxGuests != null) params['guests'] = maxGuests.toString();
    if (checkIn != null) params['checkIn'] = checkIn;
    if (checkOut != null) params['checkOut'] = checkOut;

    if (params.isEmpty) return Routes.search;

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${Routes.search}?$queryString';
  }

  RoutePaths._();
}

/// Extension on BuildContext for easy navigation
extension NavigationExtensions on BuildContext {
  // Basic navigation
  void goToHome() => go(Routes.home);

  void goToSearch({
    String? query,
    String? location,
    int? maxGuests,
    String? checkIn,
    String? checkOut,
  }) =>
      go(RoutePaths.search(
        query: query,
        location: location,
        maxGuests: maxGuests,
        checkIn: checkIn,
        checkOut: checkOut,
      ));

  void goToPropertyDetails(String propertyId) =>
      go(RoutePaths.propertyDetails(propertyId));

  void goToBooking(String unitId) => go(RoutePaths.booking(unitId));

  void goToBookingReview() => go(Routes.bookingReview);

  void goToPayment(String bookingId) => go(RoutePaths.payment(bookingId));

  void goToPaymentSuccess(String bookingId) =>
      go(RoutePaths.paymentSuccess(bookingId));

  void goToForgotPassword() => go('/auth/forgot-password');

  // Auth navigation
  void goToLogin({String? redirectTo}) {
    final uri = redirectTo != null
        ? Uri(path: Routes.authLogin, queryParameters: {'redirect': redirectTo})
        : Uri(path: Routes.authLogin);
    go(uri.toString());
  }

  void goToRegister({String? redirectTo}) {
    final uri = redirectTo != null
        ? Uri(path: Routes.authRegister, queryParameters: {'redirect': redirectTo})
        : Uri(path: Routes.authRegister);
    go(uri.toString());
  }

  // Owner navigation
  void goToOwnerDashboard() => go(Routes.ownerDashboard);

  void goToOwnerProperty(String propertyId) =>
      go(RoutePaths.ownerProperty(propertyId));

  void goToOwnerPropertyCreate() => go(Routes.ownerPropertyCreate);

  // Profile navigation
  void goToProfile() => go(Routes.profile);

  void goToMyBookings() => go(Routes.myBookings);

  // Payment navigation
  void goToPaymentConfirm() => go(Routes.paymentConfirm);

  // Push navigation (adds to stack)
  void pushPropertyDetails(String propertyId) =>
      push(RoutePaths.propertyDetails(propertyId));

  void pushBooking(String unitId) => push(RoutePaths.booking(unitId));

  // Navigation with result
  Future<T?> pushForResult<T>(String location) => push<T>(location);

  // Pop navigation
  void goBack() => pop();

  void goBackWithResult<T>(T result) => pop(result);

  // Replace navigation
  void replaceWithHome() => replace(Routes.home);

  void replaceWithLogin() => replace(Routes.authLogin);

  // Navigation state
  bool canPop() => GoRouter.of(this).canPop();

  String get currentRoute => GoRouterState.of(this).uri.toString();

  Map<String, String> get pathParameters =>
      GoRouterState.of(this).pathParameters;

  Map<String, String> get queryParameters =>
      GoRouterState.of(this).uri.queryParameters;
}

/// Deep link helpers
class DeepLinkHelpers {
  /// Parse deep link URL and return route path
  static String? parseDeepLink(Uri uri) {
    final path = uri.path;

    // Handle app-specific deep links
    if (uri.scheme == 'rabbooking' || uri.scheme == 'https') {
      // Example: rabbooking://property/123
      // Example: https://rabbooking.com/property/123

      if (path.startsWith('/property/')) {
        return path; // Return as-is for GoRouter
      } else if (path.startsWith('/booking/')) {
        return path;
      } else if (path.startsWith('/owner/')) {
        return path;
      } else if (path == '/search') {
        // Preserve query parameters
        return uri.toString();
      }
    }

    return null; // Invalid deep link
  }

  /// Build deep link URL for sharing
  static String buildShareableLink(String routePath) {
    const baseUrl = 'https://rabbooking.com';
    return '$baseUrl$routePath';
  }

  DeepLinkHelpers._();
}

/// Route metadata for additional configuration
class RouteMetadata {
  final bool requiresAuth;
  final String? requiredRole; // 'guest', 'owner', 'admin'
  final String? title;
  final bool showInBottomNav;
  final IconData? icon;

  const RouteMetadata({
    this.requiresAuth = false,
    this.requiredRole,
    this.title,
    this.showInBottomNav = false,
    this.icon,
  });
}

/// Bottom navigation items configuration
class BottomNavItem {
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const BottomNavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// Bottom navigation configuration
class BottomNavConfig {
  static const items = [
    BottomNavItem(
      route: Routes.home,
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    BottomNavItem(
      route: Routes.search,
      label: 'Pretraga',
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
    ),
    BottomNavItem(
      route: Routes.myBookings,
      label: 'Bookings',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
    ),
    BottomNavItem(
      route: Routes.profile,
      label: 'Profil',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  BottomNavConfig._();
}
