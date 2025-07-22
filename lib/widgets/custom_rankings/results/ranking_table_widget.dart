import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/custom_ranking_result.dart';
import 'package:mds_home/models/custom_rankings/enhanced_ranking_attribute.dart';
import 'package:mds_home/services/rankings/ranking_service.dart';
import 'package:mds_home/services/rankings/ranking_cell_shading_service.dart';
import 'package:mds_home/utils/team_logo_utils.dart';

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
  bool _showRanks = false; // Toggle between showing ranks vs raw stats
  late List<CustomRankingResult> _sortedResults;
  late Map<String, Map<String, double>> _percentileCache; // Cache for percentile calculations

  @override
  void initState() {
    super.initState();
    _sortedResults = List.from(widget.results);
    _calculatePercentiles();
    _sortResults();
  }

  @override
  void didUpdateWidget(RankingTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results || oldWidget.attributes != widget.attributes) {
      _sortedResults = List.from(widget.results);
      _calculatePercentiles();
      _sortResults();
    }
  }

  void _calculatePercentiles() {
    _percentileCache = {};
    
    // Convert widget.results to the format expected by RankingCellShadingService
    // Use either raw stats or normalized stats (ranks) based on current toggle
    final dataList = widget.results.map((result) => 
      _showRanks ? result.normalizedStats : result.rawStats
    ).toList();
    final statFields = widget.attributes.map((attr) => attr.id).toList();
    
    // Use the same percentile calculation as the position rankings
    final percentiles = RankingCellShadingService.calculatePercentiles(dataList, statFields);
    _percentileCache = percentiles;
  }
  
  int _calculateTier(int rank, String position) {
    // Position-specific tier calculation
    final pos = position.toUpperCase();
    
    if (pos == 'QB' || pos == 'TE') {
      // QB and TE: 4 players per tier (tiers 1-7), remainder in tier 8
      if (rank <= 4) return 1;
      if (rank <= 8) return 2;
      if (rank <= 12) return 3;
      if (rank <= 16) return 4;
      if (rank <= 20) return 5;
      if (rank <= 24) return 6;
      if (rank <= 28) return 7;
      return 8; // All remaining players
    } else if (pos == 'WR' || pos == 'RB') {
      // WR and RB: 8 players per tier
      if (rank <= 8) return 1;
      if (rank <= 16) return 2;
      if (rank <= 24) return 3;
      if (rank <= 32) return 4;
      if (rank <= 40) return 5;
      if (rank <= 48) return 6;
      if (rank <= 56) return 7;
      return 8; // All remaining players
    } else {
      // Default tier calculation for other positions
      if (rank <= 5) return 1;
      if (rank <= 12) return 2;
      if (rank <= 24) return 3;
      if (rank <= 48) return 4;
      return 5;
    }
  }
  
  Color _getTierColor(int tier) {
    final colors = RankingService.getTierColors();
    return Color(colors[tier] ?? 0xFF9E9E9E);
  }
  
  String _formatStatValue(dynamic value, String format) {
    return RankingService.formatStatValue(value, format);
  }
  
  Color _getAttributeCellColor(String attributeId, double rawValue, double rankValue) {
    final percentiles = _percentileCache[attributeId];
    if (percentiles == null) return Colors.grey.shade200;
    
    final p25 = percentiles['p25']!;
    final p50 = percentiles['p50']!;
    final p75 = percentiles['p75']!;
    
    // Determine which value to use for comparison
    final value = _showRanks ? rankValue : rawValue;
    
    if (_showRanks) {
      // For rank fields, lower numbers are better (rank 1 is best)
      // Inverted logic for ranks: lower rank = better = green
      if (value <= p25) {
        return Colors.green.withOpacity(0.7);  // Top 25% (best ranks)
      } else if (value <= p50) {
        return Colors.green.withOpacity(0.4);  // Top 50%
      } else if (value <= p75) {
        return Colors.orange.withOpacity(0.3); // Top 75%
      } else {
        return Colors.red.withOpacity(0.3);    // Bottom 25% (worst ranks)
      }
    } else {
      // For regular stats, higher numbers are usually better
      if (value >= p75) {
        return Colors.green.withOpacity(0.7);
      } else if (value >= p50) {
        return Colors.green.withOpacity(0.4);
      } else if (value >= p25) {
        return Colors.orange.withOpacity(0.3);
      } else {
        return Colors.red.withOpacity(0.3);
      }
    }
  }

  void _sortResults() {
    _sortedResults.sort((a, b) {
      int comparison;
      
      switch (_sortBy) {
        case 'rank':
          comparison = a.rank.compareTo(b.rank);
          break;
        case 'score':
          comparison = a.totalScore.compareTo(b.totalScore);
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
        case 'tier':
          final aTier = _calculateTier(a.rank, a.position);
          final bTier = _calculateTier(b.rank, b.position);
          comparison = aTier.compareTo(bTier);
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
    // Debug: Check if we have valid data
    if (widget.results.isEmpty) {
      return const Center(
        child: Text('No ranking results available'),
      );
    }
    
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
            final result = entry.value;
            final index = entry.key;
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTable(context),
          ),
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
          // Toggle button for ranks vs raw stats
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton(
                  context,
                  'Raw Stats',
                  !_showRanks,
                  () => setState(() {
                    _showRanks = false;
                    _calculatePercentiles();
                  }),
                ),
                _buildToggleButton(
                  context,
                  'Ranks',
                  _showRanks,
                  () => setState(() {
                    _showRanks = true;
                    _calculatePercentiles();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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

  Widget _buildToggleButton(BuildContext context, String label, bool isActive, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? ThemeConfig.darkNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
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
          if (_sortedResults.isNotEmpty)
            ..._sortedResults.map((result) => _buildPlayerRow(context, result))
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No players to display'),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeaders(BuildContext context) {
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
          _buildSortableHeader('Player', 'name', 200),
          _buildSortableHeader('Team', 'team', 60),
          _buildSortableHeader('Tier', 'tier', 60),
          ...widget.attributes.map((attr) => _buildSortableHeader(attr.displayName, attr.id, 100)).toList(),
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

  Widget _buildAttributeCell(CustomRankingResult result, EnhancedRankingAttribute attribute) {
    final rawValue = result.rawStats[attribute.id] ?? 0.0;
    final rankValue = result.normalizedStats[attribute.id] ?? 0.0;

    // Use the same cell shading service as the position rankings
    return SizedBox(
      width: 100,
      child: Container(
        width: 100,
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _getAttributeCellColor(attribute.id, rawValue, rankValue),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Center(
          child: Text(
            _showRanks ? '#${rankValue.toInt()}' : _formatStatValue(rawValue, 'decimal1'),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }


  Widget _buildPlayerRow(BuildContext context, CustomRankingResult result) {
    final theme = Theme.of(context);
    final isEven = _sortedResults.indexOf(result) % 2 == 0;
    final tier = _calculateTier(result.rank, result.position);
    final tierColor = _getTierColor(tier);
    
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tierColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${result.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // Player Name with team logo
            SizedBox(
              width: 200,
              child: Row(
                children: [
                  TeamLogoUtils.buildNFLTeamLogo(result.team, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.playerName.isEmpty ? 'Unknown Player' : result.playerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Team
            SizedBox(
              width: 60,
              child: Text(
                result.team.isEmpty ? 'N/A' : result.team,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Tier
            SizedBox(
              width: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tierColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Tier $tier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            // Dynamic Attribute Cells
            ...widget.attributes.map((attr) => _buildAttributeCell(result, attr)),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePlayerCard(BuildContext context, CustomRankingResult result, int index) {
    final theme = Theme.of(context);
    final tier = _calculateTier(result.rank, result.position);
    final tierColor = _getTierColor(tier);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onPlayerTap(result),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: tierColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            result.rank.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TeamLogoUtils.buildNFLTeamLogo(result.team, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                result.playerName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${result.position} • ${result.team}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tierColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Tier $tier',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              const Divider(height: 24),
              ...widget.attributes.map((attr) => _buildMobileAttributeRow(result, attr)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileStatRow(String title, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileAttributeRow(CustomRankingResult result, EnhancedRankingAttribute attribute) {
    final rawValue = result.rawStats[attribute.id] ?? 0.0;
    final rankValue = result.normalizedStats[attribute.id] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '${attribute.displayName}: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Container(
              height: 32,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _getAttributeCellColor(attribute.id, rawValue, rankValue),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: Center(
                child: Text(
                  _showRanks ? '#${rankValue.toInt()}' : _formatStatValue(rawValue, 'decimal1'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



}