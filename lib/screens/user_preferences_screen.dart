// lib/screens/user_preferences_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/tutorial_service.dart';
import '../utils/constants.dart';
import '../utils/theme_config.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  _UserPreferencesScreenState createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  
  /// Reset all tutorials to show them again
  Future<void> _resetTutorials(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    
    // Reset all tutorials
    await TutorialService.resetTutorial();
    
    // Reset feature-specific tutorials (common ones)
    await TutorialService.resetFeatureTutorial('trade_dialog');
    await TutorialService.resetFeatureTutorial('draft_controls');
    await TutorialService.resetFeatureTutorial('player_selection');
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tutorials have been reset! They will show next time you use those features.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  // Favorite teams
  final List<String> _selectedTeams = [];
  
  // Draft preferences
  int _defaultRounds = 1;
  double _defaultSpeed = 2.0;
  double _defaultRandomness = 0.5;
  bool _enableTrading = true;
  bool _enableUserTradeProposals = true;
  bool _enableQBPremium = true;
  bool _showAnalytics = true;
  int _defaultYear = 2025;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // lib/screens/user_preferences_screen.dart (continued)
  Future<void> _loadUserPreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) {
      setState(() {
        _error = 'User not logged in';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Load favorite teams
    if (user.favoriteTeams != null) {
      setState(() {
        _selectedTeams.clear();
        _selectedTeams.addAll(user.favoriteTeams!);
      });
    }
    
    // Load draft preferences
    if (user.draftPreferences != null) {
      final prefs = user.draftPreferences!;
      setState(() {
        _defaultRounds = prefs['defaultRounds'] ?? 1;
        _defaultSpeed = prefs['defaultSpeed'] ?? 2.0;
        _defaultRandomness = prefs['defaultRandomness'] ?? 0.5;
        _enableTrading = prefs['enableTrading'] ?? true;
        _enableUserTradeProposals = prefs['enableUserTradeProposals'] ?? true;
        _enableQBPremium = prefs['enableQBPremium'] ?? true;
        _showAnalytics = prefs['showAnalytics'] ?? true;
        _defaultYear = prefs['defaultYear'] ?? 2025;
      });
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _saveFavoriteTeams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateFavoriteTeams(_selectedTeams);
    
    setState(() {
      _isLoading = false;
      if (!success) {
        _error = authProvider.error ?? 'Failed to save favorite teams';
      }
    });
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favorite teams saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Future<void> _saveDraftPreferences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final prefs = {
      'defaultRounds': _defaultRounds,
      'defaultSpeed': _defaultSpeed,
      'defaultRandomness': _defaultRandomness,
      'enableTrading': _enableTrading,
      'enableUserTradeProposals': _enableUserTradeProposals,
      'enableQBPremium': _enableQBPremium,
      'showAnalytics': _showAnalytics,
      'defaultYear': _defaultYear,
    };
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateDraftPreferences(prefs);
    
    setState(() {
      _isLoading = false;
      if (!success) {
        _error = authProvider.error ?? 'Failed to save draft preferences';
      }
    });
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft preferences saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Preferences'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Favorite Teams', icon: Icon(Icons.sports_football)),
            Tab(text: 'Draft Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildFavoriteTeamsTab(isDarkMode),
              _buildDraftSettingsTab(isDarkMode),
            ],
          ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_error != null)
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ElevatedButton(
                onPressed: _tabController.index == 0 ? _saveFavoriteTeams : _saveDraftPreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Save Preferences'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFavoriteTeamsTab(bool isDarkMode) {
    // Get AFC and NFC teams from constants
    final afcTeams = [];
    final nfcTeams = [];
    
    // Combine divisions into conference lists
    final Map<String, List<String>> afcDivisions = {
      'AFC East': ['Buffalo Bills', 'Miami Dolphins', 'New England Patriots', 'New York Jets'],
      'AFC North': ['Baltimore Ravens', 'Cincinnati Bengals', 'Cleveland Browns', 'Pittsburgh Steelers'],
      'AFC South': ['Houston Texans', 'Indianapolis Colts', 'Jacksonville Jaguars', 'Tennessee Titans'],
      'AFC West': ['Denver Broncos', 'Kansas City Chiefs', 'Las Vegas Raiders', 'Los Angeles Chargers'],
    };
    
    final Map<String, List<String>> nfcDivisions = {
      'NFC East': ['Dallas Cowboys', 'New York Giants', 'Philadelphia Eagles', 'Washington Commanders'],
      'NFC North': ['Chicago Bears', 'Detroit Lions', 'Green Bay Packers', 'Minnesota Vikings'],
      'NFC South': ['Atlanta Falcons', 'Carolina Panthers', 'New Orleans Saints', 'Tampa Bay Buccaneers'],
      'NFC West': ['Arizona Cardinals', 'Los Angeles Rams', 'San Francisco 49ers', 'Seattle Seahawks'],
    };
    
    // Populate AFC and NFC team lists
    for (var division in afcDivisions.values) {
      afcTeams.addAll(division);
    }
    
    for (var division in nfcDivisions.values) {
      nfcTeams.addAll(division);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your favorite teams',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'These teams will be highlighted throughout the app',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          
          // AFC Teams
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: isDarkMode ? const Color(0x33FF6B6B) : const Color(0x11D50A0A),
                  child: Text(
                    'AFC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFFFF6B6B) : const Color(0xFFD50A0A),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: afcTeams.map((team) {
                      final isSelected = _selectedTeams.contains(team);
                      final abbr = NFLTeamMappings.fullNameToAbbreviation[team] ?? '';
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTeams.remove(team);
                            } else {
                              _selectedTeams.add(team);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? (isDarkMode ? const Color(0xFFFF6B6B) : const Color(0xFFD50A0A))
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            color: isSelected
                                ? (isDarkMode ? const Color(0x33FF6B6B) : const Color(0x11D50A0A))
                                : Colors.transparent,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: ClipOval(
                                  child: Image.network(
                                    'https://a.espncdn.com/i/teamlogos/nfl/500/${abbr.toLowerCase()}.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Text(
                                          abbr,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                abbr,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // NFC Teams
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: isDarkMode ? const Color(0x334D90E8) : const Color(0x11002244),
                  child: Text(
                    'NFC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFF4D90E8) : const Color(0xFF002244),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: nfcTeams.map((team) {
                      final isSelected = _selectedTeams.contains(team);
                      final abbr = NFLTeamMappings.fullNameToAbbreviation[team] ?? '';
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTeams.remove(team);
                            } else {
                              _selectedTeams.add(team);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? (isDarkMode ? const Color(0xFF4D90E8) : const Color(0xFF002244))
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            color: isSelected
                                ? (isDarkMode ? const Color(0x334D90E8) : const Color(0x11002244))
                                : Colors.transparent,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: ClipOval(
                                  child: Image.network(
                                    'https://a.espncdn.com/i/teamlogos/nfl/500/${abbr.toLowerCase()}.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Text(
                                          abbr,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                abbr,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDraftSettingsTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default Draft Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'These settings will be applied whenever you start a new draft',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          
          // Settings cards
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Default number of rounds
                  Row(
                    children: [
                      const Text('Default Rounds:'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(7, (index) {
                              final roundNum = index + 1;
                              final isSelected = _defaultRounds == roundNum;
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Material(
                                  color: isSelected ? Colors.blue : isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _defaultRounds = roundNum;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(4.0),
                                    child: Container(
                                      width: 32.0,
                                      height: 32.0,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$roundNum',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : isDarkMode ? Colors.white70 : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Draft speed
                  Row(
                    children: [
                      const Expanded(child: Text('Draft Speed:')),
                      Text('${_defaultSpeed.toInt()}'),
                    ],
                  ),
                  Slider(
                    value: _defaultSpeed,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    activeColor: Colors.green[700],
                    onChanged: (value) {
                      setState(() {
                        _defaultSpeed = value;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Slower',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Faster',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Randomness factor
                  Row(
                    children: [
                      const Expanded(child: Text('Randomness Factor:')),
                      Text('${(_defaultRandomness * 5).toInt()}'),
                    ],
                  ),
                  Slider(
                    value: _defaultRandomness * 5,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    activeColor: Colors.orange[700],
                    onChanged: (value) {
                      setState(() {
                        _defaultRandomness = value / 5.0;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Predictable',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Chaotic',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Trade settings
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trade Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Enable Trading'),
                    subtitle: const Text('Allow CPU teams to make trades during the draft'),
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
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  SwitchListTile(
                    title: const Text('User Trade Proposals'),
                    subtitle: const Text('Allow you to propose trades to CPU teams'),
                    value: _enableUserTradeProposals,
                    onChanged: _enableTrading
                        ? (value) {
                            setState(() {
                              _enableUserTradeProposals = value;
                            });
                          }
                        : null,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  SwitchListTile(
                    title: const Text('QB Premium'),
                    subtitle: const Text('Teams value QBs more highly in trades (more realistic)'),
                    value: _enableQBPremium,
                    onChanged: _enableTrading
                        ? (value) {
                            setState(() {
                              _enableQBPremium = value;
                            });
                          }
                        : null,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          
          // Display settings
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Display Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Show Analytics'),
                    subtitle: const Text('Display analytics and insights during the draft'),
                    value: _showAnalytics,
                    onChanged: (value) {
                      setState(() {
                        _showAnalytics = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  // Default year
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Default Draft Year:'),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [2023, 2024, 2025].map((year) {
                      final isSelected = _defaultYear == year;
                      
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _defaultYear = year;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected 
                              ? Colors.blue 
                              : isDarkMode ? Colors.grey[700] : Colors.grey[200],
                          foregroundColor: isSelected 
                              ? Colors.white 
                              : isDarkMode ? Colors.white70 : Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(year.toString()),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          // Reset to defaults button
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _defaultRounds = 1;
                  _defaultSpeed = 2.0;
                  _defaultRandomness = 0.5;
                  _enableTrading = true;
                  _enableUserTradeProposals = true;
                  _enableQBPremium = true;
                  _showAnalytics = true;
                  _defaultYear = 2025;
                });
              },
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Defaults'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
          
          // Reset tutorials
          Center(
            child: TextButton.icon(
              onPressed: () {
                _resetTutorials(context);
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Reset All Tutorials'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}