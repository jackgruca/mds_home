import 'package:shared_preferences/shared_preferences.dart';
import 'data_source_interface.dart';
import 'csv_data_source.dart';
import 'firebase_data_source.dart';

/// Manages data source selection and switching
/// Provides feature flag capability for A/B testing
class DataSourceManager {
  static final DataSourceManager _instance = DataSourceManager._internal();
  factory DataSourceManager() => _instance;
  DataSourceManager._internal();
  
  // Data sources
  final CsvDataSource _csvSource = CsvDataSource();
  final FirebaseDataSource _firebaseSource = FirebaseDataSource();
  
  // Current source
  DataSourceInterface? _currentSource;
  
  // Preference keys
  static const String _dataSourceKey = 'data_source_preference';
  static const String _debugModeKey = 'data_source_debug_mode';
  
  /// Initialize the data source manager
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSource = prefs.getString(_dataSourceKey) ?? 'csv'; // Default to CSV
    
    // Set initial source
    await setDataSource(savedSource == 'firebase' ? DataSourceType.firebase : DataSourceType.csv);
  }
  
  /// Get current data source
  DataSourceInterface get currentSource {
    _currentSource ??= _csvSource; // Default to CSV if not initialized
    return _currentSource!;
  }
  
  /// Get data source type
  DataSourceType get currentSourceType {
    if (_currentSource == _csvSource) return DataSourceType.csv;
    if (_currentSource == _firebaseSource) return DataSourceType.firebase;
    return DataSourceType.csv;
  }
  
  /// Set data source with validation
  Future<bool> setDataSource(DataSourceType type) async {
    DataSourceInterface newSource;
    
    switch (type) {
      case DataSourceType.csv:
        newSource = _csvSource;
        break;
      case DataSourceType.firebase:
        newSource = _firebaseSource;
        break;
    }
    
    // Check if source is available
    final isAvailable = await newSource.isAvailable();
    if (!isAvailable) {
      return false;
    }
    
    // Update current source
    _currentSource = newSource;
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dataSourceKey, type.name);
    
    return true;
  }
  
  /// Toggle between data sources
  Future<bool> toggleDataSource() async {
    final newType = currentSourceType == DataSourceType.csv 
        ? DataSourceType.firebase 
        : DataSourceType.csv;
    return setDataSource(newType);
  }
  
  /// Get debug mode status
  Future<bool> get isDebugMode async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_debugModeKey) ?? false;
  }
  
  /// Set debug mode
  Future<void> setDebugMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugModeKey, enabled);
  }
  
  /// Get performance metrics for comparison
  final Map<String, PerformanceMetric> _metrics = {};
  
  /// Record query performance
  Future<T> trackPerformance<T>(
    String operation,
    Future<T> Function() query,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await query();
      stopwatch.stop();
      
      // Record metric
      _metrics[operation] = PerformanceMetric(
        operation: operation,
        duration: stopwatch.elapsedMilliseconds,
        source: currentSource.sourceType,
        timestamp: DateTime.now(),
        success: true,
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      // Record failure
      _metrics[operation] = PerformanceMetric(
        operation: operation,
        duration: stopwatch.elapsedMilliseconds,
        source: currentSource.sourceType,
        timestamp: DateTime.now(),
        success: false,
        error: e.toString(),
      );
      
      rethrow;
    }
  }
  
  /// Get performance metrics
  List<PerformanceMetric> getMetrics() {
    return _metrics.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Clear performance metrics
  void clearMetrics() {
    _metrics.clear();
  }
  
  /// Get comparison report
  Map<String, dynamic> getComparisonReport() {
    final csvMetrics = _metrics.values
        .where((m) => m.source == 'CSV')
        .toList();
    final firebaseMetrics = _metrics.values
        .where((m) => m.source == 'Firebase')
        .toList();
    
    return {
      'csv': {
        'totalQueries': csvMetrics.length,
        'avgDuration': csvMetrics.isEmpty ? 0 : 
            csvMetrics.map((m) => m.duration).reduce((a, b) => a + b) ~/ csvMetrics.length,
        'successRate': csvMetrics.isEmpty ? 0 : 
            csvMetrics.where((m) => m.success).length / csvMetrics.length,
      },
      'firebase': {
        'totalQueries': firebaseMetrics.length,
        'avgDuration': firebaseMetrics.isEmpty ? 0 : 
            firebaseMetrics.map((m) => m.duration).reduce((a, b) => a + b) ~/ firebaseMetrics.length,
        'successRate': firebaseMetrics.isEmpty ? 0 : 
            firebaseMetrics.where((m) => m.success).length / firebaseMetrics.length,
      },
    };
  }
}

/// Data source types
enum DataSourceType {
  csv,
  firebase,
}

/// Performance metric for tracking
class PerformanceMetric {
  final String operation;
  final int duration; // milliseconds
  final String source;
  final DateTime timestamp;
  final bool success;
  final String? error;
  
  PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.source,
    required this.timestamp,
    required this.success,
    this.error,
  });
}