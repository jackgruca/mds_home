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
  final bool isEmbedded;

  const UserTradeProposalDialog({
    super.key,
    required this.userTeam,
    required this.userPicks,
    required this.targetPicks,
    required this.onPropose,
    required this.onCancel,
    this.isEmbedded = false,
  });

  @override
  _UserTradeProposalDialogState createState() => _UserTradeProposalDialogState();
}

class _UserTradeProposalDialogState extends State<UserTradeProposalDialog> {
  late String _targetTeam;
  List<DraftPick> _selectedUserPicks = [];
  List<DraftPick> _selectedTargetPicks = [];
  List<int> _selectedTargetFutureRounds = [];
  double _totalOfferedValue = 0;
  double _targetPickValue = 0;
  List<int> _selectedFutureRounds = [];
  final List<int> _availableFutureRounds = [1, 2, 3, 4, 5, 6, 7];
  
  @override
  void initState() {
    super.initState();
    if (widget.targetPicks.isNotEmpty) {
      _targetTeam = widget.targetPicks.first.teamName;
      _selectedTargetPicks = [];
      _selectedUserPicks = [];
    } else {
      _targetTeam = "";
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
    
    // Target picks calculation
    double targetValue = 0;
    for (var pick in _selectedTargetPicks) {
      targetValue += DraftValueService.getValueForPick(pick.pickNumber);
    }
    
    // Add their future picks value
    for (var round in _selectedTargetFutureRounds) {
      final futurePick = FuturePick.forRound(_targetTeam, round);
      targetValue += futurePick.value;
    }
    
    setState(() {
      _totalOfferedValue = userValue;
      _targetPickValue = targetValue;
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
    
    // Shared styles for consistent appearance
    const headerStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.bold);
    const subheaderStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
    const labelStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.bold);
    const sublabelStyle = TextStyle(fontSize: 11);
    const valueStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
    
    // Card dimensions for symmetry
    const double cardHeight = 72.0;
    const double valueColumnWidth = 55.0;
    
    // Create the content widget
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content area - two columns side by side (Their team | Your team)
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Their team
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team selection dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Team to trade with:', style: headerStyle),
                          if (targetTeams.isNotEmpty)
                            DropdownButton<String>(
                              value: targetTeams.contains(_targetTeam) ? _targetTeam : targetTeams.first,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _targetTeam = newValue;
                                    _selectedTargetPicks.clear();
                                    _selectedTargetFutureRounds.clear();
                                  });
                                  _updateValues();
                                }
                              },
                              items: targetTeams.map<DropdownMenuItem<String>>((String team) {
                                return DropdownMenuItem<String>(
                                  value: team,
                                  child: Text(team, style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              style: const TextStyle(fontSize: 13),
                            ),
                        ],
                      ),
                      
                      // Sub-header for their picks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Their picks to receive:', style: headerStyle),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              minimumSize: const Size(0, 24),
                            ),
                            onPressed: () {
                              setState(() {
                                if (_selectedTargetPicks.length == teamPicks.length &&
                                    _selectedTargetFutureRounds.length == _availableFutureRounds.length) {
                                  // Unselect all
                                  _selectedTargetPicks.clear();
                                  _selectedTargetFutureRounds.clear();
                                } else {
                                  // Select all
                                  _selectedTargetPicks = List.from(teamPicks);
                                  _selectedTargetFutureRounds = List.from(_availableFutureRounds);
                                }
                                _updateValues();
                              });
                            },
                            child: const Text(
                              'Select All',
                              style: TextStyle(fontSize: 12)
                            ),
                          ),
                        ],
                      ),
                      
                      // Draft years header row
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Text('2025 Draft', style: subheaderStyle),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text('2026 Draft', style: subheaderStyle),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Their picks in a split layout
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2025 Draft column
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                itemCount: teamPicks.length,
                                itemBuilder: (context, index) {
                                  final pick = teamPicks[index];
                                  final isSelected = _selectedTargetPicks.contains(pick);
                                  final pickValue = DraftValueService.getValueForPick(pick.pickNumber);
                                  
                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedTargetPicks.remove(pick);
                                          } else {
                                            _selectedTargetPicks.add(pick);
                                          }
                                          _updateValues();
                                        });
                                      },
                                      child: SizedBox(
                                        height: cardHeight,
                                        child: Row(
                                          children: [
                                            // Value column
                                            SizedBox(
                                              width: valueColumnWidth,
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: Text(
                                                  '${pickValue.toInt()}',
                                                  style: valueStyle,
                                                ),
                                              ),
                                            ),
                                            // Pick details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Pick #${pick.pickNumber}',
                                                    style: labelStyle,
                                                  ),
                                                  const Text(
                                                    'Round',
                                                    style: sublabelStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Checkbox
                                            Checkbox(
                                              value: isSelected,
                                              visualDensity: VisualDensity.compact,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedTargetPicks.add(pick);
                                                  } else {
                                                    _selectedTargetPicks.remove(pick);
                                                  }
                                                  _updateValues();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            // 2026 Draft column with future picks
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                itemCount: _availableFutureRounds.length,
                                itemBuilder: (context, index) {
                                  final round = _availableFutureRounds[index];
                                  final isSelected = _selectedTargetFutureRounds.contains(round);
                                  final futurePick = FuturePick.forRound(_targetTeam, round);
                                  final pickValue = futurePick.value;
                                  
                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedTargetFutureRounds.remove(round);
                                          } else {
                                            _selectedTargetFutureRounds.add(round);
                                          }
                                          _updateValues();
                                        });
                                      },
                                      child: SizedBox(
                                        height: cardHeight,
                                        child: Row(
                                          children: [
                                            // Value column
                                            SizedBox(
                                              width: valueColumnWidth,
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: Text(
                                                  '${pickValue.toInt()}',
                                                  style: valueStyle,
                                                ),
                                              ),
                                            ),
                                            // Pick details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '${_getRoundText(round)} Round',
                                                    style: labelStyle,
                                                  ),
                                                  const Text(
                                                    'Future Pick',
                                                    style: sublabelStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Checkbox
                                            Checkbox(
                                              value: isSelected,
                                              visualDensity: VisualDensity.compact,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedTargetFutureRounds.add(round);
                                                  } else {
                                                    _selectedTargetFutureRounds.remove(round);
                                                  }
                                                  _updateValues();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
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
              ),
              
              const VerticalDivider(thickness: 1, width: 1),
              
              // Right side - Your team
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team indicator with used capital
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your team: ${widget.userTeam}', style: headerStyle),
                          Text(
                            'Capital Used: ${_selectedUserPicks.length} picks',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      
                      // Sub-header for your picks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your picks to offer:', style: headerStyle),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              minimumSize: const Size(0, 24),
                            ),
                            onPressed: () {
                              setState(() {
                                if (_selectedUserPicks.length == widget.userPicks.length &&
                                    _selectedFutureRounds.length == _availableFutureRounds.length) {
                                  // Unselect all
                                  _selectedUserPicks.clear();
                                  _selectedFutureRounds.clear();
                                } else {
                                  // Select all
                                  _selectedUserPicks = List.from(widget.userPicks);
                                  _selectedFutureRounds = List.from(_availableFutureRounds);
                                }
                                _updateValues();
                              });
                            },
                            child: const Text(
                              'Select All',
                              style: TextStyle(fontSize: 12)
                            ),
                          ),
                        ],
                      ),
                      
                      // Draft years header row
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Text('2025 Draft', style: subheaderStyle),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text('2026 Draft', style: subheaderStyle),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Your picks in a split layout
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2025 Draft column
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                itemCount: widget.userPicks.length,
                                itemBuilder: (context, index) {
                                  final pick = widget.userPicks[index];
                                  final isSelected = _selectedUserPicks.contains(pick);
                                  final pickValue = DraftValueService.getValueForPick(pick.pickNumber);
                                  
                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedUserPicks.remove(pick);
                                          } else {
                                            _selectedUserPicks.add(pick);
                                          }
                                          _updateValues();
                                        });
                                      },
                                      child: SizedBox(
                                        height: cardHeight,
                                        child: Row(
                                          children: [
                                            // Value column
                                            SizedBox(
                                              width: valueColumnWidth,
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: Text(
                                                  '${pickValue.toInt()}',
                                                  style: valueStyle,
                                                ),
                                              ),
                                            ),
                                            // Pick details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Pick #${pick.pickNumber}',
                                                    style: labelStyle,
                                                  ),
                                                  const Text(
                                                    'Round',
                                                    style: sublabelStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Checkbox
                                            Checkbox(
                                              value: isSelected,
                                              visualDensity: VisualDensity.compact,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedUserPicks.add(pick);
                                                  } else {
                                                    _selectedUserPicks.remove(pick);
                                                  }
                                                  _updateValues();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            // 2026 Draft column with future picks
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                itemCount: _availableFutureRounds.length,
                                itemBuilder: (context, index) {
                                  final round = _availableFutureRounds[index];
                                  final isSelected = _selectedFutureRounds.contains(round);
                                  final futurePick = FuturePick.forRound(widget.userTeam, round);
                                  final pickValue = futurePick.value;
                                  
                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedFutureRounds.remove(round);
                                          } else {
                                            _selectedFutureRounds.add(round);
                                          }
                                          _updateValues();
                                        });
                                      },
                                      child: SizedBox(
                                        height: cardHeight,
                                        child: Row(
                                          children: [
                                            // Value column
                                            SizedBox(
                                              width: valueColumnWidth,
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 8),
                                                child: Text(
                                                  '${pickValue.toInt()}',
                                                  style: valueStyle,
                                                ),
                                              ),
                                            ),
                                            // Pick details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '${_getRoundText(round)} Round',
                                                    style: labelStyle,
                                                  ),
                                                  const Text(
                                                    'Future Pick',
                                                    style: sublabelStyle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Checkbox
                                            Checkbox(
                                              value: isSelected,
                                              visualDensity: VisualDensity.compact,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedFutureRounds.add(round);
                                                  } else {
                                                    _selectedFutureRounds.remove(round);
                                                  }
                                                  _updateValues();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
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
              ),
            ],
          ),
        ),
        
        // Trade value analysis + buttons as a compact footer
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trade Value Analysis
              const Text('Trade Value Analysis:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Row(
                children: [
                  Text('Your offer: ${_totalOfferedValue.toStringAsFixed(0)} points', 
                    style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  Text('Their picks: ${_targetPickValue.toStringAsFixed(0)} points',
                    style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 2),
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
              const SizedBox(height: 2),
              Text(_getTradeAdviceText(),
                style: TextStyle(
                  fontStyle: FontStyle.italic, 
                  fontSize: 12, 
                  color: _getTradeAdviceColor()
                )
              ),
              
              // Add button row at bottom
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Always show the propose button
                  ElevatedButton(
                    onPressed: _canProposeTrade() ? _proposeTrade : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Propose Trade'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    // If embedded, return just the content
    if (widget.isEmbedded) {
      return content;
    }
    
    // Otherwise wrap in an AlertDialog
    return AlertDialog(
      title: const Text('Propose a Trade'),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: content,
      ),
    );
  }
  
  bool _canProposeTrade() {
    return (_selectedUserPicks.isNotEmpty || _selectedFutureRounds.isNotEmpty) && 
           (_selectedTargetPicks.isNotEmpty || _selectedTargetFutureRounds.isNotEmpty);
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
    
    // Create the base package
    TradePackage package;
    
    // Check if we need to handle pure future picks trade
    if (_selectedTargetPicks.isEmpty && _selectedTargetFutureRounds.isNotEmpty) {
      // Create a virtual draft pick for the first future round
      final firstRound = _selectedTargetFutureRounds.first;
      final futurePick = FuturePick.forRound(_targetTeam, firstRound);
      
      // Create a dummy DraftPick for the future pick
      final dummyPick = DraftPick(
        pickNumber: 1000 + firstRound, // Use a high number that won't conflict
        teamName: _targetTeam,
        round: firstRound.toString(),
      );
      
      package = TradePackage(
        teamOffering: widget.userTeam,
        teamReceiving: _targetTeam,
        picksOffered: _selectedUserPicks,
        targetPick: dummyPick,
        totalValueOffered: _totalOfferedValue,
        targetPickValue: _targetPickValue,
        includesFuturePick: _selectedFutureRounds.isNotEmpty,
        futurePickDescription: _selectedFutureRounds.isNotEmpty ? 
            futurePickDescriptions.join(", ") : null,
        futurePickValue: futurePicksValue > 0 ? futurePicksValue : null,
      );
    } else {
      // Normal trade with current year picks
      package = TradePackage(
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
    }
    
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

  String _getRoundText(int round) {
    if (round == 1) return "1st";
    if (round == 2) return "2nd";
    if (round == 3) return "3rd";
    return "${round}th";
  }
}