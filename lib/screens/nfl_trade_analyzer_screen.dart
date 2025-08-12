// lib/screens/nfl_trade_analyzer_screen.dart

import 'package:flutter/material.dart';
import '../models/nfl_trade/nfl_player.dart';
import '../models/nfl_trade/nfl_team_info.dart';
import '../models/nfl_trade/trade_scenario.dart';
import '../services/nfl_trade_analyzer_service.dart';
import '../services/trade_data_service.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';

class NFLTradeAnalyzerScreen extends StatefulWidget {
  const NFLTradeAnalyzerScreen({super.key});

  @override
  State<NFLTradeAnalyzerScreen> createState() => _NFLTradeAnalyzerScreenState();
}

class _NFLTradeAnalyzerScreenState extends State<NFLTradeAnalyzerScreen> {
  NFLPlayer? selectedPlayer;
  NFLTeamInfo? selectedTargetTeam;
  List<TradeScenario> tradeScenarios = [];
  bool isAnalyzing = false;
  bool isLoading = true;
  
  // Real data from CSVs
  List<NFLPlayer> allPlayers = [];
  List<NFLTeamInfo> allTeams = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      // Initialize the trade data service
      await TradeDataService.initialize();
      
      // Get all players and teams
      allPlayers = TradeDataService.getAllPlayers();
      allTeams = TradeDataService.getAllTeams();
      
      // Sort players by market value for better display
      allPlayers.sort((a, b) => b.marketValue.compareTo(a.marketValue));
      
