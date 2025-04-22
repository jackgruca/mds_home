// lib/widgets/admin/incremental_analytics_processor.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IncrementalAnalyticsProcessor extends StatefulWidget {
  const IncrementalAnalyticsProcessor({super.key});

  @override
  State<IncrementalAnalyticsProcessor> createState() => _IncrementalAnalyticsProcessorState();
}

class _IncrementalAnalyticsProcessorState extends State<IncrementalAnalyticsProcessor> {
  String status = 'idle';
  int progress = 0;
  String? error;
  Map<String, dynamic> results = {};
  int batchSize = 100;
  String message = '';
  int maxRecordsToProcess = 10000; // New parameter to limit processing
  int startAtRecord = 0; // New parameter to start at a specific point
  
  // Store state in Firestore for resumption
  Map<String, dynamic> processingState = {
    'position_distribution': {'overall': {'total': 0, 'positions': <String, dynamic>{}}, 'byTeam': <String, dynamic>{}},
    'team_needs': <String, Map<String, int>>{},
    'positions_by_pick': <String, Map<String, dynamic>>{},
    'players_by_pick': <String, Map<String, dynamic>>{},
    'player_deviations': <String, Map<String, dynamic>>{},
    'records_processed': 0,
    'last_processed_id': null,
  };
  
  // Controllers for form inputs
  final TextEditingController _batchSizeController = TextEditingController(text: '100');
  final TextEditingController _maxRecordsController = TextEditingController(text: '10000');
  final TextEditingController _startAtController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadProcessingState();
  }
  
  @override
  void dispose() {
    _batchSizeController.dispose();
    _maxRecordsController.dispose();
    _startAtController.dispose();
    super.dispose();
  }
  
  // Load existing processing state from Firestore
  Future<void> _loadProcessingState() async {
    try {
      final db = FirebaseFirestore.instance;
      final doc = await db.collection('precomputedAnalytics').doc('processing_state').get();
      
      if (doc.exists && doc.data() != null) {
        setState(() {
          processingState = doc.data()!;
          startAtRecord = processingState['records_processed'] ?? 0;
          _startAtController.text = startAtRecord.toString();
          message = 'Loaded processing state. $startAtRecord records previously processed.';
        });
      }
    } catch (e) {
      print('Error loading processing state: $e');
    }
  }
  
  // Save processing state to Firestore
  Future<void> _saveProcessingState() async {
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('precomputedAnalytics').doc('processing_state').set(processingState);
      print('Processing state saved successfully');
    } catch (e) {
      print('Error saving processing state: $e');
    }
  }

  // Modify the _calculateAnalytics function in lib/widgets/admin/incremental_analytics_processor.dart

