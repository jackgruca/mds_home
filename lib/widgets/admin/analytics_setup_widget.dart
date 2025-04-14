// lib/widgets/admin/analytics_setup_widget.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/analytics_api_service.dart';
import '../../services/firebase_service.dart';

class AnalyticsSetupWidget extends StatefulWidget {
  const AnalyticsSetupWidget({super.key});

  @override
  _AnalyticsSetupWidgetState createState() => _AnalyticsSetupWidgetState();
}

class _AnalyticsSetupWidgetState extends State<AnalyticsSetupWidget> {
  bool _isLoading = false;
  bool _collectionsExist = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkCollections();
  }

  Future<void> _checkCollections() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking collections...';
    });

    try {
      final exist = await FirebaseService.checkAnalyticsCollections();
      
      setState(() {
        _isLoading = false;
        _collectionsExist = exist;
        _statusMessage = exist 
            ? 'Analytics collections are already set up.' 
            : 'Analytics collections need to be created.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error checking collections: $e';
      });
    }
  }

  Future<void> _setupCollections() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Setting up collections...';
    });

    try {
      final result = await FirebaseService.setupAnalyticsCollections();
      
      setState(() {
        _isLoading = false;
        _collectionsExist = result;
        _statusMessage = result 
            ? 'Success! Collections created.' 
            : 'Failed to create collections. Check logs.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  // Add this method after _setupCollections() in the _AnalyticsSetupWidgetState class
Future<void> _triggerInitialAggregation() async {
  setState(() {
    _isLoading = true;
    _statusMessage = 'Triggering initial data aggregation...';
  });

  try {
    // This is a local call to simulate the aggregation for testing
    // In production, you'd use Firebase Functions HTTP callable functions
    
    // First check if collections exist, if not, set them up
    if (!_collectionsExist) {
      await _setupCollections();
    }
    
    // Call the analytics aggregation function via HTTP callable
    // This would be better using Firebase Functions SDK but this works for testing
    await FirebaseService.triggerAnalyticsAggregation();
    
    setState(() {
      _isLoading = false;
      _statusMessage = 'Initial aggregation triggered. Data should be available shortly.';
    });
    
    // Check collections again after a delay to update the status
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkCollections();
      }
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _statusMessage = 'Error triggering aggregation: $e';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Analytics Collections Setup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'This will create the required Firestore collections for optimized analytics:',
            ),
            
            const SizedBox(height: 8),
            
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• precomputedAnalytics - For daily aggregated data'),
                  Text('• cachedQueries - For storing frequent query results'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
  children: [
    ElevatedButton(
      onPressed: _isLoading ? null : _setupCollections,
      child: _isLoading 
        ? const SizedBox(
            height: 20, 
            width: 20, 
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(_collectionsExist 
            ? 'Recreate Collections'
            : 'Setup Collections'),
    ),
    
    const SizedBox(width: 16),
    
    TextButton(
      onPressed: _isLoading ? null : _checkCollections,
      child: const Text('Check Status'),
    ),
    
    // Add this button right here
    if (_collectionsExist)
      Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          onPressed: _isLoading ? null : () async {
            setState(() {
              _isLoading = true;
              _statusMessage = 'Running local aggregation...';
            });
            
            try {
              final result = await AnalyticsApiService.runRobustAggregation();
              setState(() {
                _isLoading = false;
                _statusMessage = result 
                    ? 'Local aggregation successful! Check Community Analytics.' 
                    : 'Local aggregation failed. See logs for details.';
              });
              
              // Force refresh collection status
              _checkCollections();
            } catch (e) {
              setState(() {
                _isLoading = false;
                _statusMessage = 'Error: $e';
              });
            }
          },
          child: const Text('Run Local Aggregation'),
        ),
        
      ),
      ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
  ),
  onPressed: _isLoading ? null : () async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Fixing analytics data structure...';
    });
    
    try {
      final result = await AnalyticsApiService.fixAnalyticsDataStructure();
      setState(() {
        _isLoading = false;
        _statusMessage = result 
            ? 'Data structure fixed successfully! Check Community Analytics.' 
            : 'Failed to fix data structure. See logs for details.';
      });
      
      // Force refresh collection status
      _checkCollections();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  },
  child: const Text('Fix Data Structure'),
),
  ],
),
            
            const SizedBox(height: 16),
            
            if (_statusMessage.isNotEmpty)
  Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: _collectionsExist 
        ? (isDarkMode ? Colors.green.shade900.withOpacity(0.2) : Colors.green.shade100)
        : (isDarkMode ? Colors.orange.shade900.withOpacity(0.2) : Colors.orange.shade100),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: _collectionsExist 
          ? (isDarkMode ? Colors.green.shade700 : Colors.green.shade300)
          : (isDarkMode ? Colors.orange.shade700 : Colors.orange.shade300),
        width: 0.5,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _collectionsExist ? Icons.check_circle : Icons.info_outline,
              size: 16,
              color: _collectionsExist 
                ? (isDarkMode ? Colors.green.shade400 : Colors.green.shade700)
                : (isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: _collectionsExist 
                    ? (isDarkMode ? Colors.green.shade400 : Colors.green.shade700)
                    : (isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700),
                ),
              ),
            ),
          ],
        ),
        // Add a progress indicator
        if (_isLoading && _statusMessage.contains('aggregation'))
          FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('precomputedAnalytics')
                .doc('metadata')
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              
              final data = snapshot.data?.data();
              final inProgress = data?['inProgress'] ?? false;
              final processed = data?['documentsProcessed'] ?? 0;
              final picks = data?['picksProcessed'] ?? 0;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(
                    value: null, // Indeterminate
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Processed $processed documents with $picks picks',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ],
              );
            }
          ),
      ],
    ),
  ),
          ],
        ),
      ),
    );
  }
}