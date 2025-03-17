// lib/utils/analytics_observer.dart
import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _sendScreenView(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _sendScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      _sendScreenView(previousRoute);
    }
  }

  void _sendScreenView(PageRoute<dynamic> route) {
    // Get screen name from route settings
    String screenName;
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      screenName = route.settings.name!;
    } else {
      // Use the widget type as fallback
      screenName = '/${route.settings.arguments?.toString() ?? route.toString()}';
    }
    
    // Log page view
    AnalyticsService.logPageView(screenName);
  }
}