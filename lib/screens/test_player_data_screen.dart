import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/player_game_log.dart';

class TestPlayerDataScreen extends StatefulWidget {
  const TestPlayerDataScreen({super.key});

  @override
  State<TestPlayerDataScreen> createState() => _TestPlayerDataScreenState();
}

class _TestPlayerDataScreenState extends State<TestPlayerDataScreen> {
  bool _isLoading = true;
  String? _error;
  List<PlayerGameLog> _gameLogsCache = [];
  
  @override
  void initState() {
    super.initState();
    _loadTestData();
  }
  
  Future<void> _loadTestData() async {
    try {
      print('Loading CSV data...');
      final String csvString = await rootBundle.loadString('data/processed/player_stats/player_game_logs.csv');
      print('CSV loaded, length: ${csvString.length}');
      
      // Debug the raw CSV string
      final lines = csvString.split('\n').where((line) => line.trim().isNotEmpty).toList();
      print('CSV has ${lines.length} lines total');
      print('First line: ${lines.isNotEmpty ? lines.first : 'EMPTY'}');
      print('Second line: ${lines.length > 1 ? lines[1] : 'NO SECOND LINE'}');
      
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      print('Parsed ${csvData.length} rows');
      
      if (csvData.isNotEmpty) {
        print('Headers: ${csvData.first}');
        
        // Convert to objects
        _gameLogsCache = csvData.skip(1).map((row) {
          return PlayerGameLog.fromCsvRow(row);
        }).toList();
        
        print('Converted to ${_gameLogsCache.length} PlayerGameLog objects');
        
        if (_gameLogsCache.isNotEmpty) {
          final firstPlayer = _gameLogsCache.first;
          print('First player: ${firstPlayer.playerDisplayName} (${firstPlayer.position}) - ${firstPlayer.team} vs ${firstPlayer.opponentTeam}');
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading data: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Player Data')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Loaded ${_gameLogsCache.length} game logs'),
                      ),
                      if (_gameLogsCache.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Sample data:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ..._gameLogsCache.take(10).map((log) => Card(
                          margin: const EdgeInsets.all(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${log.playerDisplayName} (${log.position})', 
                                     style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${log.team} vs ${log.opponentTeam} - Week ${log.week}, ${log.season}'),
                                Text('Passing: ${log.completions}/${log.attempts}, ${log.passingYards} yds, ${log.passingTds} TD'),
                                Text('Rushing: ${log.carries} att, ${log.rushingYards} yds, ${log.rushingTds} TD'),
                                Text('Receiving: ${log.receptions}/${log.targets}, ${log.receivingYards} yds, ${log.receivingTds} TD'),
                                Text('Fantasy PPR: ${log.fantasyPointsPpr.toStringAsFixed(1)}'),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ],
                  ),
                ),
    );
  }
}