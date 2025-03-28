import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../services/enhanced_trade_manager.dart';
import '../utils/trade_testing_util.dart';

class TradeTestScreen extends StatefulWidget {
  const TradeTestScreen({super.key});

  @override
  _TradeTestScreenState createState() => _TradeTestScreenState();
}

class _TradeTestScreenState extends State<TradeTestScreen> {
  // Test state
  bool _isRunningTests = false;
  String _testResults = "No tests run yet";
  
  // Test data
  List<DraftPick> _draftOrder = [];
  List<Player> _players = [];
  List<TeamNeed> _teamNeeds = [];
  late EnhancedTradeManager _tradeManager;
  
  @override
  void initState() {
    super.initState();
    _initializeTestData();
  }
  
  void _initializeTestData() {
    // Generate test data
    _draftOrder = TradeTestingUtil.generateTestDraftOrder();
    _players = TradeTestingUtil.generateTestPlayers();
    _teamNeeds = TradeTestingUtil.generateTestTeamNeeds();
    
    // Create trade manager with test data
    _tradeManager = EnhancedTradeManager(
      draftOrder: _draftOrder,
      teamNeeds: _teamNeeds,
      availablePlayers: _players,
      userTeams: ['Team1'], // Just for testing
      enableVerboseLogging: true,
    );
  }
  
  void _runTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = "Running tests...";
    });
    
    try {
      // Run tests
      var results = TradeTestingUtil.runTradeTests(
        tradeManager: _tradeManager,
        testsCount: 20,
      );
      
      // Format results
      String formattedResults = '''
Tests completed successfully!

Tests Count: ${results['testsCount']}
Offers Generated: ${results['offersGenerated']}
Packages Generated: ${results['packageCount']}
Offer Rate: ${(results['offerRate'] * 100).toStringAsFixed(1)}%
Average Value Ratio: ${results['avgValueRatio'].toStringAsFixed(2)}
Min Value Ratio: ${results['minRatio'].toStringAsFixed(2)}
Max Value Ratio: ${results['maxRatio'].toStringAsFixed(2)}
QB-Targeted Offers: ${results['qbTargeted']}

Trade Log:
${_tradeManager.getTradeOperationLog()}
''';
      
      setState(() {
        _testResults = formattedResults;
        _isRunningTests = false;
      });
    } catch (e) {
      setState(() {
        _testResults = "Test error: $e";
        _isRunningTests = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade System Tests'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trade Logic Test Suite',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isRunningTests ? null : _runTests,
                  child: const Text('Run Tests'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isRunningTests ? null : _initializeTestData,
                  child: const Text('Reset Test Data'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Results:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_testResults),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}