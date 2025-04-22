// lib/widgets/admin/emergency_analytics_processor.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyAnalyticsProcessorScreen extends StatefulWidget {
  const EmergencyAnalyticsProcessorScreen({super.key});

  @override
  State<EmergencyAnalyticsProcessorScreen> createState() => _EmergencyAnalyticsProcessorScreenState();
}

class _EmergencyAnalyticsProcessorScreenState extends State<EmergencyAnalyticsProcessorScreen> {
  String status = 'idle';
  int progress = 0;
  String? error;
  Map<String, dynamic> results = {};
  int batchSize = 100;
  String message = '';

  Future<void> processAnalytics() async {
    setState(() {
      status = 'processing';
      progress = 0;
      message = 'Initializing analytics processing...';
      error = null;
    });

    try {
      final db = FirebaseFirestore.instance;

      // Create metadata record
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'lastUpdated': DateTime.now(),
        'inProgress': true,
        'documentsProcessed': 0,
      });

      // Data structures
      List<Map<String, dynamic>> draftAnalytics = [];
      int processedCount = 0;
      DocumentSnapshot? lastDoc;
      final positionDistribution = {
        'overall': {'total': 0, 'positions': <String, dynamic>{}},
        'byTeam': <String, dynamic>{},
      };
      final teamNeeds = <String, Map<String, int>>{};
      final positionsByPick = <String, Map<String, dynamic>>{};
      final playersByPick = <String, Map<String, dynamic>>{};
      final playerDeviations = <String, Map<String, dynamic>>{};

      // Collect all draftAnalytics in batches
      setState(() => message = 'Collecting draft analytics data...');
      while (true) {
        Query query = db.collection('draftAnalytics').limit(batchSize);
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        final snapshot = await query.get();
        if (snapshot.docs.isEmpty) break;
        for (final doc in snapshot.docs) {
          draftAnalytics.add(doc.data() as Map<String, dynamic>);
        }
        processedCount += snapshot.docs.length;
        setState(() {
          progress = (processedCount / (processedCount + 1000) * 50).clamp(0, 50).toInt();
          message = 'Collected $processedCount records...';
        });
        lastDoc = snapshot.docs.last;
      }

      setState(() => message = 'Processing ${draftAnalytics.length} records...');

      // Process analytics
      for (int i = 0; i < draftAnalytics.length; i++) {
        final draft = draftAnalytics[i];
        final picks = draft['picks'] as List<dynamic>? ?? [];
        
        for (final pick in picks) {
          if (pick == null) continue;
          
          final position = pick['position'] as String? ?? 'Unknown';
          final team = pick['actualTeam'] as String? ?? 'Unknown';
          
          // Overall counts
          if (!positionDistribution.containsKey('overall')) {
            positionDistribution['overall'] = {'total': 0, 'positions': <String, dynamic>{}};
          }
          
          positionDistribution['overall']!['total'] = (positionDistribution['overall']!['total'] as int) + 1;
          
          if (!positionDistribution['overall']!.containsKey('positions')) {
            positionDistribution['overall']!['positions'] = <String, dynamic>{};
          }
          
          if (!positionDistribution['overall']!['positions'].containsKey(position)) {
            positionDistribution['overall']!['positions'][position] = 0;
          }
          
          positionDistribution['overall']!['positions'][position] = 
              (positionDistribution['overall']!['positions'][position] as int) + 1;
          
          // Team-specific counts
          if (!positionDistribution.containsKey('byTeam')) {
            positionDistribution['byTeam'] = <String, dynamic>{};
          }
          
          if (!positionDistribution['byTeam']!.containsKey(team)) {
            positionDistribution['byTeam']![team] = {'total': 0, 'positions': <String, dynamic>{}};
          }
          
          positionDistribution['byTeam']![team]['total'] = 
              (positionDistribution['byTeam']![team]['total'] as int) + 1;
          
          if (!positionDistribution['byTeam']![team].containsKey('positions')) {
            positionDistribution['byTeam']![team]['positions'] = <String, dynamic>{};
          }
          
          if (!positionDistribution['byTeam']![team]['positions'].containsKey(position)) {
            positionDistribution['byTeam']![team]['positions'][position] = 0;
          }
          
          positionDistribution['byTeam']![team]['positions'][position] = 
              (positionDistribution['byTeam']![team]['positions'][position] as int) + 1;
          
          // Process team needs (focus on early round picks 1-3)
          final roundStr = pick['round'] as String? ?? '0';
          final round = int.tryParse(roundStr) ?? 0;
          
          if (round <= 3) {
            if (!teamNeeds.containsKey(team)) {
              teamNeeds[team] = <String, int>{};
            }
            
            if (!teamNeeds[team]!.containsKey(position)) {
              teamNeeds[team]![position] = 0;
            }
            
            // Apply round weighting: Round 1 = 3x, Round 2 = 2x, Round 3 = 1x
            final weight = 4 - round;
            teamNeeds[team]![position] = (teamNeeds[team]![position] ?? 0) + weight;
          }

          // Positions by pick
          final pickNumber = pick['pickNumber'].toString();
          if (!positionsByPick.containsKey(pickNumber)) {
            positionsByPick[pickNumber] = {'total': 0, 'positions': <String, int>{}, 'round': pick['round']};
          }
          positionsByPick[pickNumber]!['total'] = (positionsByPick[pickNumber]!['total'] as int) + 1;
          
          if (!positionsByPick[pickNumber]!.containsKey('positions')) {
            positionsByPick[pickNumber]!['positions'] = <String, int>{};
          }
          
          if (!positionsByPick[pickNumber]!['positions'].containsKey(position)) {
            positionsByPick[pickNumber]!['positions'][position] = 0;
          }
          
          positionsByPick[pickNumber]!['positions'][position] = 
              (positionsByPick[pickNumber]!['positions'][position] as int) + 1;
          
          // Players by pick
          if (!playersByPick.containsKey(pickNumber)) {
            playersByPick[pickNumber] = {'total': 0, 'players': <String, dynamic>{}};
          }
          playersByPick[pickNumber]!['total'] = (playersByPick[pickNumber]!['total'] as int) + 1;
          
          final playerKey = '${pick['playerName']}|${pick['position']}';
          if (!playersByPick[pickNumber]!['players'].containsKey(playerKey)) {
            playersByPick[pickNumber]!['players'][playerKey] = {
              'player': pick['playerName'],
              'position': pick['position'],
              'school': pick['school'],
              'rank': pick['playerRank'],
              'count': 0,
            };
          }
          playersByPick[pickNumber]!['players'][playerKey]['count'] = 
              (playersByPick[pickNumber]!['players'][playerKey]['count'] as int) + 1;
          
          // Player deviations
          final deviation = (pick['pickNumber'] ?? 0) - (pick['playerRank'] ?? 0);
          if (!playerDeviations.containsKey(playerKey)) {
            playerDeviations[playerKey] = {
              'name': pick['playerName'],
              'position': pick['position'],
              'school': pick['school'],
              'deviations': <int>[],
            };
          }
          
          if (!playerDeviations[playerKey]!.containsKey('deviations')) {
            playerDeviations[playerKey]!['deviations'] = <int>[];
          }
          
          (playerDeviations[playerKey]!['deviations'] as List).add(deviation);
        }
        
        if (i % 100 == 0) {
          setState(() {
            progress = 50 + ((i / draftAnalytics.length) * 50).toInt();
            message = 'Processing record ${i + 1} of ${draftAnalytics.length}...';
          });
        }
      }

