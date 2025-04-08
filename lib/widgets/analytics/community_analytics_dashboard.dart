// lib/widgets/analytics/community_analytics_dashboard.dart (MODIFIED)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/constants.dart';
import '../../utils/team_logo_utils.dart';
import 'team_draft_patterns_tab.dart';
import 'player_draft_analysis_tab.dart';
import 'draft_trend_insights_tab.dart';

class CommunityAnalyticsDashboard extends StatefulWidget {
  final String userTeam;
  final int draftYear;
  final List<String> allTeams;

  const CommunityAnalyticsDashboard({
    super.key,
    required this.userTeam,
    required this.draftYear,
    required this.allTeams,
  });

  @override
  _CommunityAnalyticsDashboardState createState() => _CommunityAnalyticsDashboardState();
}

class _CommunityAnalyticsDashboardState extends State<CommunityAnalyticsDashboard>
    with AutomaticKeepAliveClientMixin {
  String _selectedTab = 'Team Draft Patterns';
  late AnalyticsProvider _analyticsProvider;

  @override
  void initState() {
    super.initState();
    // Initialize analytics provider
    _analyticsProvider = AnalyticsProvider();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _analyticsProvider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data freshness indicator
          Consumer<AnalyticsProvider>(
            builder: (context, provider, child) {
              final lastUpdated = provider.lastUpdated;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.update, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      lastUpdated != null
                          ? 'Data updated: ${_formatDate(lastUpdated)}'
                          : 'Data freshness: Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'Refresh analytics data',
                      onPressed: () {
                        _analyticsProvider.clearCache();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Analytics cache cleared'),
                            duration: Duration(seconds: 2),
                          )
                        );
                      },
                    ),
                  ],
                ),
              );
            }
          ),
          
          // Tab selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                _buildTabButton('Team Draft Patterns', isDarkMode),
                const SizedBox(width: 12),
                _buildTabButton('Player Draft Analysis', isDarkMode),
                const SizedBox(width: 12),
                _buildTabButton('Draft Trend Insights', isDarkMode),
              ],
            ),
          ),

          // Tab content with shared provider
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTabButton(String title, bool isDarkMode) {
    final isSelected = _selectedTab == title;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade300)
                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isDarkMode ? Colors.white : Colors.blue.shade800)
                : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'Team Draft Patterns':
        return TeamDraftPatternsTab(
          initialTeam: widget.userTeam,
          allTeams: widget.allTeams,
          draftYear: widget.draftYear,
        );
      case 'Player Draft Analysis':
        return PlayerDraftAnalysisTab(draftYear: widget.draftYear);
      case 'Draft Trend Insights':
        return DraftTrendInsightsTab(draftYear: widget.draftYear);
      default:
        return const Center(
          child: Text('Select a tab to view analytics'),
        );
    }
  }

  @override
  bool get wantKeepAlive => true;
}