// lib/services/tutorial_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Manages the app tutorial and walkthrough experience
class TutorialService {
  /// Check if user has seen the main app tutorial
  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.kHasSeenTutorial) ?? false;
  }
  
  /// Mark the main tutorial as seen
  static Future<void> markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.kHasSeenTutorial, true);
  }
  
  /// Reset the tutorial state (for testing or user preference)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.kHasSeenTutorial, false);
  }
  
  /// Check if the user has seen a specific feature tutorial
  static Future<bool> hasSeenFeatureTutorial(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${StorageKeys.kHasSeenFeatureTutorial}$featureId') ?? false;
  }
  
  /// Mark a specific feature tutorial as seen
  static Future<void> markFeatureTutorialAsSeen(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${StorageKeys.kHasSeenFeatureTutorial}$featureId', true);
  }
  
  /// Reset a specific feature tutorial
  static Future<void> resetFeatureTutorial(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${StorageKeys.kHasSeenFeatureTutorial}$featureId', false);
  }
}

/// Represents a single tutorial step
class TutorialStep {
  final String title;
  final String description;
  final IconData? icon;
  final GlobalKey targetKey;

  TutorialStep({
    required this.title,
    required this.description,
    required this.targetKey,
    this.icon,
  });
}