// lib/services/analytics_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;

class AnalyticsService {
  static bool _initialized = false;

  static void initializeAnalytics({required String measurementId}) {
    if (!kIsWeb || _initialized) return;
    
    try {
      // Check if gtag already exists
      final gtagExists = js.context.hasProperty('gtag');
      if (!gtagExists) {
        // Add GA script to head
        final document = js.context['document'];
        final head = document['head'];
        
        // Create GA script element
        final gaScript = document.callMethod('createElement', ['script']);
        gaScript['async'] = true;
        gaScript['src'] = 'https://www.googletagmanager.com/gtag/js?id=$measurementId';
        head.callMethod('appendChild', [gaScript]);
        
        // Create config script element
        final configScript = document.callMethod('createElement', ['script']);
        configScript['text'] = '''
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());
          gtag('config', '$measurementId');
        ''';
        head.callMethod('appendChild', [configScript]);
      }
      
      _initialized = true;
      print('Google Analytics initialized with ID: $measurementId');
    } catch (e) {
      print('Failed to initialize analytics: $e');
    }
  }
  
  static void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (!kIsWeb || !_initialized) return;
    
    try {
      // Convert parameters to JS object
      final jsParameters = js.JsObject.jsify(parameters ?? {});
      
      // Call gtag function
      js.context.callMethod('gtag', ['event', eventName, jsParameters]);
      print('Logged event: $eventName');
    } catch (e) {
      print('Failed to log event: $e');
    }
  }
  
  static void logPageView(String screenName, {String? pageTitle}) {
    if (!kIsWeb || !_initialized) return;
    
    try {
      final params = {
        'page_title': pageTitle ?? screenName,
        'page_path': screenName,
      };
      
      // Log page_view event
      logEvent('page_view', parameters: params);
      print('Logged page view: $screenName');
    } catch (e) {
      print('Failed to log page view: $e');
    }
  }
}