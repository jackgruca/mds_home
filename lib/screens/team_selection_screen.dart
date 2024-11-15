import 'package:flutter/material.dart';
import 'package:mds_home/models/team.dart';

import 'draft_overview_screen.dart';

class TeamSelectionScreen extends StatefulWidget {
  const TeamSelectionScreen({super.key});

  @override
  TeamSelectionScreenState createState() => TeamSelectionScreenState();
}

class TeamSelectionScreenState extends State<TeamSelectionScreen> {
  int _numberOfRounds = 1;
  double _speed = 1.0;
  double _randomness = 0.5;

  List<String> teams = [
    "Arizona Cardinals",
    "Atlanta Falcons",
    "Baltimore Ravens",
    "Buffalo Bills",
    "Carolina Panthers",
    "Chicago Bears",
    "Cincinnati Bengals",
    "Cleveland Browns",
    "Dallas Cowboys",
    "Denver Broncos",
    "Detroit Lions",
    "Green Bay Packers",
    "Houston Texans",
    "Indianapolis Colts",
    "Jacksonville Jaguars",
    "Kansas City Chiefs",
    "Las Vegas Raiders",
    "Los Angeles Chargers",
    "Los Angeles Rams",
    "Miami Dolphins",
    "Minnesota Vikings",
    "New England Patriots",
    "New Orleans Saints",
    "New York Giants",
    "New York Jets",
    "Philadelphia Eagles",
    "Pittsburgh Steelers",
    "San Francisco 49ers",
    "Seattle Seahawks",
    "Tampa Bay Buccaneers",
    "Tennessee Titans",
    "Washington Commanders"
  ];

  void _startDraft() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DraftApp()),
    );
  }

  void _onTeamSelected(String teamName) {
    debugPrint("$teamName selected");

    // Maybe you want to save the team that is selected as a variable? @Gruca
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFL Draft Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: 32,
                itemBuilder: (context, index) {
                  return Team(
                    teamName: teams[index],
                    onTeamSelected: _onTeamSelected,
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Number of Rounds:'),
                DropdownButton<int>(
                  value: _numberOfRounds,
                  onChanged: (int? newValue) {
                    setState(() {
                      _numberOfRounds = newValue ?? 1;
                    });
                  },
                  items: List.generate(7, (index) => index + 1)
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Speed:'),
                Slider(
                  value: _speed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 3,
                  label: '$_speed',
                  onChanged: (value) {
                    setState(() {
                      _speed = value;
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Randomness:'),
                Slider(
                  value: _randomness,
                  min: 0.0,
                  max: 1.0,
                  divisions: 5,
                  label: '$_randomness',
                  onChanged: (value) {
                    setState(() {
                      _randomness = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _startDraft,
              child: const Text('Start Draft'),
            ),
          ],
        ),
      ),
    );
  }
}
