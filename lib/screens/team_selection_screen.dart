// lib/screens/team_selection_screen.dart
import 'package:flutter/material.dart';
import '../models/team.dart';
import '../utils/constants.dart';
import 'draft_overview_screen.dart';
import 'draft_settings_screen.dart';
import 'package:provider/provider.dart';
import '../utils/theme_manager.dart';

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

  final bool _enableTrading = true;
  final bool _enableUserTradeProposals = true;
  final bool _enableQBPremium = true;
  final bool _showAnalytics = true;

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

  void _openDraftSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DraftSettingsScreen(
          numberOfRounds: _numberOfRounds,
          randomnessFactor: _randomness,
          draftSpeed: _speed,
          userTeam: _selectedTeam,
          // Default values for new settings
          enableTrading: true,
          enableUserTradeProposals: true,
          enableQBPremium: true,
          showAnalytics: true,
          onSettingsSaved: (settings) {
            // Update settings when saved
            setState(() {
              _numberOfRounds = settings['numberOfRounds'];
              _randomness = settings['randomnessFactor'];
              _speed = settings['draftSpeed'];
              // Store the other settings to be passed to the draft screen
              // These might require you to update your DraftApp constructor to accept them
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    
    // Calculate team logo size based on screen size
    final double teamLogoSize = isSmallScreen ? 30.0 : 40.0;
    
    // Define theme colors
    const Color afcColor = Color(0xFFD50A0A);  // Dark red
    const Color nfcColor = Color(0xFF002244);  // Dark navy
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFL Draft Setup'),
        actions: [
          // Theme toggle button
          Consumer<ThemeManager>(
            builder: (context, themeManager, _) => IconButton(
              icon: Icon(
                themeManager.themeMode == ThemeMode.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              tooltip: themeManager.themeMode == ThemeMode.light
                  ? 'Switch to Dark Mode'
                  : 'Switch to Light Mode',
              onPressed: () {
                themeManager.toggleTheme();
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Team selection prompt
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Reduced vertical padding
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_football, color: Colors.blue.shade700, size: 18), // Smaller icon
                  const SizedBox(width: 12.0), // Less spacing
                  Expanded(
                    child: Text(
                      _selectedTeam != null 
                        ? 'You will control the $_selectedTeam' 
                        : 'Select a team to control in the draft',
                      style: TextStyle(
                        fontSize: 14.0, // Smaller font
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0), 
            
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
                          color: afcColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                          width: double.infinity,
                          child: const Text(
                            'AFC',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                    child: Text(
                                      division.substring(4), // Remove 'AFC ' prefix
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                        color: afcColor,
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
                                            margin: const EdgeInsets.all(2.0),
                                            padding: const EdgeInsets.all(2.0),
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
                                                const SizedBox(height: 2.0),
                                                Text(
                                                  NFLTeamMappings.fullNameToAbbreviation[team] ?? team,
                                                  style: const TextStyle(
                                                    fontSize: 10.0,
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
                                  const SizedBox(height: 8.0),
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
                          color: nfcColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                          width: double.infinity,
                          child: const Text(
                            'NFC',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                    child: Text(
                                      division.substring(4), // Remove 'NFC ' prefix
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                        color: nfcColor,
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
                                            margin: const EdgeInsets.all(2.0),
                                            padding: const EdgeInsets.all(2.0),
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
                                                const SizedBox(height: 2.0),
                                                Text(
                                                  NFLTeamMappings.fullNameToAbbreviation[team] ?? team,
                                                  style: const TextStyle(
                                                    fontSize: 10.0,
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
                                  const SizedBox(height: 8.0),
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
            // Draft settings
            Card(
              margin: const EdgeInsets.only(top: 16.0),
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
                    const SizedBox(height: 12.0),
                    
                    // Number of Rounds row with Start Draft button
                    Row(
                      children: [
                        // Left side: Rounds dropdown
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Number of Rounds:'),
                              DropdownButton<int>(
                                value: _numberOfRounds,
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _numberOfRounds = newValue;
                                    });
                                  }
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
                        // Right side: Start Draft button
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _startDraft,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              child: const Center(
                                child: Text(
                                  'Start Draft', 
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8.0),
                    
                    // Speed row with Advanced button
                    Row(
                      children: [
                        // Left side: Speed slider
                        Expanded(
                          flex: 3,
                          child: Row(
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
                                  activeColor: Colors.green.shade700,
                                  thumbColor: Colors.green.shade700,
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
                        ),
                        // Right side: Advanced Settings button
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 40,
                            child: OutlinedButton(
                              onPressed: _openDraftSettings,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.settings, size: 16, color: Colors.grey.shade700),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Advanced', 
                                    style: TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8.0),
                    
                    // Randomness row (no button on this row)
                    Row(
                      children: [
                        // Left side: Randomness slider with identical structure to Speed
                        Expanded(
                          flex: 3,
                          child: Row(
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
                                  activeColor: Colors.green.shade700,
                                  thumbColor: Colors.green.shade700,
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
                        ),
                        // Empty space to align with buttons above
                        const SizedBox(width: 16),
                        const Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
          selectedTeam: teamAbbr,
          // Add these new parameters (they need to be stored as class variables):
          enableTrading: _enableTrading,
          enableUserTradeProposals: _enableUserTradeProposals,
          enableQBPremium: _enableQBPremium,
          showAnalytics: _showAnalytics,
        ),
      ),
    );
  }
}