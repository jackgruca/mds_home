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

  // NFL divisions and conferences
  final Map<String, List<String>> _afcDivisions = {
    'AFC East': ['Buffalo Bills', 'Miami Dolphins', 'New England Patriots', 'New York Jets'],
    'AFC North': ['Baltimore Ravens', 'Cincinnati Bengals', 'Cleveland Browns', 'Pittsburgh Steelers'],
    'AFC South': ['Houston Texans', 'Indianapolis Colts', 'Jacksonville Jaguars', 'Tennessee Titans'],
    'AFC West': ['Denver Broncos', 'Kansas City Chiefs', 'Las Vegas Raiders', 'Los Angeles Chargers'],
  };
  
  final Map<String, List<String>> _nfcDivisions = {
    'NFC East': ['Dallas Cowboys', 'New York Giants', 'Philadelphia Eagles', 'Washington Commanders'],
    'NFC North': ['Chicago Bears', 'Detroit Lions', 'Green Bay Packers', 'Minnesota Vikings'],
    'NFC South': ['Atlanta Falcons', 'Carolina Panthers', 'New Orleans Saints', 'Tampa Bay Buccaneers'],
    'NFC West': ['Arizona Cardinals', 'Los Angeles Rams', 'San Francisco 49ers', 'Seattle Seahawks'],
  };

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    
    // Calculate team logo size based on screen size
    final double teamLogoSize = isSmallScreen ? 40.0 : 60.0;
    
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
            
            // Two-column conference layout
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AFC (left column)
                  Expanded(
                    child: Column(
                      children: [
                        // AFC header
                        Container(
                          color: Colors.red.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          width: double.infinity,
                          child: Text(
                            'AFC',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        // AFC divisions
                        Expanded(
                          child: ListView(
                            children: _afcDivisions.entries.map((entry) {
                              final String division = entry.key;
                              final List<String> teams = entry.value;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Division header
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    child: Text(
                                      division.substring(4), // Remove 'AFC ' prefix
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                  
                                  // Team row (all 4 teams in one row)
                                  Row(
                                    children: teams.map((team) {
                                      final isSelected = _selectedTeam == team;
                                      
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedTeam = team;
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.all(4.0),
                                            padding: const EdgeInsets.all(4.0),
                                            decoration: BoxDecoration(
                                              border: isSelected 
                                                ? Border.all(color: Colors.blue, width: 3.0) 
                                                : Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: teamLogoSize,
                                                  height: teamLogoSize,
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: NetworkImage(
                                                        'https://a.espncdn.com/i/teamlogos/nfl/500/${NFLTeamMappings.fullNameToAbbreviation[team]?.toLowerCase()}.png',
                                                      ),
                                                      fit: BoxFit.contain,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(height: 4.0),
                                                Text(
                                                  NFLTeamMappings.fullNameToAbbreviation[team] ?? team,
                                                  style: const TextStyle(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16.0),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Divider between conferences
                  const VerticalDivider(width: 1, thickness: 1),
                  
                  // NFC (right column)
                  Expanded(
                    child: Column(
                      children: [
                        // NFC header
                        Container(
                          color: Colors.blue.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          width: double.infinity,
                          child: Text(
                            'NFC',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        // NFC divisions
                        Expanded(
                          child: ListView(
                            children: _nfcDivisions.entries.map((entry) {
                              final String division = entry.key;
                              final List<String> teams = entry.value;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Division header
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                    child: Text(
                                      division.substring(4), // Remove 'NFC ' prefix
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                  
                                  // Team row (all 4 teams in one row)
                                  Row(
                                    children: teams.map((team) {
                                      final isSelected = _selectedTeam == team;
                                      
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedTeam = team;
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.all(4.0),
                                            padding: const EdgeInsets.all(4.0),
                                            decoration: BoxDecoration(
                                              border: isSelected 
                                                ? Border.all(color: Colors.blue, width: 3.0) 
                                                : Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: teamLogoSize,
                                                  height: teamLogoSize,
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: NetworkImage(
                                                        'https://a.espncdn.com/i/teamlogos/nfl/500/${NFLTeamMappings.fullNameToAbbreviation[team]?.toLowerCase()}.png',
                                                      ),
                                                      fit: BoxFit.contain,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(height: 4.0),
                                                Text(
                                                  NFLTeamMappings.fullNameToAbbreviation[team] ?? team,
                                                  style: const TextStyle(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16.0),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
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