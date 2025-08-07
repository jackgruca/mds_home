// Simple test screen to debug ADP loading
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/common/custom_app_bar.dart';

class ADPTestScreen extends StatefulWidget {
  const ADPTestScreen({super.key});

  @override
  State<ADPTestScreen> createState() => _ADPTestScreenState();
}

class _ADPTestScreenState extends State<ADPTestScreen> {
  String _status = 'Starting test...';
  
  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    setState(() => _status = 'Testing asset loading...');
    
    try {
      // Test loading metadata.csv
      await rootBundle.loadString('data_processing/assets/data/adp/metadata.csv');
      setState(() => _status = 'metadata.csv: ✅ Success\n');
      
      // Test loading main ADP file
      final csvString = await rootBundle.loadString('data_processing/assets/data/adp/adp_analysis_ppr.csv');
      final lines = csvString.split('\n');
      
      setState(() => _status = _status + 'adp_analysis_ppr.csv: ✅ Success\n'
          'Size: ${csvString.length} characters\n'
          'Lines: ${lines.length}\n'
          'First data line: ${lines.length > 1 ? lines[1] : 'N/A'}');
      
    } catch (e) {
      setState(() => _status = _status + '❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: const Text('ADP Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADP Asset Loading Test',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}