// lib/screens/draft_settings_screen.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A screen for configuring draft simulation settings
class DraftSettingsScreen extends StatefulWidget {
  // Current settings that can be modified
  final int numberOfRounds;
  final double randomnessFactor;
  final double draftSpeed;
  final String? userTeam;
  final bool enableTrading;
  final bool enableUserTradeProposals;
  final bool enableQBPremium;
  final bool showAnalytics;
  
  // Add these parameters
  final int selectedYear;
  final List<int> availableYears;

  // Callback when settings are saved
  final Function(Map<String, dynamic>) onSettingsSaved;

  const DraftSettingsScreen({
    super.key,
    required this.numberOfRounds,
    required this.randomnessFactor,
    required this.draftSpeed,
    this.userTeam,
    this.enableTrading = true,
    this.enableUserTradeProposals = true,
    this.enableQBPremium = true,
    this.showAnalytics = true,
    required this.onSettingsSaved,
    required this.selectedYear,
    required this.availableYears,
  });

  @override
  State<DraftSettingsScreen> createState() => _DraftSettingsScreenState();
}

class _DraftSettingsScreenState extends State<DraftSettingsScreen> {
  late int _numberOfRounds;
  late double _randomnessFactor;
  late double _draftSpeed;
  late bool _enableTrading;
  late bool _enableUserTradeProposals;
  late bool _enableQBPremium;
  late bool _showAnalytics;
  late int _selectedYear; // Add this
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with current settings
    _numberOfRounds = widget.numberOfRounds;
    _randomnessFactor = widget.randomnessFactor;
    _draftSpeed = widget.draftSpeed;
    _enableTrading = widget.enableTrading;
    _enableUserTradeProposals = widget.enableUserTradeProposals;
    _enableQBPremium = widget.enableQBPremium;
    _showAnalytics = widget.showAnalytics;
    _selectedYear = widget.selectedYear; // Initialize year
  }
  
  void _saveSettings() {
    // Collect all settings in a map
    final settings = {
      'numberOfRounds': _numberOfRounds,
      'randomnessFactor': _randomnessFactor,
      'draftSpeed': _draftSpeed,
      'enableTrading': _enableTrading,
      'enableUserTradeProposals': _enableUserTradeProposals,
      'enableQBPremium': _enableQBPremium,
      'showAnalytics': _showAnalytics,
      'selectedYear': _selectedYear, // Add year to settings
    };
    
    // Call the callback
    widget.onSettingsSaved(settings);
    
    // Close the screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Basic Settings
            _buildSectionHeader('Basic Settings', Icons.settings),
            const SizedBox(height: 16.0),
            
            // Number of rounds and draft year in same row
            _buildSettingItem(
              'Number of Rounds',
              'How many rounds of the draft to simulate',
              child: Row(
                children: [
                  // Rounds dropdown
                  Expanded(
                    flex: 3,
                    child: DropdownButton<int>(
                      value: _numberOfRounds,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _numberOfRounds = newValue;
                          });
                        }
                      },
                      items: List.generate(AppConstants.maxRounds, (index) => index + 1)
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value ${value == 1 ? 'Round' : 'Rounds'}'),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Draft Year section
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Draft Year:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButton<int>(
                          value: _selectedYear,
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedYear = newValue;
                              });
                            }
                          },
                          items: widget.availableYears.map<DropdownMenuItem<int>>((int year) {
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Randomness Factor
            _buildSettingItem(
              'Draft Randomness',
              'How much randomness to add to team selections',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _randomnessFactor * 5,
                          min: 1.0,
                          max: 5.0,
                          divisions: 4,
                          label: '${(_randomnessFactor * 5).toInt()}',
                          onChanged: (value) {
                            setState(() {
                              _randomnessFactor = value / 5.0;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${(_randomnessFactor * 5).toInt()}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Predictable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Chaotic',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Draft Speed
            _buildSettingItem(
              'Simulation Speed',
              'How quickly the draft progresses when simulating',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _draftSpeed,
                          min: 1.0,
                          max: 5.0,
                          divisions: 4,
                          label: '${_draftSpeed.toInt()}',
                          onChanged: (value) {
                            setState(() {
                              _draftSpeed = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${_draftSpeed.toInt()}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Slower',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Faster',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24.0),
            
            // Section: Trade Settings
            _buildSectionHeader('Trade Settings', Icons.swap_horiz),
            const SizedBox(height: 16.0),
            
            // Enable Trading
            _buildSettingItem(
              'Enable Trading',
              'Allow CPU teams to make trades during the draft',
              trailing: Switch(
                value: _enableTrading,
                onChanged: (value) {
                  setState(() {
                    _enableTrading = value;
                    // If trading is disabled, disable user trade proposals too
                    if (!value) {
                      _enableUserTradeProposals = false;
                    }
                  });
                },
              ),
            ),
            
            // Enable User Trade Proposals
            _buildSettingItem(
              'User Trade Proposals',
              'Allow you to propose trades to CPU teams',
              trailing: Switch(
                value: _enableUserTradeProposals,
                onChanged: _enableTrading
                    ? (value) {
                        setState(() {
                          _enableUserTradeProposals = value;
                        });
                      }
                    : null,
              ),
            ),
            
            // QB Premium
            _buildSettingItem(
              'QB Premium',
              'Teams value QBs more highly in trades (more realistic)',
              trailing: Switch(
                value: _enableQBPremium,
                onChanged: _enableTrading
                    ? (value) {
                        setState(() {
                          _enableQBPremium = value;
                        });
                      }
                    : null,
              ),
            ),
            
            const SizedBox(height: 24.0),
            
            // Section: UI Settings
            _buildSectionHeader('Display Settings', Icons.visibility),
            const SizedBox(height: 16.0),
            
            // Show Analytics
            _buildSettingItem(
              'Show Analytics',
              'Display analytics and insights during the draft',
              trailing: Switch(
                value: _showAnalytics,
                onChanged: (value) {
                  setState(() {
                    _showAnalytics = value;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 32.0),
            
            // Reset to Defaults button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _numberOfRounds = 7;
                    _randomnessFactor = AppConstants.defaultRandomnessFactor;
                    _draftSpeed = 3.0;
                    _enableTrading = true;
                    _enableUserTradeProposals = true;
                    _enableQBPremium = true;
                    _showAnalytics = true;
                  });
                },
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.blue.shade700,
        ),
        const SizedBox(width: 8.0),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    String description, {
    Widget? child,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              description,
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[600],
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: 16.0),
              child,
            ],
          ],
        ),
      ),
    );
  }
}