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
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select target team
            const Text('Select a team to trade with:'),
            DropdownButton<String>(
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
                  child: Text(team),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Select target pick
            const Text('Select the pick you want:'),
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: teamPicks.length,
                itemBuilder: (context, index) {
                  final pick = teamPicks[index];
                  final isSelected = _targetPick.pickNumber == pick.pickNumber;
                  
                  return ListTile(
                    title: Text('Pick #${pick.pickNumber} (Round ${pick.round})'),
                    subtitle: Text('Value: ${DraftValueService.getValueDescription(
                      DraftValueService.getValueForPick(pick.pickNumber)
                    )}'),
                    tileColor: isSelected ? Colors.blue.shade100 : null,
                    onTap: () {
                      setState(() {
                        _targetPick = pick;
                      });
                      _updateValues();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Select picks to offer
            const Text('Select picks to offer:'),
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: widget.userPicks.length,
                itemBuilder: (context, index) {
                  final pick = widget.userPicks[index];
                  final isSelected = _selectedUserPicks.contains(pick);
                  
                  return CheckboxListTile(
                    title: Text('Pick #${pick.pickNumber} (Round ${pick.round})'),
                    subtitle: Text('Value: ${DraftValueService.getValueDescription(
                      DraftValueService.getValueForPick(pick.pickNumber)
                    )}'),
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
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Trade value analysis
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trade Value Analysis:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Your offer: ${_totalOfferedValue.toStringAsFixed(0)} points'),
                    Text('Target pick: ${_targetPickValue.toStringAsFixed(0)} points'),
                    Text(
                      'Difference: ${(_totalOfferedValue - _targetPickValue).toStringAsFixed(0)} points',
                      style: TextStyle(
                        color: _totalOfferedValue >= _targetPickValue
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
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