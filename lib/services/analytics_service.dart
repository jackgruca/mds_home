// lib/services/analytics_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;

class AnalyticsService {
  static bool _initialized = false;

  static void initializeAnalytics({required String measurementId}) {
  if (!kIsWeb || _initialized) {
    print('Analytics initialization skipped: kIsWeb=$kIsWeb, _initialized=$_initialized');
    return;
  }
  
  try {
    print('Attempting to initialize Google Analytics with ID: $measurementId');
    
    // Check if gtag already exists
    final gtagExists = js.context.hasProperty('gtag');
    print('gtag already exists: $gtagExists');
    
    if (!gtagExists) {
      print('Creating gtag script elements');
      // Add GA script to head
      final document = js.context['document'];
      final head = document['head'];
      
      if (head == null) {
        print('ERROR: Could not access document.head');
        return;
      }
      
      // Create GA script element
      final gaScript = document.callMethod('createElement', ['script']);
      gaScript['async'] = true;
      gaScript['src'] = 'https://www.googletagmanager.com/gtag/js?id=$measurementId';
      head.callMethod('appendChild', [gaScript]);
      print('Added gtag.js script to head');
      
      // Create config script element
      final configScript = document.callMethod('createElement', ['script']);
      configScript['text'] = '''
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', '$measurementId', { 'debug_mode': true });
      ''';
      head.callMethod('appendChild', [configScript]);
      print('Added gtag config script to head');
    }
    
    // Force a test event to verify initialization
    js.context.callMethod('setTimeout', [
      js.allowInterop(() {
        try {
          print('Checking if gtag exists after initialization');
          if (js.context.hasProperty('gtag')) {
            print('gtag function exists, sending test event');
            js.context.callMethod('gtag', ['event', 'test_event', js.JsObject.jsify({'test_param': 'test_value'})]);
            print('Test event sent successfully');
          } else {
            print('ERROR: gtag function not found after initialization');
          }
        } catch (e) {
          print('ERROR in test event: $e');
        }
      }),
      2000  // 2 second delay to ensure scripts have loaded
    ]);
    
    _initialized = true;
    print('Google Analytics initialization complete');
  } catch (e) {
    print('Failed to initialize analytics: $e');
    // Add detailed error information
    if (e is Error) {
      print('Error stack trace: ${e.stackTrace}');
    }
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