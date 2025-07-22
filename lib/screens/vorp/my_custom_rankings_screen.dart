import 'package:flutter/material.dart';
import 'package:mds_home/screens/vorp/custom_big_board_screen.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/responsive_layout_builder.dart';
import '../../utils/theme_config.dart';
import '../../services/vorp/custom_vorp_ranking_service.dart';
import '../../models/vorp/custom_position_ranking.dart';
import '../../widgets/design_system/mds_card.dart';

class MyCustomRankingsScreen extends StatefulWidget {
  const MyCustomRankingsScreen({super.key});

  @override
  State<MyCustomRankingsScreen> createState() => _MyCustomRankingsScreenState();
}

class _MyCustomRankingsScreenState extends State<MyCustomRankingsScreen> {
  final CustomVorpRankingService _rankingService = CustomVorpRankingService();
  List<CustomPositionRanking> _rankings = [];
  List<CustomBigBoard> _bigBoards = [];
  Map<String, int> _rankingSummary = {};
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0; // 0 = rankings, 1 = big boards

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rankings = await _rankingService.getAllRankings();
      final bigBoards = await _rankingService.getAllBigBoards();
      final summary = await _rankingService.getRankingSummary();
      
      setState(() {
        _rankings = rankings;
        _bigBoards = bigBoards;
        _rankingSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRanking(String id) async {
    try {
      final success = await _rankingService.deleteRanking(id);
      if (success) {
        await _loadRankings(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ranking deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to delete ranking');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting ranking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(CustomPositionRanking ranking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ranking'),
        content: Text('Are you sure you want to delete "${ranking.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRanking(ranking.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        titleWidget: Text('My Custom Rankings'),
      ),
      body: ResponsiveLayoutBuilder(
        mobile: (context) => _buildMobileLayout(context),
        desktop: (context) => _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummarySection(context),
            const SizedBox(height: 24),
            _buildTabBar(context),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedTab == 0 
                  ? _buildRankingsList(context)
                  : _buildBigBoardsList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummarySection(context),
            const SizedBox(height: 32),
            _buildTabBar(context),
            const SizedBox(height: 24),
            Expanded(
              child: _selectedTab == 0 
                  ? _buildRankingsList(context)
                  : _buildBigBoardsList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return MdsCard(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRankings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return MdsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_outlined,
                size: 32,
                color: ThemeConfig.darkNavy,
              ),
              const SizedBox(width: 12),
              Text(
                'My Custom Rankings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeConfig.darkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Summary stats
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Rankings',
                  _rankings.length.toString(),
                  Icons.list_alt,
                  ThemeConfig.darkNavy,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Big Boards',
                  _bigBoards.length.toString(),
                  Icons.dashboard,
                  ThemeConfig.gold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Positions',
                  _rankingSummary.keys.length.toString(),
                  Icons.sports_football,
                  Colors.purple.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Position breakdown
          if (_rankingSummary.isNotEmpty) ...[
            Text(
              'By Position:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _rankingSummary.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeConfig.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ThemeConfig.gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${entry.key.toUpperCase()}: ${entry.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ThemeConfig.darkNavy,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Create Big Board button
          ElevatedButton.icon(
            onPressed: _canCreateBigBoard() ? _createCustomBigBoard : null,
            icon: const Icon(Icons.dashboard_outlined, size: 18),
            label: const Text('Create Custom Big Board'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (!_canCreateBigBoard())
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _getBigBoardRequirementText(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _selectedTab = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedTab == 0 ? ThemeConfig.darkNavy : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedTab == 0 ? ThemeConfig.darkNavy : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt,
                    color: _selectedTab == 0 ? Colors.white : Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Position Rankings',
                    style: TextStyle(
                      color: _selectedTab == 0 ? Colors.white : Colors.grey.shade600,
                      fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _selectedTab = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedTab == 1 ? ThemeConfig.darkNavy : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedTab == 1 ? ThemeConfig.darkNavy : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard,
                    color: _selectedTab == 1 ? Colors.white : Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Big Boards',
                    style: TextStyle(
                      color: _selectedTab == 1 ? Colors.white : Colors.grey.shade600,
                      fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingsList(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_rankings.isEmpty) {
      return MdsCard(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Custom Rankings Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first custom ranking by going to any position rankings page and clicking "Custom Ranking".',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/rankings/qb'),
              icon: const Icon(Icons.sports_football, size: 18),
              label: const Text('Go to QB Rankings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.darkNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Custom Rankings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Rankings list
        ...(_rankings.map((ranking) => _buildRankingCard(context, ranking)).toList()),
      ],
    );
  }

  Widget _buildRankingCard(BuildContext context, CustomPositionRanking ranking) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: MdsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ThemeConfig.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ranking.position.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ranking.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'delete':
                        _confirmDelete(ranking);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Ranking details
            Row(
              children: [
                Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${ranking.playerRanks.length} players',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Updated ${_formatDate(ranking.updatedAt)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Top 3 players preview
            if (ranking.playerRanks.isNotEmpty) ...[
              Text(
                'Top Players:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              ...ranking.playerRanks.take(3).map((player) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ThemeConfig.darkNavy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${player.customRank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          player.playerName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        player.team,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (player.vorp != 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: player.vorp >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${player.vorp >= 0 ? '+' : ''}${player.vorp.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: player.vorp >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ).toList(),
              if (ranking.playerRanks.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '...and ${ranking.playerRanks.length - 3} more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBigBoardsList(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_bigBoards.isEmpty) {
      return MdsCard(
        child: Column(
          children: [
            Icon(Icons.dashboard_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Big Boards Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create custom rankings with VORP calculations for multiple positions, then generate a big board.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _canCreateBigBoard() ? _createCustomBigBoard : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Big Board'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Custom Big Boards',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Big boards list
        ...(_bigBoards.map((bigBoard) => _buildBigBoardCard(context, bigBoard)).toList()),
      ],
    );
  }

  Widget _buildBigBoardCard(BuildContext context, CustomBigBoard bigBoard) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: MdsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ThemeConfig.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'BIG BOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bigBoard.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _viewBigBoard(bigBoard);
                        break;
                      case 'delete':
                        _confirmDeleteBigBoard(bigBoard);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('View'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Big board details
            Row(
              children: [
                Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${bigBoard.aggregatedPlayers.length} players',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.sports_football, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${bigBoard.positionRankings.keys.length} positions',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Created ${_formatDate(bigBoard.createdAt)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Top 3 players preview
            if (bigBoard.aggregatedPlayers.isNotEmpty) ...[
              Text(
                'Top Players by VORP:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              ...bigBoard.aggregatedPlayers.take(3).map((player) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ThemeConfig.darkNavy,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${player.customRank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          player.playerName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        player.team,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: player.vorp >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${player.vorp >= 0 ? '+' : ''}${player.vorp.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: player.vorp >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
              if (bigBoard.aggregatedPlayers.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '...and ${bigBoard.aggregatedPlayers.length - 3} more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
            
            const SizedBox(height: 12),
            
            // View button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewBigBoard(bigBoard),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Big Board'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewBigBoard(CustomBigBoard bigBoard) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomBigBoardScreen(bigBoard: bigBoard),
      ),
    );
  }

  void _confirmDeleteBigBoard(CustomBigBoard bigBoard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Big Board'),
        content: Text('Are you sure you want to delete "${bigBoard.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBigBoard(bigBoard.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBigBoard(String id) async {
    // Note: This method would need to be implemented in the service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Big board deletion not yet implemented'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  bool _canCreateBigBoard() {
    // Check if we have at least one ranking with VORP data for each major position
    final positions = ['qb', 'rb', 'wr', 'te'];
    final availablePositions = _rankings
        .where((ranking) => ranking.playerRanks.any((player) => player.vorp != 0.0))
        .map((ranking) => ranking.position.toLowerCase())
        .toSet();
    
    // Need at least QB, RB, WR to create a meaningful big board
    return availablePositions.contains('qb') && 
           availablePositions.contains('rb') && 
           availablePositions.contains('wr');
  }

  String _getBigBoardRequirementText() {
    final positions = ['qb', 'rb', 'wr', 'te'];
    final availablePositions = _rankings
        .where((ranking) => ranking.playerRanks.any((player) => player.vorp != 0.0))
        .map((ranking) => ranking.position.toLowerCase())
        .toSet();
    
    final missingPositions = positions
        .where((pos) => !availablePositions.contains(pos))
        .map((pos) => pos.toUpperCase())
        .toList();
    
    if (missingPositions.isEmpty) {
      return 'All positions ready for big board creation!';
    } else if (missingPositions.length <= 2) {
      return 'Need ${missingPositions.join(', ')} rankings with VORP calculations';
    } else {
      return 'Create rankings with VORP for QB, RB, WR (minimum required)';
    }
  }

  Future<void> _createCustomBigBoard() async {
    if (!_canCreateBigBoard()) return;
    
    try {
      // Get rankings with VORP data
      final rankingsWithVORP = _rankings
          .where((ranking) => ranking.playerRanks.any((player) => player.vorp != 0.0))
          .toList();
      
      // Combine all players from all positions
      final allPlayers = <Map<String, dynamic>>[];
      
      for (final ranking in rankingsWithVORP) {
        for (final player in ranking.playerRanks) {
          if (player.vorp != 0.0) {
            allPlayers.add({
              'playerId': player.playerId,
              'playerName': player.playerName,
              'team': player.team,
              'position': ranking.position.toUpperCase(),
              'customRank': player.customRank,
              'projectedPoints': player.projectedPoints,
              'vorp': player.vorp,
              'rankingName': ranking.name,
            });
          }
        }
      }
      
      // Sort by VORP (highest first)
      allPlayers.sort((a, b) => (b['vorp'] as double).compareTo(a['vorp'] as double));
      
      // Create custom big board
      final bigBoard = CustomBigBoard(
        id: _rankingService.generateRankingId(),
        name: 'Custom Big Board ${DateTime.now().month}/${DateTime.now().day}',
        positionRankings: Map.fromEntries(
          rankingsWithVORP.map((ranking) => MapEntry(ranking.position, ranking))
        ),
        aggregatedPlayers: allPlayers.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          return CustomPlayerRank(
            playerId: player['playerId'],
            playerName: player['playerName'],
            team: player['team'],
            customRank: index + 1, // Big board rank
            projectedPoints: player['projectedPoints'],
            vorp: player['vorp'],
          );
        }).toList(),
        createdAt: DateTime.now(),
      );
      
      // Save the big board
      final success = await _rankingService.saveBigBoard(bigBoard);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom Big Board created with ${allPlayers.length} players!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                _viewBigBoard(bigBoard);
              },
            ),
          ),
        );
      } else {
        throw Exception('Failed to save big board');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating big board: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}