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

  // User settings
  int _userPick = 1;
  bool _randomPick = true;
  int _timePerPick = 90; // seconds
  bool _enableAutoPick = true;
  double _randomness = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fantasy Draft Setup'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Draft Settings
              Expanded(
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(right: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Draft Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
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
                                if (_userPick > _numTeams) _userPick = 1;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
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
                      ],
                    ),
                  ),
                ),
              ),
              // Right: User Settings
              Expanded(
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(left: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Preferences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 16),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Draft Randomness', style: TextStyle(fontWeight: FontWeight.bold)),
                            Slider(
                              value: _randomness,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              label: _randomness == 0.0
                                  ? 'None'
                                  : _randomness == 1.0
                                      ? 'High'
                                      : _randomness.toStringAsFixed(1),
                              onChanged: (value) {
                                setState(() {
                                  _randomness = value;
                                });
                              },
                            ),
                            const Text('Higher randomness = more unpredictable AI picks'),
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
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              child: Text('Start Draft', style: TextStyle(fontSize: 18)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 