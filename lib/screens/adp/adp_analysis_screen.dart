// lib/screens/adp/adp_analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../models/adp/adp_comparison.dart';
import '../../services/adp/adp_service.dart';
import '../../widgets/common/custom_app_bar.dart';

class ADPAnalysisScreen extends StatefulWidget {
  const ADPAnalysisScreen({super.key});

  @override
  State<ADPAnalysisScreen> createState() => _ADPAnalysisScreenState();
}

class _ADPAnalysisScreenState extends State<ADPAnalysisScreen> {
  // Filter states
  String _scoringFormat = 'ppr';
  int _selectedYear = 2024;
  String _selectedPosition = 'All';
  bool _usePpg = false;
  String _searchQuery = '';
  
  // Data
  List<ADPComparison> _allData = [];
  List<ADPComparison> _filteredData = [];
  List<ADPComparison> _lastYearData = []; // Last year's ADP data for comparison
  List<int> _availableYears = [];
  List<String> _availablePositions = [];
  int _maxYear = 0; // Track the max year available
  
  // Loading state
  bool _isLoading = true;
  
  // Sorting
  int _sortColumnIndex = 4; // Default sort by ADP (updated index)
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Debug: Test asset loading first
    final assetTestResult = await ADPService.testAssetLoading();
    debugPrint('Asset loading test result: $assetTestResult');
    
