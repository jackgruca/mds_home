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
  bool _isDataAvailable = false;
  bool _isCheckingData = true;

  @override
  void initState() {
    super.initState();
    // Initialize analytics provider
    _analyticsProvider = AnalyticsProvider();
    
    // Check if data is available
    _checkDataAvailability();
  }
  
  Future<void> _checkDataAvailability() async {
    setState(() {
      _isCheckingData = true;
    });
    
    try {
      // A simple check to see if we have any draft analytics data
      // This is a lightweight way to determine if we should show the tabs
      await Future.delayed(const Duration(milliseconds: 500)); // Allow UI to render first
      setState(() {
        _isDataAvailable = true; // Assume data is available, the individual tabs will handle empty states
        _isCheckingData = false;
      });
    } catch (e) {
      debugPrint('Error checking data availability: $e');
      setState(() {
        _isDataAvailable = false;
        _isCheckingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isCheckingData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (!_isDataAvailable) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
            ),
            const SizedBox(height: 16),
            const Text(
              'Community Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Analytics data is currently being processed.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Draft data is still being collected from users.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkDataAvailability,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
            ),
          ],
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _analyticsProvider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data freshness indicator (only if we have data)
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
                          : 'Using direct analytics calculations',
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
                        // Clear the analytics cache
                        _analyticsProvider.clearCache();
                        
                        // Force reload by setting state
                        setState(() {
                          // Force state refresh
                        });
                        
                        // Force reload of the current tab
                        _forceReloadCurrentTab();
                        
                        // Show confirmation to user
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Analytics cache cleared, reloading data...'),
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
  
  // Force reload of the current tab's data (simplified version)
  void _forceReloadCurrentTab() {
    // This is a basic implementation that just triggers a state update
    // The actual tabs should handle their own data loading via their init/didUpdateWidget methods
    setState(() {
      // Update state to force rebuild
    });
  }

  // Build tab content based on selected tab
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

  // Helper method to format a date
  String _formatDate(DateTime date) {
    // Format: Apr 8, 2025
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  // Build a tab button with appropriate styling
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