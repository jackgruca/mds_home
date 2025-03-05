import 'package:flutter/material.dart';
import 'package:mds_home/models/team.dart';
import '../models/team.dart';
import '../utils/constants.dart';

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
  String? _selectedTeam;

  List<String> teams = NFLTeams.allTeams;

  void _startDraft() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DraftApp(
          randomnessFactor: _randomness,
          numberOfRounds: _numberOfRounds,
          speedFactor: _speed,
          selectedTeam: _selectedTeam,
        ),
      ),
    );
  }

  void _onTeamSelected(String teamName) {
    setState(() {
      _selectedTeam = teamName;
    });
    debugPrint("$teamName selected");
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
                  return TeamSelector(
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
