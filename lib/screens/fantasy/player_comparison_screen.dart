import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../utils/team_logo_utils.dart';

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
  String selectedSeason = '2023';
  int activeSearchIndex = -1;
  final TextEditingController searchController = TextEditingController();
  
  final List<String> seasons = ['2023', '2022', '2021', '2020', '2019'];

  @override
  void initState() {
    super.initState();
    _loadDefaultPlayers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultPlayers() async {
    if (!mounted) return;
    
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final callable = FirebaseFunctions.instance.httpsCallable('getTopPlayersByPosition');
      final result = await callable.call({
        'position': 'WR',
        'season': int.parse(selectedSeason),
        'limit': 2,
      });

      if (!mounted) return;

      if (result.data['data'] != null && result.data['data'].isNotEmpty) {
        setState(() {
          selectedPlayers = List<Map<String, dynamic>>.from(result.data['data']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No default players found';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = _handleFirebaseError(e, 'loading default players');
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

      final callable = FirebaseFunctions.instance.httpsCallable('getPlayerStats');
      final result = await callable.call({
        'searchQuery': query,
        'filters': {
          'season': int.parse(selectedSeason),
        },
        'limit': 20,
      });

      if (!mounted) return;

      setState(() {
        searchResults = List<Map<String, dynamic>>.from(result.data['data'] ?? []);
        isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSearching = false;
        searchResults = [];
        errorMessage = _handleFirebaseError(e, 'searching players');
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

  String _handleFirebaseError(dynamic error, String operation) {
    final errorString = error.toString();
    
    if (errorString.contains('FAILED_PRECONDITION') && errorString.contains('index')) {
      final urlMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(errorString);
      final indexUrl = urlMatch?.group(0) ?? '';
      
      if (indexUrl.isNotEmpty) {
        _logMissingIndex(indexUrl, operation);
      }
      
      return 'Missing Database Index Required - Check console for setup link';
    }
    
    if (errorString.contains('permission-denied')) {
      return 'Permission denied. Please sign in to access this feature.';
    }
    
    if (errorString.contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again in a moment.';
    }
    
    return 'Error $operation: ${errorString.length > 100 ? '${errorString.substring(0, 100)}...' : errorString}';
  }

  Future<void> _logMissingIndex(String indexUrl, String operation) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('logMissingIndex');
      await callable.call({
        'url': indexUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'screenName': 'PlayerComparisonScreen',
        'queryDetails': {
          'operation': operation,
          'season': selectedSeason,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'errorMessage': 'Index required for player comparison functionality',
      });
      print('Missing index logged successfully for operation: $operation');
    } catch (e) {
      print('Failed to log missing index: $e');
    }
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
            child: ElevatedButton(
              onPressed: () => showDialog(context: context, builder: (_) => const AuthDialog()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Sign In / Sign Up'),
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
            color: const Color(0xFF1a237e),
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
                  dropdownColor: const Color(0xFF1a237e),
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
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
                      child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
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
                            title: Text(player['player_display_name']?.toString() ?? 'Unknown'),
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
                          player['player_display_name']?.toString() ?? 'Unknown Player',
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
                    '${player['fantasy_points_ppr']?.toStringAsFixed(1) ?? '0.0'}',
                    'PPR Points',
                  ),
                  _buildStatBubble(
                    player['games']?.toString() ?? '0',
                    'Games',
                  ),
                  _buildStatBubble(
                    '${player['ppr_points_per_game']?.toStringAsFixed(1) ?? '0.0'}',
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
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade700),
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          columnSpacing: 32,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 48,
          columns: [
            const DataColumn(
              label: Text('Statistic', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...selectedPlayers.map((player) => DataColumn(
              label: SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (player['player_display_name']?.toString() ?? 'Unknown').length > 15 
                          ? '${(player['player_display_name']?.toString() ?? 'Unknown').substring(0, 15)}...'
                          : player['player_display_name']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    Text(
                      '${player['team']} ${player['position']}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
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
      {'label': 'Games Played', 'field': 'games'},
      {'label': 'Fantasy Points (PPR)', 'field': 'fantasy_points_ppr', 'format': 'decimal'},
      {'label': 'PPR Points/Game', 'field': 'ppr_points_per_game', 'format': 'decimal'},
      {'label': 'Fantasy Points (Standard)', 'field': 'fantasy_points_std', 'format': 'decimal'},
      
      // Passing Stats (if applicable)
      if (selectedPlayers.any((p) => p['position'] == 'QB')) ...[
        {'category': 'Passing'},
        {'label': 'Passing Yards', 'field': 'passing_yards'},
        {'label': 'Passing TDs', 'field': 'passing_tds'},
        {'label': 'Interceptions', 'field': 'interceptions'},
        {'label': 'Completion %', 'field': 'completion_percentage', 'format': 'percentage'},
        {'label': 'Passer Rating', 'field': 'passer_rating', 'format': 'decimal'},
      ],
      
      // Rushing Stats
      if (selectedPlayers.any((p) => ['RB', 'QB'].contains(p['position']))) ...[
        {'category': 'Rushing'},
        {'label': 'Rushing Yards', 'field': 'rushing_yards'},
        {'label': 'Rushing TDs', 'field': 'rushing_tds'},
        {'label': 'Rushing Attempts', 'field': 'carries'},
        {'label': 'Yards per Carry', 'field': 'rushing_yards_per_attempt', 'format': 'decimal'},
      ],
      
      // Receiving Stats
      if (selectedPlayers.any((p) => ['WR', 'TE', 'RB'].contains(p['position']))) ...[
        {'category': 'Receiving'},
        {'label': 'Receiving Yards', 'field': 'receiving_yards'},
        {'label': 'Receiving TDs', 'field': 'receiving_tds'},
        {'label': 'Receptions', 'field': 'receptions'},
        {'label': 'Targets', 'field': 'targets'},
        {'label': 'Catch %', 'field': 'catch_percentage', 'format': 'percentage'},
        {'label': 'Target Share', 'field': 'target_share', 'format': 'percentage'},
      ],
      
      // Advanced Stats
      {'category': 'Advanced'},
      {'label': 'Air Yards Share', 'field': 'air_yards_share', 'format': 'percentage'},
      {'label': 'WOPR', 'field': 'wopr', 'format': 'decimal'},
      {'label': 'Yards per Touch', 'field': 'yards_per_touch', 'format': 'decimal'},
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
                  displayValue = '${((value as num) * 100).toStringAsFixed(1)}%';
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