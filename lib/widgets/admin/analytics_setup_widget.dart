// lib/widgets/admin/analytics_setup_widget.dart
import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import 'emergency_analytics_processor.dart';
import 'incremental_analytics_processor.dart';

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
                const SizedBox(height: 16),

ElevatedButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const IncrementalAnalyticsProcessor(),
      ),
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green, // Make it distinct from the emergency button
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.sync),
      SizedBox(width: 8),
      Text('Run Incremental Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
    ],
  ),
),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EmergencyAnalyticsProcessorScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Run Emergency Analytics'),
                ),
                  
                const SizedBox(width: 16),
                
                TextButton(
                  onPressed: _isLoading ? null : _checkCollections,
                  child: const Text('Check Status'),
                ),
                // Add this button
    if (_collectionsExist)
      Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
          onPressed: _isLoading ? null : _triggerInitialAggregation,
          child: const Text('Run Initial Aggregation'),
        ),
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
                child: Row(
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
              ),
          ],
        ),
      ),
    );
  }
}