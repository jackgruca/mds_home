// In lib/widgets/admin/analytics_setup_widget.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/analytics_api_service.dart';
import '../../services/firebase_service.dart';
import '../../services/analytics_cache_manager.dart';

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

  // Existing method
  Future<void> _triggerInitialAggregation() async {
    // Your existing implementation
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Existing collections setup card
        Card(
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
                        // Progress indicator for aggregation
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
        ),

        // Step 5: NEW Processing Control Panel
        const SizedBox(height: 20),
        _buildProcessingControlPanel(),
      ],
    );
  }

  // STEP 5: Processing Control Panel Implementation
  Widget _buildProcessingControlPanel() {
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
                  Icons.developer_board,
                  color: isDarkMode ? Colors.purple.shade300 : Colors.purple.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Analytics Processing Control',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Add processing status indicator
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('precomputedAnalytics')
                  .doc('metadata')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      height: 40, 
                      width: 40, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                  return const Text('No analytics metadata available');
                }
                
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null) return const Text('Invalid metadata format');
                
                final inProgress = data['inProgress'] == true;
                final status = data['statusMessage'] ?? 'Unknown';
                final lastUpdated = data['lastUpdated'] as Timestamp?;
                final processingStarted = data['processingStarted'] as Timestamp?;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status row
                    Row(
                      children: [
                        Icon(
                          inProgress ? Icons.sync : Icons.check_circle,
                          color: inProgress 
                              ? Colors.blue
                              : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: inProgress 
                                ? Colors.blue
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Last updated
                    if (lastUpdated != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          'Last updated: ${_formatTimestamp(lastUpdated)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    
                    // Processing started
                    if (processingStarted != null && inProgress)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          'Processing started: ${_formatTimestamp(processingStarted)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    
                    // Progress indicator for active processing
                    if (inProgress) 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(value: null),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Documents: ${data['documentsProcessed'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Picks: ${data['picksProcessed'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Show job statuses if available
                    if (data.containsKey('jobStatus') && data['jobStatus'] is Map) ...[
                      const Text('Job Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      ...buildJobStatusList(Map<String, dynamic>.from(data['jobStatus'] as Map)),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Processing control buttons
                    Row(
                      children: [
                        // Button to resume/continue processing
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: inProgress ? null : () async {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            // Modified to call our new continuation function
                            try {
                              final result = await AnalyticsApiService.processAnalyticsBatch();
                              setState(() {
                                _isLoading = false;
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result.containsKey('error')
                                      ? 'Error: ${result['error']}'
                                      : result['complete'] == true 
                                          ? 'Processing completed successfully!'
                                          : 'Batch processed. Continuing from ${result['continuationToken'] ?? 'unknown'}'),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            } catch (e) {
                              setState(() {
                                _isLoading = false;
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: Text(inProgress ? 'Processing...' : 'Continue Processing'),
                        ),

                        const SizedBox(width: 16),
                        
                        // Button to clean up dummy data
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: inProgress ? null : () async {
                            // Open confirmation dialog
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Cleanup'),
                                content: const Text(
                                  'This will remove sample/dummy data and only keep real analytics data. '
                                  'Are you sure you want to continue?'
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed == true) {
                              setState(() {
                                _isLoading = true;
                              });
                              
                              try {
                                // Run cleanup operation
                                await _cleanupDummyData();
                                
                                setState(() {
                                  _isLoading = false;
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sample data cleared successfully'),
                                  ),
                                );
                              } catch (e) {
                                setState(() {
                                  _isLoading = false;
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error cleaning up data: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Clear Sample Data'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Additional utility buttons
                    Row(
                      children: [
                        // Cache control
                        OutlinedButton.icon(
                          onPressed: () {
                            AnalyticsCacheManager.clearCache();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Analytics cache cleared'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_sweep),
                          label: const Text('Clear Cache'),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Fix data formats button 
                        OutlinedButton.icon(
                          onPressed: () async {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            try {
                              final result = await AnalyticsApiService.fixAnalyticsDataStructure();
                              setState(() {
                                _isLoading = false;
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result
                                      ? 'Data structure fixed successfully'
                                      : 'Error fixing data structure'),
                                ),
                              );
                            } catch (e) {
                              setState(() {
                                _isLoading = false;
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.build),
                          label: const Text('Fix Data Format'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper to format Firestore timestamp
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    
    if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
      // Today - show time only
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Show date and time
      return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  // Helper to build status list for jobs
  List<Widget> buildJobStatusList(Map<String, dynamic> jobStatus) {
    return jobStatus.entries.map((entry) {
      final job = entry.key;
      final status = entry.value.toString();
      
      Color statusColor;
      IconData statusIcon;
      
      switch (status) {
        case 'completed':
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          break;
        case 'processing':
          statusColor = Colors.blue;
          statusIcon = Icons.hourglass_top;
          break;
        case 'failed':
          statusColor = Colors.red;
          statusIcon = Icons.error;
          break;
        case 'pending':
          statusColor = Colors.orange;
          statusIcon = Icons.pending;
          break;
        default:
          statusColor = Colors.grey;
          statusIcon = Icons.circle;
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 8),
            Text(
              '$job: $status',
              style: TextStyle(color: statusColor),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Helper to clean up dummy data
  Future<void> _cleanupDummyData() async {
    final db = FirebaseFirestore.instance;
    
    // Mark that we're cleaning up
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'cleanupInProgress': true,
      'cleanupStarted': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // First, check for dummy data flag
    final metadata = await db.collection('precomputedAnalytics').doc('metadata').get();
    final hasDummyData = metadata.data()?['hasDummyData'] == true || metadata.data()?['manualFix'] == true;
    
    if (hasDummyData) {
      // Delete data from main collections that likely have dummy data
      for (int round = 1; round <= 7; round++) {
        try {
          await db.collection('precomputedAnalytics').doc('positionsByPickRound$round').delete();
        } catch (e) {
          // Ignore errors if doc doesn't exist
        }
      }
      
      try {
        await db.collection('precomputedAnalytics').doc('playerDeviations').delete();
      } catch (e) {
        // Ignore errors if doc doesn't exist
      }
      
      try {
        await db.collection('precomputedAnalytics').doc('teamNeeds').delete();
      } catch (e) {
        // Ignore errors if doc doesn't exist
      }
      
      try {
        await db.collection('precomputedAnalytics').doc('positionDistribution').delete();
      } catch (e) {
        // Ignore errors if doc doesn't exist
      }
      
      // Update metadata
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'hasDummyData': false,
        'manualFix': false,
        'cleanupInProgress': false,
        'cleanupCompleted': FieldValue.serverTimestamp(),
        'cleanupMessage': 'Sample data cleared successfully',
      }, SetOptions(merge: true));
    } else {
      // No dummy data found
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'cleanupInProgress': false,
        'cleanupCompleted': FieldValue.serverTimestamp(),
        'cleanupMessage': 'No sample data found to clear',
      }, SetOptions(merge: true));
    }
    
    // Clear any caches
    AnalyticsCacheManager.clearCache();
  }

  // Method we need to add to AnalyticsApiService
  static Future<Map<String, dynamic>> processAnalyticsBatch() async {
    try {
      await FirebaseService.initialize();
      
      // Here we'd implement a method similar to runRobustAggregation but with continuation support
      // Simplified version for demonstration:
      final result = await AnalyticsApiService.processSingleBatch(null);
      return result;
    } catch (e) {
      debugPrint('Error processing analytics batch: $e');
      return {'error': e.toString()};
    }
  }
}