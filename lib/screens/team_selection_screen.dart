// lib/screens/team_selection_screen.dart
import 'package:flutter/material.dart';
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
  double _speed = 3.0;
  double _randomness = 0.5;
  String? _selectedTeam;

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
            // Team selection prompt
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_football, color: Colors.blue.shade700),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      _selectedTeam != null 
                        ? 'You will control the $_selectedTeam' 
                        : 'Select a team to control in the draft',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Team grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: NFLTeams.allTeams.length,
                itemBuilder: (context, index) {
                  final team = NFLTeams.allTeams[index];
                  final isSelected = _selectedTeam == team;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTeam = team;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: isSelected 
                          ? Border.all(color: Colors.blue, width: 3.0) 
                          : null,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TeamSelector(
                        teamName: team,
                        onTeamSelected: _onTeamSelected,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Draft settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Draft Settings',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Speed:'),
                        Expanded(
                          child: Slider(
                            value: _speed,
                            min: 1.0,
                            max: 5.0,
                            divisions: 4,
                            label: '${_speed.toInt()}',
                            onChanged: (value) {
                              setState(() {
                                _speed = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text('${_speed.toInt()}', textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Randomness:'),
                        Expanded(
                          child: Slider(
                            value: _randomness * 5,
                            min: 1.0,
                            max: 5.0,
                            divisions: 4,
                            label: '${(_randomness * 5).toInt()}',
                            onChanged: (value) {
                              setState(() {
                                _randomness = value / 5;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text('${(_randomness * 5).toInt()}', textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            
            // Start Draft button
            ElevatedButton.icon(
              onPressed: _selectedTeam != null ? _startDraft : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Draft'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18.0),
              ),
            ),
          ],
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

  // In team_selection_screen.dart
  void _startDraft() {
    // Debug what's happening
    debugPrint("Selected team (full name): $_selectedTeam");
    String? teamAbbr = _selectedTeam != null 
        ? NFLTeamMappings.fullNameToAbbreviation[_selectedTeam]
        : null;
    debugPrint("Selected team (abbreviation): $teamAbbr");
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DraftApp(
          randomnessFactor: _randomness,
          numberOfRounds: _numberOfRounds,
          speedFactor: _speed,
          selectedTeam: teamAbbr, // This should be BUF, not Buffalo Bills
        ),
      ),
    );
  }
}