// lib/widgets/admin/analytics_monitoring_dashboard.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/analytics_api_service.dart';

class AnalyticsMonitoringDashboard extends StatefulWidget {
  const AnalyticsMonitoringDashboard({super.key});

  @override
  _AnalyticsMonitoringDashboardState createState() => _AnalyticsMonitoringDashboardState();
}

class _AnalyticsMonitoringDashboardState extends State<AnalyticsMonitoringDashboard> {
  Map<String, dynamic> _metadata = {};
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadMetadata(silent: true)
    );
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMetadata({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final result = await AnalyticsApiService.getAnalyticsMetadata();
      
      setState(() {
        _metadata = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics metadata: $e');
      
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Analytics System Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _loadMetadata(),
                  tooltip: 'Refresh status',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStatusDashboard(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusDashboard() {
    final lastUpdated = _metadata['lastUpdated']?.toDate();
    final inProgress = _metadata['inProgress'] == true;
    final jobStatus = _metadata['jobStatus'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status indicators
        Row(
          children: [
            Icon(
              inProgress ? Icons.sync : Icons.check_circle,
              color: inProgress ? Colors.blue : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              inProgress
                  ? 'Analytics processing in progress'
                  : 'Analytics system ready',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: inProgress ? Colors.blue : Colors.green,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Last updated
        if (lastUpdated != null)
          Text(
            'Last updated: ${_formatDate(lastUpdated)}',
            style: const TextStyle(fontSize: 14),
          ),
          
        const SizedBox(height: 16),
        
        // Job status table
        const Text(
          'Component Status:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Colors.grey),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Component', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            
            // Component status rows
            ...jobStatus.entries.map((entry) {
              final component = entry.key;
              final status = entry.value.toString();
              
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(component),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(status),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        
        // Additional controls
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Trigger Manual Run'),
              onPressed: inProgress ? null : _triggerManualRun,
            ),
          ],
        ),
        
        // Error section if there are any errors
        if (_metadata.containsKey('error')) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 4),
                Text(_metadata['error'].toString()),
                if (_metadata.containsKey('errorStack')) ...[
                  const SizedBox(height: 8),
                  Text(
                    _metadata['errorStack'].toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _triggerManualRun() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Analytics Run'),
        content: const Text(
          'This will trigger a manual analytics run which may take several minutes. '
          'Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Run'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Triggering analytics run...'),
          ],
        ),
      ),
    );
    
    try {
      final success = await AnalyticsApiService.forceRefreshAnalytics();
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Analytics run triggered successfully!'
                  : 'Failed to trigger analytics run',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    // Refresh metadata
    _loadMetadata();
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${date.month}/${date.day}/${date.year} at '
          '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_top;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}