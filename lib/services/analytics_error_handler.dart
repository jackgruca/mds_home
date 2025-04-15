// lib/services/analytics_error_handler.dart (new file)

import 'dart:math';

class AnalyticsErrorHandler {
  // Track error counts
  static final Map<String, int> _errorCounts = {};
  static final Map<String, DateTime> _lastErrorTime = {};
  
  // Error handling with exponential backoff
  static Future<T> withErrorHandling<T>({
    required Future<T> Function() operation,
    required String operationName,
    required T fallback,
    int maxRetries = 3,
    Function(Exception)? onError,
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        // Track error
        _errorCounts[operationName] = (_errorCounts[operationName] ?? 0) + 1;
        _lastErrorTime[operationName] = DateTime.now();
        
        // Call custom error handler if provided
        if (onError != null && e is Exception) {
          onError(e);
        }
        
        if (attempt < maxRetries) {
          // Exponential backoff
          final backoffMs = 1000 * pow(2, attempt - 1);
          await Future.delayed(Duration(milliseconds: backoffMs.toInt()));
        }
      }
    }
    
    // All retries failed
    return fallback;
  }
  
  // Check if operation is in error state with cooldown
  static bool isOperationInCooldown(String operationName, {Duration cooldown = const Duration(minutes: 5)}) {
    final errorCount = _errorCounts[operationName] ?? 0;
    final lastErrorTime = _lastErrorTime[operationName];
    
    if (errorCount > 3 && lastErrorTime != null) {
      final cooldownEnd = lastErrorTime.add(cooldown);
      return DateTime.now().isBefore(cooldownEnd);
    }
    
    return false;
  }
  
  // Reset error state for an operation
  static void resetErrorState(String operationName) {
    _errorCounts.remove(operationName);
    _lastErrorTime.remove(operationName);
  }
}