// lib/screens/admin_analytics_screen.dart
import 'package:flutter/material.dart';
import '../services/optimized_analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/admin/analytics_aggregation.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  _AdminAnalyticsScreenState createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _adminStats = {};
  List<Map<String, dynamic>> _weeklyTrend = [];
  List<Map<String, dynamic>> _analyticsList = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAdminStats();
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_hasMoreData && !_isLoadingMore) {
        _loadMoreAnalytics();
      }
    }
  }

  Future<void> _loadAdminStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load daily stats
      final dailyStats = await OptimizedAnalyticsService.getDailyUsage();
      
      // Load weekly trend
      final weeklyTrend = await OptimizedAnalyticsService.getWeeklyTrend();
      
      // Load initial analytics data
      final analyticsList = await OptimizedAnalyticsService.getPaginatedAnalytics(
        metric: 'pageViews',
        limit: 10,
      );
      
      if (analyticsList.isNotEmpty) {
        _lastDocument = await FirebaseFirestore.instance
            .collection('analytics')
            .doc(analyticsList.last['id'])
            .get();
      }
      
      setState(() {
        _adminStats = dailyStats;
        _weeklyTrend = weeklyTrend;
        _analyticsList = analyticsList;
        _hasMoreData = analyticsList.length == 10;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading admin stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadMoreAnalytics() async {
    if (!_hasMoreData || _isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final moreAnalytics = await OptimizedAnalyticsService.getPaginatedAnalytics(
        metric: 'pageViews',
        limit: 10,
        lastDocument: _lastDocument,
      );
      
      if (moreAnalytics.isNotEmpty) {
        _lastDocument = await FirebaseFirestore.instance
            .collection('analytics')
            .doc(moreAnalytics.last['id'])
            .get();
            
        setState(() {
          _analyticsList.addAll(moreAnalytics);
          _hasMoreData = moreAnalytics.length == 10;
        });
      } else {
        setState(() {
          _hasMoreData = false;
        });
      }
    } catch (e) {
      print('Error loading more analytics: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Stats Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Today\'s Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.visibility,
                          title: 'Page Views',
                          value: _adminStats['pageViews']?.toString() ?? '0',
                        ),
                        _buildStatItem(
                          icon: Icons.person,
                          title: 'Unique Users',
                          value: _adminStats['uniqueUsers']?.toString() ?? '0',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Analytics List
            const Text(
              'Recent Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _analyticsList.length + (_hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _analyticsList.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final item = _analyticsList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(item['date'] ?? 'Unknown date'),
                    subtitle: Text('Views: ${item['pageViews'] ?? 0}'),
                    trailing: Text('Users: ${item['uniqueUsers'] ?? 0}'),
                  ),
                );
              },
            ),
            // Add this section for data aggregation
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics Data Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tools to optimize analytics data storage and retrieval',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Aggregate Historical Data'),
                          content: const Text('This will process the last 30 days of analytics data. This operation may take some time.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Proceed'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        // Show loading indicator
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Aggregating data... This may take some time.'))
                        );
                        
                        // Run the aggregation
                        await AnalyticsAggregation.aggregateHistoricalData(30);
                        
                        // Show completion message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Historical data aggregation complete!'))
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('Aggregate Historical Analytics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last aggregation: Never',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}