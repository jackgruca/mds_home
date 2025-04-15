// lib/widgets/analytics/community_analytics_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/analytics_api_service.dart';
import '../../services/analytics_cache_manager.dart';
import '../../utils/constants.dart';
import '../../utils/team_logo_utils.dart';
import 'team_draft_patterns_tab.dart';
import 'player_draft_analysis_tab.dart';
import 'draft_trend_insights_tab.dart';
import 'advanced_insights_tab.dart';
import '../../providers/analytics_provider.dart';

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
  
  // Tab control
  String _selectedTab = 'Team Draft Patterns';
  late PageController _pageController;
  
  // Loading states
  bool _isInitialLoad = true;
  bool _isRefreshing = false;
  final Map<String, bool> _sectionLoading = {
    'teamPatterns': false,
    'playerAnalysis': false,
    'trends': false,
    'advanced': false,
  };
  
  // Data states
  DateTime? _lastUpdated;
  Map<String, dynamic> _metadataCache = {};
  
  // Auto-refresh timer
  Timer? _autoRefreshTimer;
  bool _autoRefreshEnabled = false;
  
  // Scroll controller for main content
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadInitialData();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _autoRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAutoRefresh(bool value) {
    setState(() {
      _autoRefreshEnabled = value;
    });
    
    if (_autoRefreshEnabled) {
      // Start auto-refresh timer (every 5 minutes)
      _autoRefreshTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _refreshData(silent: true),
      );
    } else {
      // Cancel auto-refresh timer
      _autoRefreshTimer?.cancel();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoad = true;
    });

    try {
      // Get analytics metadata first (lightweight call)
      final metadata = await AnalyticsApiService.getAnalyticsMetadata();
      
      setState(() {
        _metadataCache = metadata;
        if (metadata.containsKey('lastUpdated')) {
          _lastUpdated = metadata['lastUpdated']?.toDate();
        }
        _isInitialLoad = false;
      });
      
      // Load data for the first visible tab
      _loadTabData(_selectedTab);
    } catch (e) {
      debugPrint('Error in initial data load: $e');
      setState(() {
        _isInitialLoad = false;
      });
    }
  }
  
  Future<void> _refreshData({bool silent = false}) async {
    if (_isRefreshing && silent) return; // Prevent simultaneous refreshes
    
    if (!silent) {
      setState(() {
        _isRefreshing = true;
      });
    }
    
    try {
      // Clear cache to force fresh data
      AnalyticsCacheManager.clearCache();
      
      // Get fresh metadata
      final metadata = await AnalyticsApiService.getAnalyticsMetadata();
      
      // Only update UI if the data has actually changed
      final newLastUpdated = metadata['lastUpdated']?.toDate();
      final hasNewData = newLastUpdated != null && 
          (_lastUpdated == null || newLastUpdated.isAfter(_lastUpdated!));
      
      if (hasNewData) {
        setState(() {
          _metadataCache = metadata;
          _lastUpdated = newLastUpdated;
        });
        
        // Reload data for the current tab
        await _loadTabData(_selectedTab);
      }
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      if (!silent) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
  
  Future<void> _loadTabData(String tabName) async {
    // Get loading key based on tab name
    final loadingKey = _getLoadingKeyForTab(tabName);
    
    // Check if already loading
    if (_sectionLoading[loadingKey] == true) return;
    
    setState(() {
      _sectionLoading[loadingKey] = true;
    });
    
    try {
      // Each tab has its own data needs
      switch (tabName) {
        case 'Team Draft Patterns':
          // Defer loading to the tab component
          break;
        case 'Player Draft Analysis':
          // Defer loading to the tab component
          break;
        case 'Draft Trend Insights':
          // Defer loading to the tab component
          break;
        case 'Advanced Insights':
          // Defer loading to the tab component
          break;
      }
    } catch (e) {
      debugPrint('Error loading data for tab $tabName: $e');
    } finally {
      setState(() {
        _sectionLoading[loadingKey] = false;
      });
    }
  }
  
  String _getLoadingKeyForTab(String tabName) {
    switch (tabName) {
      case 'Team Draft Patterns': return 'teamPatterns';
      case 'Player Draft Analysis': return 'playerAnalysis'; 
      case 'Draft Trend Insights': return 'trends';
      case 'Advanced Insights': return 'advanced';
      default: return 'teamPatterns';
    }
  }
  
  void _switchTab(String tabName, int index) {
    if (_selectedTab == tabName) return;
    
    setState(() {
      _selectedTab = tabName;
    });
    
    // Animate to the selected tab
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    // Load data for the new tab if needed
    _loadTabData(tabName);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => AnalyticsProvider(),
      child: RefreshIndicator(
        onRefresh: () => _refreshData(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data freshness indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: _buildDataFreshnessIndicator(),
            ),
            
            // Tab selector
            _buildTabSelector(isDarkMode),
            
            // Main content
            _isInitialLoad
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _selectedTab = _getTabNameForIndex(index);
                        });
                        _loadTabData(_selectedTab);
                      },
                      children: [
                        TeamDraftPatternsTab(
                          initialTeam: widget.userTeam,
                          allTeams: widget.allTeams, 
                          draftYear: widget.draftYear,
                        ),
                        PlayerDraftAnalysisTab(
                          draftYear: widget.draftYear,
                        ),
                        DraftTrendInsightsTab(
                          draftYear: widget.draftYear,
                        ),
                        AdvancedInsightsTab(
                          draftYear: widget.draftYear,
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataFreshnessIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              _isRefreshing ? Icons.sync : Icons.access_time,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              _lastUpdated != null 
                  ? 'Data updated: ${_formatDate(_lastUpdated!)}'
                  : 'Data freshness: Unknown',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Auto-refresh toggle
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Auto-refresh',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: _autoRefreshEnabled,
                    onChanged: _toggleAutoRefresh,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            // Manual refresh button
            IconButton(
              icon: Icon(
                _isRefreshing ? Icons.sync : Icons.refresh_outlined,
                size: 18,
                color: _isRefreshing ? Colors.blue : null,
              ),
              onPressed: _isRefreshing ? null : () => _refreshData(),
              tooltip: _isRefreshing ? 'Refreshing...' : 'Refresh data',
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTabSelector(bool isDarkMode) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          _buildTabButton('Team Draft Patterns', 0, isDarkMode),
          const SizedBox(width: 12),
          _buildTabButton('Player Draft Analysis', 1, isDarkMode),
          const SizedBox(width: 12),
          _buildTabButton('Draft Trend Insights', 2, isDarkMode),
          const SizedBox(width: 12),
          _buildTabButton('Advanced Insights', 3, isDarkMode),
        ],
      ),
    );
  }
  
  Widget _buildTabButton(String tabName, int index, bool isDarkMode) {
    final isSelected = _selectedTab == tabName;
    final isLoading = _sectionLoading[_getLoadingKeyForTab(tabName)] == true;
    
    return Stack(
      children: [
        ElevatedButton(
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
          onPressed: () => _switchTab(tabName, index),
          child: Text(tabName),
        ),
        if (isLoading)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
  
  String _getTabNameForIndex(int index) {
    switch (index) {
      case 0: return 'Team Draft Patterns';
      case 1: return 'Player Draft Analysis';
      case 2: return 'Draft Trend Insights';
      case 3: return 'Advanced Insights';
      default: return 'Team Draft Patterns';
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${date.month}/${date.day}/${date.year} at '
          '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  // Optimized loading handler for all tab types
  Widget _buildProgressiveLoadingIndicator(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  // Error state widget
  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  // Empty state widget
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _refreshData(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Data'),
          ),
        ],
      ),
    );
  }

  // Keep widget state alive while switching tabs
  @override
  bool get wantKeepAlive => true;
}

// Helper class for animation effects
class _SizeAnimation extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  
  const _SizeAnimation({
    required this.animation,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}