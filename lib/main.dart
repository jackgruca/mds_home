import 'package:flutter/material.dart';
import 'screens/team_selection_screen.dart';

import 'package:flutter/foundation.dart';

void main() {
  // Turn on debug output for the app
  if (kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        print(message);
      }
    };
  }
  
  runApp(
    MaterialApp(
      title: 'NFL Draft App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TeamSelectionScreen(),
    ),
  );
}