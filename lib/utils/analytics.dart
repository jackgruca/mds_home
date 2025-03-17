// lib/utils/analytics.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;

class Analytics {
  static bool _initialized = false;
  static String? _measurementId;

  static void initialize({required String measurementId}) {
    if (_initialized || !kIsWeb) return;
    
    try {
      _measurementId = measurementId;
      
      // Call gtag function directly through js.context
      js.context.callMethod('eval', ['''
        // Add Google Analytics script
        var gaScript = document.createElement('script');
        gaScript.async = true;
        gaScript.src = 'https://www.googletagmanager.com/gtag/js?id=$measurementId';
        document.head.appendChild(gaScript);
        
        // Initialize gtag
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', '$measurementId', {
          'send_page_view': false,
          'cookie_flags': 'SameSite=None;Secure'
        });
      ''']);
      
      _initialized = true;
      print('Google Analytics initialized with ID: $measurementId');
    } catch (e) {
      print('Failed to initialize analytics: $e');
    }
  }
  
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (!_initialized || !kIsWeb) return;
    
    try {
      final params = parameters ?? {};
      js.context.callMethod('gtag', ['event', eventName, js.JsObject.jsify(params)]);
      print('Logged event: $eventName with params: $params');
    } catch (e) {
      print('Failed to log event: $e');
    }
  }
  
  static void logPageView(String pagePath, {String? pageTitle}) {
    if (!_initialized || !kIsWeb) return;
    
    try {
      // Create config with page path
      final configParams = js.JsObject.jsify({'page_path': pagePath});
      
      // Set the page on the config
      js.context.callMethod('gtag', ['config', _measurementId, configParams]);
      
      // Log page_view event with additional details
      final pageViewParams = {
        'page_path': pagePath,
        'page_title': pageTitle ?? pagePath,
      };
      
      logEvent('page_view', parameters: pageViewParams);
      print('Logged page view: $pagePath');
    } catch (e) {
      print('Failed to log page view: $e');
    }
  }
  
  static void logUserAction(String action, {Map<String, dynamic>? details}) {
    logEvent('user_action', parameters: {
      'action': action,
      ...?details,
    });
  }
}