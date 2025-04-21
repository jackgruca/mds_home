import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/constants.dart';
import '../../utils/team_logo_utils.dart';
import 'team_draft_patterns_tab.dart';
import 'player_draft_analysis_tab.dart';
import 'draft_trend_insights_tab.dart';
import 'advanced_insights_tab.dart'; // Add this import

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
    Consumer<AnalyticsProvider>(
      builder: (context, provider, _) => provider.isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.white70 : Colors.blue,
              ),
            ),
          )
        : Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh analytics data',
                onPressed: () {
                  _analyticsProvider.refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing analytics data...'),
                      duration: Duration(seconds: 2),
                    )
                  );
                },
              ),
              if (provider.error != null)
                Tooltip(
                  message: 'Error: ${provider.error}',
                  child: const Icon(Icons.error_outline, color: Colors.orange, size: 14),
                ),
            ],
          ),
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
                const SizedBox(width: 12),
                _buildTabButton('Advanced Insights', isDarkMode), // Add this new tab
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

  // Update the tab content to include our new tab
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
      case 'Advanced Insights':
        return AdvancedInsightsTab(draftYear: widget.draftYear); // Add this case
      default:
        return const Center(
          child: Text('Select a tab to view analytics'),
        );
    }
  }

  // Helper method to format a date
  String _formatDate(DateTime date) {
    // Format: Apr 8, 2025
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  Widget _buildTabButton(String tabName, bool isDarkMode) {
  bool isSelected = _selectedTab == tabName;
  
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: isSelected 
          ? Theme.of(context).primaryColor 
          : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
      foregroundColor: isSelected 
          ? Colors.white 
          : (isDarkMode ? Colors.white70 : Colors.black87),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    onPressed: () {
      setState(() {
        _selectedTab = tabName;
      });
    },
    child: Text(tabName),
  );
}


  @override
  bool get wantKeepAlive => true;
}