      // Sort teams alphabetically
      allTeams.sort((a, b) => a.teamName.compareTo(b.teamName));
    } catch (e) {
      print('Error loading trade data: $e');
    }
    
    setState(() => isLoading = false);
  }

  // Sample data - in real app this would come from API/database
  final List<NFLPlayer> samplePlayers = [
    NFLPlayer(
      playerId: 'micah_parsons',
      name: 'Micah Parsons',
      position: 'EDGE',
      team: 'DAL',
      age: 25,
      experience: 3,
      marketValue: 45.0,
      contractStatus: 'extension',
      contractYearsRemaining: 2,
      annualSalary: 22.0,
      overallRating: 95.0,
      positionRank: 98.0,
      ageAdjustedValue: 49.5,
      positionImportance: 0.9,
      durabilityScore: 88.0,
    ),
    NFLPlayer(
      playerId: 'davante_adams',
      name: 'Davante Adams',
      position: 'WR',
      team: 'LV',
      age: 31,
      experience: 10,
      marketValue: 35.0,
      contractStatus: 'extension',
      contractYearsRemaining: 3,
      annualSalary: 28.0,
      overallRating: 92.0,
      positionRank: 95.0,
      ageAdjustedValue: 31.5,
      positionImportance: 0.75,
      durabilityScore: 85.0,
    ),
  ];

  final List<NFLTeamInfo> sampleTeams = [
    NFLTeamInfo(
      teamName: 'Buffalo Bills',
      abbreviation: 'BUF',
      availableCapSpace: 45.2,
      totalCapSpace: 255.4,
      projectedCapSpace2025: 62.1,
      philosophy: TeamPhilosophy.winNow,
      status: TeamStatus.contending,
      positionNeeds: {
        'WR': 0.9,
        'EDGE': 0.7,
        'CB': 0.6,
        'S': 0.5,
      },
      availableDraftPicks: [28, 60, 92, 124],
      futureFirstRounders: 1,
      tradeAggressiveness: 0.8,
      willingToOverpay: true,
    ),
    NFLTeamInfo(
      teamName: 'Detroit Lions',
      abbreviation: 'DET',
      availableCapSpace: 38.7,
      totalCapSpace: 255.4,
      projectedCapSpace2025: 55.3,
      philosophy: TeamPhilosophy.aggressive,
      status: TeamStatus.contending,
      positionNeeds: {
        'EDGE': 0.8,
        'CB': 0.7,
        'S': 0.6,
        'LB': 0.5,
      },
      availableDraftPicks: [24, 56, 88, 120],
      futureFirstRounders: 1,
      tradeAggressiveness: 0.9,
      willingToOverpay: true,
    ),
    NFLTeamInfo(
      teamName: 'New York Jets',
      abbreviation: 'NYJ',
      availableCapSpace: 52.1,
      totalCapSpace: 255.4,
      projectedCapSpace2025: 71.8,
      philosophy: TeamPhilosophy.winNow,
      status: TeamStatus.winNow,
      positionNeeds: {
        'WR': 0.95,
        'EDGE': 0.6,
        'OL': 0.7,
        'CB': 0.5,
      },
      availableDraftPicks: [10, 42, 74, 106],
      futureFirstRounders: 0,
      tradeAggressiveness: 0.85,
      willingToOverpay: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: ModalRoute.of(context)?.settings.name)),
          ],
        ),
      ),
      body: isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading player and team data...'),
              ],
            ),
          )
        : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructions(),
            const SizedBox(height: 24),
            _buildPlayerSelection(),
            const SizedBox(height: 24),
            _buildTargetTeamSelection(),
            const SizedBox(height: 24),
            _buildAnalyzeButton(),
            const SizedBox(height: 24),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NFL Trade Analyzer',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Analyze potential NFL player trades by considering factors like player value, team cap space, positional needs, and trade assets. Select a player and target team to see realistic trade scenarios.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSelection() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Player to Trade',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<NFLPlayer>(
              value: selectedPlayer,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose a player...',
              ),
              items: allPlayers.take(50).map((player) { // Show top 50 players
                return DropdownMenuItem(
                  value: player,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${player.position} - ${player.team} - Age ${player.age} - \$${player.marketValue.toStringAsFixed(1)}M value',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPlayer = value;
                  tradeScenarios.clear(); // Clear previous results
                });
              },
            ),
            if (selectedPlayer != null) ...[
              const SizedBox(height: 12),
              _buildPlayerDetails(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerDetails() {
    if (selectedPlayer == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Overall Rating', '${selectedPlayer!.overallRating.toInt()}/100'),
              ),
              Expanded(
                child: _buildStatItem('Position Rank', '${selectedPlayer!.positionRank.toInt()}th percentile'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Contract Years', '${selectedPlayer!.contractYearsRemaining} remaining'),
              ),
              Expanded(
                child: _buildStatItem('Annual Salary', '\$${selectedPlayer!.annualSalary.toStringAsFixed(1)}M'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetTeamSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Team (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Leave blank to analyze all potential teams',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<NFLTeamInfo>(
              value: selectedTargetTeam,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choose target team (optional)...',
              ),
              items: [
                const DropdownMenuItem<NFLTeamInfo>(
                  value: null,
                  child: Text('All Teams'),
                ),
                ...allTeams.map((team) {
                  return DropdownMenuItem(
                    value: team,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          team.teamName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Cap Space: \$${team.availableCapSpace.toStringAsFixed(1)}M - ${team.status.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  selectedTargetTeam = value;
                  tradeScenarios.clear(); // Clear previous results
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    bool canAnalyze = selectedPlayer != null && !isAnalyzing;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canAnalyze ? _analyzeTradeScenarios : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isAnalyzing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Analyze Trade Scenarios',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildResults() {
    if (tradeScenarios.isEmpty) {
      return const Center(
        child: Text(
          'Select a player and click "Analyze Trade Scenarios" to see results',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trade Scenarios for ${selectedPlayer!.name}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: tradeScenarios.length,
            itemBuilder: (context, index) {
              return _buildTradeScenarioCard(tradeScenarios[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTradeScenarioCard(TradeScenario scenario) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${scenario.player.name} to ${scenario.targetTeam.teamName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildTradeGradeBadge(scenario.tradeGrade),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Package: ${scenario.proposedPackage.description}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildScoreItem(
                    'Fair Value',
                    scenario.fairValueScore,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildScoreItem(
                    'Likelihood',
                    scenario.likelihoodScore,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              scenario.reasoning,
              style: const TextStyle(fontSize: 13),
            ),
            if (scenario.considerations.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Considerations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...scenario.considerations.map((consideration) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  consideration,
                  style: const TextStyle(fontSize: 12),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTradeGradeBadge(TradeGrade grade) {
    Color color = switch (grade) {
      TradeGrade.excellent => Colors.green.shade600,
      TradeGrade.good => Colors.lightGreen.shade600,
      TradeGrade.fair => Colors.orange.shade600,
      TradeGrade.poor => Colors.red.shade600,
      TradeGrade.unrealistic => Colors.grey.shade600,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        grade.displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(color),
        ),
        const SizedBox(height: 2),
        Text(
          '${(score * 100).round()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _analyzeTradeScenarios() async {
    if (selectedPlayer == null) return;

    setState(() {
      isAnalyzing = true;
      tradeScenarios.clear();
    });

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Get current team info (simplified - in real app would fetch from database)
    NFLTeamInfo currentTeam = NFLTeamInfo(
      teamName: _getFullTeamName(selectedPlayer!.team),
      abbreviation: selectedPlayer!.team,
      availableCapSpace: 25.0, // Default value
      totalCapSpace: 255.4,
      projectedCapSpace2025: 35.0,
      philosophy: TeamPhilosophy.balanced,
      status: TeamStatus.competitive,
      positionNeeds: {},
      availableDraftPicks: [],
      futureFirstRounders: 1,
    );

    List<NFLTeamInfo> targetsToAnalyze = selectedTargetTeam != null 
        ? [selectedTargetTeam!] 
        : allTeams.take(10).toList(); // Analyze top 10 teams by cap space

    List<TradeScenario> scenarios = NFLTradeAnalyzerService.generateTradeScenarios(
      selectedPlayer!,
      currentTeam,
      targetsToAnalyze,
    );

    setState(() {
      tradeScenarios = scenarios.take(5).toList(); // Show top 5 scenarios
      isAnalyzing = false;
    });
  }

  String _getFullTeamName(String abbreviation) {
    final teamNames = {
      'DAL': 'Dallas Cowboys',
      'LV': 'Las Vegas Raiders',
      'BUF': 'Buffalo Bills',
      'DET': 'Detroit Lions',
      'NYJ': 'New York Jets',
    };
    return teamNames[abbreviation] ?? abbreviation;
  }
}