import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mds_home/utils/team_logo_utils.dart';

import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../utils/theme_config.dart';
import '../../utils/seo_helper.dart';
import '../../widgets/design_system/mds_table.dart';
import '../../services/player_trends_service.dart';

class PlayerTrendsScreen extends StatefulWidget {
  const PlayerTrendsScreen({super.key});

  @override
  _PlayerTrendsScreenState createState() => _PlayerTrendsScreenState();
}

class _PlayerTrendsScreenState extends State<PlayerTrendsScreen> {
  String _selectedPosition = 'WR';
  String _selectedSeason = '2024';
  List<PlayerTrend> _playerTrends = [];
  bool _isLoading = true;
  String _sortColumn = 'ppr_trend_change';
  bool _sortAscending = false;
  String _errorMessage = '';
  String _trendFilter = 'All'; // 'All', 'Up', 'Down', 'Steady'
  int _recentGamesCount = 4; // Default to last 4 games

  // Separate controllers so the header mirrors the body scroll without user interaction
  final ScrollController _headerHScrollController = ScrollController();
  final ScrollController _bodyHScrollController = ScrollController();
  final ScrollController _leftVScrollController = ScrollController();
  final ScrollController _rightVScrollController = ScrollController();
  
  final List<String> _availableSeasons = ['2024', '2023', '2022', '2021', '2020', '2019'];
  final List<String> _availablePositions = ['QB', 'RB', 'WR', 'TE'];
  final List<String> _trendFilters = ['All', 'Trending Up', 'Trending Down', 'Most Consistent'];

