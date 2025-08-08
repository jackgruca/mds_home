import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/theme_config.dart';
import '../../utils/seo_helper.dart';
import '../../services/rankings/csv_rankings_service.dart';
import '../../services/rankings/ranking_cell_shading_service.dart';

class EdgeRankingsScreen extends StatefulWidget {
  const EdgeRankingsScreen({super.key});

  @override
  State<EdgeRankingsScreen> createState() => _EdgeRankingsScreenState();
}

class _EdgeRankingsScreenState extends State<EdgeRankingsScreen> {
  List<Map<String, dynamic>> _edgeRankings = [];
  List<Map<String, dynamic>> _originalRankings = []; // Store original rankings
  bool _isLoading = true;
  String? _error;
  String _selectedSeason = '2024';
  String _selectedTier = 'All';
  bool _showRanks = false; // Toggle between showing ranks vs raw stats
  bool _showWeightPanel = false; // Toggle weight adjustment panel
  bool _showFilterPanel = false; // Toggle filter panel
  bool _usingCustomWeights = false; // Track if custom weights are applied
  bool _usingFilters = false; // Track if filters are applied
  
  // Sorting state - default to rank ascending (rank 1 first)
  String _sortColumn = 'ranking';
  bool _sortAscending = true;
  
  late final List<String> _seasonOptions;
  late final List<String> _tierOptions;
  late Map<String, Map<String, dynamic>> _edgeStatFields;
  // Weight and filter variables removed until dependencies are available
  
  final Map<String, Map<String, double>> _percentileCache = {};

