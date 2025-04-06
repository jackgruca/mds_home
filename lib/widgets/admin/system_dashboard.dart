// New file: lib/widgets/admin/system_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/analytics_aggregation_service.dart';
import '../../services/cache_service.dart';

class SystemDashboard extends StatefulWidget {
  const SystemDashboard({super.key});

  @override
  _SystemDashboardState createState() => _SystemDashboardState();
}

class _SystemDashboardState extends State<SystemDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _systemStats = {};
  DateTime? _lastOptimizationTime;
  bool _optimizationSucceeded = false;
  
  @override
  void initState() {
    super.initState();
    _loadSystemStatus();
  }
  
  Future<void> _loadSystemStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load last optimization status
      final optDoc = await FirebaseFirestore.instance
          .collection('analytics_meta')
          .doc('last_optimized')
          .get();
          
      if (optDoc.exists) {
        final data = optDoc.data() as Map<String, dynamic>;
        _lastOptimizationTime = (data['timestamp'] as Timestamp).toDate();
        _optimizationSucceeded = data['success'] ?? false;
      }
      
      // Get system stats
      _systemStats = await _getSystemStats();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading system status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<Map<String, dynamic>> _getSystemStats() async {
    // Get collection counts
    final analytics = await FirebaseFirestore.instance.collection('analytics').count().get();
    final messages = await FirebaseFirestore.instance.collection('messages').count().get();
    final draftAnalytics = await FirebaseFirestore.instance.collection('draftAnalytics').count().get();
    
    return {
      'analytics_count': analytics.count,
      'messages_count': messages.count,
      'draft_analytics_count': draftAnalytics.count,
      'cache_size': CacheService.getCacheSizeEstimate(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSystemStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Optimization status card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Optimization Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Last optimization time
                          Row(
                            children: [
                              const Text('Last Run:'),
                              const Spacer(),
                              Text(
                                _lastOptimizationTime != null
                                    ? '${_lastOptimizationTime!.day}/${_lastOptimizationTime!.month}/${_lastOptimizationTime!.year} ${_lastOptimizationTime!.hour}:${_lastOptimizationTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Never',
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Success status
                          Row(
                            children: [
                              const Text('Status:'),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _optimizationSucceeded ? Colors.green.shade100 : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _optimizationSucceeded ? 'Success' : 'Failed',
                                  style: TextStyle(
                                    color: _optimizationSucceeded ? Colors.green.shade700 : Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          ElevatedButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Run Data Optimization'),
                                  content: const Text('This process may take several minutes to complete. Continue?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Continue'),
                                    ),
                                  ],
                                ),
                              ) ?? false;
                              
                              if (confirmed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Optimization started...')),
                                );
                                
                                try {
                                  await AnalyticsAggregationService.generateOptimizedStructures();
                                  await _loadSystemStatus();
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Optimization completed successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Optimization failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.speed),
                            label: const Text('Run Optimization Now'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // System stats
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'System Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildStatRow('Analytics Records', '${_systemStats['analytics_count'] ?? 0}'),
                          const SizedBox(height: 8),
                          _buildStatRow('Draft Analytics', '${_systemStats['draft_analytics_count'] ?? 0}'),
                          const SizedBox(height: 8),
                          _buildStatRow('User Messages', '${_systemStats['messages_count'] ?? 0}'),
                          const SizedBox(height: 8),
                          _buildStatRow('Cache Size', '${_systemStats['cache_size'] ?? 0} KB'),
                          
                          const SizedBox(height: 16),
                          
                          // Cache control button
                          OutlinedButton.icon(
                            onPressed: () async {
                              // Clear cache
                              CacheService.clearCache();
                              
                              // Reload stats
                              await _loadSystemStatus();
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cache cleared')),
                                );
                              }
                            },
                            icon: const Icon(Icons.cleaning_services),
                            label: const Text('Clear Cache'),
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
  
  Widget _buildStatRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}