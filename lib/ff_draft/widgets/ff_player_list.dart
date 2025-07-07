import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_player.dart';
import '../providers/ff_draft_provider.dart';
// import '../services/ff_recommendation_engine.dart'; // REMOVED
import 'ff_player_card.dart';
// import 'ff_smart_filters.dart'; // REMOVED
// import 'ff_quick_actions.dart'; // REMOVED

class FFPlayerList extends StatefulWidget {
  final Function(FFPlayer) onPlayerSelected;
  final bool showFilters;
  final bool showRecommendations;
  
  const FFPlayerList({
    super.key,
    required this.onPlayerSelected,
    this.showFilters = true,
    this.showRecommendations = true,
  });

  @override
  State<FFPlayerList> createState() => _FFPlayerListState();
}

class _FFPlayerListState extends State<FFPlayerList> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  
  List<FFPlayer> _filteredPlayers = [];
  String _selectedPosition = 'All';
  List<FFPlayer> _lastAvailablePlayers = []; // Track last known available players

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    
    // Initialize filtered players after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFilteredPlayers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeFilteredPlayers() {
    final provider = Provider.of<FFDraftProvider>(context, listen: false);
    if (provider.availablePlayers.isNotEmpty) {
      _filterPlayers(provider.availablePlayers);
    }
  }

  void _onSearchChanged() {
    final provider = Provider.of<FFDraftProvider>(context, listen: false);
    _filterPlayers(provider.availablePlayers);
  }

  void _filterPlayers(List<FFPlayer> availablePlayers) {
    final searchTerm = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredPlayers = availablePlayers.where((player) {
        // Position filter
        final positionMatch = _selectedPosition == 'All' || player.position == _selectedPosition;
        
        // Search filter
        final searchMatch = searchTerm.isEmpty || 
                           player.name.toLowerCase().contains(searchTerm) ||
                           player.team.toLowerCase().contains(searchTerm);
        
        return positionMatch && searchMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FFDraftProvider>(builder: (context, provider, child) {
      // Check if available players have changed and update filtered list
      if (_lastAvailablePlayers.length != provider.availablePlayers.length ||
          !_listsEqual(_lastAvailablePlayers, provider.availablePlayers)) {
        _lastAvailablePlayers = List.from(provider.availablePlayers);
        // Use post frame callback to avoid calling setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _filterPlayers(provider.availablePlayers);
          }
        });
      }

      return Column(
        children: [
          _buildHeader(provider),
          if (widget.showFilters) _buildSimpleFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlayerList(provider, 'All'),
                _buildPlayerList(provider, 'Recommended'),
                _buildPlayerList(provider, 'Favorites'),
              ],
            ),
          ),
        ],
      );
    });
  }

  // Helper method to compare lists efficiently
  bool _listsEqual(List<FFPlayer> a, List<FFPlayer> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Widget _buildHeader(FFDraftProvider provider) {
    final theme = Theme.of(context);
    final currentPick = provider.getCurrentPick();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_search,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Available Players',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${provider.availablePlayers.length} available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (currentPick != null)
            Text(
              currentPick.isUserPick
                  ? 'Your pick - Select a player'
                  : '${currentPick.team.name} is picking...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: currentPick.isUserPick
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'All (${_filteredPlayers.length})'),
              const Tab(text: 'Recommended'),
              Tab(text: 'Favorites (${provider.queuedPlayers.length})'),
            ],
            labelStyle: const TextStyle(fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFilters() {
    final theme = Theme.of(context);
    final positions = ['All', 'QB', 'RB', 'WR', 'TE', 'K', 'DST'];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search players...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
                prefixIcon: Icon(Icons.search, size: 18, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Position filter
          DropdownButton<String>(
            value: _selectedPosition,
            underline: const SizedBox.shrink(),
            isDense: true,
            items: positions.map((pos) => DropdownMenuItem(
              value: pos,
              child: Text(pos, style: const TextStyle(fontSize: 14)),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPosition = value;
                });
                _filterPlayers(Provider.of<FFDraftProvider>(context, listen: false).availablePlayers);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(FFDraftProvider provider, String tab) {
    List<FFPlayer> players;
    
    switch (tab) {
      case 'Recommended':
        players = provider.getRecommendations(count: 20);
        break;
      case 'Favorites':
        players = provider.queuedPlayers;
        break;
      default:
        players = _filteredPlayers;
    }
    
    if (players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab == 'Favorites' ? Icons.star_border : Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              tab == 'Favorites' 
                  ? 'No favorites yet\nTap the star to add players'
                  : tab == 'Recommended'
                      ? 'No recommendations available'
                      : 'No players found',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
                     child: FFPlayerCard(
             player: player,
             onTap: () => widget.onPlayerSelected(player),
             onFavorite: () => provider.toggleFavorite(player),
             isUserTurn: provider.isUserTurn(),
             isRecommended: tab == 'Recommended',
             // Simple recommendation based on position need
             recommendationReason: tab == 'Recommended' ? _getSimpleRecommendation(player, provider) : null,
           ),
        );
      },
    );
  }
  
  // Simple recommendation system
  String? _getSimpleRecommendation(FFPlayer player, FFDraftProvider provider) {
    final currentPick = provider.getCurrentPick();
    if (currentPick == null || !currentPick.isUserPick) return null;
    
    final userTeam = provider.teams[provider.userTeamIndex];
    final positionCounts = userTeam.getPositionCounts();
    
    // Basic need-based recommendation
    switch (player.position) {
      case 'QB':
        if (positionCounts['QB']! == 0) return 'Fill starter spot';
        break;
      case 'RB':
        if (positionCounts['RB']! < 2) return 'Need for starter/flex';
        break;
      case 'WR':
        if (positionCounts['WR']! < 2) return 'Need for starter/flex';
        break;
      case 'TE':
        if (positionCounts['TE']! == 0) return 'Fill starter spot';
        break;
    }
    
    return 'Depth/value play';
  }
}