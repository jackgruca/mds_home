import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../models/fantasy/player_ranking.dart';
import '../../services/fantasy/csv_rankings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/theme_config.dart';
import '../../utils/theme_aware_colors.dart';
import '../../utils/seo_helper.dart';
import '../../models/custom_weight_config.dart';
import '../../models/consensus_weight_config.dart';
import '../../widgets/rankings/consensus_weight_adjustment_panel.dart';
import '../../services/fantasy/vorp_service.dart';
import '../../models/fantasy/vorp_big_board.dart';
import '../../services/vorp/custom_vorp_ranking_service.dart';

class BigBoardScreen extends StatefulWidget {
  const BigBoardScreen({super.key});

  @override
  State<BigBoardScreen> createState() => _BigBoardScreenState();
}

class CustomColumn {
  String title;
  Map<String, int> values;
  CustomColumn({required this.title, Map<String, int>? values}) : values = values ?? {};
}

class _BigBoardScreenState extends State<BigBoardScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<PlayerRanking> _rankings = [];
  List<PlayerRanking> _filteredRankings = [];
  List<PlayerRanking> _cachedVisibleRankings = [];
  int? _sortColumnIndex;
  final bool _sortAscending = true;
  final CSVRankingsService _csvService = CSVRankingsService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _lastSearchQuery = '';
  String _lastPositionFilter = '';
  int _lastCurrentPage = -1;
  Timer? _searchDebounce;
  final List<CustomColumn> _customColumns = [];
  String _positionFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Pagination variables
  int _currentPage = 0;
  static const int _rowsPerPage = 25;
  int _totalRecords = 0;
  bool _hasNextPage = false;
  
  // Weight customization variables
  bool _showWeightPanel = false;
  ConsensusWeightConfig _consensusWeights = ConsensusWeightConfig.createDefault();
  bool _usingCustomWeights = false;
  bool _includeCustomRankings = false;
  final CustomVorpRankingService _customRankingService = CustomVorpRankingService();
  
  // VORP variables
  bool _showVORPMode = false;
  VORPBigBoard? _vorpBoard;
  Map<String, int> _leagueSettings = {
    'teams': 12,
    'qb': 1,
    'rb': 2,
    'wr': 2,
    'te': 1,
    'flex': 1,
  };
  String _scoringSystem = 'ppr';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    
    _fetchRankings();
    
    // Update SEO for Big Board
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForBigBoard();
      SEOHelper.updateToolStructuredData(
        toolName: 'Fantasy Football Big Board',
        description: 'Advanced fantasy football big board with VORP calculations, custom weight systems, and tier-based rankings',
        url: 'https://sticktothemodel.com/fantasy/big-board',
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchRankings() async {
    setState(() => _isLoading = true);

    try {
      final rankings = await _csvService.fetchRankings();
      setState(() {
        _rankings = rankings;
        _filteredRankings = rankings;
        _sortData('Consensus Rank', true); // Initial sort by consensus rank
        _resetPagination(); // Reset pagination for fresh data
        _updateVisibleRankings(); // Initialize visible rankings cache
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading rankings: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _filterRankings(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
        _resetPagination();
        _updateVisibleRankings();
      });
    });
  }

  void _updateVisibleRankings() {
    // Only use cache if search, position filter, current page, and rankings haven't changed
    if (_searchQuery == _lastSearchQuery && 
        _positionFilter == _lastPositionFilter && 
        _currentPage == _lastCurrentPage && 
        _cachedVisibleRankings.isNotEmpty &&
        _rankings.isNotEmpty) {
      return; // Use cached results
    }
    
    // Filter all rankings first
    final allFilteredRankings = _rankings.where((player) {
      final matchesSearch = _searchQuery.isEmpty ||
        player.name.toLowerCase().contains(_searchQuery) ||
        player.position.toLowerCase().contains(_searchQuery) ||
        player.rank.toString().contains(_searchQuery);
      final matchesPosition = _positionFilter == 'All' || player.position == _positionFilter;
      return matchesSearch && matchesPosition;
    }).toList();
    
    // Update pagination info
    _totalRecords = allFilteredRankings.length;
    final totalPages = (_totalRecords / _rowsPerPage).ceil();
    
    // Ensure current page is valid
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    
    // Calculate pagination
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _totalRecords);
    _hasNextPage = endIndex < _totalRecords;
    
    // Get current page data
    _cachedVisibleRankings = allFilteredRankings.sublist(
      startIndex, 
      endIndex,
    );
    
    _lastSearchQuery = _searchQuery;
    _lastPositionFilter = _positionFilter;
    _lastCurrentPage = _currentPage;
  }
  
  List<PlayerRanking> get _visibleRankings {
    if (_cachedVisibleRankings.isEmpty && _rankings.isNotEmpty) {
      _updateVisibleRankings();
    }
    return _cachedVisibleRankings;
  }

  void _goToNextPage() {
    if (_hasNextPage) {
      setState(() {
        _currentPage++;
        _updateVisibleRankings();
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _updateVisibleRankings();
      });
    }
  }

  void _resetPagination() {
    _currentPage = 0;
    _totalRecords = 0;
    _hasNextPage = false;
    _lastCurrentPage = -1; // Reset cache tracker
  }

  void _toggleWeightPanel() {
    setState(() {
      _showWeightPanel = !_showWeightPanel;
    });
  }

  void _onWeightsChanged(ConsensusWeightConfig newWeights) {
    setState(() {
      _consensusWeights = newWeights;
      _usingCustomWeights = true;
      _includeCustomRankings = newWeights.includeCustomRankings;
      // Clear cache to force recalculation
      _cachedVisibleRankings.clear();
      _lastSearchQuery = '';
      _lastPositionFilter = '';
      _lastCurrentPage = -1;
    });
    _applyCustomWeights();
  }

  void _resetWeights() {
    setState(() {
      _consensusWeights = ConsensusWeightConfig.createDefault();
      _usingCustomWeights = false;
      _includeCustomRankings = false;
      // Clear cache to force recalculation
      _cachedVisibleRankings.clear();
      _lastSearchQuery = '';
      _lastPositionFilter = '';
      _lastCurrentPage = -1;
    });
    _applyCustomWeights();
  }

  Future<void> _applyCustomWeights() async {
    // Apply weighted ranking calculation to update consensus rankings
    Map<String, Map<String, double>>? customRankingsData;
    
    // Load custom rankings data if included in consensus
    if (_includeCustomRankings) {
      try {
        customRankingsData = await _loadCustomRankingsData();
      } catch (e) {
        // Handle error - continue without custom rankings
        print('Error loading custom rankings: $e');
      }
    }
    
    // Create a new list of updated players to avoid state conflicts
    final updatedRankings = <PlayerRanking>[];
    
    for (final player in _rankings) {
      final weightedRanks = <double>[];
      double totalWeight = 0.0;
      
      // Create a copy of additional ranks to avoid modifying the original
      final updatedAdditionalRanks = Map<String, dynamic>.from(player.additionalRanks);
      
      // Apply platform weights
      _consensusWeights.platformWeights.forEach((platform, weight) {
        final rank = updatedAdditionalRanks[platform];
        if (rank != null && rank > 0) {
          weightedRanks.add((rank as num).toDouble() * weight);
          totalWeight += weight;
        }
      });
      
      // Apply custom rankings weight if available
      if (_includeCustomRankings && 
          customRankingsData != null && 
          _consensusWeights.customRankingsWeight > 0) {
        final customRank = customRankingsData[player.position.toLowerCase()]?[player.id];
        if (customRank != null && customRank > 0) {
          weightedRanks.add(customRank * _consensusWeights.customRankingsWeight);
          totalWeight += _consensusWeights.customRankingsWeight;
          // Add custom ranking to display
          updatedAdditionalRanks['My Custom Rankings'] = customRank;
        }
      } else {
        // Remove custom rankings if not included
        updatedAdditionalRanks.remove('My Custom Rankings');
      }
      
      if (weightedRanks.isNotEmpty && totalWeight > 0) {
        final weightedConsensus = weightedRanks.reduce((a, b) => a + b) / totalWeight;
        updatedAdditionalRanks['Consensus'] = weightedConsensus;
      }
      
      // Create updated player with new additional ranks
      final updatedPlayer = player.copyWith(additionalRanks: updatedAdditionalRanks);
      updatedRankings.add(updatedPlayer);
    }
    
    // Sort by new consensus rankings
    updatedRankings.sort((a, b) {
      final aVal = a.additionalRanks['Consensus'];
      final bVal = b.additionalRanks['Consensus'];
      if (aVal == null && bVal == null) return 0;
      if (aVal == null) return 1;
      if (bVal == null) return -1;
      return (aVal as num).compareTo(bVal as num);
    });
    
    // Update consensus rank positions and replace the rankings list
    final finalRankings = <PlayerRanking>[];
    for (int i = 0; i < updatedRankings.length; i++) {
      finalRankings.add(updatedRankings[i].copyWith(rank: i + 1));
    }
    
    setState(() {
      _rankings = finalRankings;
      _filteredRankings = List.from(_rankings);
      _resetPagination();
      _updateVisibleRankings();
    });
    
    // Update VORP board if in VORP mode
    if (_showVORPMode) {
      _calculateVORPBoard();
    }
  }

  /// Load custom rankings data and convert to position-based player rankings
  Future<Map<String, Map<String, double>>> _loadCustomRankingsData() async {
    final rankings = await _customRankingService.getAllRankings();
    final result = <String, Map<String, double>>{};
    
    for (final ranking in rankings) {
      final positionMap = <String, double>{};
      for (final playerRank in ranking.playerRanks) {
        positionMap[playerRank.playerId] = playerRank.customRank.toDouble();
      }
      result[ranking.position.toLowerCase()] = positionMap;
    }
    
    return result;
  }

  void _toggleVORPMode() {
    setState(() {
      _showVORPMode = !_showVORPMode;
      // Clear cache to force recalculation
      _cachedVisibleRankings.clear();
      _lastSearchQuery = '';
      _lastPositionFilter = '';
      _lastCurrentPage = -1;
      
      if (_showVORPMode) {
        _calculateVORPBoard();
      } else {
        _vorpBoard = null;
        // Restore original rankings order when exiting VORP mode
        _filteredRankings = List.from(_rankings);
        _resetPagination();
        _updateVisibleRankings();
      }
    });
  }

  Future<void> _calculateVORPBoard() async {
    if (_rankings.isEmpty) return;

    try {
      // Convert PlayerRanking objects to Map format for VORP service
      final playersData = _rankings.map((player) {
        return {
          'player_id': player.id,
          'fantasy_player_name': player.name,
          'player_name': player.name,
          'position': player.position.toLowerCase(),
          'posteam': player.team,
          'team': player.team,
          'myRankNum': player.rank,
          'rank': player.rank,
          'tier': _getPositionTier(player.position, player.rank),
          // Include all ranking data
          ...player.additionalRanks.map((key, value) => MapEntry(key.toLowerCase(), value)),
        };
      }).toList();

      VORPBoard vorpBoard;
      if (_usingCustomWeights) {
        // Use custom weights for VORP calculation
        vorpBoard = VORPService.calculateVORPWithCustomWeights(
          playersData,
          _consensusWeights.allWeights,
          leagueSettings: _leagueSettings,
          scoringSystem: _scoringSystem,
        );
      } else {
        // Use standard consensus rankings
        vorpBoard = VORPService.calculateVORP(
          playersData,
          leagueSettings: _leagueSettings,
          scoringSystem: _scoringSystem,
        );
      }

      setState(() {
        _vorpBoard = VORPBigBoard.fromVORPBoard(
          vorpBoard,
          customWeights: _usingCustomWeights ? _consensusWeights.allWeights : null,
          usingCustomWeights: _usingCustomWeights,
        );
        
        // Update filtered rankings to match VORP order if in VORP mode
        if (_showVORPMode && _vorpBoard != null) {
          _updateRankingsFromVORP();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating VORP: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateRankingsFromVORP() {
    if (_vorpBoard == null) return;

    // Create a map for quick lookup
    final vorpPlayerMap = <String, VORPBigBoardPlayer>{};
    for (final vorpPlayer in _vorpBoard!.players) {
      vorpPlayerMap[vorpPlayer.playerId] = vorpPlayer;
    }

    // Update rankings with VORP data
    final updatedRankings = <PlayerRanking>[];
    for (final vorpPlayer in _vorpBoard!.players) {
      final originalPlayer = _rankings.firstWhere(
        (p) => p.id == vorpPlayer.playerId,
        orElse: () => _rankings.first, // fallback
      );
      
      // Create new additional ranks with VORP data
      final updatedAdditionalRanks = Map<String, dynamic>.from(originalPlayer.additionalRanks);
      updatedAdditionalRanks['VORP'] = vorpPlayer.vorp;
      updatedAdditionalRanks['Projected Points'] = vorpPlayer.projectedPoints;
      updatedAdditionalRanks['VORP Tier'] = vorpPlayer.vorpTier;
      
      final updatedPlayer = originalPlayer.copyWith(
        rank: vorpPlayer.overallRank,
        additionalRanks: updatedAdditionalRanks,
      );
      
      updatedRankings.add(updatedPlayer);
    }

    setState(() {
      _filteredRankings = updatedRankings;
      _resetPagination();
      _updateVisibleRankings();
    });
  }

  int _getPositionTier(String position, int rank) {
    // Simple tier calculation based on position rank
    switch (position.toLowerCase()) {
      case 'qb':
        if (rank <= 3) return 1;
        if (rank <= 8) return 2;
        if (rank <= 15) return 3;
        return 4;
      case 'rb':
      case 'wr':
        if (rank <= 6) return 1;
        if (rank <= 15) return 2;
        if (rank <= 30) return 3;
        return 4;
      case 'te':
        if (rank <= 3) return 1;
        if (rank <= 8) return 2;
        if (rank <= 15) return 3;
        return 4;
      default:
        return 4;
    }
  }

  void _sortData(String column, bool ascending) {
    _filteredRankings.sort((a, b) {
      dynamic aValue;
      dynamic bValue;
      switch (column) {
        case 'Name':
          aValue = a.name;
          bValue = b.name;
          break;
        case 'Position':
          aValue = a.position;
          bValue = b.position;
          break;
        case 'Team':
          aValue = a.team;
          bValue = b.team;
          break;
        case 'ESPN':
          aValue = a.additionalRanks['ESPN'];
          bValue = b.additionalRanks['ESPN'];
          break;
        case 'PFF':
          aValue = a.additionalRanks['PFF'];
          bValue = b.additionalRanks['PFF'];
          break;
        case 'CBS':
          aValue = a.additionalRanks['CBS'];
          bValue = b.additionalRanks['CBS'];
          break;
        case 'FFToday':
          aValue = a.additionalRanks['FFToday'];
          bValue = b.additionalRanks['FFToday'];
          break;
        case 'FootballGuys':
          aValue = a.additionalRanks['FootballGuys'];
          bValue = b.additionalRanks['FootballGuys'];
          break;
        case 'Yahoo':
          aValue = a.additionalRanks['Yahoo'];
          bValue = b.additionalRanks['Yahoo'];
          break;
        case 'NFL':
          aValue = a.additionalRanks['NFL'];
          bValue = b.additionalRanks['NFL'];
          break;
        case 'Consensus':
          aValue = a.additionalRanks['Consensus'];
          bValue = b.additionalRanks['Consensus'];
          break;
        case 'Consensus Rank':
          aValue = a.rank; // Main rank is consensus
          bValue = b.rank;
          break;
        case 'Bye':
          aValue = a.additionalRanks['Bye'];
          bValue = b.additionalRanks['Bye'];
          break;
        case 'VORP':
          aValue = a.additionalRanks['VORP'];
          bValue = b.additionalRanks['VORP'];
          break;
        case 'Projected Points':
          aValue = a.additionalRanks['Projected Points'];
          bValue = b.additionalRanks['Projected Points'];
          break;
        case 'VORP Tier':
          aValue = a.additionalRanks['VORP Tier'];
          bValue = b.additionalRanks['VORP Tier'];
          break;
        default:
          if (_customColumns.any((c) => c.title == column)) {
            final col = _customColumns.firstWhere((c) => c.title == column);
            aValue = col.values[a.id];
            bValue = col.values[b.id];
          } else {
          aValue = a.name;
          bValue = b.name;
          }
      }
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? 1 : -1;
      if (bValue == null) return ascending ? -1 : 1;
      if (aValue is num && bValue is num) {
        return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      return ascending ? aValue.toString().compareTo(bValue.toString()) : bValue.toString().compareTo(aValue.toString());
    });
  }

  void _onAddCustomColumn() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Custom Column'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Column Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.darkNavy,
                foregroundColor: ThemeConfig.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (title != null && title.isNotEmpty) {
      final newCol = CustomColumn(title: title);
      for (final player in _rankings) {
        final consensusRank = player.rank; // Use main rank now
          newCol.values[player.id] = consensusRank;
      }
      setState(() {
        _customColumns.add(newCol);
      });
    }
  }

  void _onRemoveCustomColumn(int index) {
    setState(() {
      _customColumns.removeAt(index);
    });
  }

  void _editCustomRank(BuildContext context, String id, int? currentValue, int colIndex) async {
    final controller = TextEditingController(text: currentValue?.toString() ?? '');
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Set ${_customColumns[colIndex].title}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter custom rank',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                final value = int.tryParse(text);
                Navigator.pop(context, value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.darkNavy,
                foregroundColor: ThemeConfig.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        _customColumns[colIndex].values[id] = result;
      });
    }
  }

  void _onUpdateRanks() {
    setState(() {
      for (final player in _rankings) {
        final ranks = <num>[];
        if (player.rank > 0) ranks.add(player.rank);
        final fp = player.additionalRanks['FantasyPro'];
        if (fp != null) ranks.add(fp);
        final cbs = player.additionalRanks['CBS'];
        if (cbs != null) ranks.add(cbs);
        for (final col in _customColumns) {
          final val = col.values[player.id];
          if (val != null) ranks.add(val);
        }
        final consensus = ranks.isNotEmpty ? ranks.reduce((a, b) => a + b) / ranks.length : null;
        player.additionalRanks['Consensus'] = consensus;
      }
      final sorted = List<PlayerRanking>.from(_rankings);
      sorted.sort((a, b) {
        final aVal = a.additionalRanks['Consensus'];
        final bVal = b.additionalRanks['Consensus'];
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return 1;
        if (bVal == null) return -1;
        return (aVal as num).compareTo(bVal as num);
      });
      for (int i = 0; i < sorted.length; i++) {
        sorted[i].additionalRanks['Consensus Rank'] = i + 1;
      }
    });
  }

  Future<void> _onImportCSV() async {
    if (_customColumns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add a custom column first.'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.bytes != null) {
      final csvString = utf8.decode(result.files.single.bytes!);
      final lines = const LineSplitter().convert(csvString);
      // Expecting: Name,CustomRank
      final Map<String, int> importMap = {};
      for (final line in lines.skip(1)) {
        final parts = line.split(',');
        if (parts.length < 2) continue;
        final name = parts[0].trim();
        final value = int.tryParse(parts[1].trim());
        if (value != null) {
          // Find player by name
          final player = _rankings.where((p) => p.name == name).toList();
          if (player.isNotEmpty) {
            importMap[player.first.id] = value;
          }
        }
      }
      setState(() {
        // Always update the most recently added custom column
        final col = _customColumns.last;
        col.values.addAll(importMap);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Custom ranks imported successfully!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildPlayerCard(PlayerRanking player, int index) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ThemeConfig.gold.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeConfig.darkNavy.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Could add player detail dialog here
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with rank, name, position
                      Row(
                        children: [
                          // Consensus rank badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ThemeConfig.gold,
                                  ThemeConfig.gold.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: ThemeConfig.gold.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '#${player.rank}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Player info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.brightness == Brightness.dark 
                                      ? Colors.white 
                                      : ThemeConfig.darkNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Position badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getPositionColor(player.position).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getPositionColor(player.position),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        player.position,
                                        style: TextStyle(
                                          color: _getPositionColor(player.position),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Team logo and name
                                    if (player.team.isNotEmpty) ...[
                                      TeamLogoUtils.buildNFLTeamLogo(player.team, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        player.team,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                    
                                    const Spacer(),
                                    
                                    // Bye week
                                    if (player.additionalRanks['Bye'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Bye ${player.additionalRanks['Bye']}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Rankings grid
                      _buildRankingsGrid(player, theme),
                      
                      // Custom columns if any
                      if (_customColumns.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildCustomRankings(player, theme),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildRankingsGrid(PlayerRanking player, ThemeData theme) {
    final rankings = [
      {'label': 'PFF', 'value': player.additionalRanks['PFF']},
      {'label': 'CBS', 'value': player.additionalRanks['CBS']},
      {'label': 'ESPN', 'value': player.additionalRanks['ESPN']},
      {'label': 'FFToday', 'value': player.additionalRanks['FFToday']},
      {'label': 'FG', 'value': player.additionalRanks['FootballGuys']},
      {'label': 'Yahoo', 'value': player.additionalRanks['Yahoo']},
      {'label': 'NFL', 'value': player.additionalRanks['NFL']},
    ];

    // Add custom rankings if active
    if (_includeCustomRankings && player.additionalRanks['My Custom Rankings'] != null) {
      rankings.insert(0, {'label': 'My Custom', 'value': player.additionalRanks['My Custom Rankings']});
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Rankings',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.darkNavy,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: rankings.map((ranking) {
              final value = ranking['value'];
              final isCustom = ranking['label'] == 'My Custom';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCustom 
                    ? ThemeConfig.gold.withOpacity(0.2)
                    : (value != null 
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCustom 
                      ? ThemeConfig.gold
                      : (value != null 
                          ? ThemeConfig.darkNavy.withOpacity(0.2)
                          : theme.dividerColor.withOpacity(0.3)),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCustom) ...[
                          Icon(
                            Icons.star,
                            size: 12,
                            color: ThemeConfig.gold,
                          ),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          ranking['label'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: isCustom ? FontWeight.bold : FontWeight.w500,
                            color: isCustom 
                              ? ThemeConfig.darkNavy
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value?.toString() ?? '-',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCustom 
                          ? ThemeConfig.darkNavy
                          : (value != null 
                              ? ThemeConfig.darkNavy
                              : theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRankings(PlayerRanking player, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeConfig.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeConfig.gold.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Rankings',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.darkNavy,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _customColumns.map((col) {
              final value = col.values[player.id];
              return GestureDetector(
                onTap: () => _editCustomRank(context, player.id, value, _customColumns.indexOf(col)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeConfig.gold.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        col.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value?.toString() ?? '-',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.darkNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position.toUpperCase()) {
      case 'QB':
        return Colors.red.shade600;
      case 'RB':
        return Colors.green.shade600;
      case 'WR':
        return Colors.blue.shade600;
      case 'TE':
        return Colors.orange.shade600;
      case 'K':
        return Colors.purple.shade600;
      case 'D/ST':
        return Colors.brown.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);
    final List<String> positions = ['All', 'QB', 'RB', 'WR', 'TE', 'K', 'D/ST'];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: currentRouteName)),
          ],
        ),
        actions: [
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(20),
            shadowColor: ThemeConfig.gold.withOpacity(0.2),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                _fetchRankings();
              },
              tooltip: 'Refresh Rankings',
              style: IconButton.styleFrom(
                backgroundColor: ThemeConfig.darkNavy,
                foregroundColor: ThemeConfig.gold,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Compact header section
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: ThemeConfig.darkNavy.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Title row with action buttons
                      Row(
                        children: [
                          // Title section
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fantasy Big Board',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: ThemeConfig.darkNavy,
                                  ),
                                ),
                                Text(
                                  'Comprehensive rankings from multiple platforms',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Action buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _toggleWeightPanel();
                                  },
                                  icon: Icon(
                                    _showWeightPanel ? Icons.close : Icons.tune,
                                    size: 16,
                                  ),
                                  label: Text(_showWeightPanel ? 'Close' : 'Customize', style: const TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _includeCustomRankings 
                                        ? ThemeConfig.gold 
                                        : (_usingCustomWeights ? Colors.blue.shade600 : ThemeConfig.darkNavy),
                                    foregroundColor: _includeCustomRankings ? ThemeConfig.darkNavy : Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              // VORP Mode Toggle
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Material(
                                  elevation: 1,
                                  borderRadius: BorderRadius.circular(16),
                                  shadowColor: _showVORPMode ? Colors.green.withOpacity(0.3) : ThemeConfig.gold.withOpacity(0.2),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _toggleVORPMode();
                                    },
                                    icon: Icon(
                                      _showVORPMode ? Icons.analytics : Icons.bar_chart,
                                      size: 16,
                                    ),
                                    label: Text(_showVORPMode ? 'Exit VORP' : 'VORP Mode', style: const TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _showVORPMode ? Colors.green.shade600 : ThemeConfig.darkNavy,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Material(
                                elevation: 1,
                                borderRadius: BorderRadius.circular(16),
                                shadowColor: ThemeConfig.gold.withOpacity(0.2),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _onAddCustomColumn();
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Add Column', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ThemeConfig.darkNavy,
                                    foregroundColor: ThemeConfig.gold,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                elevation: 0,
                                borderRadius: BorderRadius.circular(16),
                                child: OutlinedButton.icon(
                                  onPressed: _onImportCSV,
                                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                                  label: const Text('Import CSV', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ThemeConfig.darkNavy,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: BorderSide(color: ThemeConfig.darkNavy.withOpacity(0.3)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Search and filters row
                      Row(
                        children: [
                          // Search bar
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: ThemeConfig.darkNavy.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search players...',
                                  hintStyle: const TextStyle(fontSize: 14),
                                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: ThemeConfig.darkNavy.withOpacity(0.7)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: _filterRankings,
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Position filters
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: positions.map((pos) => Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: FilterChip(
                                    label: Text(pos, style: const TextStyle(fontSize: 12)),
                                    selected: _positionFilter == pos,
                                    onSelected: (_) {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _positionFilter = pos;
                                        _resetPagination();
                                        _updateVisibleRankings();
                                      });
                                    },
                                    backgroundColor: theme.colorScheme.surface,
                                    selectedColor: ThemeConfig.gold.withOpacity(0.2),
                                    checkmarkColor: ThemeConfig.darkNavy,
                                    labelStyle: TextStyle(
                                      color: _positionFilter == pos 
                                        ? ThemeConfig.darkNavy 
                                        : theme.colorScheme.onSurface.withOpacity(0.7),
                                      fontWeight: _positionFilter == pos 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                    side: BorderSide(
                                      color: _positionFilter == pos 
                                        ? ThemeConfig.gold 
                                        : theme.dividerColor.withOpacity(0.3),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Responsive content - cards on mobile, table on web/desktop
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.gold),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading rankings...',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _visibleRankings.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 64,
                                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No players found',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search or filters',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Use cards on mobile (< 768px), table on web/desktop
                                      final isMobile = constraints.maxWidth < 768;
                                      
                                      if (isMobile) {
                                        return ListView.builder(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          itemCount: _visibleRankings.length,
                                          itemBuilder: (context, index) {
                                            return _buildPlayerCard(_visibleRankings[index], index);
                                          },
                                        );
                                      } else {
                                        return _buildTableWithStickyHeader();
                                      }
                                    },
                                  ),
                                ),
                                _buildPaginationControls(),
                              ],
                            ),
                ),
              ],
            ),
          ),
          
          // Weight Adjustment Panel
          if (_showWeightPanel)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: ConsensusWeightAdjustmentPanel(
                position: 'consensus',
                currentWeights: _consensusWeights,
                onWeightsChanged: _onWeightsChanged,
                onReset: _resetWeights,
                onClose: () {
                  setState(() {
                    _showWeightPanel = false;
                  });
                },
                isVisible: _showWeightPanel,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableWithStickyHeader() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Sticky header
        Container(
          decoration: BoxDecoration(
            color: ThemeAwareColors.getTableHeaderColor(context),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.transparent),
              headingTextStyle: TextStyle(
                color: ThemeAwareColors.getTableHeaderTextColor(context),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              showCheckboxColumn: false,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columnSpacing: 32,
              horizontalMargin: 16,
              dividerThickness: 0,
              columns: _getModernColumns(),
              rows: [], // Empty rows for header only
            ),
          ),
        ),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 0, // Hide header in scrollable content
                dataRowMinHeight: 56,
                dataRowMaxHeight: 56,
                showCheckboxColumn: false,
                columnSpacing: 32,
                horizontalMargin: 16,
                dividerThickness: 0,
                columns: _getModernColumns(),
                rows: _getModernRows(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTable() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeConfig.gold.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.darkNavy.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
              headingRowColor: WidgetStateProperty.all(ThemeAwareColors.getTableHeaderColor(context)),
              headingTextStyle: TextStyle(
                color: ThemeAwareColors.getTableHeaderTextColor(context),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              showCheckboxColumn: false,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columnSpacing: 32,
              horizontalMargin: 16,
              dividerThickness: 0,
              columns: _getModernColumns(),
              rows: _getModernRows(),
            ),
        ),
      ),
    );
  }

  List<DataColumn> _getModernColumns() {
    return [
      DataColumn(
        label: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('Rank'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Consensus Rank', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.centerLeft,
          child: const Text('Player'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Name', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('Pos'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Position', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('Team'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Team', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('Bye'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Bye', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('PFF'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('PFF', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('CBS'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('CBS', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('ESPN'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('ESPN', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('FFT'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('FFToday', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('FG'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('FootballGuys', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('Yahoo'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Yahoo', asc));
        },
      ),
      DataColumn(
        label: Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: const Text('NFL'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('NFL', asc));
        },
      ),
      // Custom Rankings column (only show when custom rankings are active)
      if (_includeCustomRankings)
        DataColumn(
          label: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 14,
                  color: ThemeConfig.gold,
                ),
                const SizedBox(width: 4),
                const Text(
                  'My Custom',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          onSort: (i, asc) {
            HapticFeedback.lightImpact();
            setState(() => _sortData('My Custom Rankings', asc));
          },
        ),
      // VORP columns (only show when VORP mode is enabled)
      if (_showVORPMode) ...[
        DataColumn(
          label: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text('VORP', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          numeric: true,
          onSort: (i, asc) {
            HapticFeedback.lightImpact();
            setState(() => _sortData('VORP', asc));
          },
        ),
        DataColumn(
          label: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text('Proj Pts', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          numeric: true,
          onSort: (i, asc) {
            HapticFeedback.lightImpact();
            setState(() => _sortData('Projected Points', asc));
          },
        ),
        DataColumn(
          label: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text('Tier', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          onSort: (i, asc) {
            HapticFeedback.lightImpact();
            setState(() => _sortData('VORP Tier', asc));
          },
        ),
      ],
      ..._customColumns.map((col) => DataColumn(
            label: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(col.title),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _onRemoveCustomColumn(_customColumns.indexOf(col)),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: ThemeAwareColors.getTableHeaderTextColor(context).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            onSort: (i, asc) {
              HapticFeedback.lightImpact();
              setState(() => _sortData(col.title, asc));
            },
          )),
    ];
  }

  List<DataRow> _getModernRows() {
    return _visibleRankings.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      
      return DataRow(
        color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return ThemeConfig.gold.withOpacity(0.1);
          }
          return ThemeAwareColors.getTableRowColor(context, index);
        }),
        cells: [
          // Rank cell with badge
          DataCell(
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ThemeConfig.gold,
                      ThemeConfig.gold.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${player.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          
          // Player name cell
          DataCell(
            Container(
              width: 140,
              alignment: Alignment.centerLeft,
              child: Text(
                player.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : ThemeConfig.darkNavy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Position cell with colored badge
          DataCell(
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _getPositionColor(player.position).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getPositionColor(player.position),
                    width: 1,
                  ),
                ),
                child: Text(
                  player.position,
                  style: TextStyle(
                    color: _getPositionColor(player.position),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          
          // Team cell with logo
          DataCell(
            Container(
              width: 80,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (player.team.isNotEmpty) ...[
                    TeamLogoUtils.buildNFLTeamLogo(player.team, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      player.team,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Ranking cells
          DataCell(_buildRankingCell(player.additionalRanks['Bye'], index, width: 50)),
          DataCell(_buildRankingCell(player.additionalRanks['PFF'], index, width: 50)),
          DataCell(_buildRankingCell(player.additionalRanks['CBS'], index, width: 50)),
          DataCell(_buildRankingCell(player.additionalRanks['ESPN'], index, width: 60)),
          DataCell(_buildRankingCell(player.additionalRanks['FFToday'], index, width: 50)),
          DataCell(_buildRankingCell(player.additionalRanks['FootballGuys'], index, width: 50)),
          DataCell(_buildRankingCell(player.additionalRanks['Yahoo'], index, width: 60)),
          DataCell(_buildRankingCell(player.additionalRanks['NFL'], index, width: 50)),
          
          // Custom Rankings column (only show when custom rankings are active)
          if (_includeCustomRankings)
            DataCell(_buildCustomRankingCell(player.additionalRanks['My Custom Rankings'], index)),
          
          // VORP columns (only show when VORP mode is enabled)
          if (_showVORPMode) ...[
            DataCell(_buildVORPCell(player.additionalRanks['VORP'], index)),
            DataCell(_buildRankingCell(player.additionalRanks['Projected Points'], index)),
            DataCell(_buildVORPTierCell(player.additionalRanks['VORP Tier'], index)),
          ],
          
          // Custom columns
          ..._customColumns.map((col) {
            final value = col.values[player.id];
            return DataCell(
              GestureDetector(
                onTap: () => _editCustomRank(context, player.id, value, _customColumns.indexOf(col)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ThemeConfig.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: ThemeConfig.gold.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    value?.toString() ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ThemeConfig.darkNavy,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }).toList();
  }

  Widget _buildRankingCell(dynamic value, int index, {double width = 50}) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: value != null 
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value?.toString() ?? '-',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: value != null 
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCustomRankingCell(dynamic value, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: value != null 
          ? ThemeConfig.gold.withOpacity(0.2)
          : ThemeConfig.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ThemeConfig.gold.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 10,
            color: ThemeConfig.gold,
          ),
          const SizedBox(width: 2),
          Text(
            value?.toString() ?? '-',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: value != null 
                ? ThemeConfig.darkNavy
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVORPCell(dynamic value, int index) {
    if (value == null) return _buildRankingCell(value, index);
    
    final vorp = value as double;
    final isPositive = vorp >= 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isPositive 
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPositive 
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        isPositive ? '+${vorp.toStringAsFixed(1)}' : vorp.toStringAsFixed(1),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildVORPTierCell(dynamic value, int index) {
    if (value == null) return _buildRankingCell(value, index);
    
    final tier = value.toString();
    final tierColor = _getVORPTierColor(tier);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Color(tierColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Color(tierColor).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        tier,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(tierColor),
          fontSize: 11,
        ),
      ),
    );
  }

  int _getVORPTierColor(String tier) {
    switch (tier) {
      case 'Elite':
        return 0xFF4CAF50; // Green
      case 'High':
        return 0xFF8BC34A; // Light Green
      case 'Solid':
        return 0xFF2196F3; // Blue
      case 'Decent':
        return 0xFFFF9800; // Orange
      case 'Replacement':
        return 0xFF9E9E9E; // Grey
      case 'Below Replacement':
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Default Grey
    }
  }

  Widget _buildPaginationControls() {
    final theme = Theme.of(context);
    final totalPages = (_totalRecords / _rowsPerPage).ceil().clamp(1, 9999);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info
          Text(
            'Page ${_currentPage + 1} of $totalPages. Total: $_totalRecords players.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          
          // Navigation buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: ThemeConfig.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                  disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                child: const Text('Previous'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _hasNextPage ? _goToNextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: ThemeConfig.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                  disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 