    try {
      // First, load all data without filters to test basic loading
      debugPrint('Loading all data without filters...');
      final allDataTest = await ADPService.loadADPComparisons(
        scoringFormat: _scoringFormat,
      );
      debugPrint('Successfully loaded ${allDataTest.length} total records');
      
      // Load available years and positions
      final years = await ADPService.getAvailableYears(_scoringFormat);
      final positions = await ADPService.getAvailablePositions(_scoringFormat);
      
      debugPrint('Available years: $years');
      debugPrint('Available positions: $positions');
      
      // Determine max year
      final maxYear = years.isNotEmpty ? years.first : 0; // Years are sorted descending
      
      // Load comparison data with filters
      var data = await ADPService.loadADPComparisons(
        scoringFormat: _scoringFormat,
        year: _selectedYear,
        position: _selectedPosition == 'All' ? null : _selectedPosition,
      );
      
      // Update selected year if not available
      var finalSelectedYear = _selectedYear;
      if (years.isNotEmpty && !years.contains(_selectedYear)) {
        finalSelectedYear = years.first; // Use the most recent year
        debugPrint('Selected year not available, using: $finalSelectedYear');
        
        // Reload data with the corrected year
        data = await ADPService.loadADPComparisons(
          scoringFormat: _scoringFormat,
          year: finalSelectedYear,
          position: _selectedPosition == 'All' ? null : _selectedPosition,
        );
      }
      
      // If on max year, load last year's data for comparison
      List<ADPComparison> lastYearData = [];
      if (finalSelectedYear == maxYear && years.length > 1) {
        final lastYear = years[1]; // Second year in the sorted list
        debugPrint('Loading last year data for year: $lastYear');
        lastYearData = await ADPService.loadADPComparisons(
          scoringFormat: _scoringFormat,
          year: lastYear,
          position: _selectedPosition == 'All' ? null : _selectedPosition,
        );
        debugPrint('Loaded ${lastYearData.length} last year records');
      }
      
      // If still no data, try without year filter as fallback
      if (data.isEmpty) {
        debugPrint('No data for selected year, trying without year filter...');
        data = await ADPService.loadADPComparisons(
          scoringFormat: _scoringFormat,
          position: _selectedPosition == 'All' ? null : _selectedPosition,
        );
        debugPrint('Fallback data: ${data.length} records');
      }
      
      setState(() {
        _availableYears = years;
        _availablePositions = positions;
        _selectedYear = finalSelectedYear;
        _maxYear = maxYear;
        _allData = data;
        _lastYearData = lastYearData;
        debugPrint('Final data loaded: ${data.length} records');
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ADP data: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredData = _allData.where((item) {
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          if (!item.player.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return false;
          }
        }
        return true;
      }).toList();
      
      // If on max year, enhance data with last year's ADP
      if (_selectedYear == _maxYear && _lastYearData.isNotEmpty) {
        // Create a map of last year's data by player name
        final lastYearMap = Map.fromEntries(
          _lastYearData.map((e) => MapEntry(e.player, e))
        );
        
        // Enhance current year data with last year's ADP info
        _filteredData = _filteredData.map((item) {
          final lastYearItem = lastYearMap[item.player];
          if (lastYearItem != null) {
            // Store last year's data in the platform ranks map temporarily
            // We'll use special keys to identify them
            item.platformRanks['_ly_adp'] = lastYearItem.avgRankNum;
            item.platformRanks['_ly_pos_rank'] = lastYearItem.positionRankNum.toDouble();
          }
          return item;
        }).toList();
      }
      
      debugPrint('After filtering: ${_filteredData.length} records');
      
      // Apply sorting
      _sortData();
    });
  }

  void _sortData() {
    _filteredData.sort((a, b) {
      int result = 0;
      final isMaxYear = _selectedYear == _maxYear;
      
      switch (_sortColumnIndex) {
        case 0: // Player
          result = a.player.compareTo(b.player);
          break;
        case 1: // Position
          result = a.position.compareTo(b.position);
          break;
        case 2: // Position Rank (Actual or LY ADP Pos)
          if (isMaxYear) {
            // Sort by last year's ADP position rank
            final aLyPosRank = a.platformRanks['_ly_pos_rank']?.toInt() ?? 999;
            final bLyPosRank = b.platformRanks['_ly_pos_rank']?.toInt() ?? 999;
            result = aLyPosRank.compareTo(bLyPosRank);
          } else {
            final aPosRank = a.getActualPositionRank(_usePpg) ?? 999;
            final bPosRank = b.getActualPositionRank(_usePpg) ?? 999;
            result = aPosRank.compareTo(bPosRank);
          }
          break;
        case 3: // ADP Position Rank
          result = a.positionRankNum.compareTo(b.positionRankNum);
          break;
        case 4: // ADP
          result = a.avgRankNum.compareTo(b.avgRankNum);
          break;
        case 5: // Final Rank or LY ADP
          if (isMaxYear) {
            // Sort by last year's ADP
            final aLyAdp = a.platformRanks['_ly_adp'] ?? 999;
            final bLyAdp = b.platformRanks['_ly_adp'] ?? 999;
            result = aLyAdp.compareTo(bLyAdp);
          } else {
            final aRank = a.getActualRank(_usePpg) ?? 999;
            final bRank = b.getActualRank(_usePpg) ?? 999;
            result = aRank.compareTo(bRank);
          }
          break;
        case 6: // Position Difference
          if (isMaxYear) {
            // Calculate diff based on last year's position rank
            final aLyPosRank = a.platformRanks['_ly_pos_rank']?.toInt();
            final bLyPosRank = b.platformRanks['_ly_pos_rank']?.toInt();
            final aPosDiff = aLyPosRank != null ? a.positionRankNum - aLyPosRank : -999;
            final bPosDiff = bLyPosRank != null ? b.positionRankNum - bLyPosRank : -999;
            result = bPosDiff.compareTo(aPosDiff); // Higher is better
          } else {
            final aPosDiff = a.getPositionDifference(_usePpg) ?? -999;
            final bPosDiff = b.getPositionDifference(_usePpg) ?? -999;
            result = bPosDiff.compareTo(aPosDiff); // Higher is better
          }
          break;
        case 7: // Total Difference
          if (isMaxYear) {
            // Calculate diff based on last year's ADP
            final aLyAdp = a.platformRanks['_ly_adp'];
            final bLyAdp = b.platformRanks['_ly_adp'];
            final aDiff = aLyAdp != null ? a.avgRankNum - aLyAdp : -999;
            final bDiff = bLyAdp != null ? b.avgRankNum - bLyAdp : -999;
            result = bDiff.compareTo(aDiff); // Higher is better
          } else {
            final aDiff = a.getDifference(_usePpg) ?? -999;
            final bDiff = b.getDifference(_usePpg) ?? -999;
            result = bDiff.compareTo(aDiff); // Higher is better
          }
          break;
        case 8: // Points/PPG
          final aPoints = a.getPoints(_usePpg) ?? 0;
          final bPoints = b.getPoints(_usePpg) ?? 0;
          result = bPoints.compareTo(aPoints); // Higher is better
          break;
        case 9: // Games
          final aGames = a.gamesPlayed ?? 0;
          final bGames = b.gamesPlayed ?? 0;
          result = bGames.compareTo(aGames);
          break;
      }
      
      return _sortAscending ? result : -result;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: const Text('ADP Analysis'),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // First row of filters
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    
                    if (isMobile) {
                      return Column(
                        children: [
                          // Mobile: Stack filters vertically
                          Row(
                            children: [
                              // Compact scoring format toggle
                              Expanded(
                                child: SegmentedButton<String>(
                                  style: SegmentedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  segments: const [
                                    ButtonSegment(value: 'ppr', label: Text('PPR')),
                                    ButtonSegment(value: 'standard', label: Text('STD')),
                                  ],
                                  selected: {_scoringFormat},
                                  onSelectionChanged: (Set<String> selected) {
                                    setState(() {
                                      _scoringFormat = selected.first;
                                      _loadData();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Compact points toggle
                              Expanded(
                                child: SegmentedButton<bool>(
                                  style: SegmentedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  segments: const [
                                    ButtonSegment(value: false, label: Text('Total')),
                                    ButtonSegment(value: true, label: Text('PPG')),
                                  ],
                                  selected: {_usePpg},
                                  onSelectionChanged: (Set<bool> selected) {
                                    setState(() {
                                      _usePpg = selected.first;
                                      _applyFilters();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Year and position on mobile
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _availableYears.contains(_selectedYear) ? _selectedYear : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Year',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    labelStyle: TextStyle(fontSize: 12),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                  items: _availableYears.map((year) => DropdownMenuItem(
                                    value: year, child: Text(year.toString()),
                                  )).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedYear = value;
                                        _loadData();
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedPosition,
                                  decoration: const InputDecoration(
                                    labelText: 'Pos',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    labelStyle: TextStyle(fontSize: 12),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                  items: _availablePositions.map((position) => DropdownMenuItem(
                                    value: position, child: Text(position),
                                  )).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedPosition = value;
                                        _loadData();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    
                    // Desktop: Original horizontal layout
                    return Row(
                      children: [
                        // Scoring format toggle
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'ppr', label: Text('PPR')),
                              ButtonSegment(value: 'standard', label: Text('Standard')),
                            ],
                            selected: {_scoringFormat},
                            onSelectionChanged: (Set<String> selected) {
                              setState(() {
                                _scoringFormat = selected.first;
                                _loadData();
                              });
                            },
                          ),
                        ),
                    const SizedBox(width: 16),
                    
                    // Year dropdown
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _availableYears.contains(_selectedYear) ? _selectedYear : null,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _availableYears.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedYear = value;
                              _loadData();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Position filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPosition,
                        decoration: const InputDecoration(
                          labelText: 'Position',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _availablePositions.map((position) {
                          return DropdownMenuItem(
                            value: position,
                            child: Text(position),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPosition = value;
                              _loadData();
                            });
                          }
                        },
                      ),
                    ),
                      ],
                    );
                  },
                ),
                
                // Desktop: search field (desktop always shows search on second row)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    
                    if (isMobile) {
                      // Mobile: Search field
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Search Player',
                            labelStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _applyFilters();
                                      });
                                    },
                                  )
                                : null,
                          ),
                          style: const TextStyle(fontSize: 12),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _applyFilters();
                            });
                          },
                        ),
                      );
                    }
                    
                    // Desktop: Points toggle and search field
                    return Row(
                      children: [
                        // Points toggle
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text('Total Points')),
                              ButtonSegment(value: true, label: Text('PPG')),
                            ],
                            selected: {_usePpg},
                            onSelectionChanged: (Set<bool> selected) {
                              setState(() {
                                _usePpg = selected.first;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Search field
                        Expanded(
                          flex: 2,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Search Player',
                              prefixIcon: const Icon(Icons.search),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _applyFilters();
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                // Legend
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('Elite Value', Colors.green.shade900),
                    const SizedBox(width: 16),
                    _buildLegendItem('Good Value', Colors.green.shade600),
                    const SizedBox(width: 16),
                    _buildLegendItem('Expected', Colors.grey.shade600),
                    const SizedBox(width: 16),
                    _buildLegendItem('Mild Bust', Colors.red.shade400),
                    const SizedBox(width: 16),
                    _buildLegendItem('Major Bust', Colors.red.shade700),
                  ],
                ),
              ],
            ),
          ),
          
          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredData.isEmpty
                    ? const Center(child: Text('No data available'))
                    : DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 1000,
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        columns: [
                          DataColumn2(
                            label: const Text('Player'),
                            size: ColumnSize.L,
                            onSort: _onSort,
                          ),
                          DataColumn2(
                            label: const Text('Pos'),
                            size: ColumnSize.S,
                            onSort: _onSort,
                          ),
                          DataColumn2(
                            label: Text(_selectedYear == _maxYear ? 'LY ADP Pos' : 'Pos Rank'),
                            size: ColumnSize.S,
                            numeric: true,
                            onSort: _onSort,
                            tooltip: _selectedYear == _maxYear ? 'Last year ADP position rank' : 'Actual position rank',
                          ),
                          DataColumn2(
                            label: const Text('ADP Pos'),
                            size: ColumnSize.S,
                            numeric: true,
                            onSort: _onSort,
                            tooltip: 'Current ADP position rank',
                          ),
                          DataColumn2(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('ADP'),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _showPlatformsInfo(context),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            size: ColumnSize.S,
                            numeric: true,
                            onSort: _onSort,
                            tooltip: 'Average Draft Position',
                          ),
                          DataColumn2(
                            label: Text(_selectedYear == _maxYear ? 'LY ADP' : (_usePpg ? 'Final (PPG)' : 'Final')),
                            size: ColumnSize.S,
                            numeric: true,
                            onSort: _onSort,
                            tooltip: _selectedYear == _maxYear ? 'Last year ADP overall rank' : 'Final overall rank by ${_usePpg ? 'points per game' : 'total points'}',
                          ),
                          DataColumn2(
                            label: const Text('Pos Diff'),
                            size: ColumnSize.S,
                            numeric: true,
                            onSort: _onSort,
                            tooltip: _selectedYear == _maxYear 
                                ? 'Current vs last year position rank (negative = higher ADP)'
                                : 'Position rank difference (positive = outperformed ADP)',
                          ),
                          DataColumn2(
                            label: const Text('Total Diff'),
                            size: ColumnSize.S,
                            numeric: true,
                            onSort: _onSort,
                            tooltip: _selectedYear == _maxYear
                                ? 'Current vs last year ADP (negative = higher ADP)'
                                : 'Overall rank difference (positive = outperformed ADP)',
                          ),
                          DataColumn2(
                            label: Text(_usePpg ? 'PPG' : 'Points'),
                            size: ColumnSize.S,
                            numeric: true,
                            onSort: _onSort,
                          ),
                          DataColumn2(
                            label: const Text('Games'),
                            size: ColumnSize.S,
                            numeric: true,
                            onSort: _onSort,
                          ),
                        ],
                        rows: _filteredData.map((item) {
                          // For max year, use last year's ADP for comparison
                          final isMaxYear = _selectedYear == _maxYear;
                          final lyAdp = item.platformRanks['_ly_adp'];
                          final lyPosRank = item.platformRanks['_ly_pos_rank']?.toInt();
                          
                          // Calculate differences based on whether we're on max year or not
                          final diff = isMaxYear && lyAdp != null 
                              ? item.avgRankNum - lyAdp
                              : item.getDifference(_usePpg);
                          final posDiff = isMaxYear && lyPosRank != null
                              ? item.positionRankNum - lyPosRank
                              : item.getPositionDifference(_usePpg);
                          
                          // For display, use last year's data when on max year
                          final displayRank = isMaxYear ? lyAdp?.toInt() : item.getActualRank(_usePpg);
                          final displayPosRank = isMaxYear ? lyPosRank : item.getActualPositionRank(_usePpg);
                          
                          final points = item.getPoints(_usePpg);
                          
                          // Color based on difference magnitude
                          final color = isMaxYear && diff != null
                              ? (diff < -20 ? Colors.green.shade900 : 
                                 diff < -10 ? Colors.green.shade600 :
                                 diff < 5 && diff > -5 ? Colors.grey.shade600 :
                                 diff < 15 ? Colors.red.shade400 : Colors.red.shade700)
                              : item.getPerformanceColor(_usePpg);
                          
                          return DataRow2(
                            cells: [
                              DataCell(
                                Text(
                                  item.player,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: (isMaxYear ? displayRank == null : item.getActualRank(_usePpg) == null) ? Colors.grey : null,
                                  ),
                                ),
                              ),
                              DataCell(Text(item.position)),
                              DataCell(Text(displayPosRank?.toString() ?? '-')),
                              DataCell(Text(item.positionRankNum.toString())),
                              DataCell(Text(item.avgRankNum.toStringAsFixed(1))),
                              DataCell(
                                Text(
                                  displayRank?.toString() ?? '-',
                                  style: TextStyle(color: color),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: posDiff != null ? (posDiff > 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1)) : null,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    posDiff != null 
                                        ? (posDiff > 0 ? '+${posDiff.toStringAsFixed(0)}' : posDiff.toStringAsFixed(0))
                                        : '-',
                                    style: TextStyle(
                                      color: posDiff != null ? (posDiff > 0 ? Colors.green.shade700 : Colors.red.shade700) : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: diff != null ? color.withValues(alpha: 0.1) : null,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    diff != null 
                                        ? (diff > 0 ? '+${diff.toStringAsFixed(0)}' : diff.toStringAsFixed(0))
                                        : '-',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(points != null ? points.toStringAsFixed(1) : '-'),
                              ),
                              DataCell(
                                Text(item.gamesPlayed?.toString() ?? '-'),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  void _showPlatformsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ADP Data Sources'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ADP data is averaged from the following platforms:'),
            const SizedBox(height: 12),
            const Text('• ESPN Fantasy Football'),
            const Text('• Sleeper'),
            const Text('• CBS Sports'),
            const Text('• NFL.com'),
            const Text('• RotobBaller (RTS)'),
            const Text('• Fantasy Football Calculator (FFC)'),
            const SizedBox(height: 12),
            Text(
              'Data sourced from FantasyPros.com',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}