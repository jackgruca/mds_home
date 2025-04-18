// lib/widgets/analytics/community_analytics_dashboard.dart
// Update your existing implementation with these changes

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/constants.dart';
import '../../utils/team_logo_utils.dart';
import 'team_draft_patterns_tab.dart';
import 'player_draft_analysis_tab.dart';
import 'draft_trend_insights_tab.dart';
import 'advanced_insights_tab.dart';
import 'analytics_status_widget.dart'; // Add this import

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
  bool _isLoading = true;
  bool _hasData = false;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Initialize analytics provider
    _analyticsProvider = AnalyticsProvider();
    _checkAnalyticsData();
  }
  
  Future<void> _checkAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if we have team needs data (which should always be available)
      final teamNeeds = await _analyticsProvider.getTeamNeeds(year: widget.draftYear);
      
      // Check if positions distribution data is available
      final positionData = await _analyticsProvider.getPositionDistribution(
        team: 'All Teams',
      );
      
      setState(() {
        _isLoading = false;
        _hasData = teamNeeds.isNotEmpty && 
                   positionData.isNotEmpty && 
                   positionData.containsKey('total') && 
                   positionData['total'] > 0;
        _isInitialLoad = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasData = false;
        _isInitialLoad = false;
      });
    }
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
                        _checkAnalyticsData();
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
          
          // Show loading or no data message
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (!_hasData)
            Expanded(
              child: AnalyticsStatusWidget(
                onRetry: _checkAnalyticsData,
              ),
            )
          else
            // Normal content when data is available
            Expanded(
              child: Column(
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
                        const SizedBox(width: 12),
                        _buildTabButton('Advanced Insights', isDarkMode),
                      ],
                    ),
                  ),

                  // Tab content with shared provider
                  Expanded(
                    child: _buildTabContent(),
                  ),
                ],
              ),
            ),
        ],
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
      case 'Advanced Insights':
        return AdvancedInsightsTab(draftYear: widget.draftYear);
      default:
        return Center(
          child: Text(
            'Select a tab to view analytics',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
            ),
          ),
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