      // Format position distribution percentages
      final overallTotal = positionDistribution['overall']!['total'] as int;
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
        final teamTotal = data['total'] as int;
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
        final total = data['total'] as int;
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
        final total = data['total'] as int;
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
        final sum = deviations.fold<num>(0, (a, b) => a + b);
        final avg = sum / deviations.length;
        final playerData = {
          'name': player['name'],
          'position': player['position'],
          'avgDeviation': avg.toStringAsFixed(1),
          'sampleSize': deviations.length,
          'school': player['school'],
        };
        formattedPlayerDeviations.add(playerData);
        
        final position = player['position'] as String;
        if (!playerDeviationsByPosition.containsKey(position)) {
          playerDeviationsByPosition[position] = [];
        }
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

      // Save analytics to Firestore
      setState(() => message = 'Saving analytics to Firestore...');
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
        'sampleSize': draftAnalytics.length,
        'positionSampleSizes': playerDeviationsByPosition.map((k, v) => MapEntry(k, v.length)),
        'lastUpdated': DateTime.now(),
      });
      
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'lastUpdated': DateTime.now(),
        'documentsProcessed': processedCount,
        'inProgress': false,
      });

      setState(() {
        status = 'success';
        progress = 100;
        message = 'Analytics processing completed successfully!';
        results = {
          'totalRecords': draftAnalytics.length,
          'teamNeeds': formattedTeamNeeds.length,
          'playerDeviations': formattedPlayerDeviations.length,
        };
      });
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
        title: const Text('Emergency Analytics Processor'),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Emergency Analytics Processor',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
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
                
                if (status == 'success')
                  Container(
                    color: Colors.green.shade50,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Success!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Processed ${results['totalRecords'] ?? 0} draft records.'),
                        const SizedBox(height: 4),
                        Text('Generated team needs for ${results['teamNeeds'] ?? 0} teams.'),
                        const SizedBox(height: 4),
                        Text('Analyzed ${results['playerDeviations'] ?? 0} players with deviation data.'),
                        const SizedBox(height: 8),
                        const Text('You can now view community analytics in your app!', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Batch Size:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: batchSize.toString(),
                        keyboardType: TextInputType.number,
                        enabled: status != 'processing',
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed >= 10 && parsed <= 500) {
                            setState(() => batchSize = parsed);
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                Text(
                  'Smaller batch sizes are safer but slower. Use 100-200 for most cases.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: status == 'processing' ? null : processAnalytics,
                    child: Text(
                      status == 'processing' ? 'Processing...' : 'Start Analytics Processing',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}