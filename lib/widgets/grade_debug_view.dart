// Add this to a new file: lib/widgets/grade_debug_view.dart
import 'package:flutter/material.dart';

class GradeDebugView extends StatelessWidget {
  final Map<String, dynamic> gradeInfo;
  final bool isTeamGrade;

  const GradeDebugView({
    super.key,
    required this.gradeInfo,
    this.isTeamGrade = false,
  });

  @override
  Widget build(BuildContext context) {
    // Extract debug log from factors
    final factors = gradeInfo['factors'] as Map<String, dynamic>;
    final debugLog = factors['debugLog'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeamGrade ? 'Team Grade Details' : 'Pick Grade Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              // Copy to clipboard functionality
              // You can implement this if needed
            },
            tooltip: 'Copy debug info',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final Grade: ${gradeInfo['letterGrade']}',
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Score: ${(gradeInfo['value'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    if (gradeInfo.containsKey('description'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Description: ${gradeInfo['description']}',
                          style: const TextStyle(fontSize: 14.0),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Debug Information:',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: Text(
                    debugLog,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}