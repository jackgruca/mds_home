import 'package:flutter/material.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';
import '../services/hybrid_data_service.dart';

class PositionAnalyticsScreen extends StatefulWidget {
  final String position;
  
  const PositionAnalyticsScreen({
    super.key,
    required this.position,
  });

  @override
  State<PositionAnalyticsScreen> createState() => _PositionAnalyticsScreenState();
}

class _PositionAnalyticsScreenState extends State<PositionAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final HybridDataService _dataService = HybridDataService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _players = [];
  late TabController _tabController;
  
  // Analytics categories
  List<Map<String, dynamic>> _elitePlayers = [];
  List<Map<String, dynamic>> _efficiencyLeaders = [];
  List<Map<String, dynamic>> _opportunityTargets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPositionData();
  }

  Future<void> _loadPositionData() async {
    setState(() => _isLoading = true);

    try {
      // Load position-specific players
      _players = await _dataService.getPlayerStats(
        position: widget.position,
        orderBy: 'fantasy_points_ppr',
        descending: true,
        limit: 100,
      );

      _generatePositionInsights();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _generatePositionInsights() {
    if (_players.isEmpty) return;

    // Filter current season
    final currentPlayers = _players
        .where((p) => p['season'] == 2024)
        .toList();

    switch (widget.position) {
      case 'QB':
        _generateQBInsights(currentPlayers);
        break;
      case 'WR':
        _generateWRInsights(currentPlayers);
        break;
      case 'RB':
        _generateRBInsights(currentPlayers);
        break;
      case 'TE':
        _generateTEInsights(currentPlayers);
        break;
    }
  }

  void _generateQBInsights(List<Map<String, dynamic>> players) {
    // Elite: High passer rating + attempts
    _elitePlayers = players
        .where((p) => 
            p['passer_rating'] != null && p['passer_rating'] > 100 &&
            p['attempts'] != null && p['attempts'] > 200)
        .toList()
      ..sort((a, b) => (b['passer_rating'] ?? 0).compareTo(a['passer_rating'] ?? 0));

    // Efficiency: Completion % above expectation
    _efficiencyLeaders = players
        .where((p) => p['completion_percentage_above_expectation'] != null)
        .toList()
      ..sort((a, b) => (b['completion_percentage_above_expectation'] ?? 0)
          .compareTo(a['completion_percentage_above_expectation'] ?? 0));

    // Opportunity: High attempts + games played
    _opportunityTargets = players
        .where((p) => 
            p['attempts'] != null && p['attempts'] > 300 &&
            p['games'] != null && p['games'] >= 10)
        .toList()
      ..sort((a, b) => (b['attempts'] ?? 0).compareTo(a['attempts'] ?? 0));
  }

  void _generateWRInsights(List<Map<String, dynamic>> players) {
    // Elite: High RACR + targets
    _elitePlayers = players
        .where((p) => 
            p['racr'] != null && p['racr'] > 110 &&
            p['targets'] != null && p['targets'] > 50)
        .toList()
      ..sort((a, b) => (b['racr'] ?? 0).compareTo(a['racr'] ?? 0));

    // Efficiency: Yards per reception
    _efficiencyLeaders = players
        .where((p) => 
            p['yards_per_reception'] != null &&
            p['receptions'] != null && p['receptions'] > 20)
        .toList()
      ..sort((a, b) => (b['yards_per_reception'] ?? 0)
          .compareTo(a['yards_per_reception'] ?? 0));

    // Opportunity: High target share
    _opportunityTargets = players
        .where((p) => p['target_share'] != null && p['target_share'] > 15)
        .toList()
      ..sort((a, b) => (b['target_share'] ?? 0).compareTo(a['target_share'] ?? 0));
  }

  void _generateRBInsights(List<Map<String, dynamic>> players) {
    // Elite: Yards over expected + attempts
    _elitePlayers = players
        .where((p) => 
            p['rush_yards_over_expected'] != null && p['rush_yards_over_expected'] > 50 &&
            p['rushing_attempts'] != null && p['rushing_attempts'] > 100)
        .toList()
      ..sort((a, b) => (b['rush_yards_over_expected'] ?? 0)
          .compareTo(a['rush_yards_over_expected'] ?? 0));

    // Efficiency: Yards per carry
    _efficiencyLeaders = players
        .where((p) => 
            p['yards_per_carry'] != null &&
            p['rushing_attempts'] != null && p['rushing_attempts'] > 50)
        .toList()
      ..sort((a, b) => (b['yards_per_carry'] ?? 0)
          .compareTo(a['yards_per_carry'] ?? 0));

    // Opportunity: High attempts + games
    _opportunityTargets = players
        .where((p) => 
            p['rushing_attempts'] != null && p['rushing_attempts'] > 150 &&
            p['games'] != null && p['games'] >= 10)
        .toList()
      ..sort((a, b) => (b['rushing_attempts'] ?? 0).compareTo(a['rushing_attempts'] ?? 0));
  }

  void _generateTEInsights(List<Map<String, dynamic>> players) {
    // Elite: High receiving yards + TDs
    _elitePlayers = players
        .where((p) => 
            p['receiving_yards'] != null && p['receiving_yards'] > 600 &&
            p['receiving_tds'] != null && p['receiving_tds'] > 3)
        .toList()
      ..sort((a, b) => (b['receiving_yards'] ?? 0).compareTo(a['receiving_yards'] ?? 0));

    // Efficiency: Yards per reception
    _efficiencyLeaders = players
        .where((p) => 
            p['yards_per_reception'] != null &&
            p['receptions'] != null && p['receptions'] > 25)
        .toList()
      ..sort((a, b) => (b['yards_per_reception'] ?? 0)
          .compareTo(a['yards_per_reception'] ?? 0));

    // Opportunity: High targets
    _opportunityTargets = players
        .where((p) => p['targets'] != null && p['targets'] > 60)
        .toList()
      ..sort((a, b) => (b['targets'] ?? 0).compareTo(a['targets'] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Text('${_getPositionTitle()} Analytics'),
      ),
      body: Column(
        children: [
          const TopNavBarContent(),
          
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Position header
                  _buildPositionHeader(),
                  
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: _getEliteLabel()),
                      Tab(text: _getEfficiencyLabel()),
                      Tab(text: _getOpportunityLabel()),
                    ],
                  ),
                  
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPlayerList(_elitePlayers, _getEliteMetric()),
                        _buildPlayerList(_efficiencyLeaders, _getEfficiencyMetric()),
                        _buildPlayerList(_opportunityTargets, _getOpportunityMetric()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPositionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getPositionColor().withOpacity(0.8),
            _getPositionColor().withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getPositionIcon(),
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            _getPositionTitle(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getPositionDescription(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(List<Map<String, dynamic>> players, String metricField) {
    if (players.isEmpty) {
      return const Center(
        child: Text('No data available for this category'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final metricValue = player[metricField]?.toStringAsFixed(1) ?? '0';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPositionColor(),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              player['player_display_name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${player['recent_team'] ?? 'UNK'} • Season: ${player['season'] ?? 'N/A'}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  metricValue,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getPositionColor(),
                  ),
                ),
                Text(
                  _getMetricLabel(metricField),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            onTap: () {
              // Navigate to player detail
              Navigator.pushNamed(
                context,
                '/player/${player['player_id']}',
              );
            },
          ),
        );
      },
    );
  }

  String _getPositionTitle() {
    switch (widget.position) {
      case 'QB': return 'Quarterback Command Center';
      case 'WR': return 'Wide Receiver Analytics';  
      case 'RB': return 'Running Back Metrics';
      case 'TE': return 'Tight End Analysis';
      default: return '${widget.position} Analytics';
    }
  }

  String _getPositionDescription() {
    switch (widget.position) {
      case 'QB': return 'Pocket presence, accuracy, pressure performance';
      case 'WR': return 'Route running, separation, target efficiency';
      case 'RB': return 'Efficiency, opportunity, yards over expected';
      case 'TE': return 'Receiving prowess, red zone targets, blocking';
      default: return 'Advanced statistical analysis';
    }
  }

  IconData _getPositionIcon() {
    switch (widget.position) {
      case 'QB': return Icons.sports_football;
      case 'WR': return Icons.directions_run;
      case 'RB': return Icons.fitness_center;
      case 'TE': return Icons.sports_handball;
      default: return Icons.person;
    }
  }

  Color _getPositionColor() {
    switch (widget.position) {
      case 'QB': return Colors.blue;
      case 'WR': return Colors.orange;
      case 'RB': return Colors.green;
      case 'TE': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getEliteLabel() {
    switch (widget.position) {
      case 'QB': return 'Elite Passers';
      case 'WR': return 'Route Masters';
      case 'RB': return 'Efficiency Kings';
      case 'TE': return 'Receiving Threats';
      default: return 'Elite';
    }
  }

  String _getEfficiencyLabel() {
    switch (widget.position) {
      case 'QB': return 'Accuracy Leaders';
      case 'WR': return 'YAC Champions';
      case 'RB': return 'YPC Leaders';
      case 'TE': return 'Efficiency Masters';
      default: return 'Efficiency';
    }
  }

  String _getOpportunityLabel() {
    switch (widget.position) {
      case 'QB': return 'Volume Leaders';
      case 'WR': return 'Target Hogs';
      case 'RB': return 'Workhorses';
      case 'TE': return 'Target Leaders';
      default: return 'Opportunity';
    }
  }

  String _getEliteMetric() {
    switch (widget.position) {
      case 'QB': return 'passer_rating';
      case 'WR': return 'racr';
      case 'RB': return 'rush_yards_over_expected';
      case 'TE': return 'receiving_yards';
      default: return 'fantasy_points_ppr';
    }
  }

  String _getEfficiencyMetric() {
    switch (widget.position) {
      case 'QB': return 'completion_percentage_above_expectation';
      case 'WR': return 'yards_per_reception';
      case 'RB': return 'yards_per_carry';
      case 'TE': return 'yards_per_reception';
      default: return 'fantasy_points_ppr_per_game';
    }
  }

  String _getOpportunityMetric() {
    switch (widget.position) {
      case 'QB': return 'attempts';
      case 'WR': return 'target_share';
      case 'RB': return 'rushing_attempts';
      case 'TE': return 'targets';
      default: return 'targets';
    }
  }

  String _getMetricLabel(String field) {
    switch (field) {
      case 'passer_rating': return 'Rating';
      case 'racr': return 'RACR';
      case 'rush_yards_over_expected': return 'RYOE';
      case 'receiving_yards': return 'Rec Yds';
      case 'completion_percentage_above_expectation': return 'CPOE';
      case 'yards_per_reception': return 'YAC';
      case 'yards_per_carry': return 'YPC';
      case 'attempts': return 'Att';
      case 'target_share': return 'Tgt %';
      case 'rushing_attempts': return 'Rush Att';
      case 'targets': return 'Targets';
      default: return '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}