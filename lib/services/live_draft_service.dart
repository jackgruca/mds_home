// lib/services/live_draft_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class LiveDraftService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference _draftRef;
  final StreamController<Map<String, dynamic>> _pickUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get pickUpdates => _pickUpdateController.stream;
  
  LiveDraftService({int year = 2025}) {
    debugPrint('Initializing LiveDraftService for year $year');
    _draftRef = _database.ref('draft_$year');
    debugPrint('Database reference set to: ${_draftRef.path}');
  }
  
  void startListening() {
    debugPrint('Starting to listen for live picks...');
    
    _draftRef.child('live_picks').onChildAdded.listen(
      (event) {
        debugPrint('Child added event received: ${event.snapshot.key}');
        
        if (event.snapshot.value != null) {
          try {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            debugPrint('Data received: $data');
            
            if (data['pickNumber'] != 0) {
              _pickUpdateController.add(data);
            }
          } catch (e) {
            debugPrint('Error processing pick update: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('Error in onChildAdded listener: $error');
      },
    );
  }
  
  Future<List<Map<String, dynamic>>> fetchAllPicks() async {
    try {
      debugPrint('Fetching all picks from database...');
      final snapshot = await _draftRef.child('live_picks').get();
      
      debugPrint('Snapshot exists: ${snapshot.exists}');
      debugPrint('Snapshot value: ${snapshot.value}');
      
      if (snapshot.exists) {
        final Map<dynamic, dynamic> picksMap = snapshot.value as Map<dynamic, dynamic>;
        return picksMap.values
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((pick) => pick['pickNumber'] != 0)
            .toList()
          ..sort((a, b) => (a['pickNumber'] as int).compareTo(b['pickNumber'] as int));
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching picks: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    return [];
  }
  
  void dispose() {
    _pickUpdateController.close();
  }
}