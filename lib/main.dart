import 'package:flutter/material.dart';
import 'screens/team_selection_screen.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'NFL Draft App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TeamSelectionScreen(),
    ),
  );
}
