import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/custom_ranking_result.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';
import 'package:mds_home/services/custom_rankings/enhanced_calculation_engine.dart';
import 'package:mds_home/services/custom_rankings/ranking_export_service.dart';
import 'package:mds_home/models/custom_weight_config.dart';
import 'package:mds_home/services/rankings/ranking_calculation_service.dart';
import '../../widgets/custom_rankings/results/ranking_table_widget.dart';
import '../../widgets/custom_rankings/results/ranking_analysis_widget.dart';
import '../../widgets/rankings/draggable_ranking_list.dart';
import '../../widgets/rankings/save_custom_ranking_dialog.dart';
import '../../services/fantasy/custom_ranking_service.dart';
import '../../models/fantasy/custom_position_ranking.dart';
import '../../services/vorp/custom_vorp_ranking_service.dart';
import '../../services/vorp/historical_points_service.dart';
import '../../widgets/vorp/drag_drop_position_ranking_list.dart' as vorp_widgets;
import '../../widgets/vorp/save_custom_vorp_ranking_dialog.dart';
import '../../models/vorp/custom_position_ranking.dart' as vorp;

class CustomRankingsResultsScreen extends StatefulWidget {
  final String position;
  final List<EnhancedRankingAttribute> attributes;
  final String rankingName;
  final List<CustomRankingResult> results;

  const CustomRankingsResultsScreen({
    super.key,
    required this.position,
    required this.attributes,
    required this.rankingName,
    required this.results,
  });

  @override
  State<CustomRankingsResultsScreen> createState() => _CustomRankingsResultsScreenState();
}

