import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/custom_ranking_result.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';

class RankingTableWidget extends StatefulWidget {
  final List<CustomRankingResult> results;
  final List<EnhancedRankingAttribute> attributes;
  final Function(CustomRankingResult) onPlayerTap;

  const RankingTableWidget({
    super.key,
    required this.results,
    required this.attributes,
    required this.onPlayerTap,
  });

  @override
  State<RankingTableWidget> createState() => _RankingTableWidgetState();
}

class _RankingTableWidgetState extends State<RankingTableWidget> {
  String _sortBy = 'rank';
  bool _ascending = true;
  late List<CustomRankingResult> _sortedResults;

  @override
  void initState() {
    super.initState();
    _sortedResults = List.from(widget.results);
    _sortResults();
  }

  void _sortResults() {
    _sortedResults.sort((a, b) {
      int comparison;
      
      switch (_sortBy) {
        case 'rank':
          comparison = a.rank.compareTo(b.rank);
          break;
        case 'projected_points':
          final aPoints = a.normalizedStats['projected_points_raw'] ?? 0.0;
          final bPoints = b.normalizedStats['projected_points_raw'] ?? 0.0;
          comparison = aPoints.compareTo(bPoints);
          break;
        case 'adp':
          final aAdp = a.normalizedStats['adp_raw'] ?? 999.0;
          final bAdp = b.normalizedStats['adp_raw'] ?? 999.0;
          comparison = aAdp.compareTo(bAdp);
          break;
        case 'consensus_rank':
          final aConsensus = a.normalizedStats['consensus_rank_raw'] ?? 999.0;
          final bConsensus = b.normalizedStats['consensus_rank_raw'] ?? 999.0;
          comparison = aConsensus.compareTo(bConsensus);
          break;
        case 'name':
          comparison = a.playerName.compareTo(b.playerName);
          break;
        case 'team':
          comparison = a.team.compareTo(b.team);
          break;
        default:
          // Sort by attribute score
          final aScore = a.attributeScores[_sortBy] ?? 0.0;
          final bScore = b.attributeScores[_sortBy] ?? 0.0;
          comparison = aScore.compareTo(bScore);
      }
      
      return _ascending ? comparison : -comparison;
    });
  }

  void _onSort(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _ascending = !_ascending;
      } else {
        _sortBy = sortBy;
        _ascending = false; // Default to descending for most metrics
      }
      _sortResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      mobile: (context) => _buildMobileLayout(context),
      desktop: (context) => _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader(context),
          const SizedBox(height: 16),
          ..._sortedResults.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            return _buildMobilePlayerCard(context, result, index);
          }),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader(context),
          _buildTable(context),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            'Player Rankings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${_sortedResults.length} players',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          _buildTableHeaders(context),
          const Divider(height: 1),
          ..._sortedResults.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            return _buildPlayerRow(context, result, index);
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeaders(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _buildSortableHeader('Rank', 'rank', 60),
          _buildSortableHeader('Player', 'name', 120),
          _buildSortableHeader('Team', 'team', 60),
          _buildSortableHeader('Proj. Points', 'projected_points', 90),
          _buildSortableHeader('ADP', 'adp', 60),
          _buildSortableHeader('Consensus', 'consensus_rank', 80),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(String title, String sortKey, double width) {
    final theme = Theme.of(context);
    final isActive = _sortBy == sortKey;
    
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => _onSort(sortKey),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isActive ? ThemeConfig.darkNavy : Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isActive 
                ? (_ascending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.sort,
              size: 14,
              color: isActive ? ThemeConfig.darkNavy : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow(BuildContext context, CustomRankingResult result, int index) {
    final theme = Theme.of(context);
    final isEven = index % 2 == 0;
    
    return InkWell(
      onTap: () => widget.onPlayerTap(result),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isEven ? Colors.white : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getRankColor(result.rank),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${result.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Player Name
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.playerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    result.position,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Team
            SizedBox(
              width: 60,
              child: Text(
                result.team,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Projected Points
            SizedBox(
              width: 90,
              child: Text(
                _formatProjectedPoints(result),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeConfig.darkNavy,
                ),
              ),
            ),
            // ADP
            SizedBox(
              width: 60,
              child: Text(
                _formatADP(result),
                style: theme.textTheme.bodySmall,
              ),
            ),
            // Consensus Rank
            SizedBox(
              width: 80,
              child: Text(
                _formatConsensusRank(result),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePlayerCard(BuildContext context, CustomRankingResult result, int index) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onPlayerTap(result),
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getRankColor(result.rank),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          '${result.rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.playerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                result.team,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: ThemeConfig.darkNavy,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  result.position,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Custom Rank',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '#${result.rank}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ThemeConfig.darkNavy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Proj. Points',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatProjectedPoints(result),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'ADP',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatADP(result),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Consensus',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatConsensusRank(result),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
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
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 5) return ThemeConfig.successGreen;
    if (rank <= 12) return ThemeConfig.gold;
    if (rank <= 24) return Colors.orange;
    return Colors.grey;
  }

  String _formatProjectedPoints(CustomRankingResult result) {
    final points = result.normalizedStats['projected_points_raw'];
    if (points == null || points == 0.0) return 'N/A';
    return points.toStringAsFixed(1);
  }

  String _formatADP(CustomRankingResult result) {
    final adp = result.normalizedStats['adp_raw'];
    if (adp == null || adp >= 999) return 'N/A';
    return adp.toStringAsFixed(0);
  }

  String _formatConsensusRank(CustomRankingResult result) {
    final consensus = result.normalizedStats['consensus_rank_raw'];
    if (consensus == null || consensus >= 999) return 'N/A';
    return '#${consensus.toStringAsFixed(0)}';
  }
}