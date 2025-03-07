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
  double _totalOfferedValue = 0;
  double _targetPickValue = 0;
  final List<int> _selectedFutureRounds = [];
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
    
    // Create the content widget
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (only when not embedded)
        if (!widget.isEmbedded)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Propose a Trade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Headers row with dropdowns
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Left team dropdown
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Team to trade with:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                    ),
                    if (targetTeams.isNotEmpty)
                      DropdownButton<String>(
                        value: targetTeams.contains(_targetTeam) ? _targetTeam : targetTeams.first,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _targetTeam = newValue;
                              _selectedTargetPicks.clear();
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
              ),
              
              const SizedBox(width: 16),
              
              // Right side "Used Capital" indicator (for symmetry)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Draft Capital Used:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                    ),
                    Text(
                      '${_selectedUserPicks.length} picks',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main content area - two columns side by side
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Current year picks
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Their picks to receive:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              minimumSize: const Size(0, 24),
                            ),
                            onPressed: () {
                              setState(() {
                                if (_selectedTargetPicks.length == teamPicks.length) {
                                  _selectedTargetPicks.clear(); // Deselect all
                                } else {
                                  _selectedTargetPicks = List.from(teamPicks); // Select all
                                }
                                _updateValues();
                              });
                            },
                            child: Text(
                              _selectedTargetPicks.length == teamPicks.length ? 'Unselect All' : 'Select All',
                              style: const TextStyle(fontSize: 12)
                            ),
                          ),
                        ],
                      ),
                      
                      // Their picks list in a grid layout
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: teamPicks.length,
                          itemBuilder: (context, index) {
                            final pick = teamPicks[index];
                            final isSelected = _selectedTargetPicks.contains(pick);
                            final pickValue = DraftValueService.getValueForPick(pick.pickNumber);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
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
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4, right: 2),
                                  child: Row(
                                    children: [
                                      // Left side with value
                                      SizedBox(
                                        width: 30,
                                        child: Center(
                                          child: Text(
                                            '${pickValue.toInt()}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Middle section with pick info
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Pick #${pick.pickNumber}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Text(
                                                'Round ${pick.round}',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            ],
                                          ),
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
                    ],
                  ),
                ),
                
                const VerticalDivider(width: 16),
                
                // Right side - Current year picks + future picks
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header for your picks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your picks to offer:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              minimumSize: const Size(0, 24),
                            ),
                            onPressed: () {
                              setState(() {
                                if (_selectedUserPicks.length == widget.userPicks.length) {
                                  _selectedUserPicks.clear(); // Deselect all
                                } else {
                                  _selectedUserPicks = List.from(widget.userPicks); // Select all
                                }
                                _updateValues();
                              });
                            },
                            child: Text(
                              _selectedUserPicks.length == widget.userPicks.length ? 'Unselect All' : 'Select All',
                              style: const TextStyle(fontSize: 12)
                            ),
                          ),
                        ],
                      ),
                      
                      // Your current year picks
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: widget.userPicks.length,
                          itemBuilder: (context, index) {
                            final pick = widget.userPicks[index];
                            final isSelected = _selectedUserPicks.contains(pick);
                            final pickValue = DraftValueService.getValueForPick(pick.pickNumber);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
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
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4, right: 2),
                                  child: Row(
                                    children: [
                                      // Left side with value
                                      SizedBox(
                                        width: 30,
                                        child: Center(
                                          child: Text(
                                            '${pickValue.toInt()}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Middle section with pick info
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Pick #${pick.pickNumber}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Text(
                                                'Round ${pick.round}',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            ],
                                          ),
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
                      
                      // Future picks section - more compact
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('2026 Draft Picks to Include:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _availableFutureRounds.map((round) {
                                  bool isSelected = _selectedFutureRounds.contains(round);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(_getRoundText(round),
                                        style: const TextStyle(fontSize: 11)),
                                      selected: isSelected,
                                      visualDensity: VisualDensity.compact,
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                      padding: EdgeInsets.zero,
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
                ),
              ],
            ),
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