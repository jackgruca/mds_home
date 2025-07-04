import 'package:flutter/material.dart';
import '../models/ff_player.dart';
import '../models/ff_position_constants.dart';

class PlayerFilter {
  final Set<String> positions;
  final Set<String> teams;
  final Set<String> byeWeeks;
  final Set<String> tiers;
  final Set<String> tags;
  final String searchQuery;
  final bool showFavoritesOnly;
  final bool showRecommendedOnly;

  const PlayerFilter({
    this.positions = const {},
    this.teams = const {},
    this.byeWeeks = const {},
    this.tiers = const {},
    this.tags = const {},
    this.searchQuery = '',
    this.showFavoritesOnly = false,
    this.showRecommendedOnly = false,
  });

  PlayerFilter copyWith({
    Set<String>? positions,
    Set<String>? teams,
    Set<String>? byeWeeks,
    Set<String>? tiers,
    Set<String>? tags,
    String? searchQuery,
    bool? showFavoritesOnly,
    bool? showRecommendedOnly,
  }) {
    return PlayerFilter(
      positions: positions ?? this.positions,
      teams: teams ?? this.teams,
      byeWeeks: byeWeeks ?? this.byeWeeks,
      tiers: tiers ?? this.tiers,
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      showRecommendedOnly: showRecommendedOnly ?? this.showRecommendedOnly,
    );
  }

  bool get hasActiveFilters {
    return positions.isNotEmpty ||
           teams.isNotEmpty ||
           byeWeeks.isNotEmpty ||
           tiers.isNotEmpty ||
           tags.isNotEmpty ||
           searchQuery.isNotEmpty ||
           showFavoritesOnly ||
           showRecommendedOnly;
  }

  bool matchesPlayer(FFPlayer player, {bool isRecommended = false}) {
    // Search query filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final name = player.name.toLowerCase();
      final team = player.team.toLowerCase();
      if (!name.contains(query) && !team.contains(query)) {
        return false;
      }
    }

    // Position filter
    if (positions.isNotEmpty && !positions.contains(player.position)) {
      return false;
    }

    // Team filter
    if (teams.isNotEmpty && !teams.contains(player.team)) {
      return false;
    }

    // Bye week filter
    if (byeWeeks.isNotEmpty && 
        (player.byeWeek == null || !byeWeeks.contains(player.byeWeek!))) {
      return false;
    }

    // Tier filter
    if (tiers.isNotEmpty) {
      final playerTier = _getPlayerTier(player);
      if (!tiers.contains(playerTier)) {
        return false;
      }
    }

    // Tags filter
    if (tags.isNotEmpty) {
      final hasMatchingTag = tags.any((tag) => player.hasTag(tag));
      if (!hasMatchingTag) {
        return false;
      }
    }

    // Favorites filter
    if (showFavoritesOnly && !player.isFavorite) {
      return false;
    }

    // Recommended filter
    if (showRecommendedOnly && !isRecommended) {
      return false;
    }

    return true;
  }

  String _getPlayerTier(FFPlayer player) {
    final rank = player.consensusRank ?? player.rank ?? 999;
    if (rank <= 12) return 'Elite';
    if (rank <= 36) return 'Tier 1';
    if (rank <= 60) return 'Tier 2';
    if (rank <= 100) return 'Tier 3';
    return 'Deep';
  }
}

class FFSmartFilters extends StatefulWidget {
  final PlayerFilter currentFilter;
  final Function(PlayerFilter) onFilterChanged;
  final List<FFPlayer> allPlayers;

  const FFSmartFilters({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.allPlayers,
  });

  @override
  State<FFSmartFilters> createState() => _FFSmartFiltersState();
}

