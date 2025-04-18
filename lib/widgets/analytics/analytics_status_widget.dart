// lib/widgets/analytics/analytics_status_widget.dart
import 'package:flutter/material.dart';
import '../../services/precomputed_analytics_service.dart';
import '../../services/analytics_query_service.dart';

class AnalyticsStatusWidget extends StatefulWidget {
  final VoidCallback onRetry;
  
  const AnalyticsStatusWidget({
    super.key,
    required this.onRetry,
  });

  @override
  _AnalyticsStatusWidgetState createState() => _AnalyticsStatusWidgetState();
}

class _AnalyticsStatusWidgetState extends State<AnalyticsStatusWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  String _statusMessage = 'Checking analytics data...';
  DateTime? _lastUpdated;
  
  @override
  void initState() {
    super.initState();
    _checkAnalyticsStatus();
  }
  
  Future<void> _checkAnalyticsStatus() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _statusMessage = 'Checking analytics data...';
    });
    
    try {
      // Get the latest stats timestamp
      final timestamp = await PrecomputedAnalyticsService.getLatestStatsTimestamp();
      
      // Check if a simple query returns data
      final positionData = await PrecomputedAnalyticsService.getPositionBreakdownByTeam(
        team: 'All Teams',
      );
      
      final hasData = positionData.isNotEmpty && 
                      positionData.containsKey('total') && 
                      positionData['total'] > 0;
      
      setState(() {
        _isLoading = false;
        _lastUpdated = timestamp;
        
        if (hasData) {
          _hasError = false;
          _statusMessage = 'Analytics data available';
        } else {
          _hasError = true;
          _statusMessage = 'Analytics data is not yet available';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage = 'Error checking analytics data: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLoading ? Icons.hourglass_top : 
                _hasError ? Icons.error_outline : Icons.check_circle,
                size: 48,
                color: _isLoading ? Colors.blue : 
                       _hasError ? Colors.red : Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                _isLoading ? 'Checking Analytics Status' : 
                _hasError ? 'Analytics Data Not Available' : 'Analytics Ready',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
              ),
              if (_lastUpdated != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${_formatDate(_lastUpdated!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              if (_hasError)
                ElevatedButton(
                  onPressed: () {
                    _checkAnalyticsStatus();
                    widget.onRetry();
                  },
                  child: const Text('Retry'),
                )
              else if (!_isLoading)
                TextButton(
                  onPressed: () {
                    _checkAnalyticsStatus();
                    widget.onRetry();
                  },
                  child: const Text('Refresh Data'),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    // Format: Month Day, Year at Hour:Minute
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    
    return '$month $day, $year at $hour:$minute $period';
  }
}