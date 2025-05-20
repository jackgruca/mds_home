import 'package:flutter/material.dart';
import '../models/ff_draft_settings.dart';
import '../screens/ff_draft_screen.dart';

class FFDraftSetupScreen extends StatefulWidget {
  const FFDraftSetupScreen({super.key});

  @override
  State<FFDraftSetupScreen> createState() => _FFDraftSetupScreenState();
}

class _FFDraftSetupScreenState extends State<FFDraftSetupScreen> {
  // Draft settings
  int _numTeams = 12;
  String _scoringSystem = 'PPR';
  String _platform = 'ESPN';
  int _rosterSize = 15;
  bool _isSnakeDraft = true;
  int _timePerPick = 90; // seconds
  bool _enableAutoPick = true;
  int _userPick = 1;
  bool _randomPick = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Draft Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Number of Teams
            DropdownButtonFormField<int>(
              value: _numTeams,
              decoration: const InputDecoration(
                labelText: 'Number of Teams',
                border: OutlineInputBorder(),
              ),
              items: [8, 10, 12, 14, 16].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value Teams'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _numTeams = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Scoring System
            DropdownButtonFormField<String>(
              value: _scoringSystem,
              decoration: const InputDecoration(
                labelText: 'Scoring System',
                border: OutlineInputBorder(),
              ),
              items: ['Standard', 'PPR', 'Half PPR'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _scoringSystem = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Platform
            DropdownButtonFormField<String>(
              value: _platform,
              decoration: const InputDecoration(
                labelText: 'Draft Platform',
                border: OutlineInputBorder(),
              ),
              items: ['ESPN', 'Yahoo', 'Sleeper', 'NFL.com'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _platform = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Roster Size
            DropdownButtonFormField<int>(
              value: _rosterSize,
              decoration: const InputDecoration(
                labelText: 'Roster Size',
                border: OutlineInputBorder(),
              ),
              items: [12, 13, 14, 15, 16].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value Players'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _rosterSize = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Draft Type
            SwitchListTile(
              title: const Text('Snake Draft'),
              subtitle: const Text('Reverse order in even rounds'),
              value: _isSnakeDraft,
              onChanged: (bool value) {
                setState(() {
                  _isSnakeDraft = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Time per Pick
            DropdownButtonFormField<int>(
              value: _timePerPick,
              decoration: const InputDecoration(
                labelText: 'Time per Pick',
                border: OutlineInputBorder(),
              ),
              items: [30, 60, 90, 120].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value seconds'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _timePerPick = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Auto Pick
            SwitchListTile(
              title: const Text('Enable Auto Pick'),
              subtitle: const Text('Automatically pick for non-user teams'),
              value: _enableAutoPick,
              onChanged: (bool value) {
                setState(() {
                  _enableAutoPick = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // User Pick Number
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _randomPick ? null : _userPick,
                    decoration: const InputDecoration(
                      labelText: 'Your Pick #',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(_numTeams, (i) => i + 1).map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('Pick $value'),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      setState(() {
                        _userPick = newValue ?? 1;
                        _randomPick = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Checkbox(
                  value: _randomPick,
                  onChanged: (val) {
                    setState(() {
                      _randomPick = val ?? true;
                    });
                  },
                ),
                const Text('Random'),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final userPick = _randomPick ? null : _userPick;
                  final settings = FFDraftSettings(
                    numTeams: _numTeams,
                    scoringSystem: _scoringSystem,
                    platform: _platform,
                    rosterSize: _rosterSize,
                    isSnakeDraft: _isSnakeDraft,
                    timePerPick: _timePerPick,
                    enableAutoPick: _enableAutoPick,
                    rosterPositions: ['QB', 'RB', 'RB', 'WR', 'WR', 'WR', 'TE', 'FLEX', 'K', 'DEF', 'BN', 'BN', 'BN', 'BN', 'BN'],
                    numRounds: _rosterSize,
                  );
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FFDraftScreen(
                        settings: settings,
                        userPick: userPick,
                      ),
                    ),
                  );
                },
                child: const Text('Start Draft'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 