class _FFSmartFiltersState extends State<FFSmartFilters> {
  late TextEditingController _searchController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.currentFilter.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Search bar and expand button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search players...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _updateSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _updateSearchQuery,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.tune,
                  color: widget.currentFilter.hasActiveFilters 
                    ? theme.colorScheme.primary 
                    : null,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _isExpanded 
                    ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                    : null,
                ),
              ),
            ],
          ),
          
          // Quick filters row
          const SizedBox(height: 12),
          _buildQuickFilters(theme),
          
          // Expanded filters
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            _buildExpandedFilters(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFilters(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildToggleFilter(
            'Favorites',
            Icons.star,
            widget.currentFilter.showFavoritesOnly,
            (value) => _updateFilter(
              widget.currentFilter.copyWith(showFavoritesOnly: value),
            ),
            theme,
          ),
          const SizedBox(width: 8),
          _buildToggleFilter(
            'Recommended',
            Icons.trending_up,
            widget.currentFilter.showRecommendedOnly,
            (value) => _updateFilter(
              widget.currentFilter.copyWith(showRecommendedOnly: value),
            ),
            theme,
          ),
          const SizedBox(width: 16),
          ..._buildPositionChips(theme),
        ],
      ),
    );
  }

  Widget _buildExpandedFilters(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Teams filter
        _buildFilterSection(
          'Teams',
          _buildTeamChips(theme),
          theme,
        ),
        const SizedBox(height: 16),
        
        // Bye weeks filter
        _buildFilterSection(
          'Bye Weeks',
          _buildByeWeekChips(theme),
          theme,
        ),
        const SizedBox(height: 16),
        
        // Tiers filter
        _buildFilterSection(
          'Tiers',
          _buildTierChips(theme),
          theme,
        ),
        const SizedBox(height: 16),
        
        // Tags filter
        _buildFilterSection(
          'Player Types',
          _buildTagChips(theme),
          theme,
        ),
        const SizedBox(height: 16),
        
        // Clear filters button
        if (widget.currentFilter.hasActiveFilters)
          Center(
            child: TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Filters'),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterSection(String title, Widget content, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildToggleFilter(
    String label,
    IconData icon,
    bool isSelected,
    Function(bool) onChanged,
    ThemeData theme,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: onChanged,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  List<Widget> _buildPositionChips(ThemeData theme) {
    const positions = ['QB', 'RB', 'WR', 'TE', 'K', 'DEF'];
    
    return positions.map((position) {
      final isSelected = widget.currentFilter.positions.contains(position);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(position),
          selected: isSelected,
          onSelected: (selected) {
            final newPositions = Set<String>.from(widget.currentFilter.positions);
            if (selected) {
              newPositions.add(position);
            } else {
              newPositions.remove(position);
            }
            _updateFilter(widget.currentFilter.copyWith(positions: newPositions));
          },
          selectedColor: _getPositionColor(position).withValues(alpha: 0.2),
          checkmarkColor: _getPositionColor(position),
        ),
      );
    }).toList();
  }

  Widget _buildTeamChips(ThemeData theme) {
    final teams = widget.allPlayers
        .map((p) => p.team)
        .where((team) => team.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: teams.map((team) {
        final isSelected = widget.currentFilter.teams.contains(team);
        return FilterChip(
          label: Text(team),
          selected: isSelected,
          onSelected: (selected) {
            final newTeams = Set<String>.from(widget.currentFilter.teams);
            if (selected) {
              newTeams.add(team);
            } else {
              newTeams.remove(team);
            }
            _updateFilter(widget.currentFilter.copyWith(teams: newTeams));
          },
        );
      }).toList(),
    );
  }

  Widget _buildByeWeekChips(ThemeData theme) {
    final byeWeeks = widget.allPlayers
        .map((p) => p.byeWeek)
        .where((bye) => bye != null && bye.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: byeWeeks.map((bye) {
        final isSelected = widget.currentFilter.byeWeeks.contains(bye!);
        return FilterChip(
          label: Text('Week $bye'),
          selected: isSelected,
          onSelected: (selected) {
            final newByeWeeks = Set<String>.from(widget.currentFilter.byeWeeks);
            if (selected) {
              newByeWeeks.add(bye);
            } else {
              newByeWeeks.remove(bye);
            }
            _updateFilter(widget.currentFilter.copyWith(byeWeeks: newByeWeeks));
          },
        );
      }).toList(),
    );
  }

  Widget _buildTierChips(ThemeData theme) {
    const tiers = ['Elite', 'Tier 1', 'Tier 2', 'Tier 3', 'Deep'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tiers.map((tier) {
        final isSelected = widget.currentFilter.tiers.contains(tier);
        return FilterChip(
          label: Text(tier),
          selected: isSelected,
          onSelected: (selected) {
            final newTiers = Set<String>.from(widget.currentFilter.tiers);
            if (selected) {
              newTiers.add(tier);
            } else {
              newTiers.remove(tier);
            }
            _updateFilter(widget.currentFilter.copyWith(tiers: newTiers));
          },
        );
      }).toList(),
    );
  }

  Widget _buildTagChips(ThemeData theme) {
    const tags = ['rookie', 'high_upside', 'safe_floor', 'injury_risk'];
    const tagLabels = {
      'rookie': 'Rookies',
      'high_upside': 'High Upside',
      'safe_floor': 'Safe Floor',
      'injury_risk': 'Injury Risk',
    };
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) {
        final isSelected = widget.currentFilter.tags.contains(tag);
        return FilterChip(
          label: Text(tagLabels[tag] ?? tag),
          selected: isSelected,
          onSelected: (selected) {
            final newTags = Set<String>.from(widget.currentFilter.tags);
            if (selected) {
              newTags.add(tag);
            } else {
              newTags.remove(tag);
            }
            _updateFilter(widget.currentFilter.copyWith(tags: newTags));
          },
        );
      }).toList(),
    );
  }

  Color _getPositionColor(String position) {
    // Handle DEF variation  
    if (position == 'DEF') {
      return FFPositionConstants.getPositionColor('DST');
    }
    return FFPositionConstants.getPositionColor(position);
  }

  void _updateSearchQuery(String query) {
    _updateFilter(widget.currentFilter.copyWith(searchQuery: query));
  }

  void _updateFilter(PlayerFilter newFilter) {
    widget.onFilterChanged(newFilter);
  }

  void _clearAllFilters() {
    _searchController.clear();
    _updateFilter(const PlayerFilter());
  }
}