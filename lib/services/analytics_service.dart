// lib/utils/analytics_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;

class AnalyticsService {
  static bool _initialized = false;

  static void initializeAnalytics({required String measurementId}) {
    if (!kIsWeb || _initialized) return;
    
    try {
      // Add Google Analytics script dynamically
      final gaScript = _createScriptElement();
      gaScript.src = 'https://www.googletagmanager.com/gtag/js?id=$measurementId';
      gaScript.async = true;
      _appendToHead(gaScript);
      
      // Add configuration script
      final configScript = _createScriptElement();
      configScript.text = '''
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', '$measurementId');
      ''';
      _appendToHead(configScript);
      
      _initialized = true;
      print('Google Analytics initialized with ID: $measurementId');
    } catch (e) {
      print('Failed to initialize analytics: $e');
    }
  }
  
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (!kIsWeb || !_initialized) return;
    
    try {
      // Call gtag to log the event
      final params = parameters ?? {};
      _callGtag('event', eventName, params);
      print('Logged event: $eventName with params: $params');
    } catch (e) {
      print('Failed to log event: $e');
    }
  }
  
  static void logPageView(String pageName, {String? pageTitle}) {
    logEvent('page_view', parameters: {
      'page_path': pageName,
      'page_title': pageTitle ?? pageName,
    });
  }
  
  // Helper methods for JS interop that are safe for web and non-web platforms
  static dynamic _createScriptElement() {
    if (kIsWeb) {
      // Using dart:js_util would be more proper, but this works for the simple case
      return _jsEval('document.createElement("script")');
    }
    return null;
  }
  
  static void _appendToHead(dynamic script) {
    if (kIsWeb && script != null) {
      _jsEval('document.head.appendChild(arguments[0])', [script]);
    }
  }
  
  static void _callGtag(String command, String eventName, Map<String, dynamic> parameters) {
    if (kIsWeb) {
      _jsEval('window.gtag(arguments[0], arguments[1], arguments[2])', 
          [command, eventName, parameters]);
    }
  }
  
  static dynamic _jsEval(String code, [List<dynamic>? args]) {
    if (kIsWeb) {
      // In real implementation, you would use js_util from dart:js
      // This is a placeholder for the actual implementation
      print('JS would execute: $code with args: $args');
      // The real implementation would use js_util.callMethod or eval
    }
    return null;
  }
}