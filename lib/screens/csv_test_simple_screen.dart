import 'package:flutter/material.dart';
import '../services/hybrid_data_service.dart';
import '../services/csv_debug_service.dart';

/// Simple test screen for CSV functionality
class CsvTestSimpleScreen extends StatefulWidget {
  const CsvTestSimpleScreen({Key? key}) : super(key: key);

  @override
  State<CsvTestSimpleScreen> createState() => _CsvTestSimpleScreenState();
}

class _CsvTestSimpleScreenState extends State<CsvTestSimpleScreen> {
  final HybridDataService _dataService = HybridDataService();
  bool _isLoading = true;
  String _status = 'Initializing...';
  List<Map<String, dynamic>> _playerData = [];
  String _dataSource = 'Unknown';
  
  @override
  void initState() {
    super.initState();
    _testCsvAndLoadData();
  }
  
  Future<void> _testCsvAndLoadData() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing CSV loading...';
    });
    
    // Run detailed debug first
    await CsvDebugService.debugCsvParsing();
    
    // First test if CSV loads at all
    final csvWorks = await _dataService.testCsvLoading();
    
    if (!csvWorks) {
      setState(() {
        _status = '❌ CSV loading failed - check console for errors';
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _status = 'Loading player data...';
    });
    
    try {
      // Try to load top QBs
      final startTime = DateTime.now();
      final players = await _dataService.getPlayerStats(
        position: 'QB',
        orderBy: 'passing_yards',
        limit: 10,
      );
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      
      // Check cache to see if we used CSV
      final cacheStats = _dataService.getCacheStats();
      _dataSource = cacheStats['playerStatsRecords'] > 0 ? 'CSV' : 'Firebase';
      
      setState(() {
        _playerData = players;
        _status = '✅ Loaded ${players.length} players in ${loadTime}ms from $_dataSource';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error loading data: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV Test - Simple'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () {
              _dataService.clearCache();
              _testCsvAndLoadData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _dataSource == 'CSV' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  'Data Source: $_dataSource',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _dataSource == 'CSV' ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_status),
                if (_isLoading) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
          
          // Player data
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _playerData.isEmpty
                    ? const Center(child: Text('No data loaded'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _playerData.length,
                        itemBuilder: (context, index) {
                          final player = _playerData[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(
                                player['player_display_name'] ?? player['player_name'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${player['recent_team'] ?? 'UNK'} • ${player['position'] ?? 'UNK'}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${player['passing_yards']?.toStringAsFixed(0) ?? '0'} YDS',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${player['passing_tds'] ?? 0} TD',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Debug info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Debug Info:', style: Theme.of(context).textTheme.titleSmall),
                Text('Cache Stats: ${_dataService.getCacheStats()}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}