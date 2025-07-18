import 'package:flutter/material.dart';
import '../../utils/theme_config.dart';

class FilterQuery {
  final String? playerNameQuery;
  final List<String> selectedTeams;
  final List<int> selectedTiers;
  final Map<String, RangeFilter> statFilters;
  final List<int> selectedSeasons;

  const FilterQuery({
    this.playerNameQuery,
    this.selectedTeams = const [],
    this.selectedTiers = const [],
    this.statFilters = const {},
    this.selectedSeasons = const [],
  });

  FilterQuery copyWith({
    String? playerNameQuery,
    List<String>? selectedTeams,
    List<int>? selectedTiers,
    Map<String, RangeFilter>? statFilters,
    List<int>? selectedSeasons,
  }) {
    return FilterQuery(
      playerNameQuery: playerNameQuery ?? this.playerNameQuery,
      selectedTeams: selectedTeams ?? this.selectedTeams,
      selectedTiers: selectedTiers ?? this.selectedTiers,
      statFilters: statFilters ?? this.statFilters,
      selectedSeasons: selectedSeasons ?? this.selectedSeasons,
    );
  }

  bool get hasActiveFilters {
    return (playerNameQuery?.isNotEmpty ?? false) ||
           selectedTeams.isNotEmpty ||
           selectedTiers.isNotEmpty ||
           statFilters.isNotEmpty ||
           selectedSeasons.isNotEmpty;
  }
}

class RangeFilter {
  final double? min;
  final double? max;

  const RangeFilter({this.min, this.max});

  bool get hasFilter => min != null || max != null;

  bool matches(double value) {
    if (min != null && value < min!) return false;
    if (max != null && value > max!) return false;
    return true;
  }
}

class FilterPanel extends StatefulWidget {
  final FilterQuery currentQuery;
  final Function(FilterQuery) onFilterChanged;
  final bool isVisible;
  final List<String> availableTeams;
  final List<int> availableSeasons;
  final Map<String, Map<String, dynamic>> statFields;

  const FilterPanel({
    super.key,
    required this.currentQuery,
    required this.onFilterChanged,
    required this.isVisible,
    required this.availableTeams,
    required this.availableSeasons,
    required this.statFields,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late TextEditingController _playerSearchController;
  late FilterQuery _workingQuery;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -350.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _playerSearchController = TextEditingController(text: widget.currentQuery.playerNameQuery ?? '');
    _workingQuery = widget.currentQuery;
    
    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(FilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
    
    if (widget.currentQuery != oldWidget.currentQuery) {
      setState(() {
        _workingQuery = widget.currentQuery;
        _playerSearchController.text = widget.currentQuery.playerNameQuery ?? '';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _playerSearchController.dispose();
    super.dispose();
  }

  void _updateQuery(FilterQuery newQuery) {
    setState(() {
      _workingQuery = newQuery;
    });
    widget.onFilterChanged(newQuery);
  }

  void _clearAllFilters() {
    _playerSearchController.clear();
    _updateQuery(const FilterQuery());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Container(
            width: 350,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(child: _buildFilterControls()),
                _buildFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeConfig.darkNavy,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Filters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Filter and analyze player data',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          if (_workingQuery.hasActiveFilters) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Filters Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPlayerSearchFilter(),
        const SizedBox(height: 20),
        _buildTeamFilter(),
        const SizedBox(height: 20),
        _buildTierFilter(),
        const SizedBox(height: 20),
        _buildSeasonFilter(),
        const SizedBox(height: 20),
        _buildStatFilters(),
      ],
    );
  }

  Widget _buildPlayerSearchFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Player Search',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _playerSearchController,
          decoration: const InputDecoration(
            hintText: 'Search player names...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
            _updateQuery(_workingQuery.copyWith(
              playerNameQuery: value.isEmpty ? null : value,
            ));
          },
        ),
      ],
    );
  }

  Widget _buildTeamFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teams',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableTeams.map((team) {
            final isSelected = _workingQuery.selectedTeams.contains(team);
            return FilterChip(
              label: Text(team),
              selected: isSelected,
              onSelected: (selected) {
                final teams = List<String>.from(_workingQuery.selectedTeams);
                if (selected) {
                  teams.add(team);
                } else {
                  teams.remove(team);
                }
                _updateQuery(_workingQuery.copyWith(selectedTeams: teams));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTierFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiers',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(8, (index) {
            final tier = index + 1;
            final isSelected = _workingQuery.selectedTiers.contains(tier);
            return FilterChip(
              label: Text('Tier $tier'),
              selected: isSelected,
              onSelected: (selected) {
                final tiers = List<int>.from(_workingQuery.selectedTiers);
                if (selected) {
                  tiers.add(tier);
                } else {
                  tiers.remove(tier);
                }
                _updateQuery(_workingQuery.copyWith(selectedTiers: tiers));
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSeasonFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seasons',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableSeasons.map((season) {
            final isSelected = _workingQuery.selectedSeasons.contains(season);
            return FilterChip(
              label: Text(season.toString()),
              selected: isSelected,
              onSelected: (selected) {
                final seasons = List<int>.from(_workingQuery.selectedSeasons);
                if (selected) {
                  seasons.add(season);
                } else {
                  seasons.remove(season);
                }
                _updateQuery(_workingQuery.copyWith(selectedSeasons: seasons));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatFilters() {
    final numericStats = widget.statFields.entries
        .where((entry) => entry.value['format'] != 'string')
        .toList();

    if (numericStats.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistical Filters',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Filter by minimum and maximum values for each statistic:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...numericStats.map((entry) => _buildStatRangeFilter(entry.key, entry.value)).toList(),
      ],
    );
  }

  Widget _buildStatRangeFilter(String statKey, Map<String, dynamic> statInfo) {
    final currentFilter = _workingQuery.statFilters[statKey];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statInfo['name'] ?? statKey,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Min',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final minValue = double.tryParse(value);
                    final filters = Map<String, RangeFilter>.from(_workingQuery.statFilters);
                    if (minValue == null && (currentFilter?.max == null)) {
                      filters.remove(statKey);
                    } else {
                      filters[statKey] = RangeFilter(
                        min: minValue,
                        max: currentFilter?.max,
                      );
                    }
                    _updateQuery(_workingQuery.copyWith(statFilters: filters));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final maxValue = double.tryParse(value);
                    final filters = Map<String, RangeFilter>.from(_workingQuery.statFilters);
                    if (maxValue == null && (currentFilter?.min == null)) {
                      filters.remove(statKey);
                    } else {
                      filters[statKey] = RangeFilter(
                        min: currentFilter?.min,
                        max: maxValue,
                      );
                    }
                    _updateQuery(_workingQuery.copyWith(statFilters: filters));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _workingQuery.hasActiveFilters ? _clearAllFilters : null,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear All Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use filters to narrow down the player list and focus on specific criteria.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}