  @override
  void initState() {
    super.initState();
    
    // Update SEO meta tags for EDGE Rankings page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // SEOHelper.updateForEdgeRankings(); // Add this method if needed
    });
    
    _seasonOptions = ['2024', '2023', '2022', '2021', 'All']; // Will be loaded from CSV
    _tierOptions = ['All', '1', '2', '3', '4', '5']; // Will be loaded from CSV
    _updateStatFields();
    _loadEdgeRankings();
  }
  
  void _updateStatFields() {
    // For now, use basic EDGE stat fields - can be enhanced later
    _edgeStatFields = {
      'ranking': {'label': 'Rank', 'type': 'rank', 'weight': 0},
      'name': {'label': 'Name', 'type': 'text', 'weight': 0},
      'team': {'label': 'Team', 'type': 'text', 'weight': 0},
      'season': {'label': 'Season', 'type': 'text', 'weight': 0},
      'tier': {'label': 'Tier', 'type': 'tier', 'weight': 0},
      'sacks': {'label': 'Sacks', 'type': 'stat', 'weight': 0.3},
      'qb_hits': {'label': 'QB Hits', 'type': 'stat', 'weight': 0.25},
      'pressure_rate': {'label': 'Pressure %', 'type': 'stat', 'weight': 0.2},
      'tfls': {'label': 'TFLs', 'type': 'stat', 'weight': 0.15},
      'forced_fumbles': {'label': 'FF', 'type': 'stat', 'weight': 0.1},
    };
  }

  Future<void> _loadEdgeRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🏈 EdgeRankings: Starting to load EDGE rankings...');
      final csvService = CSVRankingsService();
      final allRankings = await csvService.fetchEdgeRankings();
      
      print('🏈 EdgeRankings: Received ${allRankings.length} total rankings from CSV service');
      print('🏈 EdgeRankings: Current filters - Season: "$_selectedSeason", Tier: "$_selectedTier"');
      
      // Filter by season and tier
      final rankings = allRankings.where((ranking) {
        bool matchesSeason = _selectedSeason == 'All' || 
                            ranking['season']?.toString() == _selectedSeason;
        bool matchesTier = _selectedTier == 'All' || 
                          (ranking['tier']?.toString() == _selectedTier);
        return matchesSeason && matchesTier;
      }).toList();
      
      print('🏈 EdgeRankings: After filtering: ${rankings.length} rankings remain');
      
      if (rankings.isEmpty && allRankings.isNotEmpty) {
        print('⚠️ EdgeRankings: All rankings were filtered out!');
        print('⚠️ EdgeRankings: Sample raw data - season: ${allRankings.first['season']}, tier: ${allRankings.first['tier']}');
        print('⚠️ EdgeRankings: Filter criteria - season: "$_selectedSeason", tier: "$_selectedTier"');
      }

      setState(() {
        _originalRankings = allRankings;
        _edgeRankings = rankings;
        _isLoading = false;
      });

      // Calculate percentiles for shading
      _calculatePercentiles();

    } catch (e) {
      print('❌ EdgeRankings: Error loading rankings: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _calculatePercentiles() {
    if (_edgeRankings.isEmpty) return;
    
    final statFields = _edgeStatFields.keys.where((key) => 
      !['ranking', 'name', 'team', 'season', 'tier'].contains(key)
    ).toList();
    
    for (final field in statFields) {
      final values = _edgeRankings
          .map((r) => _parseDouble(r[field]))
          .where((v) => v > 0)
          .toList()
        ..sort();
      
      if (values.isNotEmpty) {
        final percentiles = <String, double>{};
        for (final ranking in _edgeRankings) {
          final value = _parseDouble(ranking[field]);
          if (value > 0) {
            final percentile = values.where((v) => v <= value).length / values.length;
            final playerId = '${ranking['name']}_${ranking['season']}';
            percentiles[playerId] = percentile;
          }
        }
        _percentileCache[field] = percentiles;
      }
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _sortTable(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = column == 'ranking'; // Rank should be ascending by default
      }
      
      _edgeRankings.sort((a, b) {
        dynamic aValue = a[column];
        dynamic bValue = b[column];
        
        // Handle numeric fields
        if (column == 'ranking' || column == 'tier' || _edgeStatFields[column]?['type'] == 'stat') {
          double aNum = _parseDouble(aValue);
          double bNum = _parseDouble(bValue);
          int result = aNum.compareTo(bNum);
          return _sortAscending ? result : -result;
        }
        
        // Handle text fields
        String aStr = aValue?.toString() ?? '';
        String bStr = bValue?.toString() ?? '';
        int result = aStr.compareTo(bStr);
        return _sortAscending ? result : -result;
      });
    });
  }

  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: currentRouteName)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading EDGE rankings...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEdgeRankings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFiltersSection(),
        _buildTableHeader(),
        Expanded(child: _buildDataTable()),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSeason,
              decoration: const InputDecoration(
                labelText: 'Season',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _seasonOptions.map((season) {
                return DropdownMenuItem(value: season, child: Text(season));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSeason = value);
                  _loadEdgeRankings();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTier,
              decoration: const InputDecoration(
                labelText: 'Tier',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _tierOptions.map((tier) {
                return DropdownMenuItem(value: tier, child: Text(tier));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTier = value);
                  _loadEdgeRankings();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Text(
            'EDGE Rankings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          // Toggle ranks/stats button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showRanks = !_showRanks;
                _updateStatFields();
              });
            },
            icon: Icon(_showRanks ? Icons.numbers : Icons.bar_chart),
            label: Text(_showRanks ? 'Show Stats' : 'Show Ranks'),
          ),
          const SizedBox(width: 8),
          // Weight adjustment button
          TextButton.icon(
            onPressed: _toggleWeightPanel,
            icon: Icon(
              Icons.tune,
              color: _usingCustomWeights ? Colors.orange : null,
            ),
            label: Text(
              'Weights',
              style: TextStyle(
                color: _usingCustomWeights ? Colors.orange : null,
                fontWeight: _usingCustomWeights ? FontWeight.bold : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter button
          TextButton.icon(
            onPressed: _toggleFilterPanel,
            icon: Icon(
              Icons.filter_list,
              color: _usingFilters ? Colors.blue : null,
            ),
            label: Text(
              'Filter',
              style: TextStyle(
                color: _usingFilters ? Colors.blue : null,
                fontWeight: _usingFilters ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_edgeRankings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No EDGE rankings found for the selected filters.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          sortColumnIndex: _edgeStatFields.keys.toList().indexOf(_sortColumn) != -1 
              ? _edgeStatFields.keys.toList().indexOf(_sortColumn) 
              : null,
          sortAscending: _sortAscending,
          headingRowHeight: 56,
          dataRowHeight: 48,
          columns: _edgeStatFields.entries.map((entry) {
            return DataColumn(
              label: Text(
                entry.value['label'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: entry.key == 'name' || entry.key == 'team' 
                  ? null 
                  : (_, __) => _sortTable(entry.key),
            );
          }).toList(),
          rows: _edgeRankings.map((ranking) {
            return DataRow(
              cells: _edgeStatFields.keys.map((field) {
                final value = ranking[field];
                return _buildDataCell(field, value, ranking);
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  DataCell _buildDataCell(String field, dynamic value, Map<String, dynamic> ranking) {
    final fieldConfig = _edgeStatFields[field]!;
    
    Widget cellContent;
    
    switch (fieldConfig['type']) {
      case 'tier':
        final tier = _parseDouble(value).toInt();
        cellContent = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTierColor(tier),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tier.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
        break;
      case 'rank':
        cellContent = Text(
          value?.toString() ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
        break;
      case 'stat':
        final numValue = _parseDouble(value);
        cellContent = Container(
          decoration: BoxDecoration(
            color: _getCellColor(field, ranking),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(4),
          child: Text(
            numValue.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        );
        break;
      case 'text':
      default:
        cellContent = Text(value?.toString() ?? '');
        break;
    }
    
    return DataCell(cellContent);
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1: return Colors.green.shade600;
      case 2: return Colors.lightGreen.shade600;
      case 3: return Colors.yellow.shade700;
      case 4: return Colors.orange.shade600;
      case 5: return Colors.red.shade400;
      default: return Colors.grey.shade500;
    }
  }

  Color? _getCellColor(String field, Map<String, dynamic> ranking) {
    final value = _parseDouble(ranking[field]);
    if (value <= 0) return null;
    
    // Create a simple percentile-based color scheme
    final values = _edgeRankings
        .map((r) => _parseDouble(r[field]))
        .where((v) => v > 0)
        .toList()
      ..sort();
    
    if (values.isEmpty) return null;
    
    final percentile = values.where((v) => v <= value).length / values.length;
    
    // Higher is better for most stats, so higher percentile = better color
    if (percentile >= 0.75) {
      return Colors.green.withOpacity(0.7);
    } else if (percentile >= 0.5) {
      return Colors.green.withOpacity(0.4);
    } else if (percentile >= 0.25) {
      return Colors.orange.withOpacity(0.3);
    } else {
      return Colors.red.withOpacity(0.3);
    }
  }

  void _onWeightsChanged() {
    // Weight changes logic placeholder
    setState(() {
      _usingCustomWeights = true;
    });
  }

  void _resetWeights() {
    setState(() {
      _usingCustomWeights = false;
    });
  }

  void _toggleWeightPanel() {
    setState(() {
      _showWeightPanel = !_showWeightPanel;
      if (_showWeightPanel) {
        _showFilterPanel = false;
      }
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
      if (_showFilterPanel) {
        _showWeightPanel = false;
      }
    });
  }

  void _onFilterChanged() {
    setState(() {
      _usingFilters = !_usingFilters;
    });
    
    // Apply filter logic here if needed
    _loadEdgeRankings();
  }
}