import 'package:flutter/material.dart';
import '../services/data_source_manager.dart';
import '../services/data_source_interface.dart';

/// Test screen for validating CSV vs Firebase data sources
class DataSourceTestScreen extends StatefulWidget {
  const DataSourceTestScreen({Key? key}) : super(key: key);

  @override
  State<DataSourceTestScreen> createState() => _DataSourceTestScreenState();
}

class _DataSourceTestScreenState extends State<DataSourceTestScreen> {
  final DataSourceManager _manager = DataSourceManager();
  bool _isLoading = false;
  String _status = '';
  List<Map<String, dynamic>> _testResults = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAndTest();
  }
  
  Future<void> _initializeAndTest() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing data sources...';
    });
    
    await _manager.initialize();
    await _runTests();
  }
  
  Future<void> _runTests() async {
    setState(() {
      _testResults.clear();
      _status = 'Running tests on ${_manager.currentSource.sourceType}...';
    });
    
    // Test 1: Load data
    final loadTest = await _testQuery(
      'Load Player Stats',
      () => _manager.currentSource.queryPlayerStats(limit: 10),
    );
    
    // Test 2: Filter by position
    final positionTest = await _testQuery(
      'Filter by Position (QB)',
      () => _manager.currentSource.queryPlayerStats(position: 'QB', limit: 5),
    );
    
    // Test 3: Top performers
    final topTest = await _testQuery(
      'Top Passing Yards',
      () => _manager.currentSource.getTopPerformers(stat: 'passing_yards', limit: 5),
    );
    
    // Test 4: Search
    final searchTest = await _testQuery(
      'Search "Mahomes"',
      () => _manager.currentSource.searchPlayers('Mahomes'),
    );
    
    setState(() {
      _isLoading = false;
      _status = 'Tests complete!';
      _testResults = [loadTest, positionTest, topTest, searchTest];
    });
  }
  
  Future<Map<String, dynamic>> _testQuery(
    String name,
    Future<List<Map<String, dynamic>>> Function() query,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final results = await _manager.trackPerformance(name, query);
      stopwatch.stop();
      
      return {
        'name': name,
        'success': true,
        'duration': stopwatch.elapsedMilliseconds,
        'count': results.length,
        'sample': results.isNotEmpty ? results.first['player_display_name'] ?? 'Unknown' : 'No results',
      };
    } catch (e) {
      stopwatch.stop();
      
      return {
        'name': name,
        'success': false,
        'duration': stopwatch.elapsedMilliseconds,
        'error': e.toString(),
      };
    }
  }
  
  Future<void> _toggleSource() async {
    setState(() {
      _isLoading = true;
      _status = 'Switching data source...';
    });
    
    final success = await _manager.toggleDataSource();
    
    if (success) {
      await _runTests();
    } else {
      setState(() {
        _isLoading = false;
        _status = 'Failed to switch data source';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Source Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runTests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  'Current Source: ${_manager.currentSource.sourceType}',
                  style: Theme.of(context).textTheme.titleLarge,
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
          
          // Test results
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final test = _testResults[index];
                final success = test['success'] as bool;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      success ? Icons.check_circle : Icons.error,
                      color: success ? Colors.green : Colors.red,
                    ),
                    title: Text(test['name'] as String),
                    subtitle: success
                        ? Text('${test['duration']}ms • ${test['count']} results\nSample: ${test['sample']}')
                        : Text('Error: ${test['error']}'),
                    trailing: Text(
                      '${test['duration']}ms',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: success ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Performance comparison
          if (_manager.getMetrics().length > 5) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildComparisonReport(),
            ),
          ],
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _toggleSource,
                    icon: const Icon(Icons.swap_horiz),
                    label: Text('Switch to ${_manager.currentSourceType == DataSourceType.csv ? "Firebase" : "CSV"}'),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _manager.clearMetrics();
                    setState(() {
                      _testResults.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildComparisonReport() {
    final report = _manager.getComparisonReport();
    final csvStats = report['csv'] as Map<String, dynamic>;
    final firebaseStats = report['firebase'] as Map<String, dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Comparison',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn('CSV', csvStats),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatColumn('Firebase', firebaseStats),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(String title, Map<String, dynamic> stats) {
    final avgDuration = stats['avgDuration'] as int;
    final successRate = ((stats['successRate'] as double) * 100).toStringAsFixed(0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('Avg: ${avgDuration}ms'),
        Text('Success: $successRate%'),
        Text('Total: ${stats['totalQueries']}'),
      ],
    );
  }
}