// lib/widgets/admin/analytics_setup_widget.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mds_home/services/analytics_query_service.dart';
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
  Future<void> _resetPrecomputedAnalytics() async {
  // First show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset All Analytics Data'),
      content: const Text(
        'This will delete ALL precomputed analytics data and reset the processing state. '
        'You will need to reprocess all your draft analytics from scratch. '
        'This operation cannot be undone. Are you sure?'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reset Everything'),
        ),
      ],
    ),
  ) ?? false;
  
  if (!confirmed) return;
  
  setState(() {
    _isLoading = true;
    _statusMessage = 'Resetting precomputed analytics...';
  });
  
  try {
    final db = FirebaseFirestore.instance;
    
    // Get all documents in precomputedAnalytics collection
    final snapshot = await db.collection('precomputedAnalytics').get();
    
    // Delete all documents one by one
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    
    // Create fresh metadata
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'lastUpdated': DateTime.now(),
      'documentsProcessed': 0,
      'inProgress': false,
      'resetDate': DateTime.now(),
    });
    
    // Reset processing state
    final processingStateDoc = db.collection('precomputedAnalytics').doc('processing_state');
    await processingStateDoc.delete();
    
    setState(() {
      _isLoading = false;
      _collectionsExist = true; // Collections still exist, just empty
      _statusMessage = 'All precomputed analytics have been reset! You can now reprocess all data from scratch.';
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _statusMessage = 'Error resetting analytics: $e';
    });
  }
}

  Future<void> _checkAnalyticsProcessing() async {
  setState(() {
    _isLoading = true;
    _statusMessage = 'Checking analytics processing...';
  });

  try {
    final db = FirebaseFirestore.instance;
    
    // Get metadata document
    final metadataDoc = await db.collection('precomputedAnalytics').doc('metadata').get();
    final metadata = metadataDoc.data() ?? {};
    final processedCount = metadata['documentsProcessed'] ?? 0;
    
    // Get count of actual analytics documents
    final rawCount = await db.collection('draftAnalytics').count().get();
    
    // Check pick #1 count in positionsByPick
    final pickData = await db.collection('precomputedAnalytics').doc('positionsByPick').get();
    final pickDataObj = pickData.data() ?? {};
    final pickDataList = (pickDataObj['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    
    // Find pick #1 data
    final pick1Data = pickDataList.firstWhere(
      (item) => item['pick'] == 1, 
      orElse: () => {'totalDrafts': 0, 'positions': []}
    );
    
    final pick1Count = pick1Data['totalDrafts'] ?? 0;
    
    setState(() {
      _isLoading = false;
      _statusMessage = 'Analytics Diagnostic:\n'
          '- Raw draftAnalytics: ${rawCount.count} documents\n'
          '- Processed count in metadata: $processedCount\n'
          '- Pick #1 total count: $pick1Count\n\n'
          'ISSUE: ${pick1Count / processedCount < 0.1 ? 
              "Processing inconsistency detected! Aggregation is not including all drafts." : 
              "Processing appears consistent."}';
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _statusMessage = 'Error checking analytics: $e';
    });
  }
}

// Add this to lib/widgets/admin/analytics_setup_widget.dart

Future<void> _fetchAnalyticsStats() async {
  setState(() {
    _isLoading = true;
    _statusMessage = 'Fetching analytics stats...';
  });

  try {
    final db = FirebaseFirestore.instance;
    
    // Get metadata
    final metadataDoc = await db.collection('precomputedAnalytics').doc('metadata').get();
    final metadata = metadataDoc.data() ?? {};
    
    // Get total drafts count
    final draftCount = await AnalyticsQueryService.getDraftCount();
    
    // Get position distribution document
    final posDistDoc = await db.collection('precomputedAnalytics').doc('positionDistribution').get();
    final posDistData = posDistDoc.data() ?? {};
    final totalPositions = posDistData['overall']?['total'] ?? 0;
    
    // Get team needs document
    final teamNeedsDoc = await db.collection('precomputedAnalytics').doc('teamNeeds').get();
    final teamNeedsData = teamNeedsDoc.data() ?? {};
    final totalTeams = teamNeedsData['needs'] != null 
      ? (teamNeedsData['needs'] as Map).length 
      : 0;
    
    // Get playerDeviations document
    final playerDevsDoc = await db.collection('precomputedAnalytics').doc('playerDeviations').get();
    final playerDevsData = playerDevsDoc.data() ?? {};
    final totalPlayers = playerDevsData['players'] != null 
      ? (playerDevsData['players'] as List).length 
      : 0;
    
    // Build stats message
    final statsMessage = '''
Analytics Collection Stats:
--------------------------
Total draft simulations: ${draftCount ?? 'Unknown'}
Drafts processed for analytics: ${metadata['documentsProcessed'] ?? 'Unknown'}
Last updated: ${metadata['lastUpdated'] != null ? (metadata['lastUpdated'] as Timestamp).toDate().toString() : 'Unknown'}

Precomputed Data:
--------------------------
Total positions (filtered by userTeam): $totalPositions
Team needs entries: $totalTeams
Player deviation entries: $totalPlayers

Status: ${metadata['inProgress'] == true ? 'Processing in progress' : 'Ready'}
${metadata['error'] != null ? 'Error: ${metadata['error']}' : ''}
''';
    
    setState(() {
      _isLoading = false;
      _statusMessage = statsMessage;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _statusMessage = 'Error fetching analytics stats: $e';
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
// Add to lib/widgets/admin/analytics_setup_widget.dart
// This is a targeted fix for the positionsByPick document

Future<void> _fixPickCountsInPositionsByPick() async {
  setState(() {
    _isLoading = true;
    _statusMessage = 'Fixing position counts in positionsByPick...';
  });

  try {
    final db = FirebaseFirestore.instance;
    
    // First check if we have positionsByPick data
    final pickDataDoc = await db.collection('precomputedAnalytics').doc('positionsByPick').get();
    if (!pickDataDoc.exists) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: positionsByPick document does not exist. Run the aggregation first.';
      });
      return;
    }
    
    // Get the raw data
    final Map<String, dynamic> pickData = pickDataDoc.data() ?? {};
    List<Map<String, dynamic>> pickList = [];
    
    if (pickData.containsKey('data') && pickData['data'] is List) {
      pickList = List<Map<String, dynamic>>.from(pickData['data']);
    }
    
    // For debugging: Check if the list has any entries
    debugPrint('Found ${pickList.length} pick entries in positionsByPick');
    
    // The issue might be that the pick data structure is created but totals are incorrect
    // Let's directly query draft analytics to get accurate counts for each pick
    
    // Use a smaller batch size for this focused operation
    const batchSize = 500;
    DocumentSnapshot? lastDoc;
    int processedCount = 0;
    
    // Maps to track pick counts
    Map<int, Map<String, int>> pickPositionCounts = {};
    Map<int, int> pickTotals = {};
    Map<int, String> pickRounds = {};
    
    // Keep processing until we've gone through all documents
    bool hasMoreDocs = true;
    while (hasMoreDocs) {
      Query query = db.collection('draftAnalytics').limit(batchSize);
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        hasMoreDocs = false;
        continue;
      }
      
      int batchPickCount = 0;
      
      // Process each document
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (!data.containsKey('picks') || data['picks'] is! List) {
          continue;
        }
        
        final List<dynamic> picks = data['picks'];
        
        // Process each pick
        for (var pick in picks) {
          if (pick == null) continue;
          
          batchPickCount++;
          
          // Extract pick data
          final int pickNumber = pick['pickNumber'] as int? ?? 0;
          final String position = pick['position'] as String? ?? 'Unknown';
          final String round = pick['round'] as String? ?? '1';
          
          // Initialize tracking if needed
          if (!pickPositionCounts.containsKey(pickNumber)) {
            pickPositionCounts[pickNumber] = {};
          }
          if (!pickTotals.containsKey(pickNumber)) {
            pickTotals[pickNumber] = 0;
          }
          
          // Update counts
          pickPositionCounts[pickNumber]![position] = 
              (pickPositionCounts[pickNumber]![position] ?? 0) + 1;
          pickTotals[pickNumber] = (pickTotals[pickNumber] ?? 0) + 1;
          pickRounds[pickNumber] = round;
        }
        
        lastDoc = doc;
      }
      
      processedCount += snapshot.docs.length;
      
      setState(() {
        _statusMessage = 'Processed $processedCount documents. Found $batchPickCount picks in last batch.';
      });
    }
    
    // Now format the correct data
    List<Map<String, dynamic>> correctedPickList = [];
    
    for (var entry in pickPositionCounts.entries) {
      final pickNumber = entry.key;
      final positionCounts = entry.value;
      final total = pickTotals[pickNumber] ?? 0;
      
      // Skip if no data
      if (total == 0) continue;
      
      // Format positions with percentages
      List<Map<String, dynamic>> positions = positionCounts.entries
          .map((e) => {
                'position': e.key,
                'count': e.value,
                'percentage': '${((e.value / total) * 100).toStringAsFixed(1)}%',
              })
          .toList();
      
      // Sort by frequency (most common first)
      positions.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      correctedPickList.add({
        'pick': pickNumber,
        'round': pickRounds[pickNumber] ?? '1',
        'positions': positions,
        'totalDrafts': total,
      });
    }
    
    // Sort by pick number
    correctedPickList.sort((a, b) => (a['pick'] as int).compareTo(b['pick'] as int));
    
    // Save the corrected data
    await db.collection('precomputedAnalytics').doc('positionsByPick').set({
      'data': correctedPickList,
      'lastUpdated': DateTime.now(),
    });
    
    // Also fix round-specific documents
    for (int round = 1; round <= 7; round++) {
      final roundPicks = correctedPickList
          .where((pick) => int.tryParse(pick['round'].toString()) == round)
          .toList();
      
      await db.collection('precomputedAnalytics').doc('positionsByPickRound$round').set({
        'data': roundPicks,
        'lastUpdated': DateTime.now(),
      });
    }
    
    // Check the counts for diagnostics
    final pick1Data = correctedPickList.firstWhere(
      (pick) => pick['pick'] == 1, 
      orElse: () => {'totalDrafts': 0, 'positions': []}
    );
    
    setState(() {
      _isLoading = false;
      _statusMessage = 'Position counts fixed!\n'
          '- Processed $processedCount documents\n'
          '- Pick #1 total count: ${pick1Data['totalDrafts']}\n'
          '- Total picks fixed: ${correctedPickList.length}\n'
          '- Most common position at Pick #1: ${pick1Data['positions'].isNotEmpty ? pick1Data['positions'][0]['position'] : "None"} '
          '(${pick1Data['positions'].isNotEmpty ? pick1Data['positions'][0]['count'] : 0} drafts)';
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _statusMessage = 'Error fixing pick counts: $e';
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
  onPressed: _fixPickCountsInPositionsByPick,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.build),
      SizedBox(width: 8),
      Text('Fix Pick Counts'),
    ],
  ),
),
ElevatedButton(
  onPressed: _resetPrecomputedAnalytics,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
  ),
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.delete_forever),
      SizedBox(width: 8),
      Text('Reset All Precomputed Data'),
    ],
  ),
),
ElevatedButton(
  onPressed: _fetchAnalyticsStats,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.amber,
    foregroundColor: Colors.black,
  ),
  child: const Text('Run Analytics Diagnostic'),
),
ElevatedButton(
  onPressed: _checkAnalyticsProcessing,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.amber,
    foregroundColor: Colors.black,
  ),
  child: const Text('Run Analytics Diagnostic'),
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