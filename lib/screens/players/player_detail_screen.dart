import 'package:flutter/material.dart';
import '../../models/player_info.dart';
import '../../services/player_data_service.dart';

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
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ESPN-style banner header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getPositionColor(widget.player.positionGroup),
                      _getPositionColor(widget.player.positionGroup).withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        // Player name and team
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.player.displayNameOrFullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          widget.player.team,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${widget.player.position} ${widget.player.jerseyNumber != null ? "#${widget.player.jerseyNumber}" : ""}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Player avatar/position badge
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.player.position,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (widget.player.jerseyNumber != null)
                                    Text(
                                      '#${widget.player.jerseyNumber}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Quick stats row
                        Row(
                          children: [
                            _buildQuickStat('PPG', widget.player.fantasyPpg.toStringAsFixed(1)),
                            const SizedBox(width: 24),
                            _buildQuickStat('Games', widget.player.games.toString()),
                            const SizedBox(width: 24),
                            if (widget.player.college != null)
                              _buildQuickStat('College', widget.player.college!),
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
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Stats'),
                  Tab(text: 'Bio'),
                  Tab(text: 'Similar'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildStatsTab(),
            _buildBioTab(),
            _buildSimilarPlayersTab(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key stats card
          _buildStatsCard(
            '2024 Season Stats',
            [
              _buildStatRow('Games', widget.player.games.toString()),
              _buildStatRow('Fantasy PPG', widget.player.fantasyPpg.toStringAsFixed(1)),
              _buildStatRow('Total Fantasy Points', widget.player.fantasyPointsPpr.toStringAsFixed(1)),
              _buildStatRow('Total TDs', widget.player.totalTds.toString()),
            ],
          ),
          const SizedBox(height: 16),
          
          // Position-specific stats
          if (widget.player.isQuarterback && widget.player.attempts > 0)
            _buildStatsCard(
              'Passing Stats',
              [
                _buildStatRow('Completions/Attempts', '${widget.player.completions}/${widget.player.attempts}'),
                _buildStatRow('Passing Yards', '${widget.player.passingYards} (${widget.player.passYpg.toStringAsFixed(1)}/game)'),
                _buildStatRow('Passing TDs', widget.player.passingTds.toString()),
                _buildStatRow('Interceptions', widget.player.interceptions.toString()),
                if (widget.player.attempts > 0)
                  _buildStatRow('Completion %', '${((widget.player.completions / widget.player.attempts) * 100).toStringAsFixed(1)}%'),
              ],
            ),
          
          if ((widget.player.isQuarterback || widget.player.isRunningBack) && widget.player.carries > 0)
            _buildStatsCard(
              'Rushing Stats',
              [
                _buildStatRow('Carries', widget.player.carries.toString()),
                _buildStatRow('Rushing Yards', '${widget.player.rushingYards} (${widget.player.rushYpg.toStringAsFixed(1)}/game)'),
                _buildStatRow('Rushing TDs', widget.player.rushingTds.toString()),
                if (widget.player.carries > 0)
                  _buildStatRow('Yards/Carry', (widget.player.rushingYards / widget.player.carries).toStringAsFixed(1)),
              ],
            ),
          
          if ((widget.player.isRunningBack || widget.player.isWideReceiver || widget.player.isTightEnd) && widget.player.targets > 0)
            _buildStatsCard(
              'Receiving Stats',
              [
                _buildStatRow('Receptions/Targets', '${widget.player.receptions}/${widget.player.targets}'),
                _buildStatRow('Receiving Yards', '${widget.player.receivingYards} (${widget.player.recYpg.toStringAsFixed(1)}/game)'),
                _buildStatRow('Receiving TDs', widget.player.receivingTds.toString()),
                if (widget.player.targets > 0)
                  _buildStatRow('Catch %', '${((widget.player.receptions / widget.player.targets) * 100).toStringAsFixed(1)}%'),
                if (widget.player.receptions > 0)
                  _buildStatRow('Yards/Reception', (widget.player.receivingYards / widget.player.receptions).toStringAsFixed(1)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return const Center(child: Text('Stats tab - Coming soon'));
  }

  Widget _buildBioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.player.height != null || widget.player.weight != null || widget.player.yearsExp != null)
            _buildStatsCard(
              'Physical Info',
              [
                if (widget.player.height != null)
                  _buildStatRow('Height', '${widget.player.height}"'),
                if (widget.player.weight != null)
                  _buildStatRow('Weight', '${widget.player.weight} lbs'),
                if (widget.player.yearsExp != null)
                  _buildStatRow('Experience', '${widget.player.yearsExp} years'),
                if (widget.player.college != null)
                  _buildStatRow('College', widget.player.college!),
                if (widget.player.status != null)
                  _buildStatRow('Status', widget.player.status!),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSimilarPlayersTab() {
    final similarPlayers = _playerService.getPlayersByPosition(widget.player.position)
        .where((p) => p.playerId != widget.player.playerId)
        .take(10)
        .toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: similarPlayers.length,
      itemBuilder: (context, index) {
        final player = similarPlayers[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPositionColor(player.positionGroup),
              child: Text(
                player.position,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(player.displayNameOrFullName),
            subtitle: Text('${player.team} • ${player.fantasyPpg.toStringAsFixed(1)} PPG'),
            trailing: Text('#${player.jerseyNumber ?? ""}'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerDetailScreen(player: player),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'QB':
        return Colors.red;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.blue;
      case 'TE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}