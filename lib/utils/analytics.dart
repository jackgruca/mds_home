// lib/utils/analytics.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js_interop';
import 'dart:html' as html;

class Analytics {
  static bool _initialized = false;
  static String? _measurementId;

  static void initialize({required String measurementId}) {
    if (_initialized || !kIsWeb) return;
    
    try {
      _measurementId = measurementId;
      
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
          gtag('config', '$measurementId', {
            'send_page_view': false,
            'cookie_flags': 'SameSite=None;Secure'
          });
        ''';
      html.document.head?.append(configScript);
      
      _initialized = true;
      print('Google Analytics initialized with ID: $measurementId');
    } catch (e) {
      print('Failed to initialize analytics: $e');
    }
  }
  
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (!_initialized || !kIsWeb) return;
    
    try {
      // Call gtag function
      final params = parameters ?? {};
      final gtagFn = html.window.getProperty('gtag');
      gtagFn?.callMethod('apply', [html.window, ['event', eventName, params].toJS]);
      print('Logged event: $eventName with params: $params');
    } catch (e) {
      print('Failed to log event: $e');
    }
  }
  
  static void logPageView(String pagePath, {String? pageTitle}) {
    if (!_initialized || !kIsWeb) return;
    
    try {
      // Log page_view event
      final params = {
        'page_path': pagePath,
        'page_title': pageTitle ?? pagePath,
        'page_location': '${html.window.location.origin}$pagePath'
      };
      
      // First, set the page on the config
      final gtagFn = html.window.getProperty('gtag');
      gtagFn?.callMethod('apply', [html.window, ['config', _measurementId, {'page_path': pagePath}].toJS]);
      
      // Then send the page_view event
      gtagFn?.callMethod('apply', [html.window, ['event', 'page_view', params].toJS]);
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