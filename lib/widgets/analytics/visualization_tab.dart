import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mds_home/models/nfl_matchup.dart';
// import 'package:mds_home/services/historical_data_service.dart';
import 'package:mds_home/screens/historical_data_screen.dart';

class VisualizationTab extends StatelessWidget {
  final List<NFLMatchup> matchups;
  final String? selectedTeam;
  final List<QueryCondition> currentFilters;
  final Function(List<QueryCondition>) onApplyFilter;

  const VisualizationTab({
    super.key,
    required this.matchups,
    this.selectedTeam,
    required this.currentFilters,
    required this.onApplyFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (matchups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No data available for current filters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => onApplyFilter([]),
              icon: const Icon(Icons.refresh),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    // --- HEADLINE STATS SECTION ---
    final totalGames = matchups.length;
    final wins = matchups.where((m) => m.isWin).length;
    final losses = totalGames - wins;
    final winPct = totalGames > 0 ? (wins / totalGames * 100).toStringAsFixed(1) : '0.0';
    final spreadWins = matchups.where((m) => m.isSpreadWin).length;
    final spreadPct = totalGames > 0 ? (spreadWins / totalGames * 100).toStringAsFixed(1) : '0.0';

    // --- GROUP-BY LOGIC ---
    // List of attributes to group by (add/remove as needed)
    final groupByAttributes = <_GroupByAttribute>[
      _GroupByAttribute(
        field: 'Season',
        label: 'Season',
        valueGetter: (NFLMatchup m) => m.season.toString(),
      ),
      _GroupByAttribute(
        field: 'temp',
        label: 'Temperature (°F, 10° bins)',
        valueGetter: (NFLMatchup m) {
          if (m.temperature == null) return 'Unknown';
          final t = m.temperature!.round();
          final bin = (t ~/ 10) * 10;
          return '$bin-${bin + 9}';
        },
      ),
      _GroupByAttribute(
        field: 'setting',
        label: 'Setting',
        valueGetter: (NFLMatchup m) => m.setting ?? 'Unknown',
      ),
      _GroupByAttribute(
        field: 'Opponent_passOffTier',
        label: 'Opponent Pass Off Tier',
        valueGetter: (NFLMatchup m) => m.opponentPassOffTier.toString(),
      ),
      _GroupByAttribute(
        field: 'Opponent_defVsWR_tier',
        label: 'Opponent Def vs WR Tier',
        valueGetter: (NFLMatchup m) => m.opponentDefVsWRTier.toString(),
      ),
      _GroupByAttribute(
        field: 'Opponent_defVsRB_tier',
        label: 'Opponent Def vs RB Tier',
        valueGetter: (NFLMatchup m) => m.opponentDefVsRBTier.toString(),
      ),
      _GroupByAttribute(
        field: 'Opponent_defVsQB_tier',
        label: 'Opponent Def vs QB Tier',
        valueGetter: (NFLMatchup m) => m.opponentDefVsQBTier.toString(),
      ),
      // Add more group-by attributes as needed
    ];
    // NOTE: The visualizations below use the full `matchups` list passed to this widget.
    // If you see only a subset (e.g., 25 rows), update the parent to pass the full filtered data for visualization purposes.

    // Determine which fields are already filtered
    final filteredFields = currentFilters.map((f) => f.field).toSet();
    final groupBysToShow = groupByAttributes.where((g) => !filteredFields.contains(g.field)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADLINE STATS CARDS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _headlineStatCard('W/L', '$wins-$losses', '$winPct% Win'),
              const SizedBox(width: 16),
              _headlineStatCard('ATS', '$spreadWins-${totalGames - spreadWins}', '$spreadPct% ATS'),
            ],
          ),
          const SizedBox(height: 24),

          // --- GROUP-BY SUMMARIES ---
          for (final groupBy in groupBysToShow) ...[
            Text(
              'By ${groupBy.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _GroupBySummary(
              matchups: matchups,
              groupBy: groupBy,
              onApplyFilter: onApplyFilter,
            ),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }

// --- Helper: Headline Stat Card ---
  Widget _headlineStatCard(String title, String stat, String sub) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(stat, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(sub, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }

// --- GroupBy Attribute Helper Class ---
}

class _GroupByAttribute {
  final String field;
  final String label;
  final String Function(NFLMatchup) valueGetter;
  final Map<String, String>? valueLabels;
  _GroupByAttribute({
    required this.field,
    required this.label,
    required this.valueGetter,
    this.valueLabels,
  });
}

// --- GroupBy Summary Widget ---
class _GroupBySummary extends StatelessWidget {
  final List<NFLMatchup> matchups;
  final _GroupByAttribute groupBy;
  final Function(List<QueryCondition>) onApplyFilter;
  const _GroupBySummary({
    required this.matchups,
    required this.groupBy,
    required this.onApplyFilter,
  });

  @override
  Widget build(BuildContext context) {
    // Group matchups by the attribute value
    final Map<String, List<NFLMatchup>> grouped = {};
    for (final m in matchups) {
      final val = groupBy.valueGetter(m);
      grouped.putIfAbsent(val, () => []).add(m);
    }
    // Sort keys for display
    final keys = grouped.keys.toList()..sort();
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: keys.map((val) {
        final group = grouped[val]!;
        final wins = group.where((m) => m.isWin).length;
        final total = group.length;
        final winPct = total > 0 ? (wins / total * 100).toStringAsFixed(1) : '0.0';
        final spreadWins = group.where((m) => m.isSpreadWin).length;
        final spreadPct = total > 0 ? (spreadWins / total * 100).toStringAsFixed(1) : '0.0';
        final label = groupBy.valueLabels != null ? (groupBy.valueLabels![val] ?? val) : val;
        return GestureDetector(
          onTap: () {
            // Apply this group as a filter
            onApplyFilter([
              QueryCondition(field: groupBy.field, operator: QueryOperator.equals, value: val),
            ]);
          },
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('W/L: $wins-${total - wins}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Win%: $winPct%', style: TextStyle(color: Colors.green[700], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('ATS: $spreadWins-${total - spreadWins}', style: const TextStyle(fontSize: 16)),
                  Text('ATS%: $spreadPct%', style: TextStyle(color: Colors.blue[700], fontSize: 14)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
} 