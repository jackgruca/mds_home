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

  // Standard NFL positions for display in order
  final List<String> _offensePositions = [
    'QB', 'RB', 'FB', 'WR', 'WR', 'TE', 'OT', 'OG', 'C', 'OG', 'OT'
  ];
  
  final List<String> _defensePositions = [
    'EDGE', 'DT', 'DT', 'EDGE', 'LB', 'LB', 'LB', 'CB', 'S', 'S', 'CB'
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
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: ModalRoute.of(context)?.settings.name)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
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
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
                columnSpacing: 24,
                dataRowMinHeight: 48,
                columns: _buildColumns(),
                rows: _buildRows(),
              ),
            ),
          ),
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
    
    // Handle position mappings
    switch (targetPosition) {
      case 'WR':
        return playerPosition.startsWith('WR') || playerPosition == 'SWR';
      case 'EDGE':
        return playerPosition == 'DE' || playerPosition.startsWith('DE') || 
               playerPosition == 'OLB' || playerPosition == 'EDGE';
      case 'DT':
        return playerPosition == 'DT' || playerPosition.startsWith('DT') || playerPosition == 'NT';
      case 'LB':
        return playerPosition == 'LB' || playerPosition == 'ILB' || playerPosition == 'MLB' ||
               playerPosition == 'OLB' || playerPosition.startsWith('LB');
      case 'CB':
        return playerPosition == 'CB' || playerPosition.startsWith('CB');
      case 'S':
        return playerPosition == 'S' || playerPosition == 'SS' || playerPosition == 'FS' || 
               playerPosition == 'SAF';
      case 'OT':
        return playerPosition == 'T' || playerPosition == 'LT' || playerPosition == 'RT' || 
               playerPosition == 'OT';
      case 'OG':
        return playerPosition == 'G' || playerPosition == 'LG' || playerPosition == 'RG' || 
               playerPosition == 'OG';
      case 'C':
        return playerPosition == 'C';
      case 'QB':
        return playerPosition == 'QB';
      case 'RB':
        return playerPosition == 'RB' || playerPosition == 'HB';
      case 'FB':
        return playerPosition == 'FB';
      case 'TE':
        return playerPosition == 'TE';
      case 'K':
        return playerPosition == 'K';
      case 'P':
        return playerPosition == 'P';
      case 'LS':
        return playerPosition == 'LS';
      default:
        return false;
    }
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

  List<DataColumn> _buildColumns() {
    // Determine max depth across all positions for this team
    int maxDepth = _getMaxDepthForTeam();
    
    List<DataColumn> columns = [
      const DataColumn(
        label: Text(
          'Position',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    ];

    // Add depth columns dynamically
    for (int i = 1; i <= maxDepth; i++) {
      columns.add(DataColumn(
        label: Text(
          '$i${_getOrdinalSuffix(i)}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ));
    }

    return columns;
  }

  List<DataRow> _buildRows() {
    List<DataRow> rows = [];
    List<String> allPositions = [..._offensePositions, ..._defensePositions, ..._specialTeamsPositions];
    int maxDepth = _getMaxDepthForTeam();

    // Track position instances for splitting players
    Map<String, int> positionCounts = {};
    for (String pos in allPositions) {
      positionCounts[pos] = (positionCounts[pos] ?? 0) + 1;
    }

    // Track which players have been assigned to avoid duplicates
    Map<String, int> positionInstances = {};
    
    for (String position in allPositions) {
      int currentInstance = positionInstances[position] ?? 0;
      positionInstances[position] = currentInstance + 1;
      
      // Get players for this position, grouped by depth
      Map<int, List<Map<String, dynamic>>> playersByDepth = _getPlayersByDepth(position);
      
      if (playersByDepth.isNotEmpty) {
        List<DataCell> cells = [
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                position,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ),
        ];

        // Add player cells for each depth level
        for (int depth = 1; depth <= maxDepth; depth++) {
          List<Map<String, dynamic>> playersAtDepth = playersByDepth[depth] ?? [];
          
          // Split players across position instances
          Map<String, dynamic>? playerForThisInstance = _getPlayerForInstance(
            playersAtDepth, 
            currentInstance, 
            positionCounts[position] ?? 1
          );
          
          cells.add(DataCell(_buildSinglePlayerCell(playerForThisInstance)));
        }

        rows.add(DataRow(cells: cells));
      }
    }

    return rows;
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

  int _getMaxDepthForTeam() {
    if (_depthCharts.isEmpty) return 3; // Default to 3 levels
    
    int maxDepth = 0;
    for (var player in _depthCharts) {
      int depth = int.tryParse(player['depth_chart_order']?.toString() ?? '1') ?? 1;
      if (depth > maxDepth) maxDepth = depth;
    }
    
    return maxDepth.clamp(1, 5); // Cap at 5 levels for UI purposes
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';  
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Map<int, List<Map<String, dynamic>>> _getPlayersByDepth(String position) {
    Map<int, List<Map<String, dynamic>>> playersByDepth = {};
    
    for (var player in _depthCharts) {
      String playerPosition = player['depth_chart_position']?.toString() ?? '';
      
      if (_matchesPosition(playerPosition, position)) {
        int depth = int.tryParse(player['depth_chart_order']?.toString() ?? '1') ?? 1;
        
        playersByDepth.putIfAbsent(depth, () => []);
        playersByDepth[depth]!.add(player);
      }
    }
    
    return playersByDepth;
  }

  Map<String, dynamic>? _getPlayerForInstance(List<Map<String, dynamic>> players, int instance, int totalInstances) {
    if (players.isEmpty) return null;
    
    // For multiple instances of the same position, distribute players evenly
    if (totalInstances > 1 && players.length > 1) {
      // Calculate which player this instance should get (0-based index)
      int playerIndex = (instance - 1) % players.length;
      return playerIndex < players.length ? players[playerIndex] : null;
    }
    
    // For single instance or single player, return first player
    return players.isNotEmpty ? players.first : null;
  }

  Widget _buildSinglePlayerCell(Map<String, dynamic>? player) {
    if (player == null) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          player['full_name']?.toString() ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        if (player['jersey_number'] != null)
          Text(
            '#${player['jersey_number']}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _buildPlayerCell(List<Map<String, dynamic>> players) {
    if (players.isEmpty) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }
    
    if (players.length == 1) {
      var player = players.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player['full_name']?.toString() ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          if (player['jersey_number'] != null)
            Text(
              '#${player['jersey_number']}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
        ],
      );
    }
    
    // Multiple players at same depth
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: players.take(3).map((player) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '${player['full_name']?.toString() ?? 'Unknown'} ${player['jersey_number'] != null ? '#${player['jersey_number']}' : ''}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }
}