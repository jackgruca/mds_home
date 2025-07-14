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
  bool _showRanks = false; // Toggle between showing ranks vs raw stats
  late List<CustomRankingResult> _sortedResults;
  late Map<String, Map<double, double>> _percentileCache; // Cache for percentile calculations

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
    
    for (final attribute in widget.attributes) {
      final values = widget.results
          .map((result) => result.rawStats[attribute.id] ?? 0.0)
          .where((value) => value > 0)
          .toList();
      
      if (values.isNotEmpty) {
        values.sort();
        _percentileCache[attribute.id] = {};
        
        for (final result in widget.results) {
          final value = result.rawStats[attribute.id] ?? 0.0;
          if (value > 0) {
            final rank = values.where((v) => v < value).length;
            final count = values.where((v) => v == value).length;
            final percentile = (rank + 0.5 * count) / values.length;
            _percentileCache[attribute.id]![value] = percentile;
          }
        }
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
                  () => setState(() => _showRanks = false),
                ),
                _buildToggleButton(
                  context,
                  'Ranks',
                  _showRanks,
                  () => setState(() => _showRanks = true),
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
          _buildSortableHeader('Score', 'score', 80),
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
    final percentile = _percentileCache[attribute.id]?[rawValue] ?? 0.0;

    String displayValue;
    if (_showRanks) {
      // Show rank (e.g., "#1", "#15")
      displayValue = '#${rankValue.toInt()}';
    } else {
      // Show raw stat value with appropriate formatting
      displayValue = _formatStatValue(rawValue, attribute);
    }

    return SizedBox(
      width: 100,
      child: Container(
        color: _getColorForPercentile(percentile),
        padding: const EdgeInsets.all(8.0),
        child: Text(
          displayValue,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: percentile > 0.85 ? FontWeight.bold : FontWeight.normal,
            color: percentile > 0.7 ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  String _formatStatValue(double value, EnhancedRankingAttribute attribute) {
    if (value == 0.0) return 'N/A';
    
    // Format based on attribute type
    if (attribute.name.contains('percentage') || 
        attribute.name.contains('rate') || 
        attribute.name.contains('share')) {
      // Handle percentage stats - check if value is already in percentage format
      if (value > 1.0) {
        // Value is already in percentage format (e.g., 27.23 for 27.23%)
        return '${value.toStringAsFixed(1)}%';
      } else {
        // Value is in decimal format (e.g., 0.2723 for 27.23%)
        return '${(value * 100).toStringAsFixed(1)}%';
      }
    } else if (attribute.name.contains('per_game') || 
               attribute.name.contains('yards') || 
               attribute.name.contains('points')) {
      // Show with 1 decimal place
      return value.toStringAsFixed(1);
    } else {
      // Show as whole number for counts (TDs, receptions, etc.)
      return value.toInt().toString();
    }
  }

  Color _getColorForPercentile(double? percentile) {
    if (percentile == null || percentile.isNaN || percentile.isInfinite) {
      return Colors.transparent;
    }
    
    // Ensure percentile is within valid range (0.0 to 1.0)
    final clampedPercentile = percentile.clamp(0.0, 1.0);
    
    // Use the same color scheme as data hub tables
    // Higher percentile = darker color (better performance)
    return Color.fromRGBO(
      100,  // Red
      140,  // Green  
      240,  // Blue
      0.1 + (clampedPercentile * 0.85)  // Alpha (10% to 95%)
    );
  }

  Widget _buildPlayerRow(BuildContext context, CustomRankingResult result) {
    final theme = Theme.of(context);
    final isEven = _sortedResults.indexOf(result) % 2 == 0;
    
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        result.rank.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Player Name and Position
            SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.playerName.isEmpty ? 'Unknown Player' : result.playerName,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    result.position.isEmpty ? 'N/A' : result.position,
                    style: theme.textTheme.bodySmall,
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
            // Score
            SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _getScoreColor(result.totalScore),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.totalScore.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
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
                          color: _getRankColor(result.rank),
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
                          Text(
                            result.playerName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${result.position} • ${result.team}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              const Divider(height: 24),
              _buildMobileStatRow('Score', result.totalScore.toStringAsFixed(1)),
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
    final percentile = _percentileCache[attribute.id]?[rawValue] ?? 0.0;

    String displayValue;
    if (_showRanks) {
      displayValue = '#${rankValue.toInt()}';
    } else {
      displayValue = _formatStatValue(rawValue, attribute);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColorForPercentile(percentile),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            attribute.displayName,
            style: TextStyle(
              fontSize: 12,
              color: percentile > 0.7 ? Colors.white : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 12,
                fontWeight: percentile > 0.85 ? FontWeight.bold : FontWeight.w600,
                color: percentile > 0.7 ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 5) return ThemeConfig.successGreen;
    if (rank <= 12) return ThemeConfig.gold;
    if (rank <= 24) return Colors.orange;
    return Colors.grey;
  }

  Color _getScoreColor(double score) {
    // Since lower scores are better in the new rank-based system,
    // we'll use a gradient where lower scores get better colors
    if (score <= 10) return ThemeConfig.successGreen;
    if (score <= 20) return ThemeConfig.gold;
    if (score <= 40) return Colors.orange;
    return Colors.grey;
  }


}