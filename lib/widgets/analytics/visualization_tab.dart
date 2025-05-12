import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mds_home/models/nfl_matchup.dart';
import 'package:mds_home/services/historical_data_service.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Insights Cards
          _buildQuickInsightsCards(context),
          const SizedBox(height: 24),
          
          // Win/Loss Record Chart
          if (selectedTeam != null) ...[
            Text(
              'Win/Loss Record',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _buildWinLossChart(),
            ),
            const SizedBox(height: 24),
          ],

          // Points Distribution Chart
          Text(
            'Points Distribution',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildPointsDistributionChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsightsCards(BuildContext context) {
    // Calculate insights
    final totalGames = matchups.length;
    final wins = matchups.where((m) => m.isWin).length;
    final homeGames = matchups.where((m) => m.isHome).length;
    final homeWins = matchups.where((m) => m.isHome && m.isWin).length;
    final spreadWins = matchups.where((m) => m.isSpreadWin).length;
    final overs = matchups.where((m) => m.isOver).length;

    // Calculate additional insights
    final avgPoints = matchups.fold<double>(
            0, (sum, m) => sum + (m.finalScore + m.opponentScore)) /
        totalGames;
    final avgMargin = matchups.fold<double>(
            0, (sum, m) => sum + (m.finalScore - m.opponentScore).abs()) /
        totalGames;

    // Find patterns
    final List<Map<String, dynamic>> patterns = [];
    
    // Home field advantage pattern
    if (homeWins / homeGames > 0.6) {
      patterns.add({
        'title': 'Strong Home Field Advantage',
        'description': 'Team performs significantly better at home',
        'filter': [
          QueryCondition(
            field: 'VH',
            operator: QueryOperator.equals,
            value: 'H',
          ),
        ],
      });
    }

    // High scoring pattern
    if (avgPoints > 50) {
      patterns.add({
        'title': 'High Scoring Games',
        'description': 'Games average over 50 points',
        'filter': [
          QueryCondition(
            field: 'Actual_total',
            operator: QueryOperator.greaterThan,
            value: '50',
          ),
        ],
      });
    }

    // Close games pattern
    if (avgMargin < 7) {
      patterns.add({
        'title': 'Close Games',
        'description': 'Games decided by less than a touchdown on average',
        'filter': [
          QueryCondition(
            field: 'Final',
            operator: QueryOperator.lessThan,
            value: '7',
          ),
        ],
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Insights',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            _buildInsightCard(
              'Overall Record',
              '$wins-${totalGames - wins}',
              '${((wins / totalGames) * 100).toStringAsFixed(1)}% Win Rate',
              Icons.sports_score,
            ),
            _buildInsightCard(
              'Home Record',
              '$homeWins-${homeGames - homeWins}',
              '${((homeWins / homeGames) * 100).toStringAsFixed(1)}% Home Win Rate',
              Icons.home,
            ),
            _buildInsightCard(
              'Against Spread',
              '$spreadWins-${totalGames - spreadWins}',
              '${((spreadWins / totalGames) * 100).toStringAsFixed(1)}% ATS Win Rate',
              Icons.trending_up,
            ),
            _buildInsightCard(
              'Over/Under',
              '$overs-${totalGames - overs}',
              '${((overs / totalGames) * 100).toStringAsFixed(1)}% Over Rate',
              Icons.show_chart,
            ),
          ],
        ),
        if (patterns.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Patterns Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: patterns.map((pattern) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(pattern['description']),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => onApplyFilter(pattern['filter']),
                      child: const Text('Explore Further'),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildInsightCard(String title, String record, String percentage, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              record,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinLossChart() {
    // Group matchups by season
    final Map<int, List<NFLMatchup>> matchupsBySeason = {};
    for (var matchup in matchups) {
      matchupsBySeason.putIfAbsent(matchup.season, () => []);
      matchupsBySeason[matchup.season]!.add(matchup);
    }

    // Calculate wins and losses per season
    final List<BarChartGroupData> barGroups = [];
    final seasons = matchupsBySeason.keys.toList()..sort();

    for (var season in seasons) {
      final seasonMatchups = matchupsBySeason[season]!;
      final wins = seasonMatchups.where((m) => m.isWin).length;
      final losses = seasonMatchups.length - wins;

      barGroups.add(
        BarChartGroupData(
          x: seasons.indexOf(season),
          barRods: [
            BarChartRodData(
              toY: wins.toDouble(),
              color: Colors.green,
              width: 20,
            ),
            BarChartRodData(
              toY: losses.toDouble(),
              color: Colors.red,
              width: 20,
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 20, // Adjust based on your data
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < seasons.length) {
                  return Text(seasons[value.toInt()].toString());
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _buildPointsDistributionChart() {
    // Create points distribution data
    final List<FlSpot> spots = [];
    final Map<int, int> pointsDistribution = {};

    for (var matchup in matchups) {
      final totalPoints = matchup.finalScore + matchup.opponentScore;
      pointsDistribution[totalPoints] = (pointsDistribution[totalPoints] ?? 0) + 1;
    }

    final sortedPoints = pointsDistribution.keys.toList()..sort();
    for (var i = 0; i < sortedPoints.length; i++) {
      spots.add(FlSpot(
        sortedPoints[i].toDouble(),
        pointsDistribution[sortedPoints[i]]!.toDouble(),
      ));
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
        titlesData: const FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
      ),
    );
  }
} 