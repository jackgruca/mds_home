// lib/widgets/admin/analytics_trigger_widget.dart
import 'package:flutter/material.dart';
import '../../services/analytics_query_service.dart';
import '../../services/firebase_service.dart';

class AnalyticsTriggerWidget extends StatefulWidget {
  const AnalyticsTriggerWidget({super.key});

  @override
  _AnalyticsTriggerWidgetState createState() => _AnalyticsTriggerWidgetState();
}

class _AnalyticsTriggerWidgetState extends State<AnalyticsTriggerWidget> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _hasMore = true;
  String? _lastDocId;
  int _totalProcessed = 0;
  
  Future<void> _triggerAnalyticsRegeneration({bool fullRegeneration = false}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting analytics regeneration...';
      if (fullRegeneration) {
        _lastDocId = null;
        _totalProcessed = 0;
        _hasMore = true;
      }
    });

    try {
      // Call the manualAnalyticsRegeneration function via Firestore
      final result = await FirebaseService.callCloudFunction(
        'manualAnalyticsRegeneration',
        {
          'startAfter': _lastDocId,
          'limit': 100,
          'fullRegeneration': fullRegeneration && _lastDocId == null,
        },
      );
      
      // Update state based on result
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          final count = result['processedCount'] ?? 0;
          _totalProcessed += count as int;
          _statusMessage = 'Processed $count documents (total: $_totalProcessed)';
          _hasMore = result['hasMore'] ?? false;
          _lastDocId = result['lastDocId'];
        } else {
          _statusMessage = 'Error: ${result['error'] ?? 'Unknown error'}';
        }
      });
      
      // Force refresh the client cache
      await AnalyticsQueryService.forceRefreshAnalyticsCache();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Regeneration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Process analytics data in batches to avoid timeouts.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading 
                      ? null 
                      : () => _triggerAnalyticsRegeneration(fullRegeneration: true),
                  child: const Text('Start Full Regeneration'),
                ),
                const SizedBox(width: 8),
                if (_hasMore && _lastDocId != null)
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _triggerAnalyticsRegeneration(),
                    child: const Text('Process Next Batch'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const LinearProgressIndicator(),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_statusMessage),
              ),
            if (_totalProcessed > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Total processed: $_totalProcessed documents'),
              ),
          ],
        ),
      ),
    );
  }
}