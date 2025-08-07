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
  
  // Advanced filter states
  double? _adpMin;
  double? _adpMax;
  double? _pointsMin;
  double? _pointsMax;
  int? _gamesMin;
  bool _showFiltersExpanded = false;
  
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
  
  // Pagination
  int _currentPage = 0;
  static const int _rowsPerPage = 50;

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
        
        // Apply ADP range filter
        if (_adpMin != null && item.avgRankNum < _adpMin!) {
          return false;
        }
        if (_adpMax != null && item.avgRankNum > _adpMax!) {
          return false;
        }
        
        // Apply points range filter
        if (_pointsMin != null || _pointsMax != null) {
          final points = item.getPoints(_usePpg);
          if (points == null) return false;
          if (_pointsMin != null && points < _pointsMin!) return false;
          if (_pointsMax != null && points > _pointsMax!) return false;
        }
        
        // Apply games filter
        if (_gamesMin != null) {
          final games = item.gamesPlayed;
          if (games == null || games < _gamesMin!) return false;
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
      
      // Reset to first page when filters change
      _currentPage = 0;
      
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
            // Calculate diff based on last year's position rank (LY - Current = positive for risers)
            final aLyPosRank = a.platformRanks['_ly_pos_rank']?.toInt();
            final bLyPosRank = b.platformRanks['_ly_pos_rank']?.toInt();
            final aPosDiff = aLyPosRank != null ? aLyPosRank - a.positionRankNum : -999;
            final bPosDiff = bLyPosRank != null ? bLyPosRank - b.positionRankNum : -999;
            result = bPosDiff.compareTo(aPosDiff); // Higher is better
          } else {
            final aPosDiff = a.getPositionDifference(_usePpg) ?? -999;
            final bPosDiff = b.getPositionDifference(_usePpg) ?? -999;
            result = bPosDiff.compareTo(aPosDiff); // Higher is better
          }
          break;
        case 7: // Total Difference
          if (isMaxYear) {
            // Calculate diff based on last year's ADP (LY - Current = positive for risers)
            final aLyAdp = a.platformRanks['_ly_adp'];
            final bLyAdp = b.platformRanks['_ly_adp'];
            final aDiff = aLyAdp != null ? aLyAdp - a.avgRankNum : -999;
            final bDiff = bLyAdp != null ? bLyAdp - b.avgRankNum : -999;
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
  
  List<ADPComparison> _getPagedRows() {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredData.length);
    return _filteredData.sublist(startIndex, endIndex);
  }
  
  int _getTotalPages() {
    return (_filteredData.length / _rowsPerPage).ceil().clamp(1, double.infinity).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: const Text('ADP Analysis'),
      ),
      body: Column(
        children: [
          // Condensed Filter Section
          Container(
            padding: const EdgeInsets.all(12),
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
                // Main controls row
                Row(
                  children: [
                    // Format toggle (compact)
                    SegmentedButton<String>(
                      style: SegmentedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
                    const SizedBox(width: 12),
                    
                    // Year dropdown (compact)
                    SizedBox(
                      width: 80,
                      child: DropdownButtonFormField<int>(
                        value: _availableYears.contains(_selectedYear) ? _selectedYear : null,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          labelStyle: TextStyle(fontSize: 12),
                        ),
                        style: const TextStyle(fontSize: 13),
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
                    const SizedBox(width: 12),
                    
                    // Position dropdown (compact)
                    SizedBox(
                      width: 70,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPosition,
                        decoration: const InputDecoration(
                          labelText: 'Pos',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          labelStyle: TextStyle(fontSize: 12),
                        ),
                        style: const TextStyle(fontSize: 13),
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
                    const SizedBox(width: 12),
                    
                    // Points toggle (compact)
                    SegmentedButton<bool>(
                      style: SegmentedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
                    
                    const Spacer(),
                    
                    // Advanced filters toggle
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showFiltersExpanded = !_showFiltersExpanded;
                        });
                      },
                      icon: Icon(
                        _showFiltersExpanded ? Icons.keyboard_arrow_up : Icons.tune,
                        size: 18,
                      ),
                      label: Text(
                        _showFiltersExpanded ? 'Hide Filters' : 'Advanced Filters',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Search field (always visible)
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Player',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    labelStyle: const TextStyle(fontSize: 13),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _applyFilters();
                              });
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                
                // Advanced filters (expandable)
                if (_showFiltersExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Advanced Filters',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // ADP Range filters
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'ADP Min (e.g., 1)',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  labelStyle: TextStyle(fontSize: 12),
                                ),
                                style: const TextStyle(fontSize: 13),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _adpMin = value.isEmpty ? null : double.tryParse(value);
                                    _applyFilters();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'ADP Max (e.g., 100)',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  labelStyle: TextStyle(fontSize: 12),
                                ),
                                style: const TextStyle(fontSize: 13),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _adpMax = value.isEmpty ? null : double.tryParse(value);
                                    _applyFilters();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Points and Games filters
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Min ${_usePpg ? 'PPG' : 'Points'}',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  labelStyle: const TextStyle(fontSize: 12),
                                ),
                                style: const TextStyle(fontSize: 13),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _pointsMin = value.isEmpty ? null : double.tryParse(value);
                                    _applyFilters();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Min Games',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  labelStyle: TextStyle(fontSize: 12),
                                ),
                                style: const TextStyle(fontSize: 13),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    _gamesMin = value.isEmpty ? null : int.tryParse(value);
                                    _applyFilters();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        // Quick filter buttons
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildQuickFilterChip('Top 100 ADP', () {
                              setState(() {
                                _adpMin = null;
                                _adpMax = 100;
                                _applyFilters();
                              });
                            }),
                            _buildQuickFilterChip('Early Rounds (1-50)', () {
                              setState(() {
                                _adpMin = null;
                                _adpMax = 50;
                                _applyFilters();
                              });
                            }),
                            _buildQuickFilterChip('Mid Rounds (51-120)', () {
                              setState(() {
                                _adpMin = 51;
                                _adpMax = 120;
                                _applyFilters();
                              });
                            }),
                            _buildQuickFilterChip('Clear Filters', () {
                              setState(() {
                                _adpMin = null;
                                _adpMax = null;
                                _pointsMin = null;
                                _pointsMax = null;
                                _gamesMin = null;
                                _applyFilters();
                              });
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Legend (condensed)
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildLegendItem('Elite Value', Colors.green.shade900),
                      const SizedBox(width: 12),
                      _buildLegendItem('Good Value', Colors.green.shade600),
                      const SizedBox(width: 12),
                      _buildLegendItem('Expected', Colors.grey.shade600),
                      const SizedBox(width: 12),
                      _buildLegendItem('Mild Bust', Colors.red.shade400),
                      const SizedBox(width: 12),
                      _buildLegendItem('Major Bust', Colors.red.shade700),
                    ],
                  ),
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
                    : Column(
                        children: [
                          Expanded(
                            child: DataTable2(
                              columnSpacing: 10,
                              horizontalMargin: 10,
                              minWidth: 800,
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _sortAscending,
                              columns: [
                                DataColumn2(
                                  label: const Text('Player', style: TextStyle(fontSize: 13)),
                                  fixedWidth: 180,
                                  onSort: _onSort,
                                ),
                                DataColumn2(
                                  label: const Text('Pos', style: TextStyle(fontSize: 13)),
                                  fixedWidth: 50,
                                  onSort: _onSort,
                                ),
                                DataColumn2(
                                  label: Text(
                                    _selectedYear == _maxYear ? 'LY ADP\nPos' : 'Pos\nRank',
                                    style: const TextStyle(fontSize: 13),
                                    textAlign: TextAlign.left,
                                  ),
                                  fixedWidth: 70,
                                  numeric: true,
                                  onSort: _onSort,
                                  tooltip: _selectedYear == _maxYear ? 'Last year ADP position rank' : 'Actual position rank',
                                ),
                                DataColumn2(
                                  label: const Text('ADP\nPos', style: TextStyle(fontSize: 13), textAlign: TextAlign.left),
                                  fixedWidth: 60,
                                  numeric: true,
                                  onSort: _onSort,
                                  tooltip: 'Current ADP position rank',
                                ),
                                DataColumn2(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('ADP', style: TextStyle(fontSize: 13)),
                                      const SizedBox(width: 3),
                                      GestureDetector(
                                        onTap: () => _showPlatformsInfo(context),
                                        child: Icon(
                                          Icons.info_outline,
                                          size: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  fixedWidth: 75,
                                  numeric: true,
                                  onSort: _onSort,
                                  tooltip: 'Average Draft Position',
                                ),
                                DataColumn2(
                                  label: Text(
                                    _selectedYear == _maxYear ? 'LY\nADP' : (_usePpg ? 'Final\nPPG' : 'Final'),
                                    style: const TextStyle(fontSize: 13),
                                    textAlign: TextAlign.left,
                                  ),
                                  fixedWidth: 65,
                                  numeric: true,
                                  onSort: _onSort,
                                  tooltip: _selectedYear == _maxYear ? 'Last year ADP overall rank' : 'Final overall rank by ${_usePpg ? 'points per game' : 'total points'}',
                                ),
                                DataColumn2(
                                  label: const Text('Pos\nDiff', style: TextStyle(fontSize: 13), textAlign: TextAlign.left),
                                  fixedWidth: 65,
                                  numeric: true,
                                  onSort: _onSort,
                                  tooltip: _selectedYear == _maxYear 
                                      ? 'Last year vs current position rank (positive = riser)'
                                      : 'Position rank difference (positive = outperformed ADP)',
                                ),
                                DataColumn2(
                                  label: const Text('Total\nDiff', style: TextStyle(fontSize: 13), textAlign: TextAlign.left),
                                  fixedWidth: 65,
                                  numeric: true,
                                  onSort: _onSort,
                                  tooltip: _selectedYear == _maxYear
                                      ? 'Last year vs current ADP (positive = riser)'
                                      : 'Overall rank difference (positive = outperformed ADP)',
                                ),
                                DataColumn2(
                                  label: Text(_usePpg ? 'PPG' : 'Points', style: const TextStyle(fontSize: 13)),
                                  fixedWidth: 70,
                                  numeric: true,
                                  onSort: _onSort,
                                ),
                                DataColumn2(
                                  label: const Text('Games', style: TextStyle(fontSize: 13)),
                                  fixedWidth: 60,
                                  numeric: true,
                                  onSort: _onSort,
                                ),
                              ],
                              rows: _getPagedRows().map((item) {
                          // For max year, use last year's ADP for comparison
                          final isMaxYear = _selectedYear == _maxYear;
                          final lyAdp = item.platformRanks['_ly_adp'];
                          final lyPosRank = item.platformRanks['_ly_pos_rank']?.toInt();
                          
                          // Calculate differences based on whether we're on max year or not
                          // For max year: LY - Current = positive for risers (improved players)
                          final diff = isMaxYear && lyAdp != null 
                              ? lyAdp - item.avgRankNum
                              : item.getDifference(_usePpg);
                          final posDiff = isMaxYear && lyPosRank != null
                              ? lyPosRank - item.positionRankNum
                              : item.getPositionDifference(_usePpg);
                          
                          // For display, use last year's data when on max year
                          final displayRank = isMaxYear ? lyAdp?.toInt() : item.getActualRank(_usePpg);
                          final displayPosRank = isMaxYear ? lyPosRank : item.getActualPositionRank(_usePpg);
                          
                          final points = item.getPoints(_usePpg);
                          
                          // Color based on difference magnitude (positive = riser/green, negative = faller/red)
                          final color = isMaxYear && diff != null
                              ? (diff > 20 ? Colors.green.shade900 : 
                                 diff > 10 ? Colors.green.shade600 :
                                 diff < 5 && diff > -5 ? Colors.grey.shade600 :
                                 diff > -15 ? Colors.red.shade400 : Colors.red.shade700)
                              : item.getPerformanceColor(_usePpg);
                          
                          return DataRow2(
                            cells: [
                              DataCell(
                                Text(
                                  item.player,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: (isMaxYear ? displayRank == null : item.getActualRank(_usePpg) == null) ? Colors.grey : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(Text(item.position, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(displayPosRank?.toString() ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(item.positionRankNum.toString(), style: const TextStyle(fontSize: 12))),
                              DataCell(Text(item.avgRankNum.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
                              DataCell(
                                Text(
                                  displayRank?.toString() ?? '-',
                                  style: TextStyle(color: color, fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                                Text(points != null ? points.toStringAsFixed(1) : '-', style: const TextStyle(fontSize: 12)),
                              ),
                              DataCell(
                                Text(item.gamesPlayed?.toString() ?? '-', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    // Pagination controls
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${_currentPage * _rowsPerPage + 1}-${((_currentPage + 1) * _rowsPerPage).clamp(0, _filteredData.length)} of ${_filteredData.length}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.first_page, size: 20),
                                onPressed: _currentPage > 0
                                    ? () => setState(() => _currentPage = 0)
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_left, size: 20),
                                onPressed: _currentPage > 0
                                    ? () => setState(() => _currentPage--)
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Page ${_currentPage + 1} of ${_getTotalPages()}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, size: 20),
                                onPressed: _currentPage < _getTotalPages() - 1
                                    ? () => setState(() => _currentPage++)
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.last_page, size: 20),
                                onPressed: _currentPage < _getTotalPages() - 1
                                    ? () => setState(() => _currentPage = _getTotalPages() - 1)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }
  
  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: onTap,
      backgroundColor: Colors.blue.withValues(alpha: 0.1),
      side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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