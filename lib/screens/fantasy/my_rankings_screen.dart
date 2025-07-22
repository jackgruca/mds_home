import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../utils/theme_config.dart';
import '../../services/fantasy/custom_ranking_service.dart';
import '../../models/fantasy/custom_position_ranking.dart';

class MyRankingsScreen extends StatefulWidget {
  const MyRankingsScreen({super.key});

  @override
  State<MyRankingsScreen> createState() => _MyRankingsScreenState();
}

class _MyRankingsScreenState extends State<MyRankingsScreen>
    with TickerProviderStateMixin {
  List<CustomPositionRanking> _allRankings = [];
  Map<String, List<CustomPositionRanking>> _rankingsByPosition = {};
  bool _isLoading = true;
  String? _error;
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
    _loadRankings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rankings = await CustomRankingService.getAllCustomRankings();
      
      // Group by position
      final groupedRankings = <String, List<CustomPositionRanking>>{};
      for (final ranking in rankings) {
        final position = ranking.position.toLowerCase();
        groupedRankings[position] = (groupedRankings[position] ?? [])..add(ranking);
      }

      setState(() {
        _allRankings = rankings;
        _rankingsByPosition = groupedRankings;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to load rankings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRanking(String id, String name) async {
    final confirmed = await _showDeleteConfirmation(name);
    if (!confirmed) return;

    try {
      final success = await CustomRankingService.deleteCustomRanking(id);
      if (success) {
        HapticFeedback.lightImpact();
        _loadRankings(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text('Ranking "$name" deleted successfully'),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting ranking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ranking?'),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _createCustomBigBoard() async {
    // TODO: Implement in Phase 2
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom Big Board creation coming in Phase 2!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position.toLowerCase()) {
      case 'qb':
        return Colors.red.shade600;
      case 'rb':
        return Colors.blue.shade600;
      case 'wr':
        return Colors.green.shade600;
      case 'te':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getPositionIcon(String position) {
    switch (position.toLowerCase()) {
      case 'qb':
        return Icons.sports_football;
      case 'rb':
        return Icons.directions_run;
      case 'wr':
        return Icons.catching_pokemon;
      case 'te':
        return Icons.sports_handball;
      default:
        return Icons.person;
    }
  }

  String _getPositionDisplayName(String position) {
    switch (position.toLowerCase()) {
      case 'qb':
        return 'Quarterback';
      case 'rb':
        return 'Running Back';
      case 'wr':
        return 'Wide Receiver';
      case 'te':
        return 'Tight End';
      default:
        return position.toUpperCase();
    }
  }

  @override
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
      return const Center(child: CircularProgressIndicator());
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
              onPressed: _loadRankings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _allRankings.isEmpty 
                ? _buildEmptyState()
                : _buildRankingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final canCreateBigBoard = _rankingsByPosition.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConfig.darkNavy,
            ThemeConfig.darkNavy.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Custom Rankings',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Manage your personalized player rankings',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Create Big Board Button
              ElevatedButton.icon(
                onPressed: canCreateBigBoard ? _createCustomBigBoard : null,
                icon: const Icon(Icons.add_chart, size: 20),
                label: const Text('Create Big Board'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canCreateBigBoard ? ThemeConfig.gold : Colors.grey,
                  foregroundColor: ThemeConfig.darkNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _buildStatCard('Total Rankings', _allRankings.length.toString()),
              const SizedBox(width: 16),
              _buildStatCard('Positions Covered', _rankingsByPosition.length.toString()),
              const SizedBox(width: 16),
              _buildStatCard('Latest Updated', _getLatestUpdateTime()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLatestUpdateTime() {
    if (_allRankings.isEmpty) return 'None';
    
    final latest = _allRankings.reduce((a, b) => 
        a.updatedAt.isAfter(b.updatedAt) ? a : b);
    
    final now = DateTime.now();
    final difference = now.difference(latest.updatedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Custom Rankings Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first custom ranking from any position screen',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/rankings/qb'),
            icon: const Icon(Icons.add),
            label: const Text('Start with QB Rankings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.darkNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rankingsByPosition.length,
        itemBuilder: (context, index) {
          final position = _rankingsByPosition.keys.elementAt(index);
          final rankings = _rankingsByPosition[position]!;
          
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 600),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildPositionSection(position, rankings),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPositionSection(String position, List<CustomPositionRanking> rankings) {
    final theme = Theme.of(context);
    final positionColor = _getPositionColor(position);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: positionColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: positionColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: positionColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPositionIcon(position),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPositionDisplayName(position),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: positionColor,
                        ),
                      ),
                      Text(
                        '${rankings.length} ranking${rankings.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rankings list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rankings.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final ranking = rankings[index];
              return _buildRankingTile(ranking, positionColor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankingTile(CustomPositionRanking ranking, Color positionColor) {
    final theme = Theme.of(context);
    final summary = ranking.getSummary();
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: CircleAvatar(
        backgroundColor: positionColor.withOpacity(0.1),
        child: Text(
          '${ranking.playerRanks.length}',
          style: TextStyle(
            color: positionColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        ranking.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Updated ${_formatTimeAgo(ranking.updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (summary['topPlayer'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Top: ${summary['topPlayer']}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: positionColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        onSelected: (value) async {
          switch (value) {
            case 'edit':
              // TODO: Navigate to edit mode
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit functionality coming soon!')),
              );
              break;
            case 'duplicate':
              // TODO: Implement duplicate
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Duplicate functionality coming soon!')),
              );
              break;
            case 'delete':
              await _deleteRanking(ranking.id, ranking.name);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 12),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy, size: 18),
                SizedBox(width: 12),
                Text('Duplicate'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 12),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}