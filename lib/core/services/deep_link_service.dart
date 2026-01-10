import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Deep Link Service
///
/// Handles deep linking for:
/// - App navigation (bookbed://)
/// - External platform links (Booking.com, Airbnb)
/// - Web URLs
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  /// Whitelist of allowed external domains
  /// SECURITY: Only these domains can be opened via deep links
  static const List<String> _allowedExternalDomains = [
    'booking.com',
    'www.booking.com',
    'admin.booking.com',
    'airbnb.com',
    'www.airbnb.com',
    'stripe.com',
    'connect.stripe.com',
    'bookbed.io',
    'app.bookbed.io',
    'help.bookbed.io',
    'view.bookbed.io',
  ];

  /// Check if the URL is allowed to be opened externally
  /// SECURITY: Prevents open redirect attacks
  bool _isAllowedExternalUrl(Uri uri) {
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    // Check against whitelist (exact match or subdomain)
    return _allowedExternalDomains.any((domain) => host == domain || host.endsWith('.$domain'));
  }

  /// Parse and handle deep link
  /// Returns true if link was handled, false otherwise
  Future<bool> handleDeepLink(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);

      // Handle app deep links (bookbed://)
      if (uri.scheme == 'bookbed') {
        return _handleAppDeepLink(uri, context);
      }

      // Handle web URLs (strictly validated against whitelist)
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        if (_isAllowedExternalUrl(uri)) {
          return _handleWebUrl(uri);
        } else {
          debugPrint('[DeepLinkService] Blocked unauthorized external URL: $url');
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('[DeepLinkService] Error handling deep link: $e');
      return false;
    }
  }

  /// Handle app deep links (bookbed://)
  /// SECURITY: Uses Uri class to safely construct URLs and prevent parameter injection
  bool _handleAppDeepLink(Uri uri, BuildContext context) {
    final path = uri.path;
    final queryParams = uri.queryParameters;

    switch (path) {
      case '/owner/calendar':
        final unitId = queryParams['unit'];
        final date = queryParams['date'];
        final conflictId = queryParams['conflict'];

        if (unitId != null) {
          // SECURITY FIX: Use Uri to safely construct URL and prevent parameter injection
          final safeUri = Uri(
            path: '/owner/calendar',
            queryParameters: {
              'unit': unitId,
              if (date != null) 'date': date,
              if (conflictId != null) 'conflict': conflictId,
            },
          );
          context.go(safeUri.toString());
          return true;
        }
        break;

      case '/owner/bookings':
        final bookingId = queryParams['booking'];
        final conflictId = queryParams['conflict'];

        if (bookingId != null) {
          final safeUri = Uri(path: '/owner/bookings', queryParameters: {'booking': bookingId});
          context.go(safeUri.toString());
          return true;
        } else if (conflictId != null) {
          final safeUri = Uri(path: '/owner/bookings', queryParameters: {'conflict': conflictId});
          context.go(safeUri.toString());
          return true;
        } else {
          context.go('/owner/bookings');
          return true;
        }

      case '/owner/platform-connections':
        final unitId = queryParams['unit'];

        if (unitId != null) {
          final safeUri = Uri(path: '/owner/platform-connections', queryParameters: {'unit': unitId});
          context.go(safeUri.toString());
          return true;
        } else {
          context.go('/owner/platform-connections');
          return true;
        }

      default:
        return false;
    }

    return false;
  }

  /// Handle web URLs
  Future<bool> _handleWebUrl(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[DeepLinkService] Error launching web URL: $e');
      return false;
    }
  }

  /// Generate deep link URL for blocking dates on Booking.com
  static String generateBookingComBlockUrl({
    required String hotelId,
    required String roomTypeId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    final checkInStr = checkIn.toIso8601String().split('T')[0];
    final checkOutStr = checkOut.toIso8601String().split('T')[0];
    // URLs to whitelisted domains are safe to construct like this
    // The base domain is hardcoded and safe
    return 'https://admin.booking.com/hotels/$hotelId/room-types/$roomTypeId/calendar?checkin=$checkInStr&checkout=$checkOutStr';
  }

  /// Generate deep link URL for blocking dates on Airbnb
  static String generateAirbnbBlockUrl({
    required String listingId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    final checkInStr = checkIn.toIso8601String().split('T')[0];
    final checkOutStr = checkOut.toIso8601String().split('T')[0];
    return 'https://www.airbnb.com/hosting/listings/$listingId/calendar?checkin=$checkInStr&checkout=$checkOutStr';
  }

  /// Generate app deep link URL
  static String generateAppDeepLink({required String path, Map<String, String>? queryParams}) {
    final uri = Uri(scheme: 'bookbed', path: path, queryParameters: queryParams);
    return uri.toString();
  }
}
