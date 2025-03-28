// lib/services/csv_import_service.dart
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'dart:async';

import 'package:flutter/material.dart';


class CsvImportService {
  /// Import data from a CSV file
  static Future<List<List<dynamic>>?> importFromCsv() async {
    if (!kIsWeb) {
      debugPrint('CSV import is currently only supported on web platform');
      return null;
    }
    
    try {
      // Create a file input element
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = '.csv';
      uploadInput.click();
      
      // Wait for file selection
      final completer = Completer<List<List<dynamic>>?>();
      
      uploadInput.onChange.listen((event) {
        final files = uploadInput.files;
        if (files == null || files.isEmpty) {
          completer.complete(null);
          return;
        }
        
        final file = files[0];
        final reader = html.FileReader();
        
        reader.onLoad.listen((event) {
          final String content = reader.result as String;
          
          // Parse CSV
          final List<List<dynamic>> data = const CsvToListConverter().convert(
            content,
            eol: '\n',
            fieldDelimiter: ',',
          );
          
          completer.complete(data);
        });
        
        reader.onError.listen((event) {
          debugPrint('Error reading file: ${reader.error}');
          completer.complete(null);
        });
        
        reader.readAsText(file);
      });
      
      return await completer.future;
    } catch (e) {
      debugPrint('Error importing CSV: $e');
      return null;
    }
  }
  
  /// Validate imported team needs data format
  static bool validateTeamNeedsFormat(List<List<dynamic>> data) {
    if (data.isEmpty) return false;
    
    // Check header row
    final header = data[0];
    if (header.length < 3 || 
        !header.contains('TEAM') && !header.contains('Team')) {
      return false;
    }
    
    // Check at least one data row
    if (data.length < 2) return false;
    
    return true;
  }
  
  /// Validate imported player rankings format
  static bool validatePlayerRankingsFormat(List<List<dynamic>> data) {
    if (data.isEmpty) return false;
    
    // Check header row
    final header = data[0];
    if (header.length < 3 || 
        !header.contains('NAME') && !header.contains('Name') ||
        !header.contains('POSITION') && !header.contains('Position')) {
      return false;
    }
    
    // Check at least one data row
    if (data.length < 2) return false;
    
    return true;
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