class _CustomRankingsResultsScreenState extends State<CustomRankingsResultsScreen>
    with TickerProviderStateMixin {
  late Future<RankingAnalysis> _analysisFuture;
  
  // Current state for real-time updates
  late List<CustomRankingResult> _currentResults;
  late List<EnhancedRankingAttribute> _currentAttributes;
  
  // Panel visibility state
  bool _showCustomizePanel = false;
  bool _showHealthPanel = false;
  
  // Weight adjustment state
  late CustomWeightConfig _currentWeights;
  late CustomWeightConfig _defaultWeights;
  int _selectedTab = 0; // 0 = weights, 1 = what-if
  
  // Drag-and-drop and VORP state
  bool _showDragDropMode = false;
  bool _showVORPPreview = false;
  bool _isCalculatingVORP = false;
  List<vorp_widgets.RankingPlayerItem> _dragDropPlayers = [];
  
  // VORP services
  final CustomVorpRankingService _vorpRankingService = CustomVorpRankingService();
  final HistoricalPointsService _historicalPointsService = HistoricalPointsService();
  
  // Debounce timer for weight updates
  Timer? _weightUpdateDebounce;

  @override
  void initState() {
    super.initState();
    
    // Initialize current state
    _currentResults = List.from(widget.results);
    _currentAttributes = List.from(widget.attributes);
    
    // Initialize weight configurations
    _defaultWeights = RankingCalculationService.getDefaultWeights(widget.position);
    _currentWeights = _defaultWeights;
    
    _updateAnalysis();
  }
  
  void _updateAnalysis() {
    final engine = EnhancedCalculationEngine();
    _analysisFuture = engine.analyzeRankings(_currentResults);
  }
  
  @override
  void dispose() {
    _weightUpdateDebounce?.cancel();
    super.dispose();
  }
  


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rankingName.isNotEmpty 
            ? widget.rankingName 
            : 'Custom ${widget.position} Rankings'),
        actions: [
          // Health button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _toggleHealthPanel,
              icon: Icon(
                _showHealthPanel ? Icons.close : Icons.health_and_safety,
                size: 16,
              ),
              label: Text(_showHealthPanel ? 'Close' : 'Health'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showHealthPanel ? Colors.blue.shade600 : ThemeConfig.darkNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          // Customize button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _toggleCustomizePanel,
              icon: Icon(
                _showCustomizePanel ? Icons.close : Icons.tune,
                size: 16,
              ),
              label: Text(_showCustomizePanel ? 'Close' : 'Customize'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showCustomizePanel ? Colors.blue.shade600 : ThemeConfig.darkNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          // Manual Adjustments button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _toggleDragDropMode,
              icon: Icon(
                _showDragDropMode ? Icons.close : Icons.edit,
                size: 16,
              ),
              label: Text(_showDragDropMode ? 'Exit Manual' : 'Manual Adjust'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showDragDropMode ? Colors.green.shade600 : ThemeConfig.darkNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.share),
            onSelected: _shareRankings,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'methodology',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Share Methodology'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'url',
                child: Row(
                  children: [
                    Icon(Icons.link),
                    SizedBox(width: 8),
                    Text('Copy Results Link'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: _exportRankings,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export to CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code),
                    SizedBox(width: 8),
                    Text('Export to JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'html',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Generate Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMainContent(),
          if (_showCustomizePanel)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _buildCustomizePanel(),
            ),
          if (_showHealthPanel)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _buildHealthPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_showDragDropMode) {
      return _buildDragDropMode();
    }
    
    return Column(
      children: [
        _buildSummaryHeader(),
        Expanded(child: _buildRankingsTab()),
      ],
    );
  }

  Widget _buildDragDropMode() {
    return Column(
      children: [
        // Drag-and-drop header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border(bottom: BorderSide(color: Colors.green.shade200)),
          ),
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Manual Adjustments Mode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const Spacer(),
              // VORP Calculate/Toggle button
              if (!_showVORPPreview)
                ElevatedButton.icon(
                  onPressed: _isCalculatingVORP ? null : _calculateVORPForDragDropPlayers,
                  icon: _isCalculatingVORP 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate, size: 16),
                  label: Text(_isCalculatingVORP ? 'Calculating...' : 'Calculate VORP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _toggleVORPPreview,
                  icon: const Icon(Icons.visibility_off, size: 16),
                  label: const Text('Hide VORP'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                  ),
                ),
              const SizedBox(width: 8),
              // Save Button
              ElevatedButton.icon(
                onPressed: _saveCustomRanking,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save As Custom'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Instructions
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.green.shade50,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drag and drop players to reorder your rankings. Toggle VORP to see projected fantasy points and value over replacement.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Draggable list
        Expanded(
          child: _dragDropPlayers.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : vorp_widgets.DragDropPositionRankingList(
                  players: _dragDropPlayers,
                  onReorder: _onDragDropReorder,
                  onRankChange: _onDragDropRankChange,
                  onVORPCalculate: _calculateVORPForDragDropPlayers,
                  showVORP: _showVORPPreview,
                  isLoading: _isCalculatingVORP,
                  position: widget.position.toLowerCase(),
                ),
        ),
      ],
    );
  }

  Widget _buildCustomizePanel() {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Customize Rankings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _toggleCustomizePanel,
                ),
              ],
            ),
          ),
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                        border: _selectedTab == 0 ? Border(
                          bottom: BorderSide(color: Colors.blue.shade600, width: 2),
                        ) : null,
                      ),
                      child: Text(
                        'Weights',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                          color: _selectedTab == 0 ? Colors.blue.shade600 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                        border: _selectedTab == 1 ? Border(
                          bottom: BorderSide(color: Colors.blue.shade600, width: 2),
                        ) : null,
                      ),
                      child: Text(
                        'What-If',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                          color: _selectedTab == 1 ? Colors.blue.shade600 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0 ? _buildWeightsTab() : _buildWhatIfTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthPanel() {
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ranking Health',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _toggleHealthPanel,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<RankingAnalysis>(
              future: _analysisFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                
                if (snapshot.hasData) {
                  return RankingAnalysisWidget(
                    analysis: snapshot.data!,
                    results: _currentResults,
                  );
                }
                
                return const Center(child: Text('No analysis available'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.darkNavy.withValues(alpha: 0.1),
            ThemeConfig.gold.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sports_football,
            size: 32,
            color: ThemeConfig.darkNavy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.position} Rankings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_currentResults.length} players • ${_currentAttributes.length} attributes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<RankingAnalysis>(
            future: _analysisFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final analysis = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Quality: ${analysis.hasGoodSeparation && analysis.isWellDistributed ? 'Excellent' : 'Good'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: analysis.hasGoodSeparation && analysis.isWellDistributed 
                            ? ThemeConfig.successGreen 
                            : ThemeConfig.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tiers: ${analysis.hasGoodSeparation ? 'Clear' : 'Similar'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsTab() {
    return RankingTableWidget(
      results: _currentResults,
      attributes: _currentAttributes,
      onPlayerTap: (result) => _showPlayerDetails(result),
    );
  }


  void _showPlayerDetails(CustomRankingResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.playerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rank: #${result.rank}'),
            Text('Total Score: ${result.formattedScore}'),
            Text('Team: ${result.team}'),
            const SizedBox(height: 16),
            const Text('Attribute Scores:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...result.attributeScores.entries.map((entry) {
              final attr = _currentAttributes.firstWhere(
                (a) => a.id == entry.key,
                orElse: () => EnhancedRankingAttribute(
                  id: entry.key,
                  name: entry.key,
                  displayName: entry.key,
                  category: 'Unknown',
                  position: widget.position,
                  weight: 0.0,
                ),
              );
              return Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('${attr.displayName}: ${entry.value.toStringAsFixed(3)}'),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightsTab() {
    return Column(
      children: [
        // Weight summary header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${widget.position.toUpperCase()} Weight Adjustment',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _currentWeights.isNormalized 
                      ? Colors.green.shade600 
                      : Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Total: ${(_currentWeights.totalWeight * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Weight sliders
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Adjust the weight of each factor in the ranking calculation:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ..._currentWeights.weights.entries.map((entry) {
                return _buildWeightSlider(entry.key, entry.value);
              }).toList(),
            ],
          ),
        ),
        // Footer with normalize and reset buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_currentWeights.isNormalized)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: _normalizeWeights,
                    icon: const Icon(Icons.balance, size: 16),
                    label: const Text('Normalize to 100%'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _resetToDefaultWeights,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset to Defaults'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: Higher weights give more influence to that statistic in the ranking.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhatIfTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.science, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What-If Scenario Testing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create scenarios with different weight configurations to see how rankings would change.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Create scenario section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Create New Scenario',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter scenario name (e.g., "Heavy EPA Focus")',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showCreateScenarioDialog();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Create'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Scenarios list and comparison
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scenarios list
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.list, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                'Scenarios',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(8),
                            children: [
                              _buildScenarioItem('Current Rankings', true, isSelected: true),
                              _buildScenarioItem('High EPA Focus', false),
                              _buildScenarioItem('Volume Priority', false),
                              _buildScenarioItem('Efficiency Focus', false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Comparison panel
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                            border: Border(
                              bottom: BorderSide(color: Colors.blue.shade200),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.compare_arrows, size: 16, color: Colors.blue.shade600),
                              const SizedBox(width: 6),
                              Text(
                                'Scenario Comparison',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Select two scenarios to compare',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rankings changes, biggest movers, and impact analysis will appear here',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScenarioItem(String name, bool isCurrent, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          // Handle scenario selection
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                isCurrent ? Icons.home : Icons.science,
                size: 14,
                color: isCurrent ? Colors.green.shade600 : Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!isCurrent)
                Icon(
                  Icons.more_vert,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showCreateScenarioDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create What-If Scenario'),
        content: SizedBox(
          width: 400,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Scenario Name',
                  hintText: 'e.g., "Heavy Volume Focus" or "Efficiency Priority"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Adjust Weights for This Scenario',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _currentWeights.weights.length,
                  itemBuilder: (context, index) {
                    final entry = _currentWeights.weights.entries.elementAt(index);
                    return _buildScenarioWeightSlider(entry.key, entry.value);
                  },
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
            onPressed: () {
              Navigator.pop(context);
              // Create scenario logic here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Scenario'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScenarioWeightSlider(String variable, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  variable,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue.shade600,
              inactiveTrackColor: Colors.blue.shade200,
              thumbColor: Colors.blue.shade600,
              overlayColor: Colors.blue.shade600.withValues(alpha: 0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 0.30,
              divisions: 60,
              onChanged: (newValue) {
                // Handle weight change for scenario
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSlider(String variable, double value) {
    final descriptions = RankingCalculationService.getWeightDescriptions(widget.position);
    final description = descriptions[variable] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                variable,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getWeightColor(value),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(value * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getWeightColor(value),
              inactiveTrackColor: _getWeightColor(value).withValues(alpha: 0.3),
              thumbColor: _getWeightColor(value),
              overlayColor: _getWeightColor(value).withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 0.30,
              divisions: 60,
              onChanged: (newValue) => _updateWeight(variable, newValue),
            ),
          ),
        ],
      ),
    );
  }

  Color _getWeightColor(double weight) {
    if (weight >= 0.15) return Colors.red.shade600;
    if (weight >= 0.10) return Colors.orange.shade600;
    if (weight >= 0.05) return Colors.blue.shade600;
    return Colors.grey.shade600;
  }

  void _updateWeight(String variable, double value) {
    setState(() {
      final updatedWeights = Map<String, double>.from(_currentWeights.weights);
      updatedWeights[variable] = value;
      _currentWeights = _currentWeights.copyWith(weights: updatedWeights);
    });
    
    // Debounce the weight application to prevent rapid updates
    _weightUpdateDebounce?.cancel();
    _weightUpdateDebounce = Timer(const Duration(milliseconds: 150), () {
      _applyCustomWeights();
    });
  }

  void _normalizeWeights() {
    final normalized = _currentWeights.normalize();
    setState(() {
      _currentWeights = normalized;
    });
    _applyCustomWeights();
  }

  void _resetToDefaultWeights() {
    setState(() {
      _currentWeights = _defaultWeights;
    });
    
    // Reset to original rankings
    setState(() {
      _currentResults = List.from(widget.results);
    });
    _updateAnalysis();
  }

  void _applyCustomWeights() {
    // COPY THE EXACT WORKING LOGIC from EnhancedCalculationEngine
    // Use rank-based scoring system where lower total scores are better
    final newResults = widget.results.map((result) {
      double totalWeightedRank = 0.0;
      double totalWeight = 0.0;
      final newAttributeScores = <String, double>{};
      
      // Apply weights to rank values (from normalizedStats)
      for (final weightEntry in _currentWeights.weights.entries) {
        final attributeName = weightEntry.key;  // e.g., "EPA", "YPG"
        final weight = weightEntry.value;       // e.g., 0.15, 0.20
        
        // Find the rank value for this attribute in normalizedStats
        double? rankValue;
        
        // Try different key variations to find the rank
        if (result.normalizedStats.containsKey(attributeName)) {
          rankValue = result.normalizedStats[attributeName];
        }
        else if (result.normalizedStats.containsKey(attributeName.toLowerCase())) {
          rankValue = result.normalizedStats[attributeName.toLowerCase()];
        }
        // Try looking through all attribute IDs in the original data
        else {
          for (final attr in _currentAttributes) {
            if (attr.displayName == attributeName || attr.name == attributeName || attr.id == attributeName) {
              rankValue = result.normalizedStats[attr.id];
              break;
            }
          }
        }
        
        // If still not found, try rawStats and attributeScores as fallback
        if (rankValue == null) {
          rankValue = result.rawStats[attributeName] ?? result.attributeScores[attributeName];
        }
        
        if (rankValue != null && weight > 0) {
          // EXACT SAME LOGIC: rank * weight (lower ranks get lower weighted scores)
          final weightedRank = rankValue * weight;
          newAttributeScores[attributeName] = weightedRank;
          totalWeightedRank += weightedRank;
          totalWeight += weight;
        }
      }
      
      // EXACT SAME LOGIC: Calculate average weighted rank (lower is better)
      final averageRank = totalWeight > 0 ? totalWeightedRank / totalWeight : 999.0;
      
      return CustomRankingResult(
        id: result.id,
        questionnaireId: result.questionnaireId,
        playerId: result.playerId,
        playerName: result.playerName,
        team: result.team,
        position: result.position,
        rank: result.rank, // Will be updated after sorting
        totalScore: averageRank, // Lower scores are better
        attributeScores: newAttributeScores,
        normalizedStats: result.normalizedStats,
        rawStats: result.rawStats,
        calculatedAt: result.calculatedAt,
      );
    }).toList();
    
    // EXACT SAME LOGIC: Sort by total score (ascending - lower is better)
    newResults.sort((a, b) => a.totalScore.compareTo(b.totalScore));
    
    // EXACT SAME LOGIC: Assign final ranks
    final finalResults = <CustomRankingResult>[];
    for (int i = 0; i < newResults.length; i++) {
      finalResults.add(newResults[i].copyWith(rank: i + 1));
    }
    
    // Update state
    setState(() {
      _currentResults = finalResults;
    });
    _updateAnalysis();
  }
  
  CustomRankingResult _findOriginalResult(String playerName, List<CustomRankingResult> results) {
    try {
      return results.firstWhere((r) => r.playerName == playerName);
    } catch (e) {
      return results.first; // fallback
    }
  }

  void _toggleCustomizePanel() {
    setState(() {
      _showCustomizePanel = !_showCustomizePanel;
      if (_showCustomizePanel) {
        _showHealthPanel = false; // Close health panel when opening customize panel
      }
    });
  }

  void _toggleHealthPanel() {
    setState(() {
      _showHealthPanel = !_showHealthPanel;
      if (_showHealthPanel) {
        _showCustomizePanel = false; // Close customize panel when opening health panel
      }
    });
  }

  void _toggleDragDropMode() {
    setState(() {
      _showDragDropMode = !_showDragDropMode;
      if (_showDragDropMode) {
        _initializeDragDropPlayers();
        // Close other panels
        _showCustomizePanel = false;
        _showHealthPanel = false;
      }
    });
  }

  void _initializeDragDropPlayers() {
    _dragDropPlayers = _currentResults.map((result) {
      return vorp_widgets.RankingPlayerItem(
        id: result.playerId,
        name: result.playerName,
        team: result.team ?? '',
        position: widget.position.toLowerCase(),
        originalRank: result.rank,
        customRank: result.rank,
        originalData: {
          'totalScore': result.totalScore,
          'attributeScores': result.attributeScores,
        },
      );
    }).toList();
  }

  void _toggleVORPPreview() {
    setState(() {
      _showVORPPreview = !_showVORPPreview;
    });
    
    if (_showVORPPreview) {
      _calculateVORPForDragDropPlayers();
    }
  }

  Future<void> _calculateVORPForDragDropPlayers() async {
    setState(() {
      _isCalculatingVORP = true;
    });

    try {
      // Calculate projected points and VORP for custom rankings
      for (int i = 0; i < _dragDropPlayers.length; i++) {
        final player = _dragDropPlayers[i];
        
        // Get projected points based on rank
        final projectedPoints = await _historicalPointsService.getProjectedPointsForRank(
          widget.position.toLowerCase(), 
          player.customRank,
        );
        
        // Calculate VORP
        final vorp = await _historicalPointsService.calculateVORPForPlayer(
          widget.position.toLowerCase(),
          player.customRank,
          projectedPoints,
        );
        
        _dragDropPlayers[i] = player.copyWith(
          projectedPoints: projectedPoints,
          vorp: vorp,
        );
      }
      
      setState(() {
        _showVORPPreview = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating VORP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCalculatingVORP = false;
      });
    }
  }

  void _onDragDropReorder(List<vorp_widgets.RankingPlayerItem> reorderedPlayers) {
    setState(() {
      _dragDropPlayers = reorderedPlayers;
    });

    // Recalculate VORP if preview is showing
    if (_showVORPPreview) {
      _calculateVORPForDragDropPlayers();
    }
  }

  void _onDragDropRankChange(vorp_widgets.RankingPlayerItem player, int newRank) {
    if (newRank < 1 || newRank > _dragDropPlayers.length) return;
    
    setState(() {
      // Remove player from current position
      _dragDropPlayers.removeWhere((p) => p.id == player.id);
      
      // Insert at new position (convert to 0-based index)
      _dragDropPlayers.insert(newRank - 1, player.copyWith(customRank: newRank));
      
      // Update custom ranks for all players based on their new positions
      for (int i = 0; i < _dragDropPlayers.length; i++) {
        _dragDropPlayers[i] = _dragDropPlayers[i].copyWith(customRank: i + 1);
      }
    });

    // Recalculate VORP if preview is showing
    if (_showVORPPreview) {
      _calculateVORPForDragDropPlayers();
    }
  }

  Future<void> _saveCustomRanking() async {
    showDialog(
      context: context,
      builder: (context) => SaveCustomVorpRankingDialog(
        position: widget.position.toLowerCase(),
        existingName: widget.rankingName.isNotEmpty ? '${widget.rankingName} - Manual' : null,
        onSave: (name) async {
          try {
            // Convert RankingPlayerItem list to CustomPlayerRank list
            final playerRanks = _dragDropPlayers.map((player) => 
              vorp.CustomPlayerRank(
                playerId: player.id,
                playerName: player.name,
                team: player.team,
                customRank: player.customRank,
                projectedPoints: player.projectedPoints,
                vorp: player.vorp,
              )
            ).toList();

            final customRanking = vorp.CustomPositionRanking(
              id: _vorpRankingService.generateRankingId(),
              userId: 'anonymous_user', // For MVP
              position: widget.position.toLowerCase(),
              name: name,
              playerRanks: playerRanks,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            final success = await _vorpRankingService.saveRanking(customRanking);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success 
                      ? 'Custom ${widget.position.toUpperCase()} rankings saved successfully!'
                      : 'Failed to save custom rankings.'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving rankings: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _shareRankings(String action) async {
    try {
      switch (action) {
        case 'methodology':
          final methodology = RankingExportService.generateMethodologySummary(
            attributes: _currentAttributes,
            rankingName: widget.rankingName.isNotEmpty 
                ? widget.rankingName 
                : 'Custom ${widget.position} Rankings',
            position: widget.position,
          );
          
          final methodologyText = '''
${methodology['name']}
Position: ${methodology['position']}
Total Attributes: ${methodology['totalAttributes']}
Primary Focus: ${methodology['primaryFocus']}

Attribute Breakdown:
${(methodology['attributes'] as List).map((attr) => 
  '• ${attr['name']}: ${attr['weightPercentage']}% (${attr['category']})'
).join('\n')}

Category Weights:
${(methodology['categoryBreakdown'] as Map).entries.map((entry) => 
  '• ${entry.key}: ${entry.value}%'
).join('\n')}
          ''';
          
          // For web, copy to clipboard
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Ranking Methodology'),
                content: SingleChildScrollView(
                  child: SelectableText(methodologyText),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }
          break;
          
        case 'url':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Results URL copied to clipboard (feature in development)'),
            ),
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  Future<void> _exportRankings(String format) async {
    try {
      final rankingName = widget.rankingName.isNotEmpty 
          ? widget.rankingName 
          : 'Custom ${widget.position} Rankings';
      
      switch (format) {
        case 'csv':
          await RankingExportService.exportToCsv(
            results: _currentResults,
            attributes: _currentAttributes,
            rankingName: rankingName,
          );
          break;
          
        case 'json':
          await RankingExportService.exportToJson(
            results: _currentResults,
            attributes: _currentAttributes,
            rankingName: rankingName,
          );
          break;
          
        case 'html':
          final analysis = await _analysisFuture;
          await RankingExportService.exportToHtmlReport(
            results: _currentResults,
            attributes: _currentAttributes,
            rankingName: rankingName,
            position: widget.position,
            analysis: analysis,
          );
          break;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rankings exported as ${format.toUpperCase()}'),
            backgroundColor: ThemeConfig.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}