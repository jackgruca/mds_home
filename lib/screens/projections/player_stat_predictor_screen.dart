import 'package:flutter/material.dart';
import '../../models/projections/stat_prediction.dart';
import '../../services/projections/stat_predictor_service.dart';
import '../../services/projections/team_normalization_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/design_system/mds_button.dart';
import '../../widgets/design_system/mds_card.dart';
import '../../widgets/stat_predictor/prediction_table.dart';

class PlayerStatPredictorScreen extends StatefulWidget {
  const PlayerStatPredictorScreen({super.key});

  @override
  State<PlayerStatPredictorScreen> createState() => _PlayerStatPredictorScreenState();
}

class _PlayerStatPredictorScreenState extends State<PlayerStatPredictorScreen> {
  final StatPredictorService _predictorService = StatPredictorService();
  
  List<StatPrediction> _allPredictions = [];
  List<StatPrediction> _filteredPredictions = [];
  final Map<String, List<StatPrediction>> _teamPredictions = {};
  
  bool _isLoading = true;
  bool _hasChanges = false;
  String _selectedPosition = 'All';
  String _selectedTeam = 'All';
  String _searchQuery = '';
  
  final List<String> _positionOptions = ['All', 'WR', 'TE'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPredictions() async {
    try {
      setState(() => _isLoading = true);
      
      print('Starting to load predictions...');
      _allPredictions = await _predictorService.loadPredictions();
      print('Loaded ${_allPredictions.length} predictions');
      
      _buildTeamCache();
      _applyFilters();
      
      print('Applied filters. Filtered predictions: ${_filteredPredictions.length}');
      
    } catch (e) {
      print('Error in _loadPredictions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading predictions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _buildTeamCache() {
    _teamPredictions.clear();
    for (final prediction in _allPredictions) {
      if (!_teamPredictions.containsKey(prediction.team)) {
        _teamPredictions[prediction.team] = [];
      }
      _teamPredictions[prediction.team]!.add(prediction);
    }
  }

  void _applyFilters() {
    _filteredPredictions = _allPredictions.where((prediction) {
      // Position filter
      if (_selectedPosition != 'All' && prediction.position != _selectedPosition) {
        return false;
      }
      
      // Team filter
      if (_selectedTeam != 'All' && prediction.team != _selectedTeam) {
        return false;
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!prediction.playerName.toLowerCase().contains(query) &&
            !prediction.team.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Sort by team, then by target share
    _filteredPredictions.sort((a, b) {
      final teamCompare = a.team.compareTo(b.team);
      if (teamCompare != 0) return teamCompare;
      return b.nyTgtShare.compareTo(a.nyTgtShare);
    });
  }

  Future<void> _updatePlayerPrediction(StatPrediction updatedPrediction, String statName, dynamic newValue) async {
    try {
      // Update the prediction
      final updated = updatedPrediction.updateNyStat(statName, newValue);
      
      // If it's target share, normalize the team
      if (statName == 'nyTgtShare') {
        final teamPlayers = _teamPredictions[updated.team] ?? [];
        final normalizedTeam = TeamNormalizationService.normalizeTeamTargetShares(
          teamPlayers,
          updated.playerId,
          updated.nyTgtShare,
        );
        
        // Update all team players
        for (final teamPlayer in normalizedTeam) {
          await _predictorService.updatePlayerPrediction(teamPlayer);
          
          // Update in our local lists
          final allIndex = _allPredictions.indexWhere((p) => p.playerId == teamPlayer.playerId);
          if (allIndex != -1) {
            _allPredictions[allIndex] = teamPlayer;
          }
          
          final teamIndex = _teamPredictions[teamPlayer.team]!.indexWhere((p) => p.playerId == teamPlayer.playerId);
          if (teamIndex != -1) {
            _teamPredictions[teamPlayer.team]![teamIndex] = teamPlayer;
          }
        }
      } else {
        // Update just the single player
        await _predictorService.updatePlayerPrediction(updated);
        
        final allIndex = _allPredictions.indexWhere((p) => p.playerId == updated.playerId);
        if (allIndex != -1) {
          _allPredictions[allIndex] = updated;
        }
        
        final teamIndex = _teamPredictions[updated.team]!.indexWhere((p) => p.playerId == updated.playerId);
        if (teamIndex != -1) {
          _teamPredictions[updated.team]![teamIndex] = updated;
        }
      }
      
      setState(() {
        _hasChanges = true;
        _applyFilters();
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating prediction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetAllToOriginal() async {
    try {
      await _predictorService.resetAllToOriginal();
      await _loadPredictions();
      
      setState(() {
        _hasChanges = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All predictions reset to original values'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting predictions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetPlayerToOriginal(StatPrediction prediction) async {
    try {
      await _predictorService.resetPlayerToOriginal(prediction.playerId);
      await _loadPredictions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${prediction.playerName} reset to original values'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting player: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilters() {
    final teams = _teamPredictions.keys.toList()..sort();
    
    return MdsCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Position Filter
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Position', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: _selectedPosition,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _positionOptions.map((position) {
                          return DropdownMenuItem(
                            value: position,
                            child: Text(position),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPosition = value ?? 'All';
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Team Filter
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Team', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: _selectedTeam,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: ['All', ...teams].map((team) {
                          return DropdownMenuItem(
                            value: team,
                            child: Text(team),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTeam = value ?? 'All';
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Search
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Search', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          hintText: 'Search players...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    final totalPlayers = _filteredPredictions.length;
    final editedPlayers = _filteredPredictions.where((p) => p.isEdited).length;
    final wrCount = _filteredPredictions.where((p) => p.position == 'WR').length;
    final teCount = _filteredPredictions.where((p) => p.position == 'TE').length;

    return MdsCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Players', totalPlayers.toString()),
            _buildStatItem('WR', wrCount.toString()),
            _buildStatItem('TE', teCount.toString()),
            _buildStatItem('Modified', editedPlayers.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons() {
    final buttons = <Widget>[];
    
    if (_hasChanges) {
      buttons.addAll([
        MdsButton(
          text: 'Reset All',
          onPressed: _resetAllToOriginal,
          type: MdsButtonType.secondary,
          icon: Icons.refresh,
        ),
        const SizedBox(width: 12),
      ]);
    }
    
    buttons.add(
      MdsButton(
        text: 'Export to Rankings',
        onPressed: _hasChanges ? () => _navigateToCustomRankings() : null,
        type: MdsButtonType.primary,
        icon: Icons.arrow_forward,
      ),
    );
    
    return buttons;
  }

  void _navigateToCustomRankings() {
    // Store the current predictions state for use in custom rankings
    // For now, just navigate to custom rankings with a success message
    Navigator.pushNamed(context, '/fantasy/custom-rankings');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Predictions ready! Enable "Next Year Predictions" in the preview step.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: const Row(
          children: [
            Icon(Icons.analytics_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Player Stat Predictor'),
          ],
        ),
        actions: !_isLoading ? _buildActionButtons() : null,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading predictions...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryStats(),
                  const SizedBox(height: 16),
                  _buildFilters(),
                  const SizedBox(height: 24),
                  
                  // Table Header
                  const Row(
                    children: [
                      Icon(Icons.table_chart, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Current vs Next Year Predictions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click on next year values to edit. Target share changes will automatically normalize team totals.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Predictions Table
                  PredictionTable(
                    predictions: _filteredPredictions,
                    onValueChanged: _updatePlayerPrediction,
                    onResetPlayer: _resetPlayerToOriginal,
                  ),
                ],
              ),
            ),
    );
  }
}