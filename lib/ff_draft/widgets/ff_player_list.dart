import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_player.dart';
import '../providers/ff_draft_provider.dart';
import '../services/ff_recommendation_engine.dart';
import 'ff_player_card.dart';
import 'ff_smart_filters.dart';
import 'ff_quick_actions.dart';

class FFPlayerList extends StatefulWidget {
  final Function(FFPlayer) onPlayerSelected;

  const FFPlayerList({
    super.key,
    required this.onPlayerSelected,
  });

  @override
  State<FFPlayerList> createState() => _FFPlayerListState();
}

class _FFPlayerListState extends State<FFPlayerList> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  PlayerFilter _currentFilter = const PlayerFilter();
  final FFRecommendationEngine _recommendationEngine = FFRecommendationEngine();
  
  List<DraftRecommendation> _recommendations = [];
  FFPlayer? _bestAvailable;
  FFPlayer? _needPlayer;
  FFPlayer? _valuePlayer;
  String? _needPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }
  
  void _onTabChanged() {
    // Update recommendations when switching to Quick Pick tab
    if (_tabController.index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final provider = Provider.of<FFDraftProvider>(context, listen: false);
          _updateRecommendations(provider);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FFDraftProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Tab bar for switching between modes
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All Players'),
                  Tab(text: 'Quick Pick'),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllPlayersTab(provider),
                  _buildQuickPickTab(provider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAllPlayersTab(FFDraftProvider provider) {
    final filteredPlayers = _getFilteredPlayers(provider.availablePlayers);
    debugPrint('Player list tab - Available: ${provider.availablePlayers.length}, Filtered: ${filteredPlayers.length}');
    
    return Column(
      children: [
        // Smart filters
        FFSmartFilters(
          currentFilter: _currentFilter,
          onFilterChanged: (newFilter) {
            setState(() {
              _currentFilter = newFilter;
            });
          },
          allPlayers: provider.availablePlayers,
        ),
        
        // Player list
        Expanded(
          child: filteredPlayers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredPlayers.length,
                  itemBuilder: (context, index) {
                    final player = filteredPlayers[index];
                    final isRecommended = _isPlayerRecommended(player);
                    final recommendation = _getRecommendationForPlayer(player);
                    
                    return FFPlayerCard(
                      player: player,
                      isRecommended: isRecommended,
                      isUserTurn: provider.isUserTurn(),
                      recommendationReason: recommendation?.reason,
                      onTap: () => widget.onPlayerSelected(player),
                      onFavorite: () => provider.toggleFavorite(player),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuickPickTab(FFDraftProvider provider) {
    
    return FFQuickActions(
      isUserTurn: provider.isUserTurn(),
      bestAvailablePlayer: _bestAvailable,
      needPlayer: _needPlayer,
      valuePlayer: _valuePlayer,
      needPosition: _needPosition,
      onBestAvailable: _bestAvailable != null 
          ? () => widget.onPlayerSelected(_bestAvailable!) 
          : null,
      onFillNeed: _needPlayer != null 
          ? () => widget.onPlayerSelected(_needPlayer!) 
          : null,
      onTopValue: _valuePlayer != null 
          ? () => widget.onPlayerSelected(_valuePlayer!) 
          : null,
      onTopRookie: () => _selectRookieUpside(provider),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No players found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _updateRecommendations(FFDraftProvider provider) {
    try {
      if (!provider.isUserTurn()) {
        setState(() {
          _recommendations = [];
          _bestAvailable = null;
          _needPlayer = null;
          _valuePlayer = null;
          _needPosition = null;
        });
        return;
      }

      final currentPick = provider.getCurrentPick();
      if (currentPick == null) return;

      if (provider.teams.isEmpty || provider.userTeamIndex >= provider.teams.length) {
        return;
      }

      final userTeam = provider.teams[provider.userTeamIndex];
      
      setState(() {
        // Get recommendations safely
        _recommendations = _recommendationEngine.getRecommendations(
          availablePlayers: provider.availablePlayers,
          userTeam: userTeam,
          draftPicks: provider.draftPicks,
          currentPick: currentPick.pickNumber,
          currentRound: currentPick.round,
        );

        // Get specific recommendation types with null safety
        final bestAvailableRec = _recommendationEngine.getBestAvailableRecommendation(
          availablePlayers: provider.availablePlayers,
          userTeam: userTeam,
          draftPicks: provider.draftPicks,
          currentPick: currentPick.pickNumber,
          currentRound: currentPick.round,
        );
        _bestAvailable = bestAvailableRec?.player;

        final fillNeedRec = _recommendationEngine.getFillNeedRecommendation(
          availablePlayers: provider.availablePlayers,
          userTeam: userTeam,
          draftPicks: provider.draftPicks,
          currentPick: currentPick.pickNumber,
          currentRound: currentPick.round,
        );
        _needPlayer = fillNeedRec?.player;
        _needPosition = fillNeedRec?.metadata['position'];

        final valueRec = _recommendationEngine.getValueRecommendation(
          availablePlayers: provider.availablePlayers,
          userTeam: userTeam,
          draftPicks: provider.draftPicks,
          currentPick: currentPick.pickNumber,
          currentRound: currentPick.round,
        );
        _valuePlayer = valueRec?.player;
      });
    } catch (e) {
      // Safely handle any errors in recommendation updates
      debugPrint('Error updating recommendations: $e');
      setState(() {
        _recommendations = [];
        _bestAvailable = null;
        _needPlayer = null;
        _valuePlayer = null;
        _needPosition = null;
      });
    }
  }

  List<FFPlayer> _getFilteredPlayers(List<FFPlayer> players) {
    return players.where((player) {
      final isRecommended = _isPlayerRecommended(player);
      return _currentFilter.matchesPlayer(player, isRecommended: isRecommended);
    }).toList();
  }

  bool _isPlayerRecommended(FFPlayer player) {
    return _recommendations.any((rec) => rec.player.id == player.id);
  }

  DraftRecommendation? _getRecommendationForPlayer(FFPlayer player) {
    try {
      return _recommendations.firstWhere((rec) => rec.player.id == player.id);
    } catch (_) {
      return null;
    }
  }

  void _selectRookieUpside(FFDraftProvider provider) {
    final currentPick = provider.getCurrentPick();
    if (currentPick == null) return;

    final userTeam = provider.teams[provider.userTeamIndex];
    final rookieRec = _recommendationEngine.getRookieUpsideRecommendation(
      availablePlayers: provider.availablePlayers,
      userTeam: userTeam,
      draftPicks: provider.draftPicks,
      currentPick: currentPick.pickNumber,
      currentRound: currentPick.round,
    );

    if (rookieRec != null) {
      widget.onPlayerSelected(rookieRec.player);
    }
  }
}