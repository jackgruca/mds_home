import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import '../../models/fantasy/player_ranking.dart';
import '../../services/fantasy/csv_rankings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/theme_config.dart';

class BigBoardScreen extends StatefulWidget {
  const BigBoardScreen({super.key});

  @override
  State<BigBoardScreen> createState() => _BigBoardScreenState();
}

class CustomColumn {
  String title;
  Map<String, int> values;
  CustomColumn({required this.title, Map<String, int>? values}) : values = values ?? {};
}

class _BigBoardScreenState extends State<BigBoardScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<PlayerRanking> _rankings = [];
  List<PlayerRanking> _filteredRankings = [];
  int? _sortColumnIndex;
  final bool _sortAscending = true;
  final CSVRankingsService _csvService = CSVRankingsService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<CustomColumn> _customColumns = [];
  String _positionFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchRankings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRankings() async {
    setState(() => _isLoading = true);

    try {
      final rankings = await _csvService.fetchRankings();
      setState(() {
        _rankings = rankings;
        _filteredRankings = rankings;
        _sortData('Consensus Rank', true); // Initial sort by consensus rank
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading rankings: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _filterRankings(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<PlayerRanking> get _visibleRankings {
    return _rankings.where((player) {
      final matchesSearch = _searchQuery.isEmpty ||
        player.name.toLowerCase().contains(_searchQuery) ||
        player.position.toLowerCase().contains(_searchQuery) ||
        player.rank.toString().contains(_searchQuery) ||
        (player.additionalRanks['PFF']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['CBS']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['ESPN']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['FFToday']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['FootballGuys']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['Yahoo']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['NFL']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['Consensus']?.toString() ?? '').contains(_searchQuery) ||
        (player.additionalRanks['Consensus Rank']?.toString() ?? '').contains(_searchQuery) ||
        _customColumns.any((col) => (col.values[player.id]?.toString() ?? '').contains(_searchQuery));
      final matchesPosition = _positionFilter == 'All' || player.position == _positionFilter;
      return matchesSearch && matchesPosition;
    }).toList();
  }

  void _sortData(String column, bool ascending) {
    _filteredRankings.sort((a, b) {
      dynamic aValue;
      dynamic bValue;
      switch (column) {
        case 'Name':
          aValue = a.name;
          bValue = b.name;
          break;
        case 'Position':
          aValue = a.position;
          bValue = b.position;
          break;
        case 'Team':
          aValue = a.team;
          bValue = b.team;
          break;
        case 'ESPN':
          aValue = a.additionalRanks['ESPN'];
          bValue = b.additionalRanks['ESPN'];
          break;
        case 'PFF':
          aValue = a.additionalRanks['PFF'];
          bValue = b.additionalRanks['PFF'];
          break;
        case 'CBS':
          aValue = a.additionalRanks['CBS'];
          bValue = b.additionalRanks['CBS'];
          break;
        case 'FFToday':
          aValue = a.additionalRanks['FFToday'];
          bValue = b.additionalRanks['FFToday'];
          break;
        case 'FootballGuys':
          aValue = a.additionalRanks['FootballGuys'];
          bValue = b.additionalRanks['FootballGuys'];
          break;
        case 'Yahoo':
          aValue = a.additionalRanks['Yahoo'];
          bValue = b.additionalRanks['Yahoo'];
          break;
        case 'NFL':
          aValue = a.additionalRanks['NFL'];
          bValue = b.additionalRanks['NFL'];
          break;
        case 'Consensus':
          aValue = a.additionalRanks['Consensus'];
          bValue = b.additionalRanks['Consensus'];
          break;
        case 'Consensus Rank':
          aValue = a.rank; // Main rank is consensus
          bValue = b.rank;
          break;
        case 'Bye':
          aValue = a.additionalRanks['Bye'];
          bValue = b.additionalRanks['Bye'];
          break;
        default:
          if (_customColumns.any((c) => c.title == column)) {
            final col = _customColumns.firstWhere((c) => c.title == column);
            aValue = col.values[a.id];
            bValue = col.values[b.id];
          } else {
          aValue = a.name;
          bValue = b.name;
          }
      }
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? 1 : -1;
      if (bValue == null) return ascending ? -1 : 1;
      if (aValue is num && bValue is num) {
        return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      return ascending ? aValue.toString().compareTo(bValue.toString()) : bValue.toString().compareTo(aValue.toString());
    });
  }

  void _onAddCustomColumn() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Custom Column'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Column Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.darkNavy,
                foregroundColor: ThemeConfig.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (title != null && title.isNotEmpty) {
      final newCol = CustomColumn(title: title);
      for (final player in _rankings) {
        final consensusRank = player.rank; // Use main rank now
          newCol.values[player.id] = consensusRank;
      }
      setState(() {
        _customColumns.add(newCol);
      });
    }
  }

  void _onRemoveCustomColumn(int index) {
    setState(() {
      _customColumns.removeAt(index);
    });
  }

  void _editCustomRank(BuildContext context, String id, int? currentValue, int colIndex) async {
    final controller = TextEditingController(text: currentValue?.toString() ?? '');
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Set ${_customColumns[colIndex].title}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter custom rank',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                final value = int.tryParse(text);
                Navigator.pop(context, value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.darkNavy,
                foregroundColor: ThemeConfig.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        _customColumns[colIndex].values[id] = result;
      });
    }
  }

  void _onUpdateRanks() {
    setState(() {
      for (final player in _rankings) {
        final ranks = <num>[];
        if (player.rank > 0) ranks.add(player.rank);
        final fp = player.additionalRanks['FantasyPro'];
        if (fp != null) ranks.add(fp);
        final cbs = player.additionalRanks['CBS'];
        if (cbs != null) ranks.add(cbs);
        for (final col in _customColumns) {
          final val = col.values[player.id];
          if (val != null) ranks.add(val);
        }
        final consensus = ranks.isNotEmpty ? ranks.reduce((a, b) => a + b) / ranks.length : null;
        player.additionalRanks['Consensus'] = consensus;
      }
      final sorted = List<PlayerRanking>.from(_rankings);
      sorted.sort((a, b) {
        final aVal = a.additionalRanks['Consensus'];
        final bVal = b.additionalRanks['Consensus'];
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return 1;
        if (bVal == null) return -1;
        return (aVal as num).compareTo(bVal as num);
      });
      for (int i = 0; i < sorted.length; i++) {
        sorted[i].additionalRanks['Consensus Rank'] = i + 1;
      }
    });
  }

  Future<void> _onImportCSV() async {
    if (_customColumns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Add a custom column first.'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.bytes != null) {
      final csvString = utf8.decode(result.files.single.bytes!);
      final lines = const LineSplitter().convert(csvString);
      // Expecting: Name,CustomRank
      final Map<String, int> importMap = {};
      for (final line in lines.skip(1)) {
        final parts = line.split(',');
        if (parts.length < 2) continue;
        final name = parts[0].trim();
        final value = int.tryParse(parts[1].trim());
        if (value != null) {
          // Find player by name
          final player = _rankings.where((p) => p.name == name).toList();
          if (player.isNotEmpty) {
            importMap[player.first.id] = value;
          }
        }
      }
      setState(() {
        // Always update the most recently added custom column
        final col = _customColumns.last;
        col.values.addAll(importMap);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Custom ranks imported successfully!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildPlayerCard(PlayerRanking player, int index) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 20.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ThemeConfig.gold.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeConfig.darkNavy.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Could add player detail dialog here
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with rank, name, position
                      Row(
                        children: [
                          // Consensus rank badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ThemeConfig.gold,
                                  ThemeConfig.gold.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: ThemeConfig.gold.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '#${player.rank}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Player info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: ThemeConfig.darkNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Position badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getPositionColor(player.position).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getPositionColor(player.position),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        player.position,
                                        style: TextStyle(
                                          color: _getPositionColor(player.position),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Team logo and name
                                    if (player.team.isNotEmpty) ...[
                                      TeamLogoUtils.buildNFLTeamLogo(player.team, size: 20),
                                      const SizedBox(width: 6),
                                      Text(
                                        player.team,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                    
                                    const Spacer(),
                                    
                                    // Bye week
                                    if (player.additionalRanks['Bye'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Bye ${player.additionalRanks['Bye']}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Rankings grid
                      _buildRankingsGrid(player, theme),
                      
                      // Custom columns if any
                      if (_customColumns.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildCustomRankings(player, theme),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingsGrid(PlayerRanking player, ThemeData theme) {
    final rankings = [
      {'label': 'PFF', 'value': player.additionalRanks['PFF']},
      {'label': 'CBS', 'value': player.additionalRanks['CBS']},
      {'label': 'ESPN', 'value': player.additionalRanks['ESPN']},
      {'label': 'FFToday', 'value': player.additionalRanks['FFToday']},
      {'label': 'FG', 'value': player.additionalRanks['FootballGuys']},
      {'label': 'Yahoo', 'value': player.additionalRanks['Yahoo']},
      {'label': 'NFL', 'value': player.additionalRanks['NFL']},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Rankings',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.darkNavy,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: rankings.map((ranking) {
              final value = ranking['value'];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: value != null 
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: value != null 
                      ? ThemeConfig.darkNavy.withOpacity(0.2)
                      : theme.dividerColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ranking['label'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value?.toString() ?? '-',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: value != null 
                          ? ThemeConfig.darkNavy
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRankings(PlayerRanking player, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeConfig.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeConfig.gold.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Rankings',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.darkNavy,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _customColumns.map((col) {
              final value = col.values[player.id];
              return GestureDetector(
                onTap: () => _editCustomRank(context, player.id, value, _customColumns.indexOf(col)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ThemeConfig.gold.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        col.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value?.toString() ?? '-',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeConfig.darkNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position.toUpperCase()) {
      case 'QB':
        return Colors.red.shade600;
      case 'RB':
        return Colors.green.shade600;
      case 'WR':
        return Colors.blue.shade600;
      case 'TE':
        return Colors.orange.shade600;
      case 'K':
        return Colors.purple.shade600;
      case 'D/ST':
        return Colors.brown.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);
    final List<String> positions = ['All', 'QB', 'RB', 'WR', 'TE', 'K', 'D/ST'];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: currentRouteName)),
          ],
        ),
        actions: [
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(20),
            shadowColor: ThemeConfig.gold.withOpacity(0.2),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                _fetchRankings();
              },
              tooltip: 'Refresh Rankings',
              style: IconButton.styleFrom(
                backgroundColor: ThemeConfig.darkNavy,
                foregroundColor: ThemeConfig.gold,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Compact header section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: ThemeConfig.darkNavy.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Title row with action buttons
                  Row(
                    children: [
                      // Title section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fantasy Big Board',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ThemeConfig.darkNavy,
                              ),
                            ),
                            Text(
                              'Comprehensive rankings from multiple platforms',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            elevation: 1,
                            borderRadius: BorderRadius.circular(16),
                            shadowColor: ThemeConfig.gold.withOpacity(0.2),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _onAddCustomColumn();
                              },
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add Column', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ThemeConfig.darkNavy,
                                foregroundColor: ThemeConfig.gold,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            elevation: 0,
                            borderRadius: BorderRadius.circular(16),
                            child: OutlinedButton.icon(
                              onPressed: _onImportCSV,
                              icon: const Icon(Icons.upload_file_rounded, size: 16),
                              label: const Text('Import CSV', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ThemeConfig.darkNavy,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: const Size(0, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: ThemeConfig.darkNavy.withOpacity(0.3)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Search and filters row
                  Row(
                    children: [
                      // Search bar
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: ThemeConfig.darkNavy.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search players...',
                              hintStyle: const TextStyle(fontSize: 14),
                              prefixIcon: Icon(Icons.search_rounded, size: 20, color: ThemeConfig.darkNavy.withOpacity(0.7)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            onChanged: _filterRankings,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Position filters
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: positions.map((pos) => Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: FilterChip(
                                label: Text(pos, style: const TextStyle(fontSize: 12)),
                                selected: _positionFilter == pos,
                                onSelected: (_) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _positionFilter = pos;
                                  });
                                },
                                backgroundColor: theme.colorScheme.surface,
                                selectedColor: ThemeConfig.gold.withOpacity(0.2),
                                checkmarkColor: ThemeConfig.darkNavy,
                                labelStyle: TextStyle(
                                  color: _positionFilter == pos 
                                    ? ThemeConfig.darkNavy 
                                    : theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: _positionFilter == pos 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: _positionFilter == pos 
                                    ? ThemeConfig.gold 
                                    : theme.dividerColor.withOpacity(0.3),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Responsive content - cards on mobile, table on web/desktop
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.gold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading rankings...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _visibleRankings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: theme.colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No players found',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search or filters',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Use cards on mobile (< 768px), table on web/desktop
                            final isMobile = constraints.maxWidth < 768;
                            
                            if (isMobile) {
                              return AnimationLimiter(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  itemCount: _visibleRankings.length,
                                  itemBuilder: (context, index) {
                                    return _buildPlayerCard(_visibleRankings[index], index);
                                  },
                                ),
                              );
                            } else {
                              return SingleChildScrollView(
                                child: _buildModernTable(),
                              );
                            }
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTable() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeConfig.gold.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.darkNavy.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: AnimationLimiter(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(ThemeConfig.darkNavy),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              showCheckboxColumn: false,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              columnSpacing: 24,
              horizontalMargin: 20,
              dividerThickness: 0,
              columns: _getModernColumns(),
              rows: _getModernRows(),
            ),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _getModernColumns() {
    return [
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('Rank'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Consensus Rank', asc));
        },
      ),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('Player'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Name', asc));
        },
      ),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('Pos'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Position', asc));
        },
      ),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('Team'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Team', asc));
        },
      ),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('Bye'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Bye', asc));
        },
      ),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('PFF'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('PFF', asc));
        },
      ),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('CBS'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('CBS', asc));
        },
      ),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('ESPN'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('ESPN', asc));
        },
      ),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('FFT'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('FFToday', asc));
        },
      ),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('FG'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('FootballGuys', asc));
        },
      ),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('Yahoo'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('Yahoo', asc));
        },
      ),
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: const Text('NFL'),
        ),
        onSort: (i, asc) {
          HapticFeedback.lightImpact();
          setState(() => _sortData('NFL', asc));
        },
      ),
      ..._customColumns.map((col) => DataColumn(
            label: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(col.title),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _onRemoveCustomColumn(_customColumns.indexOf(col)),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            onSort: (i, asc) {
              HapticFeedback.lightImpact();
              setState(() => _sortData(col.title, asc));
            },
          )),
    ];
  }

  List<DataRow> _getModernRows() {
    return _visibleRankings.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      
      return DataRow(
        color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return ThemeConfig.gold.withOpacity(0.1);
          }
          return index.isEven 
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : null;
        }),
        cells: [
          // Rank cell with badge
          DataCell(
            AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 10.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ThemeConfig.gold,
                        ThemeConfig.gold.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${player.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Player name cell
          DataCell(
            AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 10.0,
                child: Text(
                  player.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.darkNavy,
                  ),
                ),
              ),
            ),
          ),
          
          // Position cell with colored badge
          DataCell(
            AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 10.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getPositionColor(player.position).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getPositionColor(player.position),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    player.position,
                    style: TextStyle(
                      color: _getPositionColor(player.position),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Team cell with logo
          DataCell(
            AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 10.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (player.team.isNotEmpty) ...[
                      TeamLogoUtils.buildNFLTeamLogo(player.team, size: 16),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      player.team,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Ranking cells
          DataCell(_buildRankingCell(player.additionalRanks['Bye'], index)),
          DataCell(_buildRankingCell(player.additionalRanks['PFF'], index)),
          DataCell(_buildRankingCell(player.additionalRanks['CBS'], index)),
          DataCell(_buildRankingCell(player.additionalRanks['ESPN'], index)),
          DataCell(_buildRankingCell(player.additionalRanks['FFToday'], index)),
          DataCell(_buildRankingCell(player.additionalRanks['FootballGuys'], index)),
          DataCell(_buildRankingCell(player.additionalRanks['Yahoo'], index)),
          DataCell(_buildRankingCell(player.additionalRanks['NFL'], index)),
          
          // Custom columns
          ..._customColumns.map((col) {
            final value = col.values[player.id];
            return DataCell(
              GestureDetector(
                onTap: () => _editCustomRank(context, player.id, value, _customColumns.indexOf(col)),
                child: AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 10.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ThemeConfig.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ThemeConfig.gold.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        value?.toString() ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ThemeConfig.darkNavy,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }).toList();
  }

  Widget _buildRankingCell(dynamic value, int index) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 10.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: value != null 
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value?.toString() ?? '-',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: value != null 
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
} 