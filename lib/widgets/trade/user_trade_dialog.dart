// lib/widgets/trade/user_trade_dialog.dart
import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/trade_package.dart';
import '../../services/draft_value_service.dart';
import '../../models/future_pick.dart';


class UserTradeProposalDialog extends StatefulWidget {
  final String userTeam;
  final List<DraftPick> userPicks;
  final List<DraftPick> targetPicks;
  final Function(TradePackage) onPropose;
  final VoidCallback onCancel;

  const UserTradeProposalDialog({
    super.key,
    required this.userTeam,
    required this.userPicks,
    required this.targetPicks,
    required this.onPropose,
    required this.onCancel,
  });

  @override
  _UserTradeProposalDialogState createState() => _UserTradeProposalDialogState();
}

class _UserTradeProposalDialogState extends State<UserTradeProposalDialog> {
  late String _targetTeam;
  List<DraftPick> _selectedUserPicks = [];
  List<DraftPick> _selectedTargetPicks = []; // New variable for other team's selections
  double _totalOfferedValue = 0;
  double _targetPickValue = 0;
  final bool _includeFuturePick = false;
  final List<int> _selectedFutureRounds = [];
  final List<int> _availableFutureRounds = [1, 2, 3, 4, 5, 6, 7];
  
  @override
  void initState() {
    super.initState();
    if (widget.targetPicks.isNotEmpty) {
      _targetTeam = widget.targetPicks.first.teamName;
      // Don't auto-select any picks by default
      _selectedTargetPicks = [];
      _selectedUserPicks = [];
    }
    _updateValues();
  }
  
  void _updateValues() {
    double userValue = 0;
    
    // Current year picks
    for (var pick in _selectedUserPicks) {
      userValue += DraftValueService.getValueForPick(pick.pickNumber);
    }
    
    // Future picks
    for (var round in _selectedFutureRounds) {
      final futurePick = FuturePick.forRound(widget.userTeam, round);
      userValue += futurePick.value;
    }
    
    // Target picks calculation (unchanged)
    double targetValue = 0;
    for (var pick in _selectedTargetPicks) {
      targetValue += DraftValueService.getValueForPick(pick.pickNumber);
    }
    
    setState(() {
      _totalOfferedValue = userValue;
      _targetPickValue = targetValue;
    });
  }
  