  @override
  void initState() {
    super.initState();
    
    // Update SEO meta tags for Player Trends page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForPlayerTrends();
    });

    // Mirror body horizontal scroll to the header so columns remain aligned
    _bodyHScrollController.addListener(() {
      final double bodyOffset = _bodyHScrollController.hasClients ? _bodyHScrollController.offset : 0.0;
      if (_headerHScrollController.hasClients && _headerHScrollController.offset != bodyOffset) {
        _headerHScrollController.jumpTo(bodyOffset);
      }
    });

    // Mirror right vertical scroll to the left frozen column
    _rightVScrollController.addListener(() {
      final double off = _rightVScrollController.hasClients ? _rightVScrollController.offset : 0.0;
      if (_leftVScrollController.hasClients && _leftVScrollController.offset != off) {
        _leftVScrollController.jumpTo(off);
      }
    });
    
    _loadPlayerTrends();
  }

  @override
  void dispose() {
    _headerHScrollController.dispose();
    _bodyHScrollController.dispose();
    _leftVScrollController.dispose();
    _rightVScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerTrends() async {
    print('DEBUG: _loadPlayerTrends called with season=$_selectedSeason, position=$_selectedPosition');
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final trends = await PlayerTrendsService.getPlayerTrends(
        season: _selectedSeason,
        position: _selectedPosition,
        minGames: _recentGamesCount + 2, // Need at least recent games + 2 for meaningful trends
        minRecentGames: _recentGamesCount,
        recentGamesCount: _recentGamesCount,
      );

      print('DEBUG: Received ${trends.length} player trends');

      setState(() {
        _playerTrends = _applyTrendFilter(trends);
        _isLoading = false;
      });
      
      if (trends.isNotEmpty) {
        print('DEBUG: First trend: ${trends.first.playerName} - Change: ${trends.first.pprTrendChange.toStringAsFixed(1)}');
      }
    } catch (e, stackTrace) {
      print('ERROR: Error in _loadPlayerTrends: $e');
      print('ERROR: Stack trace: $stackTrace');
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading player trends: ${e.toString()}';
        _playerTrends = [];
      });
    }
  }

  List<PlayerTrend> _applyTrendFilter(List<PlayerTrend> trends) {
    switch (_trendFilter) {
      case 'Trending Up':
        return PlayerTrendsService.getTrendingUp(trends, limit: 50);
      case 'Trending Down':
        return PlayerTrendsService.getTrendingDown(trends, limit: 50);
      case 'Most Consistent':
        return PlayerTrendsService.getMostConsistent(trends, limit: 50);
      default:
        return trends;
    }
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }
      
      // Sort the current trends list
      _playerTrends.sort((a, b) {
        int result = 0;
        switch (column) {
          case 'player_name':
            result = a.playerName.compareTo(b.playerName);
            break;
          case 'team':
            result = a.team.compareTo(b.team);
            break;
          case 'ppr_trend_change':
            result = a.pprTrendChange.compareTo(b.pprTrendChange);
            break;
          case 'recent_avg_ppr':
            result = a.recentAvgPPR.compareTo(b.recentAvgPPR);
            break;
          case 'season_avg_ppr':
            result = a.seasonAvgPPR.compareTo(b.seasonAvgPPR);
            break;
          case 'consistency':
            result = a.consistency.compareTo(b.consistency);
            break;
          default:
            result = a.pprTrendChange.compareTo(b.pprTrendChange);
        }
        return _sortAscending ? result : -result;
      });
    });
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(24),
              shadowColor: ThemeConfig.gold.withOpacity(0.3),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showDialog(context: context, builder: (_) => const AuthDialog());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: ThemeConfig.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Sign In / Sign Up'),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildControlsSection(),
          Expanded(child: _buildDataTable()),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      color: ThemeConfig.darkNavy,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Player Performance Trends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.gold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Season Selector
              Expanded(
                child: _buildSelector(
                  'Season',
                  _selectedSeason,
                  _availableSeasons,
                  (value) {
                    setState(() => _selectedSeason = value!);
                    _loadPlayerTrends();
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Position Selector
              Expanded(
                child: _buildSelector(
                  'Position',
                  _selectedPosition,
                  _availablePositions,
                  (value) {
                    setState(() => _selectedPosition = value!);
                    _loadPlayerTrends();
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Trend Filter
              Expanded(
                child: _buildSelector(
                  'Trend Filter',
                  _trendFilter,
                  _trendFilters,
                  (value) {
                    setState(() => _trendFilter = value!);
                    _loadPlayerTrends();
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Recent Games Slider
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Games: $_recentGamesCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: ThemeConfig.gold,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: ThemeConfig.gold,
                        overlayColor: ThemeConfig.gold.withOpacity(0.2),
                        valueIndicatorColor: ThemeConfig.gold,
                      ),
                      child: Slider(
                        value: _recentGamesCount.toDouble(),
                        min: 1,
                        max: 17,
                        divisions: 16,
                        label: _recentGamesCount.toString(),
                        onChanged: (value) {
                          setState(() {
                            _recentGamesCount = value.round();
                          });
                        },
                        onChangeEnd: (value) {
                          _loadPlayerTrends();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Refresh Button
              ElevatedButton.icon(
                onPressed: _loadPlayerTrends,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.gold,
                  foregroundColor: ThemeConfig.darkNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadPlayerTrends,
                    child: const Text('Retry', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelector(String label, String value, List<String> options, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: ThemeConfig.darkNavy,
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading player trends...'),
          ],
        ),
      );
    }

    if (_playerTrends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No player trends found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different position, season, or filter',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    final theme = Theme.of(context);
    // Fixed sizes to guarantee column alignment between header and rows
    const double playerColWidth = 260;
    const double statColWidth = 96;
    const double rowHeight = 48;

    final stats = _getPositionStats(_selectedPosition);

    Widget buildHeaderCell(String group, String label, {Color? groupColor}) {
      return SizedBox(
        width: statColWidth,
        height: rowHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              group,
              style: TextStyle(
                color: groupColor ?? ThemeConfig.gold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              _getStatDisplayName(label),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      );
    }

    Widget buildValueCell(String stat, PlayerTrend t, {required bool isRecent}) {
      if (stat == 'fantasy_points_ppr' || stat == 'yards_per_target' || stat.contains('pct') || stat.contains('%')
          || stat == 'targets' || stat == 'receptions' || stat == 'receiving_yards' || stat == 'receiving_tds'
          || stat == 'passing_yards' || stat == 'passing_tds' || stat == 'interceptions' || stat == 'carries' || stat == 'rushing_yards' || stat == 'rushing_tds') {
        final double v = isRecent ? _getRecentStatValue(t, stat) : _getSeasonStatValue(t, stat);
        return SizedBox(
          width: statColWidth,
          height: rowHeight,
          child: Center(
            child: Text(
              _formatStatValue(v, stat),
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        );
      }
      // Fallback
      final double v = isRecent ? _getRecentStatValue(t, stat) : _getSeasonStatValue(t, stat);
      return SizedBox(
        width: statColWidth,
        height: rowHeight,
        child: Center(
          child: Text(_formatStatValue(v, stat), style: theme.textTheme.bodyMedium),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
        child: Column(
          children: [
            // Sticky header: left frozen "Player" + right header row that mirrors horizontal scroll
            Container(
              color: ThemeConfig.darkNavy,
              height: rowHeight,
              child: Row(
                children: [
                  // Frozen top-left cell
                  SizedBox(
                    width: playerColWidth,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Player', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  // Scrollable header cells
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _headerHScrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Season group
                          for (final s in stats) buildHeaderCell('SEASON', s, groupColor: ThemeConfig.gold),
                          // Recent group
                          for (final s in stats) buildHeaderCell('RECENT $_recentGamesCount', s, groupColor: Colors.lightBlue),
                          // Trend group
                          for (final s in stats) buildHeaderCell('TREND', s, groupColor: Colors.orange),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body: left frozen first column + right grid that scrolls both ways
            Expanded(
              child: Row(
                children: [
                  // Frozen first column (players)
                  SizedBox(
                    width: playerColWidth,
                    child: ListView.builder(
                      controller: _leftVScrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemExtent: rowHeight,
                      itemCount: _playerTrends.length,
                      itemBuilder: (context, index) {
                        final trend = _playerTrends[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[100],
                                ),
                                child: TeamLogoUtils.buildNFLTeamLogo(trend.team.trim(), size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(trend.playerName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis),
                                    Text('${trend.team} ${trend.position}', style: TextStyle(fontSize: 10, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Scrollable grid (horizontal + vertical)
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _bodyHScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: statColWidth * stats.length * 3,
                        child: ListView.builder(
                          controller: _rightVScrollController,
                          itemExtent: rowHeight,
                          itemCount: _playerTrends.length,
                          itemBuilder: (context, index) {
                            final t = _playerTrends[index];
                            return Row(
                              children: [
                                // Season values
                                for (final s in stats) buildValueCell(s, t, isRecent: false),
                                // Recent values
                                for (final s in stats) buildValueCell(s, t, isRecent: true),
                                // Trend values
                                for (final s in stats)
                                  SizedBox(width: statColWidth, height: rowHeight, child: Center(child: _buildTrendCell(t, s))),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    List<DataColumn> columns = [
      // Player Info
      const DataColumn(
        label: Text('Player', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    ];

    // Add position-specific season columns
    List<String> seasonStats = _getPositionStats(_selectedPosition);
    for (String stat in seasonStats) {
      columns.add(DataColumn(
        label: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SEASON', style: TextStyle(color: ThemeConfig.gold, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(_getStatDisplayName(stat), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        numeric: true,
      ));
    }

    // Add position-specific recent columns
    for (String stat in seasonStats) {
      columns.add(DataColumn(
        label: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RECENT $_recentGamesCount', style: const TextStyle(color: Colors.lightBlue, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(_getStatDisplayName(stat), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        numeric: true,
      ));
    }

    // Add trend columns
    for (String stat in seasonStats) {
      columns.add(DataColumn(
        label: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TREND', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(_getStatDisplayName(stat), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ));
    }

    return columns;
  }

  List<DataRow> _buildRows() {
    return _playerTrends.map((trend) {
      List<DataCell> cells = [
        // Player info
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: TeamLogoUtils.buildNFLTeamLogo(
                  trend.team.trim(),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trend.playerName,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${trend.team} ${trend.position}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ];

      List<String> stats = _getPositionStats(_selectedPosition);
      
      // Add season stat cells
      for (String stat in stats) {
        double seasonValue = _getSeasonStatValue(trend, stat);
        cells.add(DataCell(Text(_formatStatValue(seasonValue, stat))));
      }
      
      // Add recent stat cells  
      for (String stat in stats) {
        double recentValue = _getRecentStatValue(trend, stat);
        cells.add(DataCell(Text(_formatStatValue(recentValue, stat))));
      }
      
      // Add trend cells
      for (String stat in stats) {
        cells.add(DataCell(_buildTrendCell(trend, stat)));
      }

      return DataRow(cells: cells);
    }).toList();
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '-';
    if (value is num) {
      if (value % 1 == 0) {
        return value.toInt().toString();
      } else {
        return value.toStringAsFixed(1);
      }
    }
    return value.toString();
  }

  int _getColumnIndex(String column) {
    const columns = [
      'player_name', 
      'team', 
      'recent_avg_ppr', 
      'season_avg_ppr', 
      'ppr_trend_change',
      'ppr_trend_change', // Trend and Change both map to same index for sorting
      'consistency',
      'games'
    ];
    
    int index = columns.indexOf(column);
    return index != -1 ? index : 0;
  }

  IconData _getTrendIcon(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.up:
        return Icons.trending_up;
      case TrendDirection.down:
        return Icons.trending_down;
      case TrendDirection.steady:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.up:
        return Colors.green;
      case TrendDirection.down:
        return Colors.red;
      case TrendDirection.steady:
        return Colors.grey;
    }
  }

  String _getTrendText(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.up:
        return 'Up';
      case TrendDirection.down:
        return 'Down';
      case TrendDirection.steady:
        return 'Steady';
    }
  }

  List<String> _getPositionStats(String position) {
    switch (position) {
      case 'QB':
        return ['attempts', 'completions', 'completion_pct', 'passing_yards', 'passing_tds', 'interceptions', 'fantasy_points_ppr'];
      case 'RB':
        return ['carries', 'rushing_yards', 'rushing_tds', 'targets', 'receptions', 'receiving_yards', 'fantasy_points_ppr'];
      case 'WR':
      case 'TE':
        return ['targets', 'receptions', 'catch_pct', 'receiving_yards', 'receiving_tds', 'yards_per_target', 'fantasy_points_ppr'];
      default:
        return ['fantasy_points_ppr'];
    }
  }

  String _getStatDisplayName(String stat) {
    switch (stat) {
      case 'attempts':
        return 'Att';
      case 'completions':
        return 'Comp';
      case 'completion_pct':
        return 'Comp%';
      case 'passing_yards':
        return 'Pass Yds';
      case 'passing_tds':
        return 'Pass TD';
      case 'interceptions':
        return 'INT';
      case 'carries':
        return 'Car';
      case 'rushing_yards':
        return 'Rush Yds';
      case 'rushing_tds':
        return 'Rush TD';
      case 'targets':
        return 'Tgt';
      case 'receptions':
        return 'Rec';
      case 'catch_pct':
        return 'Catch%';
      case 'receiving_yards':
        return 'Rec Yds';
      case 'receiving_tds':
        return 'Rec TD';
      case 'yards_per_target':
        return 'Y/Tgt';
      case 'fantasy_points_ppr':
        return 'PPR';
      default:
        return stat;
    }
  }

  double _getSeasonStatValue(PlayerTrend trend, String stat) {
    switch (stat) {
      case 'attempts':
        return trend.seasonPositionStats['attempts'] ?? 0.0;
      case 'completions':
        return trend.seasonPositionStats['completions'] ?? 0.0;
      case 'completion_pct':
        final attempts = trend.seasonPositionStats['attempts'] ?? 0.0;
        final completions = trend.seasonPositionStats['completions'] ?? 0.0;
        return attempts > 0 ? (completions / attempts) * 100 : 0.0;
      case 'passing_yards':
        return trend.seasonPositionStats['passing_yards'] ?? 0.0;
      case 'passing_tds':
        return trend.seasonPositionStats['passing_tds'] ?? 0.0;
      case 'interceptions':
        return trend.seasonPositionStats['interceptions'] ?? 0.0;
      case 'carries':
        return trend.seasonPositionStats['carries'] ?? 0.0;
      case 'rushing_yards':
        return trend.seasonPositionStats['rushing_yards'] ?? 0.0;
      case 'rushing_tds':
        return trend.seasonPositionStats['rushing_tds'] ?? 0.0;
      case 'targets':
        return trend.seasonPositionStats['targets'] ?? 0.0;
      case 'receptions':
        return trend.seasonPositionStats['receptions'] ?? 0.0;
      case 'catch_pct':
        final targets = trend.seasonPositionStats['targets'] ?? 0.0;
        final receptions = trend.seasonPositionStats['receptions'] ?? 0.0;
        return targets > 0 ? (receptions / targets) * 100 : 0.0;
      case 'receiving_yards':
        return trend.seasonPositionStats['receiving_yards'] ?? 0.0;
      case 'receiving_tds':
        return trend.seasonPositionStats['receiving_tds'] ?? 0.0;
      case 'yards_per_target':
        final targets = trend.seasonPositionStats['targets'] ?? 0.0;
        final yards = trend.seasonPositionStats['receiving_yards'] ?? 0.0;
        return targets > 0 ? yards / targets : 0.0;
      case 'fantasy_points_ppr':
        return trend.seasonAvgPPR;
      default:
        return 0.0;
    }
  }

  double _getRecentStatValue(PlayerTrend trend, String stat) {
    switch (stat) {
      case 'attempts':
        return trend.recentPositionStats['attempts'] ?? 0.0;
      case 'completions':
        return trend.recentPositionStats['completions'] ?? 0.0;
      case 'completion_pct':
        final attempts = trend.recentPositionStats['attempts'] ?? 0.0;
        final completions = trend.recentPositionStats['completions'] ?? 0.0;
        return attempts > 0 ? (completions / attempts) * 100 : 0.0;
      case 'passing_yards':
        return trend.recentPositionStats['passing_yards'] ?? 0.0;
      case 'passing_tds':
        return trend.recentPositionStats['passing_tds'] ?? 0.0;
      case 'interceptions':
        return trend.recentPositionStats['interceptions'] ?? 0.0;
      case 'carries':
        return trend.recentPositionStats['carries'] ?? 0.0;
      case 'rushing_yards':
        return trend.recentPositionStats['rushing_yards'] ?? 0.0;
      case 'rushing_tds':
        return trend.recentPositionStats['rushing_tds'] ?? 0.0;
      case 'targets':
        return trend.recentPositionStats['targets'] ?? 0.0;
      case 'receptions':
        return trend.recentPositionStats['receptions'] ?? 0.0;
      case 'catch_pct':
        final targets = trend.recentPositionStats['targets'] ?? 0.0;
        final receptions = trend.recentPositionStats['receptions'] ?? 0.0;
        return targets > 0 ? (receptions / targets) * 100 : 0.0;
      case 'receiving_yards':
        return trend.recentPositionStats['receiving_yards'] ?? 0.0;
      case 'receiving_tds':
        return trend.recentPositionStats['receiving_tds'] ?? 0.0;
      case 'yards_per_target':
        final targets = trend.recentPositionStats['targets'] ?? 0.0;
        final yards = trend.recentPositionStats['receiving_yards'] ?? 0.0;
        return targets > 0 ? yards / targets : 0.0;
      case 'fantasy_points_ppr':
        return trend.recentAvgPPR;
      default:
        return 0.0;
    }
  }

  String _formatStatValue(double value, String stat) {
    if (stat.contains('pct') || stat.contains('%')) {
      return '${value.toStringAsFixed(1)}%';
    } else if (stat == 'yards_per_target') {
      return value.toStringAsFixed(1);
    } else if (value % 1 == 0) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(1);
    }
  }

  Widget _buildTrendCell(PlayerTrend trend, String stat) {
    double seasonValue = _getSeasonStatValue(trend, stat);
    double recentValue = _getRecentStatValue(trend, stat);
    
    if (seasonValue == 0) return const Text('-');
    
    double changePercent = ((recentValue - seasonValue) / seasonValue) * 100;
    Color trendColor = changePercent > 5 ? Colors.green : 
                      changePercent < -5 ? Colors.red : Colors.grey;
    IconData trendIcon = changePercent > 5 ? Icons.trending_up :
                        changePercent < -5 ? Icons.trending_down : Icons.trending_flat;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(trendIcon, size: 14, color: trendColor),
        const SizedBox(width: 2),
        Text(
          '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
          style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}