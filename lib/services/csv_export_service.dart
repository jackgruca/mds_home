// lib/services/csv_export_service.dart
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

class CsvExportService {
  /// Export data as a CSV file
  static void exportToCsv({
    required List<List<dynamic>> data,
    required String filename,
  }) {
    if (!kIsWeb) {
      debugPrint('CSV export is currently only supported on web platform');
      return;
    }
    
    try {
      // Convert to CSV format
      String csv = const ListToCsvConverter().convert(data);
      
      // Prepare the file for download
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Clean up
      html.Url.revokeObjectUrl(url);
      
      debugPrint('CSV export successful: $filename');
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
    }
  }
  /// Generate a template CSV file
  static void generateTemplate({
    required List<List<dynamic>> templateData,
    required String filename,
  }) {
    exportToCsv(data: templateData, filename: filename);
  }

  static bool get isWebPlatform => kIsWeb;

static void showPlatformWarning(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('CSV import/export is currently only supported on web platforms'),
      duration: Duration(seconds: 3),
    ),
  );
}

}