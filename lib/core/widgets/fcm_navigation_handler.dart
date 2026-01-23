import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../config/router_owner.dart';
import '../services/fcm_service.dart';
import '../services/logging_service.dart';
import '../../features/owner_dashboard/presentation/providers/owner_bookings_provider.dart';

/// Widget that handles FCM push notification navigation
///
/// Listens to:
/// - Navigation stream: Opens booking details when notification is tapped
/// - Foreground messages: Shows in-app notification banner
///
/// Must be placed inside the widget tree where GoRouter context is available.
class FcmNavigationHandler extends ConsumerStatefulWidget {
  final Widget child;

  const FcmNavigationHandler({super.key, required this.child});

  @override
  ConsumerState<FcmNavigationHandler> createState() =>
      _FcmNavigationHandlerState();
}

class _FcmNavigationHandlerState extends ConsumerState<FcmNavigationHandler> {
  StreamSubscription<String>? _navigationSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  @override
  void initState() {
    super.initState();
    _setupFcmListeners();
  }

  void _setupFcmListeners() {
    // Listen for notification taps (navigation stream)
    _navigationSubscription = fcmService.navigationStream.listen(
      _handleNavigation,
      onError: (error) {
        LoggingService.log(
          'FCM navigation stream error: $error',
          tag: 'FCM_NAV',
        );
      },
    );

    // Listen for foreground messages (show in-app banner)
    _foregroundSubscription = fcmService.foregroundMessageStream.listen(
      _handleForegroundMessage,
      onError: (error) {
        LoggingService.log(
          'FCM foreground stream error: $error',
          tag: 'FCM_NAV',
        );
      },
    );

    LoggingService.log(
      'FCM navigation listeners setup complete',
      tag: 'FCM_NAV',
    );
  }

  void _handleNavigation(String bookingId) {
    LoggingService.log(
      'FCM navigation received: bookingId=$bookingId',
      tag: 'FCM_NAV',
    );

    if (!mounted) return;

    // Set pending booking ID for the bookings screen to open dialog
    ref.read(pendingBookingIdProvider.notifier).state = bookingId;

    // Navigate to bookings page with booking query parameter
    // Use router directly to avoid "No GoRouter found in context" error
    // when called from SnackBar action (which has different context)
    final uri = Uri(
      path: OwnerRoutes.bookings,
      queryParameters: {'booking': bookingId},
    );

    final router = ref.read(ownerRouterProvider);
    router.go(uri.toString());
  }

  void _handleForegroundMessage(RemoteMessage message) {
    LoggingService.log(
      'FCM foreground message: ${message.notification?.title}',
      tag: 'FCM_NAV',
    );

    if (!mounted) return;

    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? 'New notification';
    final body = notification.body ?? '';
    final bookingId = message.data['bookingId'] as String?;

    // Show in-app snackbar with action to view booking
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body.isNotEmpty)
              Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: bookingId != null
            ? SnackBarAction(
                label: 'View',
                onPressed: () => _handleNavigation(bookingId),
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    _foregroundSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
