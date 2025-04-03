
import 'package:flutter/material.dart';
import '../../services/analytics_query_service.dart';
import '../../utils/constants.dart';
import '../../utils/team_logo_utils.dart';
import 'team_draft_patterns_tab.dart';
import 'player_draft_analysis_tab.dart';  // You'll need to create this
import 'draft_trend_insights_tab.dart';   // You'll need to create this

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        // Tab content
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
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

  Widget _buildPlaceholderTab(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey.shade600 
                : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '$tabName will be implemented soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade400 
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back for more community insights',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}