// lib/services/analytics_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/analytics.dart';

/// Service wrapper for Analytics
class AnalyticsService {
  /// Initialize Google Analytics
  static void initializeAnalytics({required String measurementId}) {
    if (kIsWeb) {
      Analytics.initialize(measurementId: measurementId);
    }
  }
  
  /// Log a custom event
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (kIsWeb) {
      Analytics.logEvent(eventName, parameters: parameters);
    }
  }
  
  /// Log a page view
  static void logPageView(String routeName, {String? pageTitle}) {
    if (kIsWeb) {
      Analytics.logPageView(routeName, pageTitle: pageTitle);
    }
  }
  
  /// Log a user action
  static void logUserAction(String action, {Map<String, dynamic>? details}) {
    if (kIsWeb) {
      Analytics.logUserAction(action, details: details);
    }
  }
}