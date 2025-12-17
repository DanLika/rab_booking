import 'package:flutter/material.dart';
import 'logging_service.dart';

/// Navigator observer that logs navigation events to Sentry as breadcrumbs.
/// Helps debug errors by showing the user's navigation history leading up to the error.
class SentryNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = route.settings.name ?? 'unnamed';
    LoggingService.logNavigation(routeName, params: {
      'action': 'push',
      if (previousRoute?.settings.name != null) 'from': previousRoute!.settings.name,
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final routeName = previousRoute?.settings.name ?? 'unnamed';
    LoggingService.logNavigation(routeName, params: {
      'action': 'pop',
      if (route.settings.name != null) 'popped': route.settings.name,
    });
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final routeName = newRoute?.settings.name ?? 'unnamed';
    LoggingService.logNavigation(routeName, params: {
      'action': 'replace',
      if (oldRoute?.settings.name != null) 'replaced': oldRoute!.settings.name,
    });
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    final routeName = route.settings.name ?? 'unnamed';
    LoggingService.logNavigation(routeName, params: {
      'action': 'remove',
    });
  }
}
