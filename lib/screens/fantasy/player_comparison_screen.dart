import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/theme_config.dart';
import '../../utils/seo_helper.dart';
import '../../services/csv_player_stats_service.dart';

class PlayerComparisonScreen extends StatefulWidget {
  const PlayerComparisonScreen({Key? key}) : super(key: key);

  @override
  State<PlayerComparisonScreen> createState() => _PlayerComparisonScreenState();
}

class _PlayerComparisonScreenState extends State<PlayerComparisonScreen> {
  List<Map<String, dynamic>> selectedPlayers = [];
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  bool isSearching = false;
  String errorMessage = '';
  String selectedSeason = '2024';
  int activeSearchIndex = -1;
  final TextEditingController searchController = TextEditingController();
  
  List<String> seasons = [];

  @override
  void initState() {
    super.initState();
    
    // Update SEO meta tags for Player Comparison page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForPlayerComparison();
    });
    
    _loadAvailableSeasons();
    _loadDefaultPlayers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableSeasons() async {
    try {
      final availableSeasons = await CsvPlayerStatsService.getSeasons();
      setState(() {
        seasons = availableSeasons.reversed.toList(); // Most recent first
        if (seasons.isNotEmpty && !seasons.contains(selectedSeason)) {
          selectedSeason = seasons.first;
        }
      });
    } catch (e) {
      setState(() {
        seasons = ['2024', '2023', '2022', '2021', '2020', '2019'];
      });
    }
  }

  Future<void> _loadDefaultPlayers() async {
    if (!mounted) return;
    
    print('DEBUG: _loadDefaultPlayers called with season=$selectedSeason');
    
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Get top WR players for the selected season
      final players = await CsvPlayerStatsService.getPlayerStats(
        season: selectedSeason,
        position: 'WR',
        limit: 2,
        orderBy: 'fantasy_points_ppr',
        orderDescending: true,
      );

      print('DEBUG: Received ${players.length} default players');

      if (!mounted) return;

      if (players.isNotEmpty) {
        setState(() {
          selectedPlayers = players.take(2).toList();
          isLoading = false;
        });
        
        print('DEBUG: Set ${selectedPlayers.length} default players');
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No default players found for selected season';
        });
      }
    } catch (e, stackTrace) {
      print('ERROR: Error in _loadDefaultPlayers: $e');
      print('ERROR: Stack trace: $stackTrace');
      
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading default players: ${e.toString()}';
      });
    }
  }

  Future<void> _searchPlayers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    try {
      setState(() {
        isSearching = true;
      });

      final players = await CsvPlayerStatsService.getPlayerStats(
        season: selectedSeason,
        playerName: query,
        limit: 20,
        orderBy: 'fantasy_points_ppr',
        orderDescending: true,
      );

      if (!mounted) return;

      setState(() {
        searchResults = players;
        isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSearching = false;
        searchResults = [];
        errorMessage = 'Error searching players: ${e.toString()}';
      });
    }
  }

  void _selectPlayer(Map<String, dynamic> player) {
    setState(() {
      if (activeSearchIndex < selectedPlayers.length) {
        selectedPlayers[activeSearchIndex] = player;
      } else {
        selectedPlayers.add(player);
      }
      searchResults = [];
      activeSearchIndex = -1;
      searchController.clear();
    });
  }

  void _removePlayer(int index) {
    setState(() {
      selectedPlayers.removeAt(index);
      if (activeSearchIndex >= selectedPlayers.length) {
        activeSearchIndex = -1;
      }
    });
  }

  void _startPlayerSearch(int index) {
    setState(() {
      activeSearchIndex = index;
      searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: currentRouteName)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(24),
              shadowColor: ThemeConfig.gold.withOpacity(0.3),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showDialog(context: context, builder: (_) => const AuthDialog());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: ThemeConfig.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Sign In / Sign Up'),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Player Comparison Cards
          Container(
            color: ThemeConfig.darkNavy,
            child: _buildPlayerComparisonCards(),
          ),

          // Stats Comparison
          Expanded(
            child: _buildStatsComparison(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerComparisonCards() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Season Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButton<String>(
                  value: selectedSeason,
                  dropdownColor: ThemeConfig.darkNavy,
                  underline: const SizedBox(),
                  style: const TextStyle(color: ThemeConfig.gold, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down, color: ThemeConfig.gold, size: 16),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedSeason = newValue;
                        selectedPlayers.clear();
                      });
                      _loadDefaultPlayers();
                    }
                  },
                  items: seasons.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: ThemeConfig.gold, fontSize: 14)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (errorMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        errorMessage = '';
                      });
                      _loadDefaultPlayers();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Player Selection/Search Bar
          if (activeSearchIndex >= 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Search for a player',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            activeSearchIndex = -1;
                            searchResults = [];
                            searchController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                   TextField(
                     controller: searchController,
                     autofocus: true,
                     decoration: InputDecoration(
                       hintText: 'Type player name...',
                       prefixIcon: const Icon(Icons.search, size: 20),
                       suffixIcon: isSearching
                           ? const SizedBox(
                               width: 16,
                               height: 16,
                               child: Padding(
                                 padding: EdgeInsets.all(8),
                                 child: CircularProgressIndicator(strokeWidth: 2),
                               ),
                             )
                           : null,
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(6),
                       ),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                     ),
                     onChanged: _searchPlayers,
                   ),
                   if (searchResults.isNotEmpty) ...[
                     const SizedBox(height: 12),
                     Container(
                       constraints: const BoxConstraints(maxHeight: 150),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final player = searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                player['position']?.toString() ?? 'P',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(player['player_name']?.toString() ?? 'Unknown'),
                            subtitle: Text(
                              '${player['team']?.toString().trim().isNotEmpty == true ? player['team'] : 'Unknown Team'} • ${player['position'] ?? 'Unknown'} • ${player['fantasy_points_ppr']?.toStringAsFixed(1) ?? '0.0'} PPR',
                            ),
                            onTap: () => _selectPlayer(player),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // Player Cards Row
          Row(
            children: [
              // Player 1
              Expanded(
                child: _buildLargePlayerCard(
                  selectedPlayers.isNotEmpty ? selectedPlayers[0] : null,
                  0,
                  'Player 1',
                ),
              ),
              const SizedBox(width: 16),
               // VS indicator
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.1),
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: const Text(
                   'VS',
                   style: TextStyle(
                     color: Colors.white,
                     fontWeight: FontWeight.bold,
                     fontSize: 14,
                   ),
                 ),
               ),
               const SizedBox(width: 16),
              // Player 2
              Expanded(
                child: _buildLargePlayerCard(
                  selectedPlayers.length > 1 ? selectedPlayers[1] : null,
                  1,
                  'Player 2',
                ),
              ),
            ],
          ),
          
          // Additional Players Row (if any)
           if (selectedPlayers.length > 2 || activeSearchIndex >= 2) ...[
             const SizedBox(height: 16),
             Row(
               children: [
                 if (selectedPlayers.length > 2 || activeSearchIndex == 2)
                   Expanded(
                     child: _buildLargePlayerCard(
                       selectedPlayers.length > 2 ? selectedPlayers[2] : null,
                       2,
                       'Player 3',
                     ),
                   ),
                 if (selectedPlayers.length > 2 || activeSearchIndex == 2) const SizedBox(width: 16),
                 if (selectedPlayers.length > 3 || activeSearchIndex == 3)
                   Expanded(
                     child: _buildLargePlayerCard(
                       selectedPlayers.length > 3 ? selectedPlayers[3] : null,
                       3,
                       'Player 4',
                     ),
                   ),
                 if (selectedPlayers.length <= 2 && activeSearchIndex < 2)
                   Expanded(
                     child: _buildAddPlayerButton(),
                   ),
               ],
             ),
           ] else ...[
             const SizedBox(height: 16),
             _buildAddPlayerButton(),
           ],
        ],
      ),
    );
  }

  Widget _buildLargePlayerCard(Map<String, dynamic>? player, int index, String placeholder) {
    final bool hasPlayer = player != null;
    
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: hasPlayer
          ? _buildPlayerContent(player, index)
          : _buildEmptyPlayerSlot(index, placeholder),
    );
  }

  Widget _buildPlayerContent(Map<String, dynamic> player, int index) {
    // Calculate derived stats
    final fantasyPoints = (player['fantasy_points_ppr'] as num?)?.toDouble() ?? 0.0;
    final games = _getValidGames(player);
    final ppg = games > 0 ? fantasyPoints / games : 0.0;
    
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Team Logo
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.grey[100],
                    ),
                    child: TeamLogoUtils.buildNFLTeamLogo(
                      player['team']?.toString().trim() ?? '',
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player['player_name']?.toString() ?? 'Unknown Player',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${player['position'] ?? 'Unknown'} - ${player['team']?.toString().trim().isNotEmpty == true ? player['team'] : 'Unknown Team'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Key Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBubble(
                    fantasyPoints.toStringAsFixed(1),
                    'PPR Points',
                  ),
                  _buildStatBubble(
                    games.toString(),
                    'Games',
                  ),
                  _buildStatBubble(
                    ppg.toStringAsFixed(1),
                    'PPG',
                  ),
                ],
              ),
            ],
          ),
        ),
        // Remove button
        Positioned(
          top: 6,
          right: 6,
          child: IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => _removePlayer(index),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              padding: const EdgeInsets.all(2),
              minimumSize: const Size(24, 24),
            ),
          ),
        ),
      ],
    );
  }

  int _getValidGames(Map<String, dynamic> player) {
    // Count unique weeks for this player/season/team
    // For CSV data, we'll estimate based on whether they have meaningful stats
    final fantasyPoints = (player['fantasy_points_ppr'] as num?)?.toDouble() ?? 0.0;
    final targets = (player['targets'] as num?)?.toInt() ?? 0;
    final carries = (player['carries'] as num?)?.toInt() ?? 0;
    final attempts = (player['attempts'] as num?)?.toInt() ?? 0;
    
    // Estimate games played based on activity level
    if (fantasyPoints > 100) return 17; // Full season
    if (fantasyPoints > 50) return (fantasyPoints / 8).round().clamp(1, 17);
    if (targets > 10 || carries > 10 || attempts > 10) return (fantasyPoints / 5).round().clamp(1, 17);
    return fantasyPoints > 0 ? 1 : 0;
  }

  Widget _buildEmptyPlayerSlot(int index, String placeholder) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startPlayerSearch(index),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
             border: Border.all(color: Colors.grey[300]!, width: 2),
             borderRadius: BorderRadius.circular(16),
           ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.blue[600],
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                placeholder,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to search',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPlayerButton() {
    if (selectedPlayers.length >= 4) return const SizedBox();
    
    return SizedBox(
      height: 60,
      child: Material(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _startPlayerSearch(selectedPlayers.length),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Add Another Player',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBubble(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blue[700],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsComparison() {
    if (selectedPlayers.length < 2) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Select at least 2 players to compare',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose players above to see detailed statistics comparison',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: _buildComparisonTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(ThemeConfig.darkNavy),
          columnSpacing: 32,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 48,
          columns: [
            const DataColumn(
              label: Text(
                'STAT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ...selectedPlayers.map((player) => DataColumn(
              label: SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (player['player_name']?.toString() ?? 'Unknown').length > 15 
                          ? '${(player['player_name']?.toString() ?? 'Unknown').substring(0, 15)}...'
                          : player['player_name']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    Text(
                      '${player['team']} ${player['position']}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )),
          ],
          rows: _buildComparisonRows(),
        ),
      ),
    );
  }

  List<DataRow> _buildComparisonRows() {
    final stats = [
      // Basic Stats
      {'category': 'Basic Stats'},
      {'label': 'Fantasy Points (PPR)', 'field': 'fantasy_points_ppr', 'format': 'decimal'},
      {'label': 'Fantasy Points (Standard)', 'field': 'fantasy_points', 'format': 'decimal'},
      {'label': 'Total Yards', 'field': 'total_yards', 'format': 'decimal'},
      {'label': 'Total TDs', 'field': 'total_tds'},
      
      // Passing Stats (if applicable)
      if (selectedPlayers.any((p) => p['position'] == 'QB')) ...[
        {'category': 'Passing'},
        {'label': 'Passing Yards', 'field': 'passing_yards', 'format': 'decimal'},
        {'label': 'Passing TDs', 'field': 'passing_tds'},
        {'label': 'Interceptions', 'field': 'interceptions'},
        {'label': 'Attempts', 'field': 'attempts'},
        {'label': 'Completions', 'field': 'completions'},
        {'label': 'Completion %', 'field': 'completion_percentage', 'format': 'percentage'},
        {'label': 'Yards/Attempt', 'field': 'yards_per_attempt', 'format': 'decimal'},
      ],
      
      // Rushing Stats
      if (selectedPlayers.any((p) => ['RB', 'QB'].contains(p['position']))) ...[
        {'category': 'Rushing'},
        {'label': 'Rushing Yards', 'field': 'rushing_yards', 'format': 'decimal'},
        {'label': 'Rushing TDs', 'field': 'rushing_tds'},
        {'label': 'Carries', 'field': 'carries'},
        {'label': 'Yards per Carry', 'field': 'yards_per_carry', 'format': 'decimal'},
      ],
      
      // Receiving Stats
      if (selectedPlayers.any((p) => ['WR', 'TE', 'RB'].contains(p['position']))) ...[
        {'category': 'Receiving'},
        {'label': 'Receiving Yards', 'field': 'receiving_yards', 'format': 'decimal'},
        {'label': 'Receiving TDs', 'field': 'receiving_tds'},
        {'label': 'Receptions', 'field': 'receptions'},
        {'label': 'Targets', 'field': 'targets'},
        {'label': 'Catch %', 'field': 'catch_percentage', 'format': 'percentage'},
        {'label': 'Yards/Reception', 'field': 'yards_per_reception', 'format': 'decimal'},
        {'label': 'Yards/Target', 'field': 'yards_per_target', 'format': 'decimal'},
      ],
      
      // Advanced Stats
      {'category': 'Advanced'},
      {'label': 'Passing EPA', 'field': 'passing_epa', 'format': 'decimal'},
      {'label': 'Rushing EPA', 'field': 'rushing_epa', 'format': 'decimal'},
      {'label': 'Receiving EPA', 'field': 'receiving_epa', 'format': 'decimal'},
    ];

    List<DataRow> rows = [];

    for (var stat in stats) {
      if (stat.containsKey('category')) {
        // Category header row
        rows.add(DataRow(
          color: WidgetStateProperty.all(Colors.blue[50]),
          cells: [
            DataCell(
              Text(
                stat['category'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 14,
                ),
              ),
            ),
            ...selectedPlayers.map((player) => const DataCell(Text(''))),
          ],
        ));
      } else {
        // Data row
        rows.add(DataRow(
          cells: [
            DataCell(
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  stat['label'] as String,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            ...selectedPlayers.map((player) {
              final value = player[stat['field']];
              String displayValue = '-';
              
              if (value != null) {
                if (stat['format'] == 'decimal') {
                  displayValue = (value as num).toStringAsFixed(1);
                } else if (stat['format'] == 'percentage') {
                  displayValue = '${(value as num).toStringAsFixed(1)}%';
                } else {
                  displayValue = value.toString();
                }
              }
              
              return DataCell(
                Text(
                  displayValue,
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              );
            }),
          ],
        ));
      }
    }

    return rows;
  }
}