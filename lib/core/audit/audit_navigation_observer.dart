import 'package:flutter/material.dart';

import 'audit_constants.dart';
import 'audit_logger.dart';

/// ===============================================================
/// Audit Navigation Observer
/// Automatically tracks screen navigation.
/// ===============================================================

class AuditNavigationObserver extends NavigatorObserver {
  void _logScreen(Route<dynamic>? route) {
    if (route == null) return;

    final screenName = route.settings.name ??
        route.runtimeType.toString();

    AuditLogger.log(
      module: AuditConstants.navigation,
      event: AuditConstants.navigation,
      action: 'Navigate',
      screen: screenName,
      description: 'Navigated to $screenName',
    );
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);

    _logScreen(route);
  }

  @override
  void didReplace({
    Route? newRoute,
    Route? oldRoute,
  }) {
    super.didReplace(
      newRoute: newRoute,
      oldRoute: oldRoute,
    );

    _logScreen(newRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);

    if (previousRoute != null) {
      _logScreen(previousRoute);
    }
  }
}