Future<void> processAnalytics() async {
  setState(() {
    status = 'processing';
    progress = 0;
    message = 'Initializing analytics processing...';
    error = null;
    
    // Update parameters from controllers
    batchSize = int.tryParse(_batchSizeController.text) ?? 100;
    maxRecordsToProcess = int.tryParse(_maxRecordsController.text) ?? 10000;
    startAtRecord = int.tryParse(_startAtController.text) ?? 0;
  });

  try {
    final db = FirebaseFirestore.instance;

    // Update metadata record
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'lastUpdated': DateTime.now(),
      'inProgress': true,
      'documentsProcessed': startAtRecord,
    });

    // Critical fix: Ensure we're using empty maps/counts when starting from scratch
    final bool isStartingFresh = startAtRecord == 0;
    
    // Load the processing state to local variables for processing
    Map<String, dynamic> positionDistribution = isStartingFresh ? {
      'overall': {'total': 0, 'positions': <String, dynamic>{}},
      'byTeam': <String, dynamic>{},
    } : processingState['position_distribution'];
    
    Map<String, Map<String, int>> teamNeeds = isStartingFresh ? {} : 
      Map<String, Map<String, int>>.from(
        (processingState['team_needs'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, Map<String, int>.from(value as Map<String, dynamic>))
        )
      );
    
    Map<String, Map<String, dynamic>> positionsByPick = isStartingFresh ? {} :
      Map<String, Map<String, dynamic>>.from(
        processingState['positions_by_pick'] as Map<String, dynamic>
      );
    
    Map<String, Map<String, dynamic>> playersByPick = isStartingFresh ? {} :
      Map<String, Map<String, dynamic>>.from(
        processingState['players_by_pick'] as Map<String, dynamic>
      );
    
    Map<String, Map<String, dynamic>> playerDeviations = isStartingFresh ? {} :
      Map<String, Map<String, dynamic>>.from(
        processingState['player_deviations'] as Map<String, dynamic>
      );
    
    // Start with previously skipped documents if resuming
    int recordsToProcess = maxRecordsToProcess;
    int processedCount = startAtRecord;
    DocumentSnapshot? lastDoc;
    
    if (startAtRecord > 0 && processingState['last_processed_id'] != null) {
      // Try to get the last document we processed
      try {
        final lastDocRef = await db.collection('draftAnalytics').doc(processingState['last_processed_id']).get();
        if (lastDocRef.exists) {
          lastDoc = lastDocRef;
          setState(() {
            message = 'Resuming from document ID: ${processingState['last_processed_id']}';
          });
        }
      } catch (e) {
        print('Error getting last document: $e');
        setState(() {
          message = 'Could not find last processed document. Starting from beginning of remaining data.';
        });
      }
    }

    // Process data in batches
    int totalProcessed = 0;
    bool shouldContinue = true;
    
    while (shouldContinue && totalProcessed < recordsToProcess) {
      // Build query
      Query query = db.collection('draftAnalytics').limit(batchSize);
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        setState(() {
          message = 'No more documents to process. Analytics complete!';
        });
        break;
      }
      
      // Process each document in the batch
      int batchPickCount = 0; // Count picks for verification
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final picks = List<dynamic>.from(data['picks'] ?? []);
        
        // For each pick in this draft
        for (final pick in picks) {
          if (pick == null) continue;
          
          batchPickCount++; // Increment pick counter
          
          final position = pick['position'] as String? ?? 'Unknown';
          final team = pick['actualTeam'] as String? ?? 'Unknown';
          
          // Initialize positionDistribution structures if needed
          if (!positionDistribution.containsKey('overall')) {
            positionDistribution['overall'] = {'total': 0, 'positions': <String, dynamic>{}};
          }
          
          if (!positionDistribution['overall'].containsKey('positions')) {
            positionDistribution['overall']['positions'] = <String, dynamic>{};
          }
          
          if (!positionDistribution.containsKey('byTeam')) {
            positionDistribution['byTeam'] = <String, dynamic>{};
          }
          
          // Update overall counts
          positionDistribution['overall']['total'] = (positionDistribution['overall']['total'] as int? ?? 0) + 1;
          
          if (!positionDistribution['overall']['positions'].containsKey(position)) {
            positionDistribution['overall']['positions'][position] = 0;
          }
          positionDistribution['overall']['positions'][position] = 
              (positionDistribution['overall']['positions'][position] as int? ?? 0) + 1;
          
          // Update team-specific counts
          if (!positionDistribution['byTeam'].containsKey(team)) {
            positionDistribution['byTeam'][team] = {'total': 0, 'positions': <String, dynamic>{}};
          }
          
          positionDistribution['byTeam'][team]['total'] = 
              (positionDistribution['byTeam'][team]['total'] as int? ?? 0) + 1;
          
          if (!positionDistribution['byTeam'][team].containsKey('positions')) {
            positionDistribution['byTeam'][team]['positions'] = <String, dynamic>{};
          }
          
          if (!positionDistribution['byTeam'][team]['positions'].containsKey(position)) {
            positionDistribution['byTeam'][team]['positions'][position] = 0;
          }
          
          positionDistribution['byTeam'][team]['positions'][position] = 
              (positionDistribution['byTeam'][team]['positions'][position] as int? ?? 0) + 1;
          
          // Process team needs (focus on early round picks 1-3)
          final roundStr = pick['round'] as String? ?? '0';
          final round = int.tryParse(roundStr) ?? 0;
          
          if (round <= 3) {
            teamNeeds.putIfAbsent(team, () => <String, int>{});
            teamNeeds[team]!.putIfAbsent(position, () => 0);
            
            // Apply round weighting: Round 1 = 3x, Round 2 = 2x, Round 3 = 1x
            final weight = 4 - round;
            teamNeeds[team]![position] = (teamNeeds[team]![position] ?? 0) + weight;
          }
          
          // Process positions by pick
          final pickNumber = pick['pickNumber'].toString();
          positionsByPick.putIfAbsent(pickNumber, () => {'total': 0, 'positions': <String, int>{}, 'round': pick['round']});
          positionsByPick[pickNumber]!['total'] = (positionsByPick[pickNumber]!['total'] as int? ?? 0) + 1;
          
          if (!positionsByPick[pickNumber]!.containsKey('positions')) {
            positionsByPick[pickNumber]!['positions'] = <String, int>{};
          }
          
          final posPickPos = positionsByPick[pickNumber]!['positions'] as Map<String, dynamic>;
          posPickPos[position] = (posPickPos[position] as int? ?? 0) + 1;
          
          // Process players by pick
          playersByPick.putIfAbsent(pickNumber, () => {'total': 0, 'players': <String, dynamic>{}});
          playersByPick[pickNumber]!['total'] = (playersByPick[pickNumber]!['total'] as int? ?? 0) + 1;
          
          final playerKey = '${pick['playerName']}|${pick['position']}';
          
          if (!playersByPick[pickNumber]!.containsKey('players')) {
            playersByPick[pickNumber]!['players'] = <String, dynamic>{};
          }
          
          final playersMap = playersByPick[pickNumber]!['players'] as Map<String, dynamic>;
          
          if (!playersMap.containsKey(playerKey)) {
            playersMap[playerKey] = {
              'player': pick['playerName'],
              'position': pick['position'],
              'school': pick['school'],
              'rank': pick['playerRank'],
              'count': 0,
            };
          }
          
          playersMap[playerKey]['count'] = (playersMap[playerKey]['count'] as int? ?? 0) + 1;
          
          // Process player deviations
          final deviation = (pick['pickNumber'] ?? 0) - (pick['playerRank'] ?? 0);
          playerDeviations.putIfAbsent(playerKey, () => {
            'name': pick['playerName'],
            'position': pick['position'],
            'school': pick['school'],
            'deviations': <dynamic>[],
          });
          
          if (!playerDeviations[playerKey]!.containsKey('deviations')) {
            playerDeviations[playerKey]!['deviations'] = <dynamic>[];
          }
          
          (playerDeviations[playerKey]!['deviations'] as List).add(deviation);
        }
        
        // Save the last processed document ID for resumption
        lastDoc = doc;
        processingState['last_processed_id'] = doc.id;
        
        totalProcessed++;
        processedCount++;
        
        // Check if we've reached our batch limit
        if (totalProcessed >= recordsToProcess) {
          shouldContinue = false;
          break;
        }
      }
      
      // CRITICAL FIX: Log batch pick count for diagnostics
      debugPrint('Processed $batchPickCount picks in this batch of ${snapshot.docs.length} documents');
      
      // Update progress
      setState(() {
        progress = (totalProcessed / recordsToProcess * 100).round();
        message = 'Processed $totalProcessed of $recordsToProcess records (Total: $processedCount). Picks in last batch: $batchPickCount';
      });
      
      // Save interim state every 1000 records
      if (totalProcessed % 1000 == 0 || !shouldContinue) {
        // Update processed count
        processingState['records_processed'] = processedCount;
        processingState['position_distribution'] = positionDistribution;
        processingState['team_needs'] = teamNeeds;
        processingState['positions_by_pick'] = positionsByPick;
        processingState['players_by_pick'] = playersByPick;
        processingState['player_deviations'] = playerDeviations;
        
        await _saveProcessingState();
        
        // Update metadata
        await db.collection('precomputedAnalytics').doc('metadata').set({
          'lastUpdated': DateTime.now(),
          'inProgress': true,
          'documentsProcessed': processedCount,
        }, SetOptions(merge: true));
        
        setState(() {
          message = 'Saved interim state. Processed $totalProcessed of $recordsToProcess records (Total: $processedCount)';
        });
      }
    }
    
    // Final processing and formatting results before saving to Firestore collections
    if (processedCount > 0) {
      setState(() => message = 'Formatting results and saving to Firestore...');
      
      // Format position distribution percentages
      final overallTotal = positionDistribution['overall']!['total'] as int? ?? 0;
      Map<String, dynamic> formattedPositions = {};
      
      (positionDistribution['overall']!['positions'] as Map<String, dynamic>).forEach((position, count) {
        formattedPositions[position] = {
          'count': count,
          'percentage': '${((count as int) / overallTotal * 100).toStringAsFixed(1)}%',
        };
      });
      
      positionDistribution['overall']!['positions'] = formattedPositions;
      
      Map<String, dynamic> formattedTeamPositions = {};
      (positionDistribution['byTeam'] as Map<String, dynamic>).forEach((team, data) {
        final teamTotal = data['total'] as int? ?? 0;
        Map<String, dynamic> teamFormattedPositions = {};
        
        (data['positions'] as Map<String, dynamic>).forEach((position, count) {
          teamFormattedPositions[position] = {
            'count': count,
            'percentage': '${((count as int) / teamTotal * 100).toStringAsFixed(1)}%',
          };
        });
        
        formattedTeamPositions[team] = {
          'total': teamTotal,
          'positions': teamFormattedPositions,
        };
      });
      
      positionDistribution['byTeam'] = formattedTeamPositions;
      
      // Format team needs as sorted arrays
      final formattedTeamNeeds = <String, List<String>>{};
      teamNeeds.forEach((team, needs) {
        final sorted = needs.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        formattedTeamNeeds[team] = sorted.take(5).map((e) => e.key).toList();
      });
      
      // Format positions by pick
      final formattedPositionsByPick = positionsByPick.entries.map((entry) {
        final pickNumber = int.tryParse(entry.key) ?? 0;
        final data = entry.value;
        final total = data['total'] as int? ?? 0;
        final positions = (data['positions'] as Map<String, dynamic>)
            .entries
            .map((e) => {
                  'position': e.key,
                  'count': e.value,
                  'percentage': '${((e.value as int) / total * 100).toStringAsFixed(1)}%',
                })
            .toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
        return {
          'pick': pickNumber,
          'round': data['round'],
          'positions': positions,
          'totalDrafts': total,
        };
      }).toList()
        ..sort((a, b) => (a['pick'] as int).compareTo(b['pick'] as int));
      
      // Format players by pick
      final formattedPlayersByPick = playersByPick.entries.map((entry) {
        final pickNumber = int.tryParse(entry.key) ?? 0;
        final data = entry.value;
        final total = data['total'] as int? ?? 0;
        final players = (data['players'] as Map<String, dynamic>)
            .values
            .map((player) => {
                  ...player,
                  'percentage': '${((player['count'] as int) / total * 100).toStringAsFixed(1)}%',
                })
            .toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
        return {
          'pick': pickNumber,
          'players': players.take(3).toList(),
          'totalDrafts': total,
        };
      }).toList()
        ..sort((a, b) => (a['pick'] as int).compareTo(b['pick'] as int));
      
      // Format player deviations
      final formattedPlayerDeviations = <Map<String, dynamic>>[];
      final playerDeviationsByPosition = <String, List<Map<String, dynamic>>>{};
      playerDeviations.forEach((playerKey, player) {
        final deviations = player['deviations'] as List;
        if (deviations.length < 3) return;
        final sum = deviations.fold<num>(0, (a, b) => a + (b as num));
        final avg = sum / deviations.length;
        final playerData = {
          'name': player['name'],
          'position': player['position'],
          'avgDeviation': avg.toStringAsFixed(1),
          'sampleSize': deviations.length,
          'school': player['school'],
        };
        formattedPlayerDeviations.add(playerData);
        
        final position = player['position'] as String? ?? 'Unknown';
        playerDeviationsByPosition.putIfAbsent(position, () => []);
        playerDeviationsByPosition[position]!.add(playerData);
      });
      
      // Sort by absolute deviation value
      formattedPlayerDeviations.sort((a, b) {
        final aDev = double.tryParse(a['avgDeviation'] as String) ?? 0;
        final bDev = double.tryParse(b['avgDeviation'] as String) ?? 0;
        return bDev.abs().compareTo(aDev.abs());
      });
      
      // Sort position-specific lists
      playerDeviationsByPosition.forEach((position, list) {
        list.sort((a, b) {
          final aDev = double.tryParse(a['avgDeviation'] as String) ?? 0;
          final bDev = double.tryParse(b['avgDeviation'] as String) ?? 0;
          return bDev.abs().compareTo(aDev.abs());
        });
      });
      
      // Process round-specific data
      final positionsByPickByRound = <int, List<Map<String, dynamic>>>{};
      for (int round = 1; round <= 7; round++) {
        positionsByPickByRound[round] = formattedPositionsByPick
            .where((item) => int.tryParse(item['round'].toString()) == round)
            .toList();
      }
      
      // IMPORTANT: Print diagnostic information before saving
      debugPrint('ANALYTICS SUMMARY:');
      debugPrint('- Total documents processed: $processedCount');
      debugPrint('- Total positions by pick entries: ${formattedPositionsByPick.length}');
      debugPrint('- Position #1 total: ${formattedPositionsByPick.firstWhere((p) => p['pick'] == 1, orElse: () => {'totalDrafts': 0})['totalDrafts']}');
      debugPrint('- Team needs count: ${formattedTeamNeeds.length}');
      debugPrint('- Player deviations count: ${formattedPlayerDeviations.length}');
      
      // Save analytics to Firestore
      setState(() => message = 'Saving analytics to Firestore...');
      final db = FirebaseFirestore.instance;
      
      await db.collection('precomputedAnalytics').doc('positionDistribution').set({
        'overall': positionDistribution['overall'],
        'byTeam': positionDistribution['byTeam'],
        'lastUpdated': DateTime.now(),
      });
      
      await db.collection('precomputedAnalytics').doc('teamNeeds').set({
        'needs': formattedTeamNeeds,
        'year': DateTime.now().year,
        'lastUpdated': DateTime.now(),
      });
      
      await db.collection('precomputedAnalytics').doc('positionsByPick').set({
        'data': formattedPositionsByPick,
        'lastUpdated': DateTime.now(),
      });
      
      for (int round = 1; round <= 7; round++) {
        await db.collection('precomputedAnalytics').doc('positionsByPickRound$round').set({
          'data': positionsByPickByRound[round],
          'lastUpdated': DateTime.now(),
        });
      }
      
      await db.collection('precomputedAnalytics').doc('playersByPick').set({
        'data': formattedPlayersByPick,
        'lastUpdated': DateTime.now(),
      });
      
      await db.collection('precomputedAnalytics').doc('playerDeviations').set({
        'players': formattedPlayerDeviations,
        'byPosition': playerDeviationsByPosition,
        'sampleSize': processedCount,
        'positionSampleSizes': playerDeviationsByPosition.map((k, v) => MapEntry(k, v.length)),
        'lastUpdated': DateTime.now(),
      });
      
      // Update metadata
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'lastUpdated': DateTime.now(),
        'documentsProcessed': processedCount,
        'inProgress': false,
      });
      
      // Final state update
      setState(() {
        status = (totalProcessed < recordsToProcess) ? 'partial' : 'success';
        progress = 100;
        message = (totalProcessed < recordsToProcess) 
          ? 'Analytics partially processed. Processed $totalProcessed records (Total: $processedCount).'
          : 'Analytics processing completed! Processed $totalProcessed records (Total: $processedCount).';
        results = {
          'totalRecords': processedCount,
          'teamNeeds': formattedTeamNeeds.length,
          'playerDeviations': formattedPlayerDeviations.length,
        };
      });
    }
  } catch (e) {
    print('Error processing analytics: $e');
    setState(() {
      status = 'error';
      error = e.toString();
    });
    
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'lastUpdated': DateTime.now(),
        'error': e.toString(),
        'inProgress': false,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incremental Analytics Processor'),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Incremental Analytics Processor',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Process in smaller chunks to avoid timeouts',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  
                  if (status == 'error')
                    Container(
                      color: Colors.red.shade50,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(error ?? 'Unknown error', style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  
                  if (status == 'success' || status == 'partial')
                    Container(
                      color: status == 'success' ? Colors.green.shade50 : Colors.amber.shade50,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status == 'success' ? 'Success!' : 'Partial Success',
                            style: TextStyle(
                              color: status == 'success' ? Colors.green : Colors.amber.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 18
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Processed ${results['totalRecords'] ?? 0} total draft records.'),
                          const SizedBox(height: 4),
                          Text('Generated team needs for ${results['teamNeeds'] ?? 0} teams.'),
                          const SizedBox(height: 4),
                          Text('Analyzed ${results['playerDeviations'] ?? 0} players with deviation data.'),
                          const SizedBox(height: 8),
                          const Text('Your analytics data is ready to view!', 
                            style: TextStyle(fontWeight: FontWeight.bold)),
                          if (status == 'partial')
                            const Text('You can continue processing more records if needed.',
                              style: TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Processing Controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Processing Settings',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        // Batch Size
                        Row(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text('Batch Size:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _batchSizeController,
                                keyboardType: TextInputType.number,
                                enabled: status != 'processing',
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  helperText: 'Number of records to fetch at once (50-200)',
                                  helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Start At
                        Row(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text('Start At Record:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _startAtController,
                                keyboardType: TextInputType.number,
                                enabled: status != 'processing',
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  helperText: 'Resume from specific record number',
                                  helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Max Records
                        Row(
                          children: [
                            const Expanded(
                              flex: 2,
                              child: Text('Max Records to Process:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _maxRecordsController,
                                keyboardType: TextInputType.number,
                                enabled: status != 'processing',
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  helperText: 'Process fewer records to avoid timeouts (1000-5000)',
                                  helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: status == 'processing' 
                        ? null 
                        : processAnalytics,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        status == 'processing' ? 'Processing...' : 'Start Incremental Processing',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  
                  if (status == 'processing') ...[
                    const SizedBox(height: 24),
                    LinearProgressIndicator(value: progress / 100),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                  ],
                  
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tips for Processing Large Datasets:', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('• Start with 1,000-5,000 records at a time to avoid timeouts'),
                        Text('• Use a batch size of 50-100 to reduce memory usage'),
                        Text('• The processor saves progress every 1,000 records'),
                        Text('• You can resume from where you left off if processing is interrupted'),
                        Text('• Run multiple smaller batches rather than one large batch'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
