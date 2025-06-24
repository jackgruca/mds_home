import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/common/app_drawer.dart';
import '../utils/team_logo_utils.dart';

// Enum for Query Operators
enum QueryOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEquals,
  lessThan,
  lessThanOrEquals,
  contains,
  startsWith,
  endsWith
}

// Helper to convert QueryOperator to a display string
String queryOperatorToString(QueryOperator op) {
  switch (op) {
    case QueryOperator.equals: return '==';
    case QueryOperator.notEquals: return '!=';
    case QueryOperator.greaterThan: return '>';
    case QueryOperator.greaterThanOrEquals: return '>=';
    case QueryOperator.lessThan: return '<';
    case QueryOperator.lessThanOrEquals: return '<=';
    case QueryOperator.contains: return 'Contains';
    case QueryOperator.startsWith: return 'Starts With';
    case QueryOperator.endsWith: return 'Ends With';
  }
}

// Class to represent a single query condition
class QueryCondition {
  final String field;
  final QueryOperator operator;
  final String value;

  QueryCondition({required this.field, required this.operator, required this.value});

  @override
  String toString() {
    return '$field ${queryOperatorToString(operator)} "$value"';
  }
}

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
  String _selectedSeason = '2024'; // Use 2024 for current season data
  String _selectedTeam = 'BUF'; // Buffalo Bills for testing
  String _selectedWeek = '8'; // Week 8 for testing Curtis Samuel example

  // Standard NFL positions - exactly 11 offense, 11 defense in logical order
  final List<String> _standardOffensePositions = [
    'QB',    // Quarterback
    'RB',    // Running Back
    'FB',    // Fullback
    'WR1',   // Wide Receiver 1
    'WR2',   // Wide Receiver 2
    'WR3',   // Wide Receiver 3
    'TE',    // Tight End
    'LT',    // Left Tackle
    'LG',    // Left Guard
    'C',     // Center
    'RG',    // Right Guard
    'RT'     // Right Tackle
  ];
  
  final List<String> _standardDefensePositions = [
    'DE1',   // Defensive End 1
    'DT1',   // Defensive Tackle 1
    'DT2',   // Defensive Tackle 2
    'DE2',   // Defensive End 2
    'OLB1',  // Outside Linebacker 1
    'ILB',   // Inside Linebacker
    'OLB2',  // Outside Linebacker 2
    'CB1',   // Cornerback 1
    'CB2',   // Cornerback 2
    'FS',    // Free Safety
    'SS'     // Strong Safety
  ];
  
  final List<String> _specialTeamsPositions = ['K', 'P', 'LS'];
  
  // Mapping from position_group values to standard position codes
  final Map<String, String> _positionGroupToCode = {
    'Quarterback': 'QB',
    'Running Back': 'RB',
    'Fullback': 'FB',
    'Wide Receiver': 'WR',
    'Tight End': 'TE',
    'Offensive Line': 'OL', // Generic for T, G, C
    'Defensive Line': 'DL', // Generic for DE, DT
    'Linebacker': 'LB', // Generic for OLB, MLB, ILB
    'Defensive Back': 'DB', // Generic for CB, FS, SS
    'Kicker': 'K',
    'Punter': 'P',
    'Long Snapper': 'LS',
  };
  
  // Reverse mapping for lookup
  final Map<String, List<String>> _positionCodeToGroups = {
    'QB': ['Quarterback'],
    'RB': ['Running Back'],
    'FB': ['Fullback'],
    'WR': ['Wide Receiver'],
    'TE': ['Tight End'],
    'LT': ['Offensive Line'],
    'LG': ['Offensive Line'],
    'C': ['Offensive Line'],
    'RG': ['Offensive Line'],
    'RT': ['Offensive Line'],
    'DE': ['Defensive Line'],
    'DT': ['Defensive Line'],
    'OLB': ['Linebacker'],
    'MLB': ['Linebacker'],
    'ILB': ['Linebacker'],
    'CB': ['Defensive Back'],
    'FS': ['Defensive Back'],
    'SS': ['Defensive Back'],
    'K': ['Kicker'],
    'P': ['Punter'],
    'LS': ['Long Snapper'],
  };
  
  // Query builder state
  final List<QueryCondition> _queryConditions = [];
  String? _newQueryField;
  QueryOperator? _newQueryOperator;
  final TextEditingController _newQueryValueController = TextEditingController();
  bool _isQueryBuilderExpanded = false;
  
  final List<String> _seasonOptions = ['2024', '2023', '2022', '2021'];
  final List<String> _teamOptions = [
    'ARI', 'ATL', 'BAL', 'BUF', 'CAR', 'CHI', 'CIN', 'CLE', 'DAL', 'DEN',
    'DET', 'GB', 'HOU', 'IND', 'JAX', 'KC', 'LV', 'LAC', 'LAR', 'MIA',
    'MIN', 'NE', 'NO', 'NYG', 'NYJ', 'PHI', 'PIT', 'SEA', 'SF', 'TB', 'TEN', 'WAS'
  ];
  final List<String> _weekOptions = [
    'All Weeks', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
    '10', '11', '12', '13', '14', '15', '16', '17', '18'
  ];
  
  // All available fields for query builder
  final List<String> _allFields = [
    'player_name', 'team', 'season', 'week', 'position', 'position_group', 'depth_position',
    'jersey_number', 'formation', 'depth_level', 'depth_team'
  ];
  
  // All operators for query
  final List<QueryOperator> _allOperators = [
    QueryOperator.equals,
    QueryOperator.notEquals,
    QueryOperator.greaterThan,
    QueryOperator.greaterThanOrEquals,
    QueryOperator.lessThan,
    QueryOperator.lessThanOrEquals,
    QueryOperator.contains,
    QueryOperator.startsWith,
    QueryOperator.endsWith,
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _newQueryValueController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Build query with default filters for performance
      Query query = FirebaseFirestore.instance.collection('depthCharts')
          .where('season', isEqualTo: int.parse(_selectedSeason))
          .where('team', isEqualTo: _selectedTeam);

      // Add week filter if specified
      if (_selectedWeek != 'All Weeks') {
        query = query.where('week', isEqualTo: int.parse(_selectedWeek));
      }

      // Apply additional query conditions
      for (final condition in _queryConditions) {
        query = _applyQueryCondition(query, condition);
      }

      // Limit results for performance
      query = query.limit(1000);

      final snapshot = await query.get();
      
      final depthCharts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      setState(() {
        _depthCharts = depthCharts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Query _applyQueryCondition(Query query, QueryCondition condition) {
    try {
      final value = condition.value.trim();
      if (value.isEmpty) return query;

      switch (condition.operator) {
        case QueryOperator.equals:
          // Try to parse as number for numeric fields
          final numValue = int.tryParse(value);
          if (numValue != null && ['season', 'week', 'jersey_number', 'depth_team'].contains(condition.field)) {
            return query.where(condition.field, isEqualTo: numValue);
          }
          return query.where(condition.field, isEqualTo: value);
        
        case QueryOperator.notEquals:
          final numValue = int.tryParse(value);
          if (numValue != null && ['season', 'week', 'jersey_number', 'depth_team'].contains(condition.field)) {
            return query.where(condition.field, isNotEqualTo: numValue);
          }
          return query.where(condition.field, isNotEqualTo: value);
        
        case QueryOperator.greaterThan:
          final numValue = int.tryParse(value);
          if (numValue != null) {
            return query.where(condition.field, isGreaterThan: numValue);
          }
          return query.where(condition.field, isGreaterThan: value);
        
        case QueryOperator.greaterThanOrEquals:
          final numValue = int.tryParse(value);
          if (numValue != null) {
            return query.where(condition.field, isGreaterThanOrEqualTo: numValue);
          }
          return query.where(condition.field, isGreaterThanOrEqualTo: value);
        
        case QueryOperator.lessThan:
          final numValue = int.tryParse(value);
          if (numValue != null) {
            return query.where(condition.field, isLessThan: numValue);
          }
          return query.where(condition.field, isLessThan: value);
        
        case QueryOperator.lessThanOrEquals:
          final numValue = int.tryParse(value);
          if (numValue != null) {
            return query.where(condition.field, isLessThanOrEqualTo: numValue);
          }
          return query.where(condition.field, isLessThanOrEqualTo: value);
        
        // For text-based operators, we'll handle them in memory filtering
        case QueryOperator.contains:
        case QueryOperator.startsWith:
        case QueryOperator.endsWith:
          return query; // Will be filtered in memory
      }
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        print('Error applying query condition: $e');
        return true;
      }());
      return query;
    }
  }

  void _addQueryCondition() {
    if (_newQueryField != null && 
        _newQueryOperator != null && 
        _newQueryValueController.text.trim().isNotEmpty) {
      setState(() {
        _queryConditions.add(QueryCondition(
          field: _newQueryField!,
          operator: _newQueryOperator!,
          value: _newQueryValueController.text.trim(),
        ));
        _newQueryField = null;
        _newQueryOperator = null;
        _newQueryValueController.clear();
      });
      _fetchData();
    }
  }

  void _removeQueryCondition(int index) {
    setState(() {
      _queryConditions.removeAt(index);
    });
    _fetchData();
  }

  void _clearAllConditions() {
    setState(() {
      _queryConditions.clear();
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Depth Charts'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF1E3A8A),
            child: Column(
              children: [
                // Basic Filters Row
                Row(
                  children: [
                    // Season Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Season', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSeason,
                                isExpanded: true,
                                items: _seasonOptions.map((season) {
                                  return DropdownMenuItem(value: season, child: Text(season));
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedSeason = value;
                                    });
                                    _fetchData();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Team Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedTeam,
                                isExpanded: true,
                                items: _teamOptions.map((team) {
                                  return DropdownMenuItem(value: team, child: Text(team));
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedTeam = value;
                                    });
                                    _fetchData();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Week Filter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Week', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedWeek,
                                isExpanded: true,
                                items: _weekOptions.map((week) {
                                  return DropdownMenuItem(value: week, child: Text(week));
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedWeek = value;
                                    });
                                    _fetchData();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Advanced Query Builder
                ExpansionTile(
                  title: const Text('Advanced Query Builder', style: TextStyle(color: Colors.white)),
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.white,
                  initiallyExpanded: _isQueryBuilderExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _isQueryBuilderExpanded = expanded;
                    });
                  },
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Current Conditions
                          if (_queryConditions.isNotEmpty) ...[
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Current Conditions:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(_queryConditions.length, (index) {
                              final condition = _queryConditions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(condition.toString(), style: const TextStyle(color: Colors.white)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeQueryCondition(index),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              );
                            }),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _clearAllConditions,
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Clear All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Add New Condition
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Add New Condition:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _newQueryField,
                                      hint: const Text('Field'),
                                      isExpanded: true,
                                      items: _allFields.map((field) {
                                        return DropdownMenuItem(value: field, child: Text(field));
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _newQueryField = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<QueryOperator>(
                                      value: _newQueryOperator,
                                      hint: const Text('Operator'),
                                      isExpanded: true,
                                      items: _allOperators.map((op) {
                                        return DropdownMenuItem(value: op, child: Text(queryOperatorToString(op)));
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _newQueryOperator = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _newQueryValueController,
                                  decoration: const InputDecoration(
                                    hintText: 'Value',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addQueryCondition,
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Data Display
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                            const SizedBox(height: 16),
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _depthCharts.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No depth chart data found for selected filters'),
                              ],
                            ),
                          )
                        : _buildDepthChartMatrix(),
          ),
        ],
      ),
    );
  }

  Widget _buildDepthChartMatrix() {
    // FINAL APPROACH: Create table with starters in rows, backups distributed properly
    List<Map<String, dynamic>> tableRows = [];
    
    // Find all starters (depth_team = 1)
    final starters = _depthCharts.where((player) {
      final depthTeam = player['depth_team']?.toString() ?? '';
      return depthTeam == '1';
    }).toList();
    
    print('Found ${starters.length} starters total');
    
    // Group starters by position to handle multiple players at same position
    Map<String, List<Map<String, dynamic>>> startersByPosition = {};
    for (final starter in starters) {
      final position = starter['depth_position']?.toString() ?? starter['position']?.toString() ?? '';
      if (position.isNotEmpty) {
        if (!startersByPosition.containsKey(position)) {
          startersByPosition[position] = [];
        }
        startersByPosition[position]!.add(starter);
      }
    }
    
    // Track used backups to prevent duplication
    Set<String> usedBackups = {};
    
    // Create one row per unique starter - each starter gets their own row with their backup chain
    final allStarters = _depthCharts.where((player) {
      final depthTeam = int.tryParse(player['depth_team']?.toString() ?? '99') ?? 99;
      return depthTeam == 1;
    }).toList();
    
    print('Found ${allStarters.length} starters total');
    
    // Process each position that has starters
    final processedPositions = <String>{};
    
    for (final position in startersByPosition.keys) {
      if (processedPositions.contains(position)) continue;
      processedPositions.add(position);
      
      final positionStarters = startersByPosition[position]!;
      
      if (position == 'WR') {
        // WR special case: one row per WR starter
        final wrBackups = _depthCharts.where((player) {
          final playerPosition = player['depth_position']?.toString() ?? player['position']?.toString() ?? '';
          final depthTeam = int.tryParse(player['depth_team']?.toString() ?? '99') ?? 99;
          final playerKey = '${player['first_name']}_${player['last_name']}_${player['jersey_number']}';
          return playerPosition == 'WR' && depthTeam >= 2 && !usedBackups.contains(playerKey);
        }).toList();
        
        // Sort backups by depth_team
        wrBackups.sort((a, b) {
          final depthA = int.tryParse(a['depth_team']?.toString() ?? '99') ?? 99;
          final depthB = int.tryParse(b['depth_team']?.toString() ?? '99') ?? 99;
          return depthA.compareTo(depthB);
        });
        
        for (int i = 0; i < positionStarters.length; i++) {
          final starter = positionStarters[i];
          final starterName = '${starter['first_name']} ${starter['last_name']}';
          print('Creating WR row for $starterName');
          
          // Create depth chart for this WR starter
          final Map<int, Map<String, dynamic>?> depthChart = {1: starter};
          
          // Distribute backups
          if (i < wrBackups.length) {
            depthChart[2] = wrBackups[i];
            final playerKey = '${wrBackups[i]['first_name']}_${wrBackups[i]['last_name']}_${wrBackups[i]['jersey_number']}';
            usedBackups.add(playerKey);
          }
          
          tableRows.add({
            'position': 'WR',
            'depthChart': depthChart,
            'starter': starter,
          });
        }
      } else {
        // For positions with multiple starters: distribute backups across starter rows
        
        // Find all backups for this position (depth_team >= 2)
        final positionBackups = _depthCharts.where((player) {
          final playerPosition = player['depth_position']?.toString() ?? player['position']?.toString() ?? '';
          final depthTeam = int.tryParse(player['depth_team']?.toString() ?? '99') ?? 99;
          final playerKey = '${player['first_name']}_${player['last_name']}_${player['jersey_number']}';
          return playerPosition == position && depthTeam >= 2 && !usedBackups.contains(playerKey);
        }).toList();
        
        // Sort backups by depth_team
        positionBackups.sort((a, b) {
          final depthA = int.tryParse(a['depth_team']?.toString() ?? '99') ?? 99;
          final depthB = int.tryParse(b['depth_team']?.toString() ?? '99') ?? 99;
          return depthA.compareTo(depthB);
        });
        
        // Create rows for each starter and distribute backups ROUND-ROBIN style
        print('Position $position has ${positionStarters.length} starters and ${positionBackups.length} backups');
        
        // Create all starter rows first
        List<Map<String, dynamic>> starterRows = [];
        for (int i = 0; i < positionStarters.length; i++) {
          final starter = positionStarters[i];
          final starterName = '${starter['first_name']} ${starter['last_name']}';
          print('Creating row for $starterName at $position (starter $i)');
          
          starterRows.add({
            'position': position,
            'depthChart': <int, Map<String, dynamic>?>{1: starter},
            'starter': starter,
          });
        }
        
        // Now distribute backups round-robin across all starter rows
        int currentRowIndex = 0;
        int currentDepthSlot = 2;
        
        for (final backup in positionBackups) {
          final playerKey = '${backup['first_name']}_${backup['last_name']}_${backup['jersey_number']}';
          if (usedBackups.contains(playerKey)) continue;
          
          // Find the next available row and slot
          bool placed = false;
          int attempts = 0;
          
          while (!placed && attempts < starterRows.length) {
            final currentRow = starterRows[currentRowIndex];
            final depthChart = currentRow['depthChart'] as Map<int, Map<String, dynamic>?>;
            
            // If this slot is available in this row, place the backup
            if (!depthChart.containsKey(currentDepthSlot) && currentDepthSlot <= 5) {
              final backupName = '${backup['first_name']} ${backup['last_name']}';
              final starterName = '${currentRow['starter']['first_name']} ${currentRow['starter']['last_name']}';
              print('  Assigning $backupName (depth_team ${backup['depth_team']}) to slot $currentDepthSlot for $starterName');
              
              depthChart[currentDepthSlot] = backup;
              usedBackups.add(playerKey);
              placed = true;
            }
            
            // Move to next row
            currentRowIndex = (currentRowIndex + 1) % starterRows.length;
            
            // If we've cycled through all rows, move to next depth slot
            if (currentRowIndex == 0) {
              currentDepthSlot++;
              if (currentDepthSlot > 5) break;
            }
            
            attempts++;
          }
          
          if (!placed) break; // No more slots available
        }
        
        // Add all the starter rows to tableRows
        tableRows.addAll(starterRows);
      }
    }
    
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Team header with logo - styled like the Buffalo Bills image
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.only(bottom: 24.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade600),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTeamLogo(_selectedTeam),
                    const SizedBox(width: 16),
                    Text(
                      '$_selectedTeam $_selectedSeason Week $_selectedWeek',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main depth chart table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Table header row
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          topRight: Radius.circular(8.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Position column header
                          Container(
                            width: 120,
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                            child: const Text(
                              'Pos',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Player columns headers
                          ...List.generate(5, (index) {
                            return Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: Colors.grey.shade600),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'No',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.grey.shade300,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      'Player ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    
                    // Table body - show organized rows
                    _buildTableRowGroups(tableRows),
                  ],
                ),
              ),
              
              // Legend
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Starters', Colors.green.shade100),
                    const SizedBox(width: 16),
                    _buildLegendItem('Backups', Colors.blue.shade100),
                    const SizedBox(width: 16),
                    _buildLegendItem('Third String', Colors.orange.shade100),
                    const SizedBox(width: 16),
                    _buildLegendItem('Reserves', Colors.grey.shade100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRowGroups(List<Map<String, dynamic>> tableRows) {
    // Categorize table rows by type
    final offenseRows = <Map<String, dynamic>>[];
    final defenseRows = <Map<String, dynamic>>[];
    final specialTeamsRows = <Map<String, dynamic>>[];
    
    // Define position categories
    final offenseSet = {
      'QB', 'RB', 'HB', 'FB', 'F',
      'WR', 'WR1', 'WR2', 'LWR', 'RWR', 'WRE',
      'TE', 'LTE', 'RTE',
      'LT', 'LOT', 'RT', 'ROT', 
      'LG', 'RG', 'C', 'G', 'T'
    };
    
    final defenseSet = {
      'DE', 'LDE', 'RDE', 'LE', 'RE', 'EDGE', 'LEO', 'RUSH',
      'DT', 'LDT', 'RDT', 'NT', 'DL',
      'LB', 'OLB', 'ILB', 'MLB', 'LOLB', 'ROLB', 'LILB', 'RILB',
      'MIKE', 'WILL', 'SAM', 'WIL', 'SLB', 'WLB',
      'CB', 'LCB', 'RCB', 'NCB', 'NB', 'NICK', 'NICKE', 'NKL', 'NDB',
      'S', 'FS', 'SS', 'DB'
    };
    
    final specialTeamsSet = {
      'K', 'PK', 'P', 'P.', 'P/H', 'H', 'LS',
      'KR', 'KOR', 'PR', 'KO', 'RS'
    };
    
    // Categorize each table row
    for (final tableRow in tableRows) {
      final position = tableRow['position'] as String;
      if (offenseSet.contains(position)) {
        offenseRows.add(tableRow);
      } else if (defenseSet.contains(position)) {
        defenseRows.add(tableRow);
      } else if (specialTeamsSet.contains(position)) {
        specialTeamsRows.add(tableRow);
      }
    }
    
    // Sort rows within each group using your specified ordering
    // Offense: QB, RB, FB, WRs, TE, LT, LG, C, RG, RT
    final offenseOrder = ['QB', 'RB', 'HB', 'FB', 'F', 'WR', 'WR1', 'WR2', 'LWR', 'RWR', 'WRE', 'TE', 'LTE', 'RTE', 'LT', 'LOT', 'LG', 'C', 'RG', 'RT', 'ROT'];
    // Defense: EDGE, DT, DT, EDGE, LBs, CBs, S
    final defenseOrder = ['EDGE', 'LDE', 'DE', 'LE', 'LEO', 'RUSH', 'DT', 'LDT', 'NT', 'RDT', 'DL', 'LOLB', 'OLB', 'SLB', 'LILB', 'ILB', 'MLB', 'MIKE', 'WILL', 'WIL', 'SAM', 'ROLB', 'RILB', 'WLB', 'LB', 'CB', 'LCB', 'RCB', 'NCB', 'NB', 'NICK', 'NICKE', 'NKL', 'NDB', 'S', 'FS', 'SS', 'DB'];
    final specialTeamsOrder = ['K', 'PK', 'P', 'P.', 'P/H', 'H', 'LS', 'KR', 'KOR', 'PR', 'KO', 'RS'];
    
    offenseRows.sort((a, b) {
      final aPos = a['position'] as String;
      final bPos = b['position'] as String;
      final aIndex = offenseOrder.indexOf(aPos);
      final bIndex = offenseOrder.indexOf(bPos);
      if (aIndex == -1 && bIndex == -1) return aPos.compareTo(bPos);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
    
    defenseRows.sort((a, b) {
      final aPos = a['position'] as String;
      final bPos = b['position'] as String;
      final aIndex = defenseOrder.indexOf(aPos);
      final bIndex = defenseOrder.indexOf(bPos);
      if (aIndex == -1 && bIndex == -1) return aPos.compareTo(bPos);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
    
    specialTeamsRows.sort((a, b) {
      final aPos = a['position'] as String;
      final bPos = b['position'] as String;
      final aIndex = specialTeamsOrder.indexOf(aPos);
      final bIndex = specialTeamsOrder.indexOf(bPos);
      if (aIndex == -1 && bIndex == -1) return aPos.compareTo(bPos);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
    
    return Column(
      children: [
        // Offense section
        if (offenseRows.isNotEmpty) ...[
          _buildTableRowGroup('OFFENSE', offenseRows, const Color(0xFF1565C0)),
        ],
        
        // Defense section
        if (defenseRows.isNotEmpty) ...[
          _buildTableRowGroup('DEFENSE', defenseRows, const Color(0xFFD32F2F)),
        ],
        
        // Special Teams section
        if (specialTeamsRows.isNotEmpty) ...[
          _buildTableRowGroup('SPECIAL TEAMS', specialTeamsRows, const Color(0xFF7B1FA2)),
        ],
      ],
    );
  }

  Widget _buildTableRowGroup(String groupName, List<Map<String, dynamic>> tableRows, Color headerColor) {
    return Column(
      children: [
        // Group header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: headerColor,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300),
              left: BorderSide(color: Colors.grey.shade300),
              right: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Text(
                groupName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${tableRows.length} player${tableRows.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        
        // Table rows
        ...tableRows.asMap().entries.map((entry) {
          final index = entry.key;
          final tableRow = entry.value;
          final position = tableRow['position'] as String;
          final depthChart = tableRow['depthChart'] as Map<int, Map<String, dynamic>?>;
          final isLastInGroup = index == tableRows.length - 1;
          
          return Container(
            decoration: BoxDecoration(
              color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: isLastInGroup ? 1.0 : 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Position column
                Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    position,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Player columns
                ...List.generate(5, (playerIndex) {
                  final player = depthChart[playerIndex + 1];
                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
                      decoration: BoxDecoration(
                        border: Border(
                          right: playerIndex < 4 ? BorderSide(color: Colors.grey.shade200) : BorderSide.none,
                        ),
                      ),
                      child: player != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Jersey number
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                  decoration: BoxDecoration(
                                    color: _getDepthColor(playerIndex + 1),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    '#${player['jersey_number']?.toString() ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Player name
                                Expanded(
                                  child: Text(
                                    player['full_name']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              height: 28,
                              alignment: Alignment.center,
                              child: Text(
                                '-',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getDepthColor(int depth) {
    switch (depth) {
      case 1:
        return const Color(0xFF2E7D32); // Green for starters
      case 2:
        return const Color(0xFF1976D2); // Blue for backups
      case 3:
        return const Color(0xFFE65100); // Orange for third string
      default:
        return const Color(0xFF616161); // Grey for reserves
    }
  }

  Widget _buildTeamLogo(String teamCode) {
    return TeamLogoUtils.buildNFLTeamLogo(teamCode, size: 32.0);
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 