  // In user_trade_dialog.dart, modify the build method
  // In your user_trade_dialog.dart file, look for the build method and update it:

@override
Widget build(BuildContext context) {
  // Get unique teams from target picks
  final targetTeams = widget.targetPicks
      .map((pick) => pick.teamName)
      .toSet()
      .toList();
  
  // Filter target picks by selected team
  final teamPicks = widget.targetPicks
      .where((pick) => pick.teamName == _targetTeam)
      .toList();
  
  return AlertDialog(
    title: const Text('Propose a Trade'),
    content: SizedBox(
      width: double.maxFinite,
      height: 500, // Fixed height to avoid overflow
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Other team's picks selection
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team dropdown
                Row(
                  children: [
                    const Expanded(
                      child: Text('Team to trade with:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DropdownButton<String>(
                      value: targetTeams.contains(_targetTeam) ? _targetTeam : targetTeams.first,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _targetTeam = newValue;
                            // Clear selected picks when team changes
                            _selectedTargetPicks.clear();
                          });
                          _updateValues();
                        }
                      },
                      items: targetTeams.map<DropdownMenuItem<String>>((String team) {
                        return DropdownMenuItem<String>(
                          value: team,
                          child: Text(team, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Their picks selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Their picks to receive:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          // Toggle all/none selection
                          if (_selectedTargetPicks.length == teamPicks.length) {
                            _selectedTargetPicks.clear(); // Deselect all
                          } else {
                            _selectedTargetPicks = List.from(teamPicks); // Select all
                          }
                          _updateValues();
                        });
                      },
                      child: Text(_selectedTargetPicks.length == teamPicks.length ?
                               'Unselect All' : 'Select All'),
                    ),
                  ],
                ),
                
                // Their picks with checkboxes
                Expanded(
                  child: ListView.builder(
                    itemCount: teamPicks.length,
                    itemBuilder: (context, index) {
                      final pick = teamPicks[index];
                      final isSelected = _selectedTargetPicks.contains(pick);
                      
                      return Card(
                        color: isSelected ? Colors.blue.shade100 : null,
                        child: CheckboxListTile(
                          dense: true,
                          title: Text('Pick #${pick.pickNumber}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Round ${pick.round}'),
                              // Add this debug information
                              Text(
                                'Value: ${DraftValueService.getValueForPick(pick.pickNumber)}',
                                style: const TextStyle(color: Colors.red, fontSize: 10),
                              ),
                            ],
                          ),
                          secondary: Text(
                            DraftValueService.getValueDescription(
                              DraftValueService.getValueForPick(pick.pickNumber)
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedTargetPicks.add(pick);
                              } else {
                                _selectedTargetPicks.remove(pick);
                              }
                            });
                            _updateValues();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const VerticalDivider(), // Divider between sections
          
          // Right side - Your picks selection
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your picks to offer:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          // Toggle all/none selection
                          if (_selectedUserPicks.length == widget.userPicks.length) {
                            _selectedUserPicks.clear(); // Deselect all
                          } else {
                            _selectedUserPicks = List.from(widget.userPicks); // Select all
                          }
                          _updateValues();
                        });
                      },
                      child: Text(_selectedUserPicks.length == widget.userPicks.length ?
                              'Unselect All' : 'Select All'),
                    ),
                  ],
                ),
                
                // Current year picks list
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.userPicks.length,
                    itemBuilder: (context, index) {
                      final pick = widget.userPicks[index];
                      final isSelected = _selectedUserPicks.contains(pick);
                      
                      return Card(
                        color: isSelected ? Colors.green.shade100 : null,
                        child: CheckboxListTile(
                          dense: true,
                          title: Text('Pick #${pick.pickNumber}'),
                          subtitle: Text('Round ${pick.round}'),
                          secondary: Text(
                            DraftValueService.getValueDescription(
                              DraftValueService.getValueForPick(pick.pickNumber)
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedUserPicks.add(pick);
                              } else {
                                _selectedUserPicks.remove(pick);
                              }
                            });
                            _updateValues();
                          },
                        ),
                      );
                    },
                  ),
                ),
                
                // Future picks selection (now at the bottom)
                Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2026 Draft Picks to Include:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: _availableFutureRounds.map((round) {
                          bool isSelected = _selectedFutureRounds.contains(round);
                          return FilterChip(
                            label: Text('${_getRoundText(round)} Round'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedFutureRounds.add(round);
                                } else {
                                  _selectedFutureRounds.remove(round);
                                }
                              });
                              _updateValues();
                            },
                            selectedColor: Colors.green.shade100,
                            labelStyle: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedFutureRounds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Value: ${_calculateFuturePicksValue().toStringAsFixed(0)} points',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    // Trade value analysis section at the bottom
    insetPadding: const EdgeInsets.all(16),
    contentPadding: const EdgeInsets.all(16),
    actionsPadding: const EdgeInsets.all(16),
    actions: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trade Value Analysis:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your offer: ${_totalOfferedValue.toStringAsFixed(0)} points'),
                    Text('Their picks: ${_targetPickValue.toStringAsFixed(0)} points'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _targetPickValue > 0
                      ? _totalOfferedValue / _targetPickValue
                      : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _totalOfferedValue >= _targetPickValue * 1.1
                        ? Colors.green
                        : (_totalOfferedValue >= _targetPickValue * 0.9
                            ? Colors.blue
                            : Colors.orange),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTradeAdviceText(),
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: _getTradeAdviceColor(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _canProposeTrade() ? _proposeTrade : null,
                child: const Text('Propose Trade'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
  
  bool _canProposeTrade() {
    return _selectedUserPicks.isNotEmpty && _selectedTargetPicks.isNotEmpty;
  }
  
  void _proposeTrade() {
    // Create future pick descriptions
    List<String> futurePickDescriptions = [];
    double futurePicksValue = 0;
    
    for (var round in _selectedFutureRounds) {
      futurePickDescriptions.add("2026 ${_getRoundText(round)} Round");
      final futurePick = FuturePick.forRound(widget.userTeam, round);
      futurePicksValue += futurePick.value;
    }
    
    final package = TradePackage(
      teamOffering: widget.userTeam,
      teamReceiving: _targetTeam,
      picksOffered: _selectedUserPicks,
      targetPick: _selectedTargetPicks.first,
      totalValueOffered: _totalOfferedValue,
      targetPickValue: _targetPickValue,
      additionalTargetPicks: _selectedTargetPicks.length > 1 ? 
          _selectedTargetPicks.sublist(1) : [],
      includesFuturePick: _selectedFutureRounds.isNotEmpty,
      futurePickDescription: _selectedFutureRounds.isNotEmpty ? 
          futurePickDescriptions.join(", ") : null,
      futurePickValue: futurePicksValue > 0 ? futurePicksValue : null,
    );
    
    widget.onPropose(package);
  }
  
  String _getTradeAdviceText() {
    if (_totalOfferedValue >= _targetPickValue * 1.2) {
      return 'Great offer - they\'ll likely accept!';
    } else if (_totalOfferedValue >= _targetPickValue) {
      return 'Fair offer - they may accept.';
    } else if (_totalOfferedValue >= _targetPickValue * 0.9) {
      return 'Slightly below market value - but still possible.';
    } else {
      return 'Poor value - they\'ll likely reject.';
    }
  }
  
  Color _getTradeAdviceColor() {
    if (_totalOfferedValue >= _targetPickValue * 1.2) {
      return Colors.green;
    } else if (_totalOfferedValue >= _targetPickValue) {
      return Colors.blue;
    } else if (_totalOfferedValue >= _targetPickValue * 0.9) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Add helper methods
  String _getRoundText(int round) {
    if (round == 1) return "1st";
    if (round == 2) return "2nd";
    if (round == 3) return "3rd";
    return "${round}th";
  }

  double _calculateFuturePicksValue() {
    double value = 0;
    for (var round in _selectedFutureRounds) {
      final futurePick = FuturePick.forRound(widget.userTeam, round);
      value += futurePick.value;
    }
    return value;
  }
}