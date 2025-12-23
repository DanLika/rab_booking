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

  /// Parse and handle deep link
  /// Returns true if link was handled, false otherwise
  Future<bool> handleDeepLink(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);

      // Handle app deep links (bookbed://)
      if (uri.scheme == 'bookbed') {
        return _handleAppDeepLink(uri, context);
      }

      // Handle external platform links
      if (uri.host.contains('booking.com') || uri.host.contains('airbnb.com')) {
        return _handleExternalPlatformLink(uri);
      }

      // Handle web URLs
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        return _handleWebUrl(uri);
      }

      return false;
    } catch (e) {
      debugPrint('[DeepLinkService] Error handling deep link: $e');
      return false;
    }
  }

  /// Handle app deep links (bookbed://)
  bool _handleAppDeepLink(Uri uri, BuildContext context) {
    final path = uri.path;
    final queryParams = uri.queryParameters;

    switch (path) {
      case '/owner/calendar':
        final unitId = queryParams['unit'];
        final date = queryParams['date'];
        final conflictId = queryParams['conflict'];

        if (unitId != null) {
          context.go(
            '/owner/calendar?unit=$unitId${date != null ? '&date=$date' : ''}${conflictId != null ? '&conflict=$conflictId' : ''}',
          );
          return true;
        }
        break;

      case '/owner/bookings':
        final bookingId = queryParams['booking'];
        final conflictId = queryParams['conflict'];

        if (bookingId != null) {
          context.go('/owner/bookings?booking=$bookingId');
          return true;
        } else if (conflictId != null) {
          context.go('/owner/bookings?conflict=$conflictId');
          return true;
        } else {
          context.go('/owner/bookings');
          return true;
        }

      case '/owner/platform-connections':
        final unitId = queryParams['unit'];

        if (unitId != null) {
          context.go('/owner/platform-connections?unit=$unitId');
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

  /// Handle external platform links (Booking.com, Airbnb)
  Future<bool> _handleExternalPlatformLink(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[DeepLinkService] Error launching external link: $e');
      return false;
    }
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
  static String generateAppDeepLink({
    required String path,
    Map<String, String>? queryParams,
  }) {
    final uri = Uri(
      scheme: 'bookbed',
      path: path,
      queryParameters: queryParams,
    );
    return uri.toString();
  }
}
