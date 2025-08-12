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
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const base = 1200.0;
            final targetWidth = (constraints.maxWidth < base ? constraints.maxWidth : base) / 2;
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
                          '${player['position'] ?? 'Unknown'} - ${player['team']?.toString().trim().isNotEmpty == true ? player['team'] : 'Unknown Team'}',
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      // Removed redundant mini-header under Detailed Statistics
                      _buildSectionHeader('Physical Info'),
                      _buildPhysicalInfoRows(),
                      const SizedBox(height: 16),
                      _buildSectionHeader('Season Stats ($selectedSeason)'),
                      _buildSeasonStatRows(),
                      const SizedBox(height: 16),
                      _buildSectionHeader('Advanced Metrics'),
                      _buildAdvancedRows(),
                      const SizedBox(height: 16),
                      _buildSectionHeader('Career Stats (Totals & Per Game)'),
                      _buildCareerRows(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== Sectioned layout helpers =====

  Widget _buildCompactHeaderRow() {
    // For two players: center with whitespace; for three later, we can expand
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      final isNarrow = c.maxWidth < 700;
      final children = selectedPlayers.take(3).map((p) => Expanded(child: _compactHeaderCard(p))).toList();
      if (isNarrow) {
        return Column(children: [for (final w in children) ...[w, const SizedBox(height: 8)]]);
      }
      return Row(children: [for (int i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 12), children[i]]]);
    });
  }

  Widget _compactHeaderCard(Map<String, dynamic> player) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>?>(
      future: _lookupRosterQuick(player),
      builder: (context, snap) {
        final bio = snap.data;
        final exp = bio?['experience'];
        final college = bio?['college'];
    return Container(
          padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
            color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0,2))],
          ),
          child: Row(
            children: [
              _blankHeadshot(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player['player_name']?.toString() ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      '${player['position'] ?? ''} • ${player['team'] ?? ''}${exp != null ? ' • ${exp}y' : ''}${college != null ? ' • $college' : ''}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildPlayerBanners() {
    final left = selectedPlayers[0];
    final right = selectedPlayers[1];
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 700;
        if (isNarrow) {
          return Column(
            children: [
              _playerBanner(left, alignRight: false),
              const SizedBox(height: 8),
              _centerLabel('VS'),
              const SizedBox(height: 8),
              _playerBanner(right, alignRight: true),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _playerBanner(left, alignRight: false)),
            const SizedBox(width: 12),
            _centerLabel('VS'),
            const SizedBox(width: 12),
            Expanded(child: _playerBanner(right, alignRight: true)),
          ],
        );
      },
    );
  }

  Widget _playerBanner(Map<String, dynamic> player, {required bool alignRight}) {
    final theme = Theme.of(context);
    // Best-effort roster lookup for age/experience
    Future<Map<String, dynamic>?> lookupRoster(String team, String name) async {
      try {
        final roster = await NFLRosterService.getTeamRoster(team);
        final hit = roster.firstWhere(
          (p) => p.name.toLowerCase().contains(name.toString().toLowerCase()),
          orElse: () => roster.isNotEmpty ? roster.first : NFLPlayer(
            playerId: 'na', name: name, position: player['position'] ?? 'UNK', team: team,
            age: 0, experience: 0, marketValue: 0, contractStatus: 'na', contractYearsRemaining: 0,
            annualSalary: 0, overallRating: 0, positionRank: 0, ageAdjustedValue: 0,
            positionImportance: 0, durabilityScore: 0,
          ),
        );
        // Pass richer fields
        return {
          'age': hit.age,
          'experience': hit.experience,
          'contractYearsRemaining': hit.contractYearsRemaining,
          'marketValue': hit.marketValue,
          'overallRating': hit.overallRating,
        };
      } catch (_) {
        return null;
      }
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: lookupRoster(player['team'] ?? '', player['player_name'] ?? ''),
      builder: (context, snap) {
        final age = snap.data?['age'];
        final exp = snap.data?['experience'];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0,2))],
          ),
          child: Row(
            mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!alignRight) _blankHeadshot(),
              if (!alignRight) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      player['player_name']?.toString() ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${player['position'] ?? ''} • ${player['team'] ?? ''}${exp != null ? ' • ${exp}y' : ''}${age != null && age > 0 ? ' • ${age}yo' : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (alignRight) const SizedBox(width: 12),
              if (alignRight) _blankHeadshot(),
            ],
          ),
        );
      },
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
        final isNarrow = c.maxWidth < 700;
        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
                ),
                Expanded(child: Align(alignment: Alignment.centerRight, child: Text(leftVal, style: const TextStyle(color: Colors.white)))),
                const SizedBox(width: 16),
                Expanded(child: Align(alignment: Alignment.centerLeft, child: Text(rightVal, style: const TextStyle(color: Colors.white)))),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
          child: Row(
            children: [
              Expanded(child: Align(alignment: Alignment.centerRight, child: Text(leftVal, style: const TextStyle(color: Colors.white)))),
              SizedBox(
                width: 180,
                child: Center(child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600))),
              ),
              Expanded(child: Align(alignment: Alignment.centerLeft, child: Text(rightVal, style: const TextStyle(color: Colors.white)))),
            ],
          ),
        );
      },
    );
  }

  // Physical info
  Widget _buildPhysicalInfoRows() {
    final left = selectedPlayers[0];
    final right = selectedPlayers[1];
    // Load richer roster fields for both players
    return FutureBuilder<List<Map<String, dynamic>?>>(
      future: Future.wait([
        _lookupRosterQuick(left),
        _lookupRosterQuick(right),
      ]),
      builder: (context, snap) {
        final a = snap.data != null ? snap.data![0] : null;
        final b = snap.data != null ? snap.data![1] : null;
        String fmtH(dynamic h) => (h == null || (h is String && h.isEmpty)) ? '-' : h.toString();
        String fmtW(dynamic w) => (w == null || (w is String && w.isEmpty)) ? '-' : w.toString();
        String fmt(dynamic v) => (v == null || (v is String && v.isEmpty)) ? '-' : v.toString();
        return Column(
          children: [
            _symRow('Team', left['team']?.toString() ?? '-', right['team']?.toString() ?? '-'),
            _symRow('Position', left['position']?.toString() ?? '-', right['position']?.toString() ?? '-'),
            _symRow('Jersey #', fmt(a?['jersey_number']), fmt(b?['jersey_number'])),
            _symRow('Age', fmt(a?['age']), fmt(b?['age'])),
            _symRow('Experience', fmt(a?['experience']), fmt(b?['experience'])),
            _symRow('Height', fmtH(a?['height']), fmtH(b?['height'])),
            _symRow('Weight', fmtW(a?['weight']), fmtW(b?['weight'])),
            _symRow('College', fmt(a?['college']), fmt(b?['college'])),
            _symRow('Contract Yrs', fmt(a?['contractYearsRemaining']), fmt(b?['contractYearsRemaining'])),
          ],
        );
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
      // We don’t have height/weight/college on NFLPlayer, so pull from CSV via team roster CSV is not exposed.
      // However, NFLRosterService parses the same CSV and may not store these fields; leave blank if unavailable.
      return {
        'age': hit.age,
        'experience': hit.experience,
        'contractYearsRemaining': hit.contractYearsRemaining,
        'jersey_number': null,
        'height': null,
        'weight': null,
        'college': null,
      };
    } catch (_) {
      return null;
    }
  }

  // Season stats rows (position-agnostic core + position specific)
  Widget _buildSeasonStatRows() {
    final a = selectedPlayers[0];
    final b = selectedPlayers[1];
    String fmtNum(dynamic v) {
      if (v == null) return '-';
      if (v is num) return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
      return v.toString();
    }
    final rows = <Widget>[
      _symRow('PPR Points', fmtNum(a['fantasy_points_ppr']), fmtNum(b['fantasy_points_ppr'])),
      _symRow('Total Yards', fmtNum(a['total_yards']), fmtNum(b['total_yards'])),
      _symRow('Total TDs', fmtNum(a['total_tds']), fmtNum(b['total_tds'])),
    ];
    final pos = (a['position'] ?? '').toString();
    if (pos == 'QB') {
      rows.addAll([
        _symRow('Pass Yds', fmtNum(a['passing_yards']), fmtNum(b['passing_yards'])),
        _symRow('Pass TD', fmtNum(a['passing_tds']), fmtNum(b['passing_tds'])),
        _symRow('INT', fmtNum(a['interceptions']), fmtNum(b['interceptions'])),
        _symRow('Comp %', fmtNum(a['completion_percentage']), fmtNum(b['completion_percentage'])),
        _symRow('Y/A', fmtNum(a['yards_per_attempt']), fmtNum(b['yards_per_attempt'])),
        _symRow('Sacks', fmtNum(a['sacks']), fmtNum(b['sacks'])),
      ]);
    } else if (pos == 'RB') {
      rows.addAll([
        _symRow('Rush Yds', fmtNum(a['rushing_yards']), fmtNum(b['rushing_yards'])),
        _symRow('Rush TD', fmtNum(a['rushing_tds']), fmtNum(b['rushing_tds'])),
        _symRow('Y/C', fmtNum(a['yards_per_carry']), fmtNum(b['yards_per_carry'])),
        _symRow('Rec', fmtNum(a['receptions']), fmtNum(b['receptions'])),
        _symRow('Targets', fmtNum(a['targets']), fmtNum(b['targets'])),
      ]);
                } else {
      // WR/TE default
      rows.addAll([
        _symRow('Targets', fmtNum(a['targets']), fmtNum(b['targets'])),
        _symRow('Receptions', fmtNum(a['receptions']), fmtNum(b['receptions'])),
        _symRow('Catch %', fmtNum(a['catch_percentage']), fmtNum(b['catch_percentage'])),
        _symRow('Rec Yds', fmtNum(a['receiving_yards']), fmtNum(b['receiving_yards'])),
        _symRow('Rec TD', fmtNum(a['receiving_tds']), fmtNum(b['receiving_tds'])),
      ]);
    }
    return Column(children: rows);
  }

  // Advanced metrics (position-specific)
  Widget _buildAdvancedRows() {
    final a = selectedPlayers[0];
    final b = selectedPlayers[1];
    String fmt(dynamic v) {
      if (v == null) return '-';
      if (v is num) return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
      return v.toString();
    }
    final pos = (a['position'] ?? '').toString();
    final rows = <Widget>[];
    if (pos == 'QB') {
      rows.addAll([
        _symRow('Pass EPA/play', fmt(a['passing_epa']), fmt(b['passing_epa'])),
        _symRow('TD %', fmt(a['touchdown_percentage']), fmt(b['touchdown_percentage'])),
        _symRow('INT %', fmt(a['interception_percentage']), fmt(b['interception_percentage'])),
        _symRow('1D (pass)', fmt(a['passing_first_downs']), fmt(b['passing_first_downs'])),
        _symRow('Sack Rate', _rate(a['sacks'], a['attempts']), _rate(b['sacks'], b['attempts'])),
      ]);
    } else if (pos == 'RB') {
      rows.addAll([
        _symRow('Rush EPA/play', fmt(a['rushing_epa']), fmt(b['rushing_epa'])),
        _symRow('Y/C', fmt(a['yards_per_carry']), fmt(b['yards_per_carry'])),
        _symRow('YAC/Rec', fmt(_safeDiv(a['receiving_yards_after_catch'], a['receptions'])), fmt(_safeDiv(b['receiving_yards_after_catch'], b['receptions']))),
        _symRow('1D (rush)', fmt(a['rushing_first_downs']), fmt(b['rushing_first_downs'])),
        _symRow('1D (rec)', fmt(a['receiving_first_downs']), fmt(b['receiving_first_downs'])),
      ]);
    } else {
      rows.addAll([
        _symRow('Y/Tgt', fmt(a['yards_per_target']), fmt(b['yards_per_target'])),
        _symRow('Y/Rec', fmt(a['yards_per_reception']), fmt(b['yards_per_reception'])),
        _symRow('aDOT', fmt(_safeDiv(a['receiving_air_yards'], a['targets'])), fmt(_safeDiv(b['receiving_air_yards'], b['targets']))),
        _symRow('YAC/Rec', fmt(_safeDiv(a['receiving_yards_after_catch'], a['receptions'])), fmt(_safeDiv(b['receiving_yards_after_catch'], b['receptions']))),
        _symRow('EPA/play (rec)', fmt(a['receiving_epa']), fmt(b['receiving_epa'])),
        _symRow('1D (rec)', fmt(a['receiving_first_downs']), fmt(b['receiving_first_downs'])),
      ]);
    }
    return Column(children: rows);
  }

  // Career totals and per-game (best-effort from season stats fields)
  Widget _buildCareerRows() {
    final a = selectedPlayers[0];
    final b = selectedPlayers[1];
    num n(dynamic v) => (v as num?) ?? 0;
    String perGame(dynamic total, dynamic games) {
      final t = n(total).toDouble();
      final g = n(games).toDouble();
      if (g <= 0) return '-';
      final v = t / g;
      return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
    }
    // We use available totals and the 'games' field where present
    final rows = <Widget>[
      _symRow('Games', a['games']?.toString() ?? '-', b['games']?.toString() ?? '-'),
      _symRow('Total Yards', n(a['total_yards']).toString(), n(b['total_yards']).toString()),
      _symRow('Yards/Game', perGame(a['total_yards'], a['games']), perGame(b['total_yards'], b['games'])),
      _symRow('Total TDs', n(a['total_tds']).toString(), n(b['total_tds']).toString()),
      _symRow('TDs/Game', perGame(a['total_tds'], a['games']), perGame(b['total_tds'], b['games'])),
      _symRow('PPR Points', (n(a['fantasy_points_ppr']).toString()), (n(b['fantasy_points_ppr']).toString())),
      _symRow('PPR/Game', perGame(a['fantasy_points_ppr'], a['games']), perGame(b['fantasy_points_ppr'], b['games'])),
    ];
    return Column(children: rows);
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