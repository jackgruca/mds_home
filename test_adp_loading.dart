// Test script to verify ADP data loading
import 'package:flutter/services.dart';
import 'dart:io';

void main() async {
  print('Testing ADP CSV file access...');
  
  try {
    final csvPath = 'data_processing/assets/data/adp/metadata.csv';
    final csvString = await rootBundle.loadString(csvPath);
    print('✅ Successfully loaded metadata.csv');
    print('Content: ${csvString.substring(0, 100)}...');
  } catch (e) {
    print('❌ Failed to load metadata.csv: $e');
  }
  
  try {
    final csvPath = 'data_processing/assets/data/adp/adp_analysis_ppr.csv';
    final csvString = await rootBundle.loadString(csvPath);
    print('✅ Successfully loaded adp_analysis_ppr.csv');
    print('Size: ${csvString.length} characters');
    print('First line: ${csvString.split('\n')[0]}');
  } catch (e) {
    print('❌ Failed to load adp_analysis_ppr.csv: $e');
  }
}