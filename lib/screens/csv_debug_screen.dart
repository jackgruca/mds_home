import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class CsvDebugScreen extends StatefulWidget {
  const CsvDebugScreen({super.key});

  @override
  State<CsvDebugScreen> createState() => _CsvDebugScreenState();
}

class _CsvDebugScreenState extends State<CsvDebugScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allGameData = [];
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadAndTestCSV();
  }

  Future<void> _loadAndTestCSV() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Starting CSV load...\n';
    });
    
    try {
      // Load CSV data
      final csvString = await rootBundle.loadString('assets/data/player_game_stats_2024.csv');
      _debugInfo += 'CSV loaded, length: ${csvString.length}\n';
      
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
      _debugInfo += 'CSV parsed, rows: ${csvData.length}\n';
      
      if (csvData.isEmpty) {
        _debugInfo += 'CSV data is empty!\n';
        setState(() => _isLoading = false);
        return;
      }
      
      // Get headers
      final headers = csvData.first.map((e) => e.toString()).toList();
      _debugInfo += 'Headers (first 10): ${headers.take(10).join(', ')}\n';
      
      // Convert to list of maps
      _allGameData = csvData.skip(1).map((row) {
        final Map<String, dynamic> rowData = {};
        for (int i = 0; i < headers.length && i < row.length; i++) {
          rowData[headers[i]] = row[i];
        }
        return rowData;
      }).toList();
      
      _debugInfo += 'Total game records: ${_allGameData.length}\n';
      
      // Check positions
      if (_allGameData.isNotEmpty) {
        final positions = _allGameData.map((game) => game['position']?.toString()).toSet();
        _debugInfo += 'Unique positions: $positions\n';
        
        // Count by position
        final positionCounts = <String, int>{};
        for (final game in _allGameData) {
          final pos = game['position']?.toString() ?? 'Unknown';
          positionCounts[pos] = (positionCounts[pos] ?? 0) + 1;
        }
        _debugInfo += 'Position counts: $positionCounts\n';
        
        // Show sample records
        _debugInfo += '\nFirst QB record:\n';
        final qbRecord = _allGameData.firstWhere(
          (game) => game['position'] == 'QB', 
          orElse: () => {},
        );
        if (qbRecord.isNotEmpty) {
          _debugInfo += 'Player: ${qbRecord['player_name']}, Fantasy: ${qbRecord['fantasy_points_ppr']}\n';
        } else {
          _debugInfo += 'No QB records found!\n';
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      _debugInfo += 'Error: $e\n';
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CSV Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CSV Debug Information:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _debugInfo,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}