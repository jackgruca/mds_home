import 'package:flutter/material.dart';
import '../../models/player_info.dart';
import '../../models/player_game_log.dart';
import '../../models/player_career_stats.dart';
import '../../models/player_weekly_epa.dart';
import '../../models/player_season_epa_summary.dart';
import '../../services/player_data_service.dart';
import '../../utils/constants.dart';

class PlayerDetailScreen extends StatefulWidget {
  final PlayerInfo player;

  const PlayerDetailScreen({
    super.key,
    required this.player,
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final PlayerDataService _playerService = PlayerDataService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  Future<void> _loadData() async {
    await _playerService.loadCareerStats();
    await _playerService.loadGameLogs();
    await _playerService.loadWeeklyEpaStats();
    await _playerService.loadSeasonEpaSummary();
    await _playerService.loadWeeklyNgsStats();
    if (mounted) setState(() {});
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Modern header with team color gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _getTeamPrimaryColor(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getTeamPrimaryColor(),
                      _getTeamPrimaryColor().withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40), // Space for back button
                        // Player name and details row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side - Name, team, position
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.player.displayNameOrFullName,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (widget.player.jerseyNumber != null) ...[
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '#${widget.player.jerseyNumber}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Team and position
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          widget.player.team,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.player.position,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Right side - Player details list
                            Container(
                              padding: const EdgeInsets.only(left: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.player.height != null && widget.player.weight != null)
                                    _buildDetailRow('HT/WT', '${widget.player.height}", ${widget.player.weight} lbs'),
                                  if (widget.player.yearsExp != null)
                                    _buildDetailRow('Experience', '${widget.player.yearsExp} years'),
                                  if (widget.player.college != null)
                                    _buildDetailRow('College', widget.player.college!),
                                  if (widget.player.status != null)
                                    _buildDetailRow('Status', widget.player.status!),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Career Stats'),
                    Tab(text: 'Advanced'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildCareerStatsTab(),
            _buildAdvancedTab(),
          ],
        ),
      ),
    );
  }
  
  Color _getTeamPrimaryColor() {
    final teamColors = NFLTeamColors.getTeamColors(widget.player.team);
    return teamColors.isNotEmpty ? teamColors[0] : Theme.of(context).primaryColor;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Stats section with clean background
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2024 SEASON',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCleanStatsGrid(),
                ],
              ),
            ),
            
            const SizedBox(height: 1),
            
            // Career Summary Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAREER SUMMARY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildModernCareerTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCleanStatsGrid() {
    final stats = _getSeasonStatsForPosition();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 768;
        final crossAxisCount = isDesktop ? 4 : 3;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isDesktop ? 48 : 24,
            mainAxisSpacing: 20,
            childAspectRatio: isDesktop ? 2.5 : 2.0,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return _buildCleanStatItem(stats[index]);
          },
        );
      },
    );
  }

  Widget _buildCleanStatItem(Map<String, dynamic> stat) {
    final bool hasRank = stat['rank'] != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Label
        Text(
          stat['label'].toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        // Value with rank
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              stat['value'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.0,
              ),
            ),
            if (hasRank) ...[
              const SizedBox(width: 6),
              Text(
                '#${stat['rank']}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _getRankColor(stat['rank']),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getSeasonStatsForPosition() {
    List<Map<String, dynamic>> stats = [];
    
    if (widget.player.isQuarterback) {
      stats = [
        {
          'label': 'Pass Yards',
          'value': widget.player.passingYards.toString(),
          'rank': 8,
        },
        {
          'label': 'Pass TDs',
          'value': widget.player.passingTds.toString(),
          'rank': 10,
        },
        {
          'label': 'Completion %',
          'value': widget.player.attempts > 0 
            ? '${((widget.player.completions / widget.player.attempts) * 100).toStringAsFixed(1)}%'
            : '0%',
          'rank': 12,
        },
        {
          'label': 'Interceptions',
          'value': widget.player.interceptions.toString(),
          'rank': 12,
        },
        {
          'label': 'Rush Yards',
          'value': widget.player.rushingYards.toString(),
          'rank': 15,
        },
        {
          'label': 'Rush TDs',
          'value': widget.player.rushingTds.toString(),
          'rank': 18,
        },
        {
          'label': 'Fantasy PPG',
          'value': widget.player.fantasyPpg.toStringAsFixed(1),
          'rank': 5,
        },
        {
          'label': 'Games',
          'value': widget.player.games.toString(),
        },
      ];
    } else if (widget.player.isRunningBack) {
      stats = [
        {
          'label': 'Rush Yards',
          'value': widget.player.rushingYards.toString(),
          'rank': 5,
        },
        {
          'label': 'Rush TDs',
          'value': widget.player.rushingTds.toString(),
          'rank': 8,
        },
        {
          'label': 'YPC',
          'value': widget.player.carries > 0 
            ? (widget.player.rushingYards / widget.player.carries).toStringAsFixed(1)
            : '0.0',
          'rank': 10,
        },
        {
          'label': 'Receptions',
          'value': widget.player.receptions.toString(),
          'rank': 10,
        },
        {
          'label': 'Rec Yards',
          'value': widget.player.receivingYards.toString(),
          'rank': 12,
        },
        {
          'label': 'Rec TDs',
          'value': widget.player.receivingTds.toString(),
          'rank': 15,
        },
        {
          'label': 'Fantasy PPG',
          'value': widget.player.fantasyPpg.toStringAsFixed(1),
          'rank': 5,
        },
        {
          'label': 'Games',
          'value': widget.player.games.toString(),
        },
      ];
    } else if (widget.player.isWideReceiver || widget.player.isTightEnd) {
      stats = [
        {
          'label': 'Receptions',
          'value': widget.player.receptions.toString(),
          'rank': 5,
        },
        {
          'label': 'Rec Yards',
          'value': widget.player.receivingYards.toString(),
          'rank': 8,
        },
        {
          'label': 'Rec TDs',
          'value': widget.player.receivingTds.toString(),
          'rank': 10,
        },
        {
          'label': 'Targets',
          'value': widget.player.targets.toString(),
          'rank': 6,
        },
        {
          'label': 'Catch %',
          'value': widget.player.targets > 0 
            ? '${((widget.player.receptions / widget.player.targets) * 100).toStringAsFixed(1)}%'
            : '0%',
          'rank': 15,
        },
        {
          'label': 'YPR',
          'value': widget.player.receptions > 0 
            ? (widget.player.receivingYards / widget.player.receptions).toStringAsFixed(1)
            : '0.0',
          'rank': 12,
        },
        {
          'label': 'Fantasy PPG',
          'value': widget.player.fantasyPpg.toStringAsFixed(1),
          'rank': 5,
        },
        {
          'label': 'Games',
          'value': widget.player.games.toString(),
        },
      ];
    }
    
    return stats;
  }

  Widget _buildModernCareerTable() {
    final careerStats = _playerService.getPlayerCareerStats(widget.player.playerId);
    
    // Calculate career totals
    int careerGames = 0;
    int careerPassYards = 0, careerPassTds = 0, careerInts = 0;
    int careerRushYards = 0, careerRushTds = 0;
    int careerReceptions = 0, careerRecYards = 0, careerRecTds = 0;
    
    for (var season in careerStats) {
      careerGames += season.games;
      careerPassYards += season.passingYards;
      careerPassTds += season.passingTds;
      careerInts += season.interceptions;
      careerRushYards += season.rushingYards;
      careerRushTds += season.rushingTds;
      careerReceptions += season.receptions;
      careerRecYards += season.receivingYards;
      careerRecTds += season.receivingTds;
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
            dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.hovered)) {
                return Colors.grey.shade50;
              }
              return null;
            }),
            columnSpacing: 24,
            horizontalMargin: 20,
            dataRowMaxHeight: 48,
            dataRowMinHeight: 48,
            headingRowHeight: 44,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            columns: _buildModernTableColumns(),
            rows: [
              // 2024 Season row
              _buildModernTableRow(
                '2024',
                widget.player.games,
                widget.player.passingYards,
                widget.player.passingTds,
                widget.player.interceptions,
                widget.player.rushingYards,
                widget.player.rushingTds,
                widget.player.receptions,
                widget.player.receivingYards,
                widget.player.receivingTds,
                false,
              ),
              // Career row
              _buildModernTableRow(
                'Career',
                careerGames,
                careerPassYards,
                careerPassTds,
                careerInts,
                careerRushYards,
                careerRushTds,
                careerReceptions,
                careerRecYards,
                careerRecTds,
                true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildModernTableColumns() {
    List<DataColumn> columns = [
      DataColumn(label: Text('', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
      DataColumn(label: Text('G', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
    ];
    
    // Add position-specific columns
    if (widget.player.isQuarterback) {
      columns.addAll([
        DataColumn(label: Text('PASS YDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('PASS TD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('INT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('RUSH YDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('RUSH TD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
      ]);
    } else if (widget.player.isRunningBack) {
      columns.addAll([
        DataColumn(label: Text('RUSH YDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('RUSH TD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('REC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('REC YDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('REC TD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
      ]);
    } else if (widget.player.isWideReceiver || widget.player.isTightEnd) {
      columns.addAll([
        DataColumn(label: Text('REC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('REC YDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('REC TD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('RUSH YDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
        DataColumn(label: Text('RUSH TD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))),
      ]);
    }
    
    // Add Fantasy column
    columns.add(DataColumn(label: Text('FANTASY PPG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]))));
    
    return columns;
  }

  DataRow _buildModernTableRow(
    String label,
    int games,
    int stat1,
    int stat2,
    int stat3,
    int stat4,
    int stat5,
    int stat6,
    int stat7,
    int stat8,
    bool isCareerRow,
  ) {
    final textStyle = TextStyle(
      fontSize: 13,
      fontWeight: isCareerRow ? FontWeight.w600 : FontWeight.normal,
      color: isCareerRow ? Colors.grey[900] : Colors.grey[800],
    );
    
    List<DataCell> cells = [
      DataCell(Text(label, style: textStyle.copyWith(fontWeight: FontWeight.w600))),
      DataCell(Text(games.toString(), style: textStyle)),
    ];
    
    // Add position-specific cells
    if (widget.player.isQuarterback) {
      cells.addAll([
        DataCell(Text(_formatNumber(stat1), style: textStyle)), // Pass Yds
        DataCell(Text(stat2.toString(), style: textStyle)), // Pass TD
        DataCell(Text(stat3.toString(), style: textStyle)), // INT
        DataCell(Text(_formatNumber(stat4), style: textStyle)), // Rush Yds
        DataCell(Text(stat5.toString(), style: textStyle)), // Rush TD
      ]);
    } else if (widget.player.isRunningBack) {
      cells.addAll([
        DataCell(Text(_formatNumber(stat4), style: textStyle)), // Rush Yds
        DataCell(Text(stat5.toString(), style: textStyle)), // Rush TD
        DataCell(Text(stat6.toString(), style: textStyle)), // Rec
        DataCell(Text(_formatNumber(stat7), style: textStyle)), // Rec Yds
        DataCell(Text(stat8.toString(), style: textStyle)), // Rec TD
      ]);
    } else if (widget.player.isWideReceiver || widget.player.isTightEnd) {
      cells.addAll([
        DataCell(Text(stat6.toString(), style: textStyle)), // Rec
        DataCell(Text(_formatNumber(stat7), style: textStyle)), // Rec Yds
        DataCell(Text(stat8.toString(), style: textStyle)), // Rec TD
        DataCell(Text(_formatNumber(stat4), style: textStyle)), // Rush Yds
        DataCell(Text(stat5.toString(), style: textStyle)), // Rush TD
      ]);
    }
    
    // Add Fantasy PPG
    double fantasyPpg = isCareerRow && games > 0 
      ? _calculateCareerFantasyPpg() / games
      : widget.player.fantasyPpg;
    cells.add(DataCell(Text(fantasyPpg.toStringAsFixed(1), style: textStyle)));
    
    return DataRow(cells: cells);
  }
  
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
  
  double _calculateCareerFantasyPpg() {
    final careerStats = _playerService.getPlayerCareerStats(widget.player.playerId);
    double totalFantasyPoints = 0;
    for (var season in careerStats) {
      totalFantasyPoints += season.fantasyPpg * season.games;
    }
    return totalFantasyPoints;
  }


  Widget _buildCareerStatsTab() {
    return FutureBuilder(
      future: Future.wait([
        _playerService.loadCareerStats(),
        _playerService.loadGameLogs(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final careerStats = _playerService.getPlayerCareerStats(widget.player.playerId);
        
        if (careerStats.isEmpty) {
          return const Center(
            child: Text('No career statistics available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: careerStats.length,
          itemBuilder: (context, index) {
            final seasonStats = careerStats[index];
            final seasonGameLogs = _playerService.getPlayerGameLogs(widget.player.playerId)
                .where((log) => log.season == seasonStats.season)
                .toList();
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(16),
                  childrenPadding: EdgeInsets.zero,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${seasonStats.season} Season',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${seasonStats.games} games',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildSeasonSummaryRow(seasonStats),
                  ),
                  children: [
                    if (seasonGameLogs.isNotEmpty) ...[
                      const Divider(),
                      _buildGameLogsTable(seasonGameLogs),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSeasonSummaryRow(PlayerCareerStats seasonStats) {
    List<String> summaryStats = [];
    
    if (seasonStats.isQuarterback && seasonStats.passingYards > 0) {
      summaryStats.add('${seasonStats.passingYards} pass yds');
      summaryStats.add('${seasonStats.passingTds} TDs');
    }
    if (seasonStats.rushingYards > 0) {
      summaryStats.add('${seasonStats.rushingYards} rush yds');
    }
    if (seasonStats.receivingYards > 0) {
      summaryStats.add('${seasonStats.receivingYards} rec yds');
    }
    summaryStats.add('${seasonStats.fantasyPpg.toStringAsFixed(1)} PPG');
    
    return Text(
      summaryStats.join(' • '),
      style: const TextStyle(
        fontSize: 13,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildGameLogsTable(List<PlayerGameLog> gameLogs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 36,
        columns: _buildTableColumns(),
        rows: gameLogs.map((gameLog) => _buildTableRow(gameLog)).toList(),
      ),
    );
  }

  List<DataColumn> _buildTableColumns() {
    List<DataColumn> columns = [
      const DataColumn(label: Text('Week', style: TextStyle(fontWeight: FontWeight.bold))),
      const DataColumn(label: Text('Opp', style: TextStyle(fontWeight: FontWeight.bold))),
    ];
    
    // Add position-specific columns
    if (widget.player.isQuarterback) {
      columns.addAll([
        const DataColumn(label: Text('C/A', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Pass Yds', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Pass TD', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('INT', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Rush Yds', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Rush TD', style: TextStyle(fontWeight: FontWeight.bold))),
      ]);
    } else if (widget.player.isRunningBack) {
      columns.addAll([
        const DataColumn(label: Text('Carries', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Rush Yds', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Rush TD', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Rec', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Rec Yds', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Rec TD', style: TextStyle(fontWeight: FontWeight.bold))),
      ]);
    } else if (widget.player.isWideReceiver || widget.player.isTightEnd) {
      columns.addAll([
        const DataColumn(label: Text('Rec', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Targets', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Rec Yds', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('Rec TD', style: TextStyle(fontWeight: FontWeight.bold))),
        const DataColumn(label: Text('YPR', style: TextStyle(fontWeight: FontWeight.bold))),
      ]);
    }
    
    // Fantasy points column
    columns.add(const DataColumn(label: Text('Fantasy', style: TextStyle(fontWeight: FontWeight.bold))));
    
    return columns;
  }

  DataRow _buildTableRow(PlayerGameLog gameLog) {
    List<DataCell> cells = [
      DataCell(Text(gameLog.week.toString())),
      DataCell(Text(gameLog.opponentTeam)),
    ];
    
    // Add position-specific cells
    if (widget.player.isQuarterback) {
      cells.addAll([
        DataCell(Text('${gameLog.completions}/${gameLog.attempts}')),
        DataCell(Text(gameLog.passingYards.toString())),
        DataCell(Text(gameLog.passingTds.toString())),
        DataCell(Text(gameLog.interceptions.toString())),
        DataCell(Text(gameLog.rushingYards.toString())),
        DataCell(Text(gameLog.rushingTds.toString())),
      ]);
    } else if (widget.player.isRunningBack) {
      cells.addAll([
        DataCell(Text(gameLog.carries.toString())),
        DataCell(Text(gameLog.rushingYards.toString())),
        DataCell(Text(gameLog.rushingTds.toString())),
        DataCell(Text(gameLog.receptions.toString())),
        DataCell(Text(gameLog.receivingYards.toString())),
        DataCell(Text(gameLog.receivingTds.toString())),
      ]);
    } else if (widget.player.isWideReceiver || widget.player.isTightEnd) {
      cells.addAll([
        DataCell(Text(gameLog.receptions.toString())),
        DataCell(Text(gameLog.targets.toString())),
        DataCell(Text(gameLog.receivingYards.toString())),
        DataCell(Text(gameLog.receivingTds.toString())),
        DataCell(Text(
          gameLog.receptions > 0 
            ? (gameLog.receivingYards / gameLog.receptions).toStringAsFixed(1)
            : '0.0'
        )),
      ]);
    }
    
    // Fantasy points cell with color
    cells.add(DataCell(
      Text(
        gameLog.fantasyPointsPpr.toStringAsFixed(1),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _getFantasyPointsColor(gameLog.fantasyPointsPpr),
        ),
      ),
    ));
    
    return DataRow(cells: cells);
  }

  Widget _buildAdvancedTab() {
    final seasonEpaSummaries = _playerService.getPlayerSeasonEpaSummary(widget.player.playerId);
    
    if (seasonEpaSummaries.isEmpty) {
      // Fallback to original Advanced tab
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Expected Points Added (EPA)'),
            const SizedBox(height: 16),
            _buildEpaOverview(),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('EPA Breakdown by Play Type'),
            const SizedBox(height: 16),
            _buildEpaBreakdown(),
            
            const SizedBox(height: 32),
            
            _buildSectionTitle('Efficiency Metrics'),
            const SizedBox(height: 16),
            _buildEfficiencyMetrics(),
          ],
        ),
      );
    }

    // Show expandable advanced stats
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: seasonEpaSummaries.length,
      itemBuilder: (context, index) {
        final seasonSummary = seasonEpaSummaries[index];
        final weeklyEpaData = _playerService.getPlayerWeeklyEpaForSeason(widget.player.playerId, seasonSummary.season);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              childrenPadding: EdgeInsets.zero,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${seasonSummary.season} Advanced Stats',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${seasonSummary.games} games',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildAdvancedSeasonSummary(seasonSummary),
              ),
              children: [
                if (weeklyEpaData.isNotEmpty) ...[
                  const Divider(),
                  _buildWeeklyEpaTable(weeklyEpaData),
                ] else ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No weekly advanced stats available', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEpaOverview() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildEpaCard(
                    'Total EPA',
                    widget.player.totalEpa.toStringAsFixed(1),
                    _getEpaColor(widget.player.totalEpa),
                    'Combined EPA across all play types',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'EPA measures the value a player adds above expectation on each play. Positive EPA indicates above-average performance.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpaBreakdown() {
    final breakdownItems = <Widget>[];
    
    // Passing EPA (for QBs)
    if (widget.player.isQuarterback && widget.player.passingPlays > 0) {
      breakdownItems.add(_buildEpaBreakdownCard(
        'Passing EPA',
        widget.player.passingEpaTotal,
        widget.player.passingEpaPerPlay,
        widget.player.passingPlays,
        Icons.sports_football,
        Colors.blue,
      ));
    }
    
    // Rushing EPA
    if (widget.player.rushingPlays > 0) {
      breakdownItems.add(_buildEpaBreakdownCard(
        'Rushing EPA',
        widget.player.rushingEpaTotal,
        widget.player.rushingEpaPerPlay,
        widget.player.rushingPlays,
        Icons.directions_run,
        Colors.green,
      ));
    }
    
    // Receiving EPA
    if (widget.player.receivingPlays > 0) {
      breakdownItems.add(_buildEpaBreakdownCard(
        'Receiving EPA',
        widget.player.receivingEpaTotal,
        widget.player.receivingEpaPerPlay,
        widget.player.receivingPlays,
        Icons.catching_pokemon,
        Colors.orange,
      ));
    }
    
    if (breakdownItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No EPA data available for this player',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }
    
    return Column(children: breakdownItems);
  }

  Widget _buildEpaBreakdownCard(
    String title,
    double totalEpa,
    double epaPerPlay,
    int plays,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$plays plays',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalEpa.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getEpaColor(totalEpa),
                  ),
                ),
                Text(
                  '${epaPerPlay.toStringAsFixed(3)} per play',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyMetrics() {
    final metrics = <Widget>[];
    
    // Add efficiency calculations based on position
    if (widget.player.isQuarterback && widget.player.attempts > 0) {
      final completionRate = (widget.player.completions / widget.player.attempts) * 100;
      final epaPerAttempt = widget.player.passingPlays > 0 
        ? widget.player.passingEpaTotal / widget.player.attempts 
        : 0.0;
      
      metrics.addAll([
        _buildEfficiencyCard('Completion Rate', '${completionRate.toStringAsFixed(1)}%'),
        _buildEfficiencyCard('EPA per Attempt', epaPerAttempt.toStringAsFixed(3)),
      ]);
    }
    
    if (widget.player.carries > 0) {
      final ypc = widget.player.rushingYards / widget.player.carries;
      final epaPerCarry = widget.player.rushingPlays > 0 
        ? widget.player.rushingEpaTotal / widget.player.carries 
        : 0.0;
      
      metrics.addAll([
        _buildEfficiencyCard('Yards per Carry', ypc.toStringAsFixed(1)),
        _buildEfficiencyCard('EPA per Carry', epaPerCarry.toStringAsFixed(3)),
      ]);
    }
    
    if (widget.player.targets > 0) {
      final catchRate = (widget.player.receptions / widget.player.targets) * 100;
      final epaPerTarget = widget.player.receivingPlays > 0 
        ? widget.player.receivingEpaTotal / widget.player.targets 
        : 0.0;
      
      metrics.addAll([
        _buildEfficiencyCard('Catch Rate', '${catchRate.toStringAsFixed(1)}%'),
        _buildEfficiencyCard('EPA per Target', epaPerTarget.toStringAsFixed(3)),
      ]);
    }
    
    if (metrics.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No efficiency metrics available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: metrics,
        ),
      ),
    );
  }

  Widget _buildEpaCard(String title, String value, Color color, String description) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEfficiencyCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getEpaColor(double epa) {
    if (epa > 10) return Colors.green.shade700;
    if (epa > 0) return Colors.green;
    if (epa > -10) return Colors.orange;
    return Colors.red;
  }

  Color _getRankColor(int rank) {
    if (rank <= 5) return Colors.green;
    if (rank <= 10) return Colors.orange;
    if (rank <= 20) return Colors.blue;
    return Colors.grey;
  }

  Color _getFantasyPointsColor(double points) {
    if (points >= 20) return Colors.green;
    if (points >= 15) return Colors.orange;
    if (points >= 10) return Colors.blue;
    return Colors.grey;
  }


  Widget _buildAdvancedSeasonSummary(PlayerSeasonEpaSummary seasonSummary) {
    List<String> summaryStats = [];
    
    if (seasonSummary.hasPassingStats) {
      summaryStats.add('${seasonSummary.passingEpaTotal.toStringAsFixed(1)} Pass EPA');
    }
    if (seasonSummary.hasRushingStats) {
      summaryStats.add('${seasonSummary.rushingEpaTotal.toStringAsFixed(1)} Rush EPA');  
    }
    if (seasonSummary.hasReceivingStats) {
      summaryStats.add('${seasonSummary.receivingEpaTotal.toStringAsFixed(1)} Rec EPA');
    }
    summaryStats.add('${seasonSummary.totalEpa.toStringAsFixed(1)} Total EPA');
    
    return Text(
      summaryStats.join(' • '),
      style: const TextStyle(
        fontSize: 13,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildWeeklyEpaTable(List<PlayerWeeklyEpa> weeklyData) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 40,
        headingRowHeight: 36,
        columns: const [
          DataColumn(label: Text('Week', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Matchup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Plays', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Total EPA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('EPA/Play', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Traditional Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('NGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: weeklyData.map((weekData) => _buildWeeklyEpaRowWithNgs(weekData)).toList(),
      ),
    );
  }

  DataRow _buildWeeklyEpaRowWithNgs(PlayerWeeklyEpa weekData) {
    // Build traditional stats string based on player position and available data
    String statsString = '';
    List<String> statParts = [];
    
    // Add passing stats if available
    if (weekData.hasPassingStats) {
      statParts.add('${weekData.completions}/${weekData.attempts}, ${weekData.passingYards} yds, ${weekData.passingTds} TD');
    }
    
    // Add rushing stats if available  
    if (weekData.hasRushingStats) {
      statParts.add('${weekData.carries} att, ${weekData.rushingYards} yds, ${weekData.rushingTds} TD');
    }
    
    // Add receiving stats if available
    if (weekData.hasReceivingStats) {
      statParts.add('${weekData.receptions}/${weekData.targets}, ${weekData.receivingYards} yds, ${weekData.receivingTds} TD');
    }
    
    statsString = statParts.join(' | ');

    // Get position-appropriate NGS data
    String ngsString = _buildNgsString(weekData);

    return DataRow(cells: [
      DataCell(Text(weekData.week.toString(), style: const TextStyle(fontSize: 12))),
      DataCell(Text(weekData.matchupDisplay, style: const TextStyle(fontSize: 12))),
      DataCell(Text(weekData.totalPlays.toString(), style: const TextStyle(fontSize: 12))),
      DataCell(Text(
        weekData.totalEpa.toStringAsFixed(1), 
        style: TextStyle(
          fontSize: 12, 
          color: _getEpaColor(weekData.totalEpa),
          fontWeight: FontWeight.bold,
        ),
      )),
      DataCell(Text(
        weekData.epaPerPlay.toStringAsFixed(2), 
        style: TextStyle(
          fontSize: 12, 
          color: _getEpaColor(weekData.epaPerPlay),
        ),
      )),
      DataCell(Text(statsString, style: const TextStyle(fontSize: 11))),
      DataCell(Text(ngsString, style: const TextStyle(fontSize: 11))),
    ]);
  }

  String _buildNgsString(PlayerWeeklyEpa weekData) {
    // Get NGS data for this week - filtering by position as requested
    final playerPos = widget.player.positionGroup;
    final allNgsForPlayer = _playerService.getPlayerWeeklyNgsForSeason(weekData.playerId, weekData.season);
    final ngsData = allNgsForPlayer.where((ngs) => ngs.week == weekData.week && ngs.week > 0); // Exclude Week 0 (season totals)
    
    // Filter NGS by position: QB->check for rushing, RB->rushing, WR/TE->receiving
    List<String> ngsParts = [];
    
    switch (playerPos) {
      case 'QB':
        // For QBs, prioritize passing NGS data, fall back to rushing NGS for mobile QBs
        final passingNgs = ngsData.where((ngs) => ngs.statType == 'passing').toList();
        if (passingNgs.isNotEmpty) {
          final ngs = passingNgs.first;
          if (ngs.completionPercentageAboveExpectation != null) {
            ngsParts.add('${ngs.completionPercentageAboveExpectation! > 0 ? '+' : ''}${ngs.completionPercentageAboveExpectation!.toStringAsFixed(1)}% CPOE');
          }
          if (ngs.avgTimeToThrow != null) {
            ngsParts.add('${ngs.avgTimeToThrow!.toStringAsFixed(2)}s TTT');
          }
        } else {
          // Fall back to rushing NGS for mobile QBs
          final rushingNgs = ngsData.where((ngs) => ngs.statType == 'rushing').toList();
          if (rushingNgs.isNotEmpty) {
            final ngs = rushingNgs.first;
            if (ngs.rushYardsOverExpected != null) {
              ngsParts.add('${ngs.rushYardsOverExpected! > 0 ? '+' : ''}${ngs.rushYardsOverExpected!.toStringAsFixed(1)} RYOE');
            }
            if (ngs.efficiency != null) {
              ngsParts.add('${(ngs.efficiency! * 100).toStringAsFixed(1)}% Eff');
            }
          }
        }
        break;
      case 'RB':
        final rushingNgs = ngsData.where((ngs) => ngs.statType == 'rushing').toList();
        if (rushingNgs.isNotEmpty) {
          final ngs = rushingNgs.first;
          if (ngs.rushYardsOverExpected != null) {
            ngsParts.add('${ngs.rushYardsOverExpected! > 0 ? '+' : ''}${ngs.rushYardsOverExpected!.toStringAsFixed(1)} RYOE');
          }
          if (ngs.efficiency != null) {
            ngsParts.add('${(ngs.efficiency! * 100).toStringAsFixed(1)}% Eff');
          }
        }
        break;
      case 'WR':
      case 'TE':
        final receivingNgs = ngsData.where((ngs) => ngs.statType == 'receiving').toList();
        if (receivingNgs.isNotEmpty) {
          final ngs = receivingNgs.first;
          if (ngs.avgYacAboveExpectation != null) {
            ngsParts.add('${ngs.avgYacAboveExpectation! > 0 ? '+' : ''}${ngs.avgYacAboveExpectation!.toStringAsFixed(1)} YAC+/-');
          }
          if (ngs.avgSeparation != null) {
            ngsParts.add('${ngs.avgSeparation!.toStringAsFixed(1)} Sep');
          }
        }
        break;
      default:
        return 'No NGS';
    }
    
    if (ngsParts.isNotEmpty) {
      return ngsParts.join(' | ');
    } else {
      // No NGS data available for this player/week/position combination
      return playerPos == 'QB' ? 'No QB NGS' : 'No NGS';
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverTabBarDelegate(this.child);

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

