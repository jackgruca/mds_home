import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';
import 'package:mds_home/models/custom_rankings/custom_ranking_result.dart';
import 'package:mds_home/services/custom_rankings/enhanced_calculation_engine.dart';

class ScenarioTestingWidget extends StatefulWidget {
  final String position;
  final List<EnhancedRankingAttribute> baseAttributes;
  final List<CustomRankingResult> baseResults;

  const ScenarioTestingWidget({
    super.key,
    required this.position,
    required this.baseAttributes,
    required this.baseResults,
  });

  @override
  State<ScenarioTestingWidget> createState() => _ScenarioTestingWidgetState();
}

class _ScenarioTestingWidgetState extends State<ScenarioTestingWidget> {
  final List<RankingScenario> _scenarios = [];
  final EnhancedCalculationEngine _engine = EnhancedCalculationEngine();
  bool _isCalculating = false;
  int? _selectedScenarioIndex;

  @override
  void initState() {
    super.initState();
    _addBaseScenario();
  }

  void _addBaseScenario() {
    _scenarios.add(RankingScenario(
      name: 'Current Rankings',
      attributes: List.from(widget.baseAttributes),
      results: List.from(widget.baseResults),
      isBase: true,
    ));
  }

  Future<void> _createScenario(String name, List<EnhancedRankingAttribute> attributes) async {
    setState(() {
      _isCalculating = true;
    });

    try {
      final questionnaireId = 'scenario_${DateTime.now().millisecondsSinceEpoch}';
      final results = await _engine.calculateRankings(
        questionnaireId: questionnaireId,
        position: widget.position,
        attributes: attributes,
      );

      setState(() {
        _scenarios.add(RankingScenario(
          name: name,
          attributes: attributes,
          results: results,
          isBase: false,
        ));
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating scenario: $e')),
        );
      }
    }
  }

  void _deleteScenario(int index) {
    if (!_scenarios[index].isBase) {
      setState(() {
        if (_selectedScenarioIndex == index) {
          _selectedScenarioIndex = null;
        } else if (_selectedScenarioIndex != null && _selectedScenarioIndex! > index) {
          _selectedScenarioIndex = _selectedScenarioIndex! - 1;
        }
        _scenarios.removeAt(index);
      });
    }
  }

  void _showCreateScenarioDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateScenarioDialog(
        position: widget.position,
        baseAttributes: widget.baseAttributes,
        onCreateScenario: _createScenario,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        _buildHeader(context),
        if (_isCalculating) _buildLoadingIndicator(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildScenariosPanel(context),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: _buildComparisonPanel(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science, color: ThemeConfig.darkNavy),
          const SizedBox(width: 8),
          Text(
            'What-If Scenarios',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _showCreateScenarioDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Scenario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.darkNavy,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Center(
        child: SizedBox(
          height: 2,
          child: LinearProgressIndicator(
            backgroundColor: Colors.grey,
            valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.darkNavy),
          ),
        ),
      ),
    );
  }

