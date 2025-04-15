// Add to lib/widgets/analytics/analytics_freshness_indicator.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/analytics_coordinator.dart';

class AnalyticsFreshnessIndicator extends StatelessWidget {
  final Function() onRefresh;

  const AnalyticsFreshnessIndicator({
    super.key,
    required this.onRefresh,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: AnalyticsCoordinator.getProcessingStatus(),
      builder: (context, snapshot) {
        final lastUpdated = snapshot.data?['lastUpdated'];
        final inProgress = snapshot.data?['inProgress'] == true;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  inProgress ? Icons.sync : Icons.access_time,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  lastUpdated != null 
                      ? 'Data updated: ${_formatTimestamp(lastUpdated)}'
                      : 'Data freshness: Unknown',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                inProgress ? Icons.refresh : Icons.refresh_outlined,
                size: 18,
                color: inProgress ? Colors.blue : null,
              ),
              onPressed: inProgress ? null : onRefresh,
              tooltip: inProgress ? 'Update in progress' : 'Refresh data',
            ),
          ],
        );
      },
    );
  }
  
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}