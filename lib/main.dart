import 'package:flutter/material.dart';
import 'screens/draft_order_page.dart';
import 'screens/available_players_page.dart';
import 'screens/draft_app.dart';

void main() {
  runApp(MaterialApp(
    title: 'NFL Draft App',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: DraftApp(),
  ));
}