  Widget _buildScenariosPanel(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeConfig.darkNavy.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, color: ThemeConfig.darkNavy),
                const SizedBox(width: 8),
                Text(
                  'Scenarios (${_scenarios.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.darkNavy,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _scenarios.length,
              itemBuilder: (context, index) => _buildScenarioCard(context, index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final scenario = _scenarios[index];
    final isSelected = _selectedScenarioIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedScenarioIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
                ? ThemeConfig.darkNavy.withValues(alpha: 0.1)
                : Colors.white,
            border: Border.all(
              color: isSelected 
                  ? ThemeConfig.darkNavy 
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    scenario.isBase ? Icons.home : Icons.science,
                    color: scenario.isBase ? ThemeConfig.successGreen : ThemeConfig.darkNavy,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      scenario.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? ThemeConfig.darkNavy : null,
                      ),
                    ),
                  ),
                  if (!scenario.isBase)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 16),
                      onPressed: () => _deleteScenario(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${scenario.attributes.length} attributes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Avg Score: ${scenario.averageScore.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonPanel(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_selectedScenarioIndex == null) {
      return Card(
        margin: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Select a scenario to view comparison',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final selectedScenario = _scenarios[_selectedScenarioIndex!];
    final baseScenario = _scenarios[0]; // First scenario is always base
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeConfig.gold.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows, color: ThemeConfig.gold),
                const SizedBox(width: 8),
                Text(
                  'Scenario Comparison',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.gold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Top 20 Rankings'),
                      Tab(text: 'Key Changes'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRankingsComparison(context, baseScenario, selectedScenario),
                        _buildChangesAnalysis(context, baseScenario, selectedScenario),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsComparison(BuildContext context, RankingScenario base, RankingScenario selected) {
    final theme = Theme.of(context);
    final topPlayers = selected.results.take(20).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topPlayers.length,
      itemBuilder: (context, index) {
        final player = topPlayers[index];
        final basePlayer = base.results.firstWhere(
          (p) => p.playerId == player.playerId,
          orElse: () => player,
        );
        final rankChange = basePlayer.rank - player.rank;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getRankColor(player.rank),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${player.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.playerName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${player.team} • ${player.formattedScore}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (rankChange != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: rankChange > 0 
                        ? ThemeConfig.successGreen.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rankChange > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: rankChange > 0 ? ThemeConfig.successGreen : Colors.red,
                      ),
                      Text(
                        '${rankChange.abs()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: rankChange > 0 ? ThemeConfig.successGreen : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChangesAnalysis(BuildContext context, RankingScenario base, RankingScenario selected) {
    final theme = Theme.of(context);
    final changes = _analyzeChanges(base, selected);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChangesSummary(context, changes),
        const SizedBox(height: 16),
        _buildBiggestMovers(context, changes),
      ],
    );
  }

  Widget _buildChangesSummary(BuildContext context, ScenarioChanges changes) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary of Changes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildChangeStat(context, 'Players Moved Up', '${changes.playersMovedUp}', Icons.trending_up, ThemeConfig.successGreen),
                ),
                Expanded(
                  child: _buildChangeStat(context, 'Players Moved Down', '${changes.playersMovedDown}', Icons.trending_down, Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildChangeStat(context, 'Avg Position Change', changes.averagePositionChange.toStringAsFixed(1), Icons.swap_vert, ThemeConfig.darkNavy),
                ),
                Expanded(
                  child: _buildChangeStat(context, 'Score Range Diff', changes.scoreRangeDifference.toStringAsFixed(2), Icons.compare_arrows, ThemeConfig.gold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeStat(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBiggestMovers(BuildContext context, ScenarioChanges changes) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biggest Movers',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...changes.biggestMovers.take(10).map((mover) => _buildMoverCard(context, mover)),
          ],
        ),
      ),
    );
  }

  Widget _buildMoverCard(BuildContext context, PlayerRankChange mover) {
    final theme = Theme.of(context);
    final isPositive = mover.rankChange > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? ThemeConfig.successGreen : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mover.playerName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${mover.oldRank} → ${mover.newRank}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isPositive ? ThemeConfig.successGreen : Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${isPositive ? '+' : ''}${mover.rankChange}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 5) return ThemeConfig.successGreen;
    if (rank <= 12) return ThemeConfig.gold;
    if (rank <= 24) return Colors.orange;
    return Colors.grey;
  }

  ScenarioChanges _analyzeChanges(RankingScenario base, RankingScenario selected) {
    final movers = <PlayerRankChange>[];
    int playersMovedUp = 0;
    int playersMovedDown = 0;
    double totalPositionChange = 0;
    
    for (final selectedPlayer in selected.results) {
      final basePlayer = base.results.firstWhere(
        (p) => p.playerId == selectedPlayer.playerId,
        orElse: () => selectedPlayer,
      );
      
      final rankChange = basePlayer.rank - selectedPlayer.rank;
      if (rankChange != 0) {
        movers.add(PlayerRankChange(
          playerId: selectedPlayer.playerId,
          playerName: selectedPlayer.playerName,
          oldRank: basePlayer.rank,
          newRank: selectedPlayer.rank,
          rankChange: rankChange,
        ));
        
        if (rankChange > 0) playersMovedUp++;
        if (rankChange < 0) playersMovedDown++;
        totalPositionChange += rankChange.abs();
      }
    }
    
    movers.sort((a, b) => b.rankChange.abs().compareTo(a.rankChange.abs()));
    
    final baseScoreRange = base.results.isNotEmpty 
        ? base.results.first.totalScore - base.results.last.totalScore
        : 0.0;
    final selectedScoreRange = selected.results.isNotEmpty 
        ? selected.results.first.totalScore - selected.results.last.totalScore
        : 0.0;
    
    return ScenarioChanges(
      playersMovedUp: playersMovedUp,
      playersMovedDown: playersMovedDown,
      averagePositionChange: movers.isNotEmpty ? totalPositionChange / movers.length : 0.0,
      scoreRangeDifference: selectedScoreRange - baseScoreRange,
      biggestMovers: movers,
    );
  }
}

class RankingScenario {
  final String name;
  final List<EnhancedRankingAttribute> attributes;
  final List<CustomRankingResult> results;
  final bool isBase;

  const RankingScenario({
    required this.name,
    required this.attributes,
    required this.results,
    required this.isBase,
  });

  double get averageScore {
    if (results.isEmpty) return 0.0;
    return results.map((r) => r.totalScore).reduce((a, b) => a + b) / results.length;
  }
}

class ScenarioChanges {
  final int playersMovedUp;
  final int playersMovedDown;
  final double averagePositionChange;
  final double scoreRangeDifference;
  final List<PlayerRankChange> biggestMovers;

  const ScenarioChanges({
    required this.playersMovedUp,
    required this.playersMovedDown,
    required this.averagePositionChange,
    required this.scoreRangeDifference,
    required this.biggestMovers,
  });
}

class PlayerRankChange {
  final String playerId;
  final String playerName;
  final int oldRank;
  final int newRank;
  final int rankChange;

  const PlayerRankChange({
    required this.playerId,
    required this.playerName,
    required this.oldRank,
    required this.newRank,
    required this.rankChange,
  });
}

class CreateScenarioDialog extends StatefulWidget {
  final String position;
  final List<EnhancedRankingAttribute> baseAttributes;
  final Function(String, List<EnhancedRankingAttribute>) onCreateScenario;

  const CreateScenarioDialog({
    super.key,
    required this.position,
    required this.baseAttributes,
    required this.onCreateScenario,
  });

  @override
  State<CreateScenarioDialog> createState() => _CreateScenarioDialogState();
}

class _CreateScenarioDialogState extends State<CreateScenarioDialog> {
  final TextEditingController _nameController = TextEditingController();
  late List<EnhancedRankingAttribute> _attributes;

  @override
  void initState() {
    super.initState();
    _attributes = widget.baseAttributes.map((attr) => attr.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Create What-If Scenario'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Scenario Name',
                hintText: 'e.g., "Heavy Volume Focus" or "Efficiency Priority"',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Adjust Weights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _attributes.length,
                itemBuilder: (context, index) => _buildAttributeSlider(context, index),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _nameController.text.isNotEmpty ? _createScenario : null,
          child: const Text('Create Scenario'),
        ),
      ],
    );
  }

  Widget _buildAttributeSlider(BuildContext context, int index) {
    final theme = Theme.of(context);
    final attribute = _attributes[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  attribute.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${(attribute.weight * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: attribute.weight,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                _attributes[index] = _attributes[index].copyWith(weight: value);
              });
            },
          ),
        ],
      ),
    );
  }

  void _createScenario() {
    widget.onCreateScenario(_nameController.text, _attributes);
    Navigator.pop(context);
  }
}