import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_draft_grade.dart';
import '../services/ff_draft_analytics_service.dart';
import '../services/ff_value_alert_service.dart';
import '../providers/ff_draft_provider.dart';

class FFDraftInsightsPanel extends StatefulWidget {
  const FFDraftInsightsPanel({super.key});

  @override
  State<FFDraftInsightsPanel> createState() => _FFDraftInsightsPanelState();
}

class _FFDraftInsightsPanelState extends State<FFDraftInsightsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FFDraftAnalyticsService _analyticsService = FFDraftAnalyticsService();
  final FFValueAlertService _alertService = FFValueAlertService();
  
  List<FFDraftInsight> _realtimeInsights = [];
  List<ValueAlert> _recentAlerts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Listen to value alerts
    _alertService.alertStream.listen((alert) {
      setState(() {
        _recentAlerts.insert(0, alert);
        if (_recentAlerts.length > 10) {
          _recentAlerts = _recentAlerts.take(10).toList();
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _alertService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FFDraftProvider>(
      builder: (context, provider, child) {
        // Update real-time insights
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateInsights(provider);
        });

        return Column(
          children: [
            _buildHeader(context),
            _buildTabBar(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInsightsTab(provider),
                  _buildGradesTab(provider),
                  _buildAlertsTab(),
                  _buildAnalyticsTab(provider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Draft Insights',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          if (_recentAlerts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_recentAlerts.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Insights', icon: Icon(Icons.lightbulb, size: 16)),
        Tab(text: 'Grades', icon: Icon(Icons.grade, size: 16)),
        Tab(text: 'Alerts', icon: Icon(Icons.notifications, size: 16)),
        Tab(text: 'Analytics', icon: Icon(Icons.bar_chart, size: 16)),
      ],
      labelStyle: const TextStyle(fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
    );
  }

  Widget _buildInsightsTab(FFDraftProvider provider) {
    if (_realtimeInsights.isEmpty) {
      return _buildEmptyState(
        icon: Icons.lightbulb_outline,
        title: 'Generating Insights',
        subtitle: 'Real-time draft insights will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _realtimeInsights.length,
      itemBuilder: (context, index) {
        final insight = _realtimeInsights[index];
        return _buildInsightCard(insight);
      },
    );
  }

  Widget _buildGradesTab(FFDraftProvider provider) {
    final completedPicks = provider.draftPicks
        .where((pick) => pick.selectedPlayer != null)
        .toList();

    if (completedPicks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.grade,
        title: 'No Picks Yet',
        subtitle: 'Pick grades will appear as the draft progresses',
      );
    }

    // Grade recent picks
    final recentPickGrades = completedPicks.skip((completedPicks.length - 5).clamp(0, completedPicks.length)).map((pick) {
      return _analyticsService.gradePickInRealTime(
        player: pick.selectedPlayer!,
        team: pick.team,
        pickNumber: pick.pickNumber,
        round: pick.round,
        remainingPlayers: provider.availablePlayers,
        completedPicks: completedPicks,
      );
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: recentPickGrades.length,
      itemBuilder: (context, index) {
        final grade = recentPickGrades[recentPickGrades.length - 1 - index];
        return _buildGradeCard(grade);
      },
    );
  }

  Widget _buildAlertsTab() {
    if (_recentAlerts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_none,
        title: 'No Alerts',
        subtitle: 'Value alerts and notifications will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _recentAlerts.length,
      itemBuilder: (context, index) {
        final alert = _recentAlerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAnalyticsTab(FFDraftProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDraftProgressCard(provider),
          const SizedBox(height: 16),
          _buildPositionalAnalysisCard(provider),
          const SizedBox(height: 16),
          _buildValueTrendsCard(provider),
        ],
      ),
    );
  }

  Widget _buildInsightCard(FFDraftInsight insight) {
    final theme = Theme.of(context);
    Color priorityColor = Colors.blue;
    IconData priorityIcon = Icons.info;

    switch (insight.priority) {
      case InsightPriority.HIGH:
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case InsightPriority.MEDIUM:
        priorityColor = Colors.orange;
        priorityIcon = Icons.warning;
        break;
      case InsightPriority.LOW:
        priorityColor = Colors.blue;
        priorityIcon = Icons.info;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(priorityIcon, color: priorityColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.message,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (insight.relatedPlayer != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${insight.relatedPlayer!.name} (${insight.relatedPlayer!.position})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeCard(FFPickGrade grade) {
    final theme = Theme.of(context);
    Color gradeColor = _getGradeColor(grade.grade);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    grade.gradeDisplay,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: gradeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  grade.pickTypeDisplay,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Pick ${grade.pickNumber}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${grade.player.name} (${grade.player.position}) - ${grade.team.name}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              grade.reasoning,
              style: theme.textTheme.bodyMedium,
            ),
            if (grade.positives.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...grade.positives.map((positive) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        positive,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (grade.negatives.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...grade.negatives.map((negative) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.remove_circle, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        negative,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(ValueAlert alert) {
    final theme = Theme.of(context);
    Color alertColor = _getAlertColor(alert.severity);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              _getAlertIcon(alert.type),
              color: alertColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: alertColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (alert.player != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${alert.player!.name} (${alert.player!.position})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              _formatTimeAgo(alert.timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftProgressCard(FFDraftProvider provider) {
    final theme = Theme.of(context);
    final currentPick = provider.getCurrentPick();
    final totalPicks = provider.draftPicks.length;
    final completedPicks = provider.currentPickIndex;
    final progress = completedPicks / totalPicks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Draft Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              'Pick ${completedPicks + 1} of $totalPicks (${(progress * 100).toInt()}%)',
              style: theme.textTheme.bodyMedium,
            ),
            if (currentPick != null) ...[
              const SizedBox(height: 8),
              Text(
                'Round ${currentPick.round} • ${currentPick.team.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPositionalAnalysisCard(FFDraftProvider provider) {
    final theme = Theme.of(context);
    final remainingByPosition = <String, int>{};
    
    for (final player in provider.availablePlayers) {
      remainingByPosition[player.position] = 
          (remainingByPosition[player.position] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Position Availability',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: remainingByPosition.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: theme.textTheme.labelMedium,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueTrendsCard(FFDraftProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Value Trends',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Real-time draft value analysis coming soon...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateInsights(FFDraftProvider provider) {
    if (!mounted) return;
    
    final currentPick = provider.getCurrentPick();
    if (currentPick == null) return;

    final insights = _analyticsService.generateRealTimeInsights(
      teams: provider.teams,
      remainingPlayers: provider.availablePlayers,
      completedPicks: provider.draftPicks.where((p) => p.selectedPlayer != null).toList(),
      currentRound: currentPick.round,
      userTeamId: provider.teams[provider.userTeamIndex].id,
    );

    setState(() {
      _realtimeInsights = insights;
    });
  }

  Color _getGradeColor(DraftGrade grade) {
    switch (grade) {
      case DraftGrade.A_PLUS:
      case DraftGrade.A:
        return Colors.green;
      case DraftGrade.A_MINUS:
      case DraftGrade.B_PLUS:
        return Colors.lightGreen;
      case DraftGrade.B:
      case DraftGrade.B_MINUS:
        return Colors.blue;
      case DraftGrade.C_PLUS:
      case DraftGrade.C:
        return Colors.orange;
      case DraftGrade.C_MINUS:
      case DraftGrade.D_PLUS:
        return Colors.deepOrange;
      case DraftGrade.D:
      case DraftGrade.F:
        return Colors.red;
    }
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.HIGH:
        return Colors.red;
      case AlertSeverity.MEDIUM:
        return Colors.orange;
      case AlertSeverity.LOW:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.STEAL:
        return Icons.local_fire_department;
      case AlertType.REACH:
        return Icons.trending_up;
      case AlertType.VALUE_OPPORTUNITY:
        return Icons.diamond;
      case AlertType.POSITION_SCARCITY:
        return Icons.warning;
      case AlertType.GOOD_VALUE:
        return Icons.check_circle;
      case AlertType.NEED_FILLED:
        return Icons.gps_fixed;
      default:
        return Icons.info;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    return '${difference.inHours}h';
  }
}