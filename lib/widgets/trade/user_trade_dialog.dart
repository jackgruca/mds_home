// lib/widgets/trade/user_trade_dialog.dart
import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/trade_package.dart';
import '../../services/draft_value_service.dart';

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
  late DraftPick _targetPick;
  final List<DraftPick> _selectedUserPicks = [];
  double _totalOfferedValue = 0;
  double _targetPickValue = 0;
  
  @override
  void initState() {
    super.initState();
    if (widget.targetPicks.isNotEmpty) {
      _targetPick = widget.targetPicks.first;
      _targetTeam = _targetPick.teamName;
      _targetPickValue = DraftValueService.getValueForPick(_targetPick.pickNumber);
    }
    _updateValues();
  }
  
  void _updateValues() {
    double total = 0;
    for (var pick in _selectedUserPicks) {
      total += DraftValueService.getValueForPick(pick.pickNumber);
    }
    
    setState(() {
      _totalOfferedValue = total;
      if (widget.targetPicks.isNotEmpty) {
        _targetPickValue = DraftValueService.getValueForPick(_targetPick.pickNumber);
      }
    });
  }
  
  // In user_trade_dialog.dart, modify the build method
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
        child: Column(
          children: [
            // Main content area with team picks
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Team dropdown and their picks
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Team dropdown - made narrower
                        DropdownButton<String>(
                          isExpanded: true, // Makes dropdown fit available width
                          value: targetTeams.contains(_targetTeam) ? _targetTeam : targetTeams.first,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _targetTeam = newValue;
                                // Reset target pick when team changes
                                _targetPick = widget.targetPicks
                                    .firstWhere((pick) => pick.teamName == newValue);
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
                        const SizedBox(height: 8),
                        
                        const Text('Their picks:', style: TextStyle(fontWeight: FontWeight.bold)),
                        
                        // Their picks list
                        Expanded(
                          child: ListView.builder(
                            itemCount: teamPicks.length,
                            itemBuilder: (context, index) {
                              final pick = teamPicks[index];
                              final isSelected = _targetPick.pickNumber == pick.pickNumber;
                              
                              return Card(
                                color: isSelected ? Colors.blue.shade100 : null,
                                child: ListTile(
                                  dense: true,
                                  title: Text('Pick #${pick.pickNumber}'),
                                  subtitle: Text('Round ${pick.round}'),
                                  trailing: Text(
                                    DraftValueService.getValueDescription(
                                      DraftValueService.getValueForPick(pick.pickNumber)
                                    ),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  selected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _targetPick = pick;
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
                        const Text('Your picks to offer:', style: TextStyle(fontWeight: FontWeight.bold)),
                        
                        // Your picks with checkboxes
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Trade value analysis section at the bottom
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Make this as small as needed
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
                      Text('Their pick: ${_targetPickValue.toStringAsFixed(0)} points'),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canProposeTrade() ? _proposeTrade : null,
          child: const Text('Propose Trade'),
        ),
      ],
    );
  }
  
  bool _canProposeTrade() {
    return _selectedUserPicks.isNotEmpty && _targetPickValue > 0;
  }
  
  void _proposeTrade() {
    // Create a trade package with the selected picks
    final package = TradePackage(
      teamOffering: widget.userTeam,
      teamReceiving: _targetTeam,
      picksOffered: _selectedUserPicks,
      targetPick: _targetPick,
      totalValueOffered: _totalOfferedValue,
      targetPickValue: _targetPickValue,
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
}