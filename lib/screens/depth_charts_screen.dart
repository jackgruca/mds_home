import 'package:flutter/material.dart';
import '../widgets/common/app_drawer.dart';
import '../utils/team_logo_utils.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';
import '../services/csv_depth_charts_service.dart';

class DepthChartsScreen extends StatefulWidget {
  const DepthChartsScreen({super.key});

  @override
  State<DepthChartsScreen> createState() => _DepthChartsScreenState();
}

class _DepthChartsScreenState extends State<DepthChartsScreen> {
  List<Map<String, dynamic>> _depthCharts = [];
  bool _isLoading = true;
  String? _error;
  
  // Default filters for performance
  String _selectedSeason = '2024';
  String _selectedTeam = 'BUF';
  String _selectedPositionGroup = 'All';

  // Filter options
  List<String> _seasonOptions = ['2024', '2023', '2022', '2021'];
  List<String> _teamOptions = [
    'ARI', 'ATL', 'BAL', 'BUF', 'CAR', 'CHI', 'CIN', 'CLE', 'DAL', 'DEN',
    'DET', 'GB', 'HOU', 'IND', 'JAX', 'KC', 'LV', 'LAC', 'LAR', 'MIA',
    'MIN', 'NE', 'NO', 'NYG', 'NYJ', 'PHI', 'PIT', 'SF', 'SEA', 'TB', 'TEN', 'WAS'
  ];
  List<String> _positionGroupOptions = ['All'];

  // Standard NFL positions for display
  final List<String> _standardOffensePositions = [
    'QB', 'RB', 'FB', 'WR1', 'WR2', 'WR3', 'TE', 'LT', 'LG', 'C', 'RG', 'RT'
  ];
  
  final List<String> _standardDefensePositions = [
    'DE1', 'DT1', 'DT2', 'DE2', 'OLB1', 'ILB', 'OLB2', 'CB1', 'CB2', 'FS', 'SS'
  ];
  
  final List<String> _specialTeamsPositions = ['K', 'P', 'LS'];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _fetchDepthCharts();
  }

  Future<void> _loadFilterOptions() async {
    try {
      List<String> seasons = await CsvDepthChartsService.getSeasons();
      List<String> teams = await CsvDepthChartsService.getTeams();
      List<String> positionGroups = await CsvDepthChartsService.getPositionGroups();

      setState(() {
        _seasonOptions = seasons;
        _teamOptions = teams;
        _positionGroupOptions = ['All', ...positionGroups];
      });
    } catch (e) {
      print('Error loading filter options: $e');
    }
  }

  Future<void> _fetchDepthCharts() async {
    print('DEBUG: _fetchDepthCharts called with season=$_selectedSeason, team=$_selectedTeam, positionGroup=$_selectedPositionGroup');
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> results = await CsvDepthChartsService.getDepthCharts(
        season: _selectedSeason,
        team: _selectedTeam,
        positionGroup: _selectedPositionGroup == 'All' ? null : _selectedPositionGroup,
        limit: 200,
        orderBy: 'depth_chart_order',
        orderDescending: false,
      );

      print('DEBUG: Received ${results.length} depth chart results');
      
      setState(() {
        _depthCharts = results;
        _isLoading = false;
      });
      
      if (results.isNotEmpty) {
        print('DEBUG: First result: ${results.first}');
      }
    } catch (e, stackTrace) {
      print('ERROR: Error in _fetchDepthCharts: $e');
      print('ERROR: Stack trace: $stackTrace');
      
      setState(() {
        _error = 'Error loading depth charts: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('NFL Depth Charts', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          TopNavBarContent(currentRoute: ModalRoute.of(context)?.settings.name),
          _buildFilters(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Season',
                  _selectedSeason,
                  _seasonOptions,
                  (value) {
                    setState(() => _selectedSeason = value!);
                    _fetchDepthCharts();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  'Team',
                  _selectedTeam,
                  _teamOptions,
                  (value) {
                    setState(() => _selectedTeam = value!);
                    _fetchDepthCharts();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  'Position Group',
                  _selectedPositionGroup,
                  _positionGroupOptions,
                  (value) {
                    setState(() => _selectedPositionGroup = value!);
                    _fetchDepthCharts();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchDepthCharts,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: options.map((option) {
            return DropdownMenuItem(value: option, child: Text(option));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDepthCharts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_depthCharts.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No depth chart data found for the selected filters.'),
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildDepthChartSection('Offense', _standardOffensePositions),
            const SizedBox(height: 24),
            _buildDepthChartSection('Defense', _standardDefensePositions),
            const SizedBox(height: 24),
            _buildDepthChartSection('Special Teams', _specialTeamsPositions),
          ],
        ),
      ),
    );
  }

  Widget _buildDepthChartSection(String sectionTitle, List<String> positions) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: positions.map((position) {
                  List<Map<String, dynamic>> playersAtPosition = _depthCharts
                      .where((player) => _matchesPosition(player['depth_chart_position'], position))
                      .toList();

                  // Sort by depth chart order
                  playersAtPosition.sort((a, b) => 
                    (a['depth_chart_order'] ?? 1).compareTo(b['depth_chart_order'] ?? 1));

                  return _buildPositionRow(position, playersAtPosition);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesPosition(String? playerPosition, String targetPosition) {
    if (playerPosition == null) return false;
    
    // Exact match
    if (playerPosition == targetPosition) return true;
    
    // Handle WR positions (WR1, WR2, WR3 can match WR2, WR3, etc.)
    if (targetPosition.startsWith('WR') && playerPosition.startsWith('WR')) {
      return true;
    }
    
    // Handle other similar positions
    if (targetPosition == 'DE1' && (playerPosition == 'DE' || playerPosition == 'DE1')) return true;
    if (targetPosition == 'DE2' && (playerPosition == 'DE' || playerPosition == 'DE2')) return true;
    if (targetPosition == 'DT1' && (playerPosition == 'DT' || playerPosition == 'DT1' || playerPosition == 'NT')) return true;
    if (targetPosition == 'DT2' && (playerPosition == 'DT' || playerPosition == 'DT2')) return true;
    
    return false;
  }

  Widget _buildPositionRow(String position, List<Map<String, dynamic>> players) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              position,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: players.isEmpty
                ? const Text(
                    'No player assigned',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: players.take(3).map((player) {
                      return _buildPlayerChip(player);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerChip(Map<String, dynamic> player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player['jersey_number'] != null) ...[
            Text(
              '#${player['jersey_number']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            player['full_name'] ?? 'Unknown',
            style: const TextStyle(fontSize: 12),
          ),
          if (player['years_exp'] != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${player['years_exp']}Y)',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}