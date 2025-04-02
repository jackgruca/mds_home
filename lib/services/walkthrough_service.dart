// lib/services/walkthrough_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalkthroughService {
  static const String _hasSeenWalkthroughKey = 'has_seen_walkthrough';
  static const String _hasSeenDraftWalkthroughKey = 'has_seen_draft_walkthrough';
  
  // Singleton pattern
  static final WalkthroughService _instance = WalkthroughService._internal();
  factory WalkthroughService() => _instance;
  WalkthroughService._internal();
  
  // State
  bool _initialized = false;
  bool _hasSeenWalkthrough = false;
  bool _hasSeenDraftWalkthrough = false;
  
  // Getters
  bool get hasSeenWalkthrough => _hasSeenWalkthrough;
  bool get hasSeenDraftWalkthrough => _hasSeenDraftWalkthrough;
  
  // Initialize from SharedPreferences
  Future<void> initialize() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _hasSeenWalkthrough = prefs.getBool(_hasSeenWalkthroughKey) ?? false;
    _hasSeenDraftWalkthrough = prefs.getBool(_hasSeenDraftWalkthroughKey) ?? false;
    _initialized = true;
  }
  
  // Mark walkthrough as seen
  Future<void> markWalkthroughAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenWalkthroughKey, true);
    _hasSeenWalkthrough = true;
  }
  
  // Mark draft walkthrough as seen
  Future<void> markDraftWalkthroughAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenDraftWalkthroughKey, true);
    _hasSeenDraftWalkthrough = true;
  }
  
  // Reset for testing
  Future<void> resetWalkthrough() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenWalkthroughKey, false);
    await prefs.setBool(_hasSeenDraftWalkthroughKey, false);
    _hasSeenWalkthrough = false;
    _hasSeenDraftWalkthrough = false;
  }
}