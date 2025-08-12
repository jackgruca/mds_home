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
import '../../services/nfl_roster_service.dart'; // Added for roster lookup
import '../../models/nfl_trade/nfl_player.dart'; // Roster model type

class PlayerComparisonScreen extends StatefulWidget {
  const PlayerComparisonScreen({super.key});

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Stats Comparison only (top band removed)
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
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const base = 1200.0;
            final maxW = constraints.maxWidth < base ? constraints.maxWidth : base;
            final isTwo = selectedPlayers.length <= 2;
            final targetWidth = isTwo ? maxW / 2 : maxW;
            return SizedBox(
              width: targetWidth,
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Search for a player',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
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
                     style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                     decoration: InputDecoration(
                       hintText: 'Type player name...',
                       hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                       prefixIcon: Icon(Icons.search, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                              child: Text(
                                player['position']?.toString() ?? 'P',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                              title: Text(
                                player['player_name']?.toString() ?? 'Unknown',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              ),
                            subtitle: Text(
                              '${player['team']?.toString().trim().isNotEmpty == true ? player['team'] : 'Unknown Team'} • ${player['position'] ?? 'Unknown'} • ${player['fantasy_points_ppr']?.toStringAsFixed(1) ?? '0.0'} PPR',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
          
          // Player Cards with inline add chip
          Builder(builder: (context) {
            final openThird = isTwo && activeSearchIndex >= 2;
            final showThree = !isTwo || openThird || selectedPlayers.length > 2;
            final showFourth = selectedPlayers.length > 3 || activeSearchIndex >= 3;
            if (!showThree) {
              // exactly two visible
              return Row(
            children: [
              Expanded(
                child: _buildLargePlayerCard(
                  selectedPlayers.isNotEmpty ? selectedPlayers[0] : null,
                  0,
                  'Player 1',
                ),
              ),
              const SizedBox(width: 16),
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
              Expanded(
                child: _buildLargePlayerCard(
                  selectedPlayers.length > 1 ? selectedPlayers[1] : null,
                  1,
                  'Player 2',
                ),
              ),
                  const Spacer(),
                  const SizedBox(width: 12),
                  _buildInlineAddChip(),
                ],
              );
            }
            // 3 or 4 columns inline
            return Column(
              children: [
             Row(
               children: [
                   Expanded(
                     child: _buildLargePlayerCard(
                        selectedPlayers.isNotEmpty ? selectedPlayers[0] : null,
                        0,
                        'Player 1',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildLargePlayerCard(
                        selectedPlayers.length > 1 ? selectedPlayers[1] : null,
                        1,
                        'Player 2',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildLargePlayerCard(
                        (selectedPlayers.length > 2) ? selectedPlayers[2] : null,
                       2,
                       'Player 3',
                     ),
                   ),
                    if (!showFourth) ...[
                      const SizedBox(width: 12),
                      _buildInlineAddChip(),
                    ],
                  ],
                ),
                if (showFourth) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                   Expanded(
                     child: _buildLargePlayerCard(
                       selectedPlayers.length > 3 ? selectedPlayers[3] : null,
                       3,
                       'Player 4',
                     ),
                   ),
               ],
             ),
           ],
              ],
            );
          }),
          const SizedBox(height: 12),
        ],
               ),
             );
           },
         ),
      ),
    );
  }

  Widget _buildLargePlayerCard(Map<String, dynamic>? player, int index, String placeholder) {
    final bool hasPlayer = player != null;
    
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${player['position'] ?? 'UNK'} - ${player['team']?.toString().trim().isNotEmpty == true ? player['team'] : 'Unknown Team'}',
                          style: const TextStyle(
                            color: Colors.white,
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
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
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
             border: Border.all(color: Theme.of(context).dividerColor, width: 2),
             borderRadius: BorderRadius.circular(16),
           ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                placeholder,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to search',
                style: TextStyle(
                  color: Colors.grey[400],
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
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

  Widget _buildInlineAddChip() {
    if (selectedPlayers.length >= 4) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceContainerHigh;
    final fg = theme.colorScheme.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _startPlayerSearch(selectedPlayers.length),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add_alt_1, size: 16, color: fg),
              const SizedBox(width: 6),
              Text('Add Player', style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBubble(String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
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
          // Inline search UI when adding/replacing a player
          if (activeSearchIndex >= 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Search for a player',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
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
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Type player name...',
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.search, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                              child: Text(
                                player['position']?.toString() ?? 'P',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              player['player_name']?.toString() ?? 'Unknown',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                            subtitle: Text(
                              '${player['team']?.toString().trim().isNotEmpty == true ? player['team'] : 'Unknown Team'} • ${player['position'] ?? 'Unknown'} • ${player['fantasy_points_ppr']?.toStringAsFixed(1) ?? '0.0'} PPR',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
          // Sticky header row aligned to grid width
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const base = 1200.0;
                final maxW = constraints.maxWidth < base ? constraints.maxWidth : base;
                final isTwo = selectedPlayers.length <= 2;
                final targetWidth = isTwo ? maxW / 2 : maxW;
                return SizedBox(width: targetWidth, child: _buildStickyHeaderRow());
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const base = 1200.0;
                    final maxW = constraints.maxWidth < base ? constraints.maxWidth : base;
                    final isTwo = selectedPlayers.length <= 2;
                    final targetWidth = isTwo ? maxW / 2 : maxW;
                    return SizedBox(
                      width: targetWidth,
                      child: _buildUnifiedStatsGrid(),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyHeaderRow() {
    final theme = Theme.of(context);
    final isTwo = selectedPlayers.length <= 2;
    Widget headerCard(int i) {
      final player = i < selectedPlayers.length ? selectedPlayers[i] : null;
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(12),
        child: player == null
            ? _buildEmptyPlayerSlot(i, 'Player ${i + 1}')
            : Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.grey[100],
                          ),
                          child: TeamLogoUtils.buildNFLTeamLogo(
                            player['team']?.toString().trim() ?? '',
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          player['player_name']?.toString() ?? 'Unknown Player',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${player['team'] ?? ''} - ${player['position'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => _removePlayer(i),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                        padding: const EdgeInsets.all(2),
                        minimumSize: const Size(24, 24),
                      ),
                    ),
                  ),
                ],
              ),
      );
    }

    if (isTwo) {
      return Row(
        children: [
          Expanded(child: headerCard(0)),
          const SizedBox(width: 12),
          // spacer matching centered attribute rail width
          SizedBox(width: 180),
          const SizedBox(width: 12),
          Expanded(child: headerCard(1)),
          const SizedBox(width: 12),
          _buildInlineAddChip(),
        ],
      );
    }
    return Row(
      children: [
        // left attribute rail width spacer
        SizedBox(width: 220),
        const SizedBox(width: 12),
        for (int i = 0; i < selectedPlayers.length; i++) ...[
          Expanded(child: headerCard(i)),
          if (i != selectedPlayers.length - 1) const SizedBox(width: 12),
        ],
        if (selectedPlayers.length < 4) ...[
          const SizedBox(width: 12),
          _buildInlineAddChip(),
        ],
      ],
    );
  }

  Widget _blankHeadshot() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: ThemeConfig.darkNavy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ===== Generic column grid renderer =====
  Widget _buildColumnGrid({
    required List<String> labels,
    required List<List<String>> perPlayerColumns,
    int? bannerRowIndex,
    Set<int>? sectionRowIndices,
  }) {
    final theme = Theme.of(context);
    final isTwo = perPlayerColumns.length == 2;
    final sectionRows = sectionRowIndices ?? <int>{};
    final int bannerRow = bannerRowIndex ?? -1;
    Widget buildLabelColumn() => SizedBox(
          width: isTwo ? 180 : 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < labels.length; i++)
                i == bannerRow
                    ? Container(
                        height: 140,
                        alignment: Alignment.center,
                        child: isTwo
                            ? _centerLabel('VS')
                            : const SizedBox.shrink(),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: sectionRows.contains(i) ? ThemeConfig.darkNavy : null,
                          borderRadius: sectionRows.contains(i) ? BorderRadius.circular(8) : null,
                          border: Border(
                            bottom: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              color: sectionRows.contains(i)
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: sectionRows.contains(i) ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
            ],
          ),
        );
    Widget buildPlayerColumn(int colIndex, List<String> values) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < values.length; i++)
                if (i == bannerRow)
                  Container(
                    height: 140,
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.centerLeft,
                    child: _buildInlineBanner(colIndex),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    child: Align(
                      alignment: isTwo ? Alignment.centerRight : Alignment.center,
                      child: Text(
                        values[i],
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
            ],
          ),
        );

    if (isTwo) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: buildPlayerColumn(0, perPlayerColumns[0])),
          const SizedBox(width: 12),
          buildLabelColumn(),
          const SizedBox(width: 12),
          Expanded(child: buildPlayerColumn(1, perPlayerColumns[1])),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLabelColumn(),
        const SizedBox(width: 12),
        for (int c = 0; c < perPlayerColumns.length; c++) ...[
          Expanded(child: buildPlayerColumn(c, perPlayerColumns[c])),
          if (c != perPlayerColumns.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  // Minimal stub; banner is now handled by the sticky header row
  Widget _buildInlineBanner(int playerIndex) => const SizedBox.shrink();

  Widget _buildUnifiedStatsGrid() {
    return FutureBuilder<List<Map<String, dynamic>?>>(
      future: Future.wait(selectedPlayers.map(_lookupRosterQuick)),
      builder: (context, snap) {
        final bios = snap.data ?? List<Map<String, dynamic>?>.filled(selectedPlayers.length, null);
        String fmtNum(dynamic v) {
          if (v == null) return '-';
          if (v is num) return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
          return v.toString();
        }
        String fmt(dynamic v) => (v == null) ? '-' : v.toString();
        String fmtH(dynamic h) => (h == null || (h is String && h.isEmpty)) ? '-' : h.toString();
        String fmtW(dynamic w) => (w == null || (w is String && w.isEmpty)) ? '-' : w.toString();

        final labels = <String>[];
        final sectionRows = <int>{};
        // Physical Info (Age, Experience, Height, Weight)
        sectionRows.add(labels.length);
        labels.add('Physical Info');
        final physFields = ['Age','Experience','Height','Weight'];
        labels.addAll(physFields);
        // Season Stats
        sectionRows.add(labels.length);
        labels.add('Season Stats ($selectedSeason)');
        final baseSeason = ['PPR Points','Total Yards','Total TDs'];
        labels.addAll(baseSeason);
        final pos = (selectedPlayers.first['position'] ?? '').toString();
        final seasonPosLabels = <String>[];
        if (pos == 'QB') {
          seasonPosLabels.addAll(['Pass Yds','Pass TD','INT','Comp %','Y/A','Sacks']);
        } else if (pos == 'RB') {
          seasonPosLabels.addAll(['Rush Yds','Rush TD','Y/C','Rec','Targets']);
        } else {
          seasonPosLabels.addAll(['Targets','Receptions','Catch %','Rec Yds','Rec TD']);
        }
        labels.addAll(seasonPosLabels);
        // Advanced
        sectionRows.add(labels.length);
        labels.add('Advanced Metrics');
        final advLabels = <String>[];
        if (pos == 'QB') {
          advLabels.addAll(['Pass EPA/play','TD %','INT %','1D (pass)','Sack Rate']);
        } else if (pos == 'RB') {
          advLabels.addAll(['Rush EPA/play','Y/C','1D (rush)','1D (rec)','YAC/Rec']);
        } else {
          advLabels.addAll(['Y/Tgt','Y/Rec','EPA/play (rec)','1D (rec)','aDOT','YAC/Rec']);
        }
        labels.addAll(advLabels);
        // Career
        sectionRows.add(labels.length);
        labels.add('Career Stats');
        final carLabels = ['Games','Total Yards','Yards/Game','Total TDs','TDs/Game','PPR Points','PPR/Game'];
        labels.addAll(carLabels);

        final perPlayerColumns = <List<String>>[];
        for (int i = 0; i < selectedPlayers.length; i++) {
          final p = selectedPlayers[i];
          final bio = i < bios.length ? bios[i] : null;
          final col = <String>[];
          // Spacer for section header: Physical Info
          col.add('');
          // Physical Info values
          col.add(fmt(bio?['age']));
          col.add(fmt(bio?['experience']));
          col.add(fmtH(bio?['height']));
          col.add(fmtW(bio?['weight']));
          // Spacer for section header: Season Stats
          col.add('');
          // Season base
          col.add(fmtNum(p['fantasy_points_ppr']));
          col.add(fmtNum(p['total_yards']));
          col.add(fmtNum(p['total_tds']));
          // Season pos-specific
          if (pos == 'QB') {
            col.add(fmtNum(p['passing_yards']));
            col.add(fmtNum(p['passing_tds']));
            col.add(fmtNum(p['interceptions']));
            col.add(fmtNum(p['completion_percentage']));
            col.add(fmtNum(p['yards_per_attempt']));
            col.add(fmtNum(p['sacks']));
          } else if (pos == 'RB') {
            col.add(fmtNum(p['rushing_yards']));
            col.add(fmtNum(p['rushing_tds']));
            col.add(fmtNum(p['yards_per_carry']));
            col.add(fmtNum(p['receptions']));
            col.add(fmtNum(p['targets']));
          } else {
            col.add(fmtNum(p['targets']));
            col.add(fmtNum(p['receptions']));
            col.add(fmtNum(p['catch_percentage']));
            col.add(fmtNum(p['receiving_yards']));
            col.add(fmtNum(p['receiving_tds']));
          }
          // Spacer for section header: Advanced
          col.add('');
          // Advanced
          if (pos == 'QB') {
            col.add(fmtNum(p['passing_epa']));
            col.add(fmtNum(p['touchdown_percentage']));
            col.add(fmtNum(p['interception_percentage']));
            col.add(fmtNum(p['passing_first_downs']));
            final sr = _rate(p['sacks'], p['attempts']);
            col.add(sr);
          } else if (pos == 'RB') {
            col.add(fmtNum(p['rushing_epa']));
            col.add(fmtNum(p['yards_per_carry']));
            col.add(fmtNum(p['rushing_first_downs']));
            col.add(fmtNum(p['receiving_first_downs']));
            final yacRec = _safeDiv(p['receiving_yards_after_catch'], p['receptions']);
            col.add(yacRec);
          } else {
            col.add(fmtNum(p['yards_per_target']));
            col.add(fmtNum(p['yards_per_reception']));
            col.add(fmtNum(p['receiving_epa']));
            col.add(fmtNum(p['receiving_first_downs']));
            final aDot = _safeDiv(p['receiving_air_yards'], p['targets']);
            final yacRec = _safeDiv(p['receiving_yards_after_catch'], p['receptions']);
            col.add(aDot);
            col.add(yacRec);
          }
          // Spacer for section header: Career
          col.add('');
          // Career
          final games = (p['games'] as num?)?.toInt() ?? _getValidGames(p);
          col.add(fmtNum(games));
          final totalY = (p['total_yards'] as num?) ?? 0;
          final totalTD = (p['total_tds'] as num?) ?? 0;
          final ppr = (p['fantasy_points_ppr'] as num?) ?? 0;
          col.add(fmtNum(totalY));
          col.add(_safeDiv(totalY, games));
          col.add(fmtNum(totalTD));
          col.add(_safeDiv(totalTD, games));
          col.add(fmtNum(ppr));
          col.add(_safeDiv(ppr, games));
          perPlayerColumns.add(col);
        }

        return _buildColumnGrid(
          labels: labels,
          perPlayerColumns: perPlayerColumns,
          bannerRowIndex: null,
          sectionRowIndices: sectionRows,
        );
      },
    );
  }

  Widget _centerLabel(String text) {
    return Container(
      width: 60,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // Adaptive row: on wide screens use [Left][Label][Right], on narrow use [Label][Left][Right]
  Widget _symRow(String label, String leftVal, String rightVal) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        // Treat only small mobile widths as narrow so 2-player compare keeps the centered label on desktop/tablet
        final isNarrow = c.maxWidth < 540;
        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(label, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                ),
                Expanded(child: Align(alignment: Alignment.centerRight, child: Text(leftVal, style: TextStyle(color: theme.colorScheme.onSurface)))),
                const SizedBox(width: 16),
                Expanded(child: Align(alignment: Alignment.centerLeft, child: Text(rightVal, style: TextStyle(color: theme.colorScheme.onSurface)))),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
          child: Row(
            children: [
              Expanded(child: Align(alignment: Alignment.centerRight, child: Text(leftVal, style: TextStyle(color: theme.colorScheme.onSurface)))),
              SizedBox(
                width: 180,
                child: Center(child: Text(label, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600))),
              ),
              Expanded(child: Align(alignment: Alignment.centerLeft, child: Text(rightVal, style: TextStyle(color: theme.colorScheme.onSurface)))),
            ],
          ),
        );
      },
    );
  }

  // Flexible row for 3+ players: label on left, values across
  Widget _rowMulti(String label, List<String> values) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(label, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
          ),
          for (final v in values) Expanded(child: Center(child: Text(v, style: TextStyle(color: theme.colorScheme.onSurface)))),
        ],
      ),
    );
  }

  // Physical info
  Widget _buildPhysicalInfoRows() {
    // Load richer roster fields for all selected players
    return FutureBuilder<List<Map<String, dynamic>?>>(
      future: Future.wait(selectedPlayers.map(_lookupRosterQuick)),
      builder: (context, snap) {
        final bios = snap.data ?? List<Map<String, dynamic>?>.filled(selectedPlayers.length, null);
        String fmtH(dynamic h) => (h == null || (h is String && h.isEmpty)) ? '-' : h.toString();
        String fmtW(dynamic w) => (w == null || (w is String && w.isEmpty)) ? '-' : w.toString();
        String fmt(dynamic v) => (v == null || (v is String && v.isEmpty)) ? '-' : v.toString();
        List<String> valsFor(String field, {bool height=false, bool weight=false}) {
          return List.generate(selectedPlayers.length, (i) {
            final b = i < bios.length ? bios[i] : null;
            final v = b?[field];
            if (height) return fmtH(v);
            if (weight) return fmtW(v);
            return fmt(v);
          });
        }
        List<String> valTeam() => List.generate(selectedPlayers.length, (i) => selectedPlayers[i]['team']?.toString() ?? '-');
        List<String> valPos() => List.generate(selectedPlayers.length, (i) => selectedPlayers[i]['position']?.toString() ?? '-');
        final labels = <String>['Team','Position','Jersey #','Age','Experience','Height','Weight','College','Contract Yrs'];
        final columns = <List<String>>[];
        for (int i=0;i<selectedPlayers.length;i++) {
          columns.add([
            valTeam()[i],
            valPos()[i],
            valsFor('jersey_number')[i],
            valsFor('age')[i],
            valsFor('experience')[i],
            valsFor('height', height:true)[i],
            valsFor('weight', weight:true)[i],
            valsFor('college')[i],
            valsFor('contractYearsRemaining')[i],
          ]);
        }
        return _buildColumnGrid(labels: labels, perPlayerColumns: columns);
      },
    );
  }

  Future<Map<String, dynamic>?> _lookupRosterQuick(Map<String, dynamic> player) async {
    try {
      final team = player['team']?.toString() ?? '';
      final name = player['player_name']?.toString() ?? '';
      final roster = await NFLRosterService.getTeamRoster(team);
      final hit = roster.firstWhere(
        (p) => p.name.toLowerCase().contains(name.toLowerCase()),
        orElse: () => roster.isNotEmpty ? roster.first : NFLPlayer(
          playerId: 'na', name: name, position: player['position'] ?? 'UNK', team: team,
          age: 0, experience: 0, marketValue: 0, contractStatus: 'na', contractYearsRemaining: 0,
          annualSalary: 0, overallRating: 0, positionRank: 0, ageAdjustedValue: 0,
          positionImportance: 0, durabilityScore: 0,
        ),
      );
      return {
        'age': hit.age,
        'experience': hit.experience,
        'contractYearsRemaining': hit.contractYearsRemaining,
        'jersey_number': hit.jerseyNumber,
        'height': hit.height,
        'weight': hit.weight,
        'college': hit.college,
      };
    } catch (_) {
      return null;
    }
  }

  // Season stats rows (position-agnostic core + position specific)
  Widget _buildSeasonStatRows() {
    String fmtNum(dynamic v) {
      if (v == null) return '-';
      if (v is num) return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
      return v.toString();
    }
    List<String> vals(String key) => List.generate(selectedPlayers.length, (i) => fmtNum(selectedPlayers[i][key]));
    final labels = <String>['PPR Points','Total Yards','Total TDs'];
    final baseColumns = <List<String>>[];
    final vPpr = vals('fantasy_points_ppr');
    final vYds = vals('total_yards');
    final vTds = vals('total_tds');
    for (int i=0;i<selectedPlayers.length;i++) {
      baseColumns.add([vPpr[i], vYds[i], vTds[i]]);
    }
    final pos = (selectedPlayers.first['position'] ?? '').toString();
    final extraLabels = <String>[];
    final extraColumns = <List<List<String>>>[];
    if (pos == 'QB') {
      final pairs = [
        ['Pass Yds','passing_yards'],
        ['Pass TD','passing_tds'],
        ['INT','interceptions'],
        ['Comp %','completion_percentage'],
        ['Y/A','yards_per_attempt'],
        ['Sacks','sacks'],
      ];
      for (final p in pairs) {
        extraLabels.add(p[0]);
        extraColumns.add(List.generate(selectedPlayers.length, (j)=>fmtNum(selectedPlayers[j][p[1]])).map((e)=>[e]).toList());
      }
    } else if (pos == 'RB') {
      final pairs = [
        ['Rush Yds','rushing_yards'],
        ['Rush TD','rushing_tds'],
        ['Y/C','yards_per_carry'],
        ['Rec','receptions'],
        ['Targets','targets'],
      ];
      for (final p in pairs) {
        extraLabels.add(p[0]);
        extraColumns.add(List.generate(selectedPlayers.length, (j)=>fmtNum(selectedPlayers[j][p[1]])).map((e)=>[e]).toList());
      }
    } else {
      final pairs = [
        ['Targets','targets'],
        ['Receptions','receptions'],
        ['Catch %','catch_percentage'],
        ['Rec Yds','receiving_yards'],
        ['Rec TD','receiving_tds'],
      ];
      for (final p in pairs) {
        extraLabels.add(p[0]);
        extraColumns.add(List.generate(selectedPlayers.length, (j)=>fmtNum(selectedPlayers[j][p[1]])).map((e)=>[e]).toList());
      }
    }
    final allLabels = [...labels, ...extraLabels];
    final perPlayerColumns = <List<String>>[];
    for (int i=0;i<selectedPlayers.length;i++) {
      perPlayerColumns.add([
        baseColumns[i][0],
        baseColumns[i][1],
        baseColumns[i][2],
        ...[for (final col in extraColumns) col[i][0]],
      ]);
    }
    return _buildColumnGrid(labels: allLabels, perPlayerColumns: perPlayerColumns);
  }

  // Advanced metrics (position-specific)
  Widget _buildAdvancedRows() {
    String fmt(dynamic v) {
      if (v == null) return '-';
      if (v is num) return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
      return v.toString();
    }
    final pos = (selectedPlayers.first['position'] ?? '').toString();
    final labels = <String>[];
    final columns = <List<String>>[];
    for (int i=0;i<selectedPlayers.length;i++) { columns.add([]); }
    if (pos == 'QB') {
      List<String> vals(String key) => List.generate(selectedPlayers.length, (i)=>fmt(selectedPlayers[i][key]));
      final pairs = [
        ['Pass EPA/play','passing_epa'],
        ['TD %','touchdown_percentage'],
        ['INT %','interception_percentage'],
        ['1D (pass)','passing_first_downs'],
      ];
      for (final p in pairs) {
        labels.add(p[0]);
        final vs = vals(p[1]);
        for (int i=0;i<vs.length;i++) { columns[i].add(vs[i]); }
      }
      labels.add('Sack Rate');
      final sackRates = List.generate(selectedPlayers.length, (i)=>_rate(selectedPlayers[i]['sacks'], selectedPlayers[i]['attempts']));
      for (int i=0;i<sackRates.length;i++) { columns[i].add(sackRates[i]); }
    } else if (pos == 'RB') {
      List<String> vals(String key) => List.generate(selectedPlayers.length, (i)=>fmt(selectedPlayers[i][key]));
      final pairs = [
        ['Rush EPA/play','rushing_epa'],
        ['Y/C','yards_per_carry'],
        ['1D (rush)','rushing_first_downs'],
        ['1D (rec)','receiving_first_downs'],
      ];
      for (final p in pairs){
        labels.add(p[0]);
        final vs = vals(p[1]);
        for (int i=0;i<vs.length;i++) { columns[i].add(vs[i]); }
      }
      final yacRec = List.generate(selectedPlayers.length, (i)=>_safeDiv(selectedPlayers[i]['receiving_yards_after_catch'], selectedPlayers[i]['receptions']));
      labels.add('YAC/Rec');
      for (int i=0;i<yacRec.length;i++) { columns[i].add(yacRec[i]); }
    } else {
      List<String> vals(String key) => List.generate(selectedPlayers.length, (i)=>fmt(selectedPlayers[i][key]));
      final aDot = List.generate(selectedPlayers.length, (i)=>_safeDiv(selectedPlayers[i]['receiving_air_yards'], selectedPlayers[i]['targets']));
      final yacRec = List.generate(selectedPlayers.length, (i)=>_safeDiv(selectedPlayers[i]['receiving_yards_after_catch'], selectedPlayers[i]['receptions']));
      final pairs = [
        ['Y/Tgt','yards_per_target'],
        ['Y/Rec','yards_per_reception'],
        ['EPA/play (rec)','receiving_epa'],
        ['1D (rec)','receiving_first_downs'],
      ];
      for (final p in pairs){
        labels.add(p[0]);
        final vs = vals(p[1]);
        for (int i=0;i<vs.length;i++) { columns[i].add(vs[i]); }
      }
      labels.add('aDOT');
      for (int i=0;i<aDot.length;i++) { columns[i].add(aDot[i]); }
      labels.add('YAC/Rec');
      for (int i=0;i<yacRec.length;i++) { columns[i].add(yacRec[i]); }
    }
    return _buildColumnGrid(labels: labels, perPlayerColumns: columns);
  }

  // Career totals and per-game (best-effort from season stats fields)
  Widget _buildCareerRows() {
    num n(dynamic v) => (v as num?) ?? 0;
    String perGame(dynamic total, dynamic games) {
      final t = n(total).toDouble();
      final g = n(games).toDouble();
      if (g <= 0) return '-';
      final v = t / g;
      return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
    }
    List<String> val(String key) => List.generate(selectedPlayers.length, (i)=> (selectedPlayers[i][key] == null) ? '-' : selectedPlayers[i][key].toString());
    List<String> per(String key, String gamesKey) => List.generate(selectedPlayers.length, (i)=> perGame(selectedPlayers[i][key], selectedPlayers[i][gamesKey]));
    final labels = <String>['Games','Total Yards','Yards/Game','Total TDs','TDs/Game','PPR Points','PPR/Game'];
    final columns = <List<String>>[];
    final games = val('games');
    final totY = val('total_yards');
    final ypg = per('total_yards','games');
    final totTd = val('total_tds');
    final tpg = per('total_tds','games');
    final ppr = val('fantasy_points_ppr');
    final ppg = per('fantasy_points_ppr','games');
    for (int i=0;i<selectedPlayers.length;i++) {
      columns.add([games[i], totY[i], ypg[i], totTd[i], tpg[i], ppr[i], ppg[i]]);
    }
    return _buildColumnGrid(labels: labels, perPlayerColumns: columns);
  }

  String _safeDiv(dynamic nume, dynamic den) {
    final n = (nume as num?)?.toDouble() ?? 0.0;
    final d = (den as num?)?.toDouble() ?? 0.0;
    if (d == 0) return '-';
    final v = n / d;
    return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
  }

  String _rate(dynamic nume, dynamic den) {
    final n = (nume as num?)?.toDouble() ?? 0.0;
    final d = (den as num?)?.toDouble() ?? 0.0;
    if (d == 0) return '-';
    final pct = (n / d) * 100.0;
    return '${pct.toStringAsFixed(1)}%';
  }
}