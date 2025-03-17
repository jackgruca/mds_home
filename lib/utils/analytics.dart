// lib/utils/analytics.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js_util';
import 'dart:html' as html;

class Analytics {
  static bool _initialized = false;

  static void initialize({required String measurementId}) {
    if (_initialized) return;
    
    try {
      // Add Google Analytics script dynamically
      final gaScript = html.ScriptElement()
        ..async = true
        ..src = 'https://www.googletagmanager.com/gtag/js?id=$measurementId';
      html.document.head?.append(gaScript);
      
      // Add configuration script
      final configScript = html.ScriptElement()
        ..text = '''
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());
          gtag('config', '$measurementId');
        ''';
      html.document.head?.append(configScript);
      
      _initialized = true;
      print('Google Analytics initialized with ID: $measurementId');
    } catch (e) {
      print('Failed to initialize analytics: $e');
    }
  }
  
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (!_initialized) return;
    
    try {
      // Call gtag to log the event using js_util
      final params = parameters ?? {};
      callMethod(html.window, 'gtag', ['event', eventName, params]);
      print('Logged event: $eventName with params: $params');
    } catch (e) {
      print('Failed to log event: $e');
    }
  }
  
  static void logPageView(String routeName, {String? pageTitle}) {
    logEvent('page_view', parameters: {
      'page_path': routeName,
      'page_title': pageTitle ?? routeName,
    });
  }
  
  static void logUserAction(String action, {Map<String, dynamic>? details}) {
    logEvent('user_action', parameters: {
      'action': action,
      ...?details,
    });
  }
}