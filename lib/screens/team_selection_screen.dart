import 'package:flutter/material.dart';
import '../models/team.dart'; // Import the team.dart file

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
  String _selectedYear = '2024';
  bool _enableTrading = false;
  bool _enableUserTradeProposals = false;
  bool _enableQBPremium = false;
  bool _showAnalytics = false;

  // Team abbreviations mapping
  final Map<String, String> teamAbbreviations = {
    "Arizona Cardinals": "ARI",
    "Atlanta Falcons": "ATL",
    "Baltimore Ravens": "BAL",
    "Buffalo Bills": "BUF",
    "Carolina Panthers": "CAR",
    "Chicago Bears": "CHI",
    "Cincinnati Bengals": "CIN",
    "Cleveland Browns": "CLE",
    "Dallas Cowboys": "DAL",
    "Denver Broncos": "DEN",
    "Detroit Lions": "DET",
    "Green Bay Packers": "GB",
    "Houston Texans": "HOU",
    "Indianapolis Colts": "IND",
    "Jacksonville Jaguars": "JAX",
    "Kansas City Chiefs": "KC",
    "Las Vegas Raiders": "LV",
    "Los Angeles Chargers": "LAC",
    "Los Angeles Rams": "LAR",
    "Miami Dolphins": "MIA",
    "Minnesota Vikings": "MIN",
    "New England Patriots": "NE",
    "New Orleans Saints": "NO",
    "New York Giants": "NYG",
    "New York Jets": "NYJ",
    "Philadelphia Eagles": "PHI",
    "Pittsburgh Steelers": "PIT",
    "San Francisco 49ers": "SF",
    "Seattle Seahawks": "SEA",
    "Tampa Bay Buccaneers": "TB",
    "Tennessee Titans": "TEN",
    "Washington Commanders": "WAS"
  };

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
    // Get the team abbreviation if a team is selected
    String teamAbbr = '';
    if (_selectedTeam != null && teamAbbreviations.containsKey(_selectedTeam)) {
      teamAbbr = teamAbbreviations[_selectedTeam]!;
    }
    
    debugPrint("Starting draft with parameters:");
    debugPrint("  Rounds: $_numberOfRounds");
    debugPrint("  Speed: $_speed");
    debugPrint("  Randomness: $_randomness");
    debugPrint("  Selected Team: $teamAbbr");
    debugPrint("  Draft Year: $_selectedYear");
    debugPrint("  Enable Trading: $_enableTrading");
    debugPrint("  Enable User Trade Proposals: $_enableUserTradeProposals");
    debugPrint("  Enable QB Premium: $_enableQBPremium");
    debugPrint("  Show Analytics: $_showAnalytics");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DraftApp(
          randomnessFactor: _randomness,
          numberOfRounds: _numberOfRounds,
          speedFactor: _speed,
          selectedTeam: teamAbbr,
          draftYear: _selectedYear,
          enableTrading: _enableTrading,
          enableUserTradeProposals: _enableUserTradeProposals,
          enableQBPremium: _enableQBPremium,
          showAnalytics: _showAnalytics,
        ),
      ),
    );
  }

  void _onTeamSelected(String teamName) {
    debugPrint("$teamName selected");
    setState(() {
      _selectedTeam = teamName;
    });
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
            // Team selection grid
            Expanded(
              flex: 3, // Take up more space
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: 32,
                itemBuilder: (context, index) {
                  return TeamSelector( // Changed from Team to TeamSelector
                    teamName: teams[index],
                    onTeamSelected: _onTeamSelected,
                  );
                },
              ),
            ),
            // Draft settings section
            Expanded(
              flex: 2, // Take up less space
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Draft Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // First row: Rounds and Year
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Number of Rounds
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Rounds:'),
                                DropdownButton<int>(
                                  value: _numberOfRounds,
                                  isExpanded: true,
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
                          ),
                          const SizedBox(width: 16),
                          // Draft Year
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Draft Year:'),
                                DropdownButton<String>(
                                  value: _selectedYear,
                                  isExpanded: true,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedYear = newValue ?? '2024';
                                    });
                                  },
                                  items: ['2023', '2024', '2025']
                                      .map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Speed slider
                      Row(
                        children: [
                          const Text('Speed:'),
                          Expanded(
                            child: Slider(
                              value: _speed,
                              min: 0.5,
                              max: 2.0,
                              divisions: 3,
                              label: _speed == 0.5 ? 'Slow' : 
                                     _speed == 1.0 ? 'Normal' :
                                     _speed == 1.5 ? 'Fast' : 'Very Fast',
                              onChanged: (value) {
                                setState(() {
                                  _speed = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      // Randomness slider
                      Row(
                        children: [
                          const Text('Randomness:'),
                          Expanded(
                            child: Slider(
                              value: _randomness,
                              min: 0.0,
                              max: 1.0,
                              divisions: 5,
                              label: _randomness == 0.0 ? 'None' :
                                     _randomness == 0.2 ? 'Low' :
                                     _randomness == 0.4 ? 'Medium' :
                                     _randomness == 0.6 ? 'High' :
                                     _randomness == 0.8 ? 'Very High' : 'Chaotic',
                              onChanged: (value) {
                                setState(() {
                                  _randomness = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      // Advanced settings row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Trading
                          Row(
                            children: [
                              Checkbox(
                                value: _enableTrading,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _enableTrading = value ?? false;
                                  });
                                },
                              ),
                              const Text('AI Trading'),
                            ],
                          ),
                          // User Trade Proposals
                          Row(
                            children: [
                              Checkbox(
                                value: _enableUserTradeProposals,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _enableUserTradeProposals = value ?? false;
                                  });
                                },
                              ),
                              const Text('User Trades'),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // QB Premium
                          Row(
                            children: [
                              Checkbox(
                                value: _enableQBPremium,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _enableQBPremium = value ?? false;
                                  });
                                },
                              ),
                              const Text('QB Premium'),
                            ],
                          ),
                          // Analytics
                          Row(
                            children: [
                              Checkbox(
                                value: _showAnalytics,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _showAnalytics = value ?? false;
                                  });
                                },
                              ),
                              const Text('Show Analytics'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            // Start Draft Button
            ElevatedButton.icon(
              onPressed: _startDraft,
              icon: const Icon(Icons.sports_football),
              label: const Text('Start Draft'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}