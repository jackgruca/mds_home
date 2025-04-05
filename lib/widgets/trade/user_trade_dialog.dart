import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/trade_package.dart';
import '../../services/draft_value_service.dart';
import '../../models/future_pick.dart';
import '../../utils/team_logo_utils.dart';

class UserTradeProposalDialog extends StatefulWidget {
  final String userTeam;
  final List<DraftPick> userPicks;
  final List<DraftPick> targetPicks;
  final List<DraftPick>? initialSelectedUserPicks;
  final List<DraftPick>? initialSelectedTargetPicks;
  final List<int>? initialSelectedUserFutureRounds;
  final List<int>? initialSelectedTargetFutureRounds;
  final List<int> availableFutureRounds; // NEW PROPERTY
  final Function(TradePackage) onPropose;
  final VoidCallback onCancel;
  final bool isEmbedded;
  final bool hasLeverage;
  final VoidCallback? onBack;

  const UserTradeProposalDialog({
    super.key,
    required this.userTeam,
    required this.userPicks,
    required this.targetPicks,
    required this.onPropose,
    required this.onCancel,
    this.initialSelectedUserPicks,
    this.initialSelectedTargetPicks, 
    this.initialSelectedUserFutureRounds,
    this.initialSelectedTargetFutureRounds,
    this.availableFutureRounds = const [], // Default to empty list
    this.hasLeverage = false,
    this.isEmbedded = false,
    this.onBack,
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
  bool _forceTradeEnabled = false;

  
  @override
void initState() {
  super.initState();
  if (widget.targetPicks.isNotEmpty) {
    _targetTeam = widget.targetPicks.first.teamName;
  } else {
    _targetTeam = "";
  }

  // Initialize with pre-selected picks if provided
  if (widget.initialSelectedUserPicks != null) {
    _selectedUserPicks = List.from(widget.initialSelectedUserPicks!);
  }
  
  if (widget.initialSelectedTargetPicks != null) {
    _selectedTargetPicks = List.from(widget.initialSelectedTargetPicks!);
  }
  
  // Initialize future picks if provided
  if (widget.initialSelectedUserFutureRounds != null) {
    _selectedFutureRounds = List.from(widget.initialSelectedUserFutureRounds!);
  }
  
  if (widget.initialSelectedTargetFutureRounds != null) {
    _selectedTargetFutureRounds = List.from(widget.initialSelectedTargetFutureRounds!);
  }
  
  // Update values based on selections
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
    final List<int> displayAvailableFutureRounds = widget.availableFutureRounds.isEmpty 
      ? [1, 2, 3, 4, 5, 6, 7] // Fallback to all rounds if not specified
      : widget.availableFutureRounds;
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
        // Main content area - two columns side by side (Their team | Your team)
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Their team
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team selection dropdown (made to match size on right)
                      Container(
                        width: double.infinity,
                        height: 36.0,
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people, size: 16, color: Colors.blue),
                            const SizedBox(width: 6),
                            const Text(
                              'Trade with:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Spacer(),
                            if (targetTeams.isNotEmpty)
                              DropdownButton<String>(
                                value: targetTeams.contains(_targetTeam) ? _targetTeam : targetTeams.first,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _targetTeam = newValue;
                                      
                                      // Only clear selections if they're from a different team
                                      if (widget.initialSelectedTargetPicks != null) {
                                        // Keep only the selected picks that belong to the new target team
                                        _selectedTargetPicks = _selectedTargetPicks
                                          .where((pick) => pick.teamName == newValue)
                                          .toList();
                                      } else {
                                        // If no initial selections, just clear the list
                                        _selectedTargetPicks.clear();
                                      }
                                      
                                      // Clear future rounds since they're team-specific
                                      _selectedTargetFutureRounds.clear();
                                    });
                                    _updateValues();
                                  }
                                },
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.blue.shade800, // Always use dark blue for visibility
                                ),
                                iconSize: 24,
                                items: targetTeams.map<DropdownMenuItem<String>>((String team) {
                                  return DropdownMenuItem<String>(
                                    value: team,
                                    child: Row(
                                      children: [
                                        TeamLogoUtils.buildNFLTeamLogo(
                                          team,
                                          size: 24.0,

                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          team, 
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.dark 
                                              ? Colors.black87 
                                              : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : Colors.black87,
                                ),
                                underline: Container(height: 0),
                                dropdownColor: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey.shade700 
                                  : Colors.white,
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Sub-header for their picks (more compact)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                        child: Text(
                          'Their picks to receive:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      // Draft years header row
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Text('2025 Draft', style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                )),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text('2026 Draft', style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                )),
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
                                      side: BorderSide(
                                        color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    color: isSelected ? Colors.blue.shade50 : null,
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
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 50, // Slightly smaller height
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Round & Pick on same line
                                            Row(
                                              children: [
                                                Text(
                                                  pick.round,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold, 
                                                    fontSize: 11,
                                                    color: isSelected ? Colors.blue.shade700 : null,
                                                  ),
                                                ),
                                                const Text(' | ', style: TextStyle(color: Colors.grey)),
                                                Text(
                                                  'Pick #${pick.pickNumber}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold, 
                                                    fontSize: 11,
                                                    color: isSelected ? Colors.blue.shade700 : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Value underneath
                                            Text(
                                              'Value: ${pickValue.toInt()}',
                                              style: TextStyle(
                                                fontSize: 10, 
                                                color: isSelected ? Colors.blue.shade400 : Colors.grey,
                                              ),
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
    itemCount: displayAvailableFutureRounds.length,
    itemBuilder: (context, index) {
      final round = displayAvailableFutureRounds[index];
                                  final isSelected = _selectedTargetFutureRounds.contains(round);
                                  final futurePick = FuturePick.forRound(_targetTeam, round);
                                  final pickValue = futurePick.value;
                                  
                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSelected ? Colors.amber.shade400 : Colors.grey.shade300,
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    color: isSelected ? Colors.amber.shade50 : null,
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
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 50, // Slightly smaller height
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_getRoundText(round)} Round',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold, 
                                                fontSize: 11,
                                                color: isSelected ? Colors.amber.shade800 : null,
                                              ),
                                            ),
                                            Text(
                                              'Est. Value: ${pickValue.toInt()}',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: isSelected ? Colors.amber.shade600 : Colors.grey,
                                              ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team indicator with used capital (more compact)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Your team: ${widget.userTeam}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Sub-header for your picks (more compact)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                        child: Text(
                          'Your picks to offer:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      // Draft years header row (reuse the same compact header)
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Text('2025 Draft', style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                )),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text('2026 Draft', style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                )),
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
                                      side: BorderSide(
                                        color: isSelected ? Colors.green.shade400 : Colors.grey.shade300,
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    color: isSelected ? Colors.green.shade50 : null,
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
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 50, // Slightly smaller height
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Round & Pick on same line
                                            Row(
                                              children: [
                                                Text(
                                                  pick.round,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold, 
                                                    fontSize: 11,
                                                    color: isSelected ? Colors.green.shade700 : null,
                                                  ),
                                                ),
                                                const Text(' | ', style: TextStyle(color: Colors.grey)),
                                                Text(
                                                  'Pick #${pick.pickNumber}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold, 
                                                    fontSize: 11,
                                                    color: isSelected ? Colors.green.shade700 : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Value underneath
                                            Text(
                                              'Value: ${pickValue.toInt()}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isSelected ? Colors.green.shade400 : Colors.grey,
                                              ),
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
    itemCount: displayAvailableFutureRounds.length,
    itemBuilder: (context, index) {
      final round = displayAvailableFutureRounds[index];
                                  final isSelected = _selectedFutureRounds.contains(round);
                                  final futurePick = FuturePick.forRound(widget.userTeam, round);
                                  final pickValue = futurePick.value;
                                  
                                  return Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isSelected ? Colors.orange.shade400 : Colors.grey.shade300,
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    color: isSelected ? Colors.orange.shade50 : null,
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
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 50, // Slightly smaller height
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${_getRoundText(round)} Round',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold, 
                                                fontSize: 11,
                                                color: isSelected ? Colors.orange.shade700 : null,
                                              ),
                                            ),
                                            Text(
                                              'Est. Value: ${pickValue.toInt()}',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: isSelected ? Colors.orange.shade600 : Colors.grey,
                                              ),
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
        // Find this section in your build method
        Container(
          color: Theme.of(context).brightness == Brightness.dark ? 
            Colors.grey.shade800 : Colors.grey.shade100,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar, trade values, etc.
              Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: Theme.of(context).brightness == Brightness.dark ? 
          _getTradeAdviceColor().withOpacity(0.2) : _getTradeAdviceColor().withOpacity(0.1),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: _getTradeAdviceColor().withOpacity(0.5)),
  ),
  child: Row(
    children: [
      Icon(
        _getTradeAdviceIcon(),
        size: 16,
        color: _getTradeAdviceColor(),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          _getTradeAdviceText(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11, 
            color: _getTradeAdviceColor(),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      // Add leverage indicator here if applicable
      if (widget.hasLeverage)
        Tooltip(
          message: "You have leverage in this negotiation. The offering team is eager to acquire your pick.",
          waitDuration: const Duration(milliseconds: 500),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue, width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 12,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 2),
                    Text(
                      "Leverage",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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

              const SizedBox(height: 8),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? 
                            Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              width: constraints.maxWidth * (_totalOfferedValue > 0 && _targetPickValue > 0 ? 
                                        (_totalOfferedValue / _targetPickValue).clamp(0.0, 1.0) : 0.0),
                              decoration: BoxDecoration(
                                color: _getTradeAdviceColor(),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Value info text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your value: ${_totalOfferedValue.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark ? 
                              Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'Their value: ${_targetPickValue.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark ? 
                              Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
                  
              const SizedBox(height: 8),
              
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.onBack != null && widget.isEmbedded)
                    TextButton(
                      onPressed: widget.onBack,
                      child: const Text('Back to Offers'),
                    ),
                  const SizedBox(width: 8),
                  // Add the force trade checkbox here
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _forceTradeEnabled,
                          onChanged: (value) {
                            setState(() {
                              _forceTradeEnabled = value ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _forceTradeEnabled = !_forceTradeEnabled;
                          });
                        },
                        child: Text(
                          "Force Trade",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark ? 
                                  Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _canProposeTrade() ? _proposeTrade : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTradeAdviceColor(),
                      foregroundColor: Colors.white,
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
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: content,
      ),
      // Only show Cancel in the dialog actions
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
  
  // Re-added methods for trade advice
  IconData _getTradeAdviceIcon() {
    double valueRatio = _targetPickValue > 0 ? _totalOfferedValue / _targetPickValue : 0;
    
    if (valueRatio >= 1.2) {
      return Icons.thumb_up;
    } else if (valueRatio >= 1.0) {
      return Icons.check_circle;
    } else if (valueRatio >= 0.9) {
      return Icons.info_outline;
    } else {
      return Icons.warning;
    }
  }
  
String _getTradeAdviceText() {
  if (_totalOfferedValue >= _targetPickValue * 1.2) {
    return widget.hasLeverage ? 'Great offer - they\'ll accept!' : 'Great offer - they\'ll likely accept!';
  } else if (_totalOfferedValue >= _targetPickValue) {
    return widget.hasLeverage ? 'Fair offer - they\'ll accept.' : 'Fair offer - they may accept.';
  } else if (_totalOfferedValue >= _targetPickValue * 0.9) {
    return widget.hasLeverage ? 'Below value - but still acceptable.' : 'Slightly below market value - but still possible.';
  } else {
    return widget.hasLeverage ? 'Poor value - but they might accept.' : 'Poor value - they\'ll likely reject.';
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
  
  bool _canProposeTrade() {
    return (_selectedUserPicks.isNotEmpty || _selectedFutureRounds.isNotEmpty) && 
           (_selectedTargetPicks.isNotEmpty || _selectedTargetFutureRounds.isNotEmpty);
  }
  
  void _proposeTrade() {
  // Create future pick descriptions

  List<String> futurePickDescriptions = [];
  List<FuturePick> futurePicks = [];
  double futurePicksValue = 0;
  
  for (var round in _selectedFutureRounds) {
    futurePickDescriptions.add("2026 ${_getRoundText(round)} Round");
    final futurePick = FuturePick.forRound(widget.userTeam, round);
    futurePicks.add(futurePick);
    futurePicksValue += futurePick.value;
  }
  
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
    targetPick: _selectedTargetPicks.isNotEmpty 
  ? _selectedTargetPicks.first 
  : _selectedTargetFutureRounds.isNotEmpty
      ? DraftPick(
          pickNumber: 1000 + _selectedTargetFutureRounds.first,
          teamName: _targetTeam,
          round: _selectedTargetFutureRounds.first.toString(),
        )
      : DraftPick(
          pickNumber: 999,
          teamName: _targetTeam,
          round: "1",
        ),

    totalValueOffered: _totalOfferedValue,
    targetPickValue: _targetPickValue,
    additionalTargetPicks: _selectedTargetPicks.length > 1 ? _selectedTargetPicks.sublist(1) : [],
    includesFuturePick: _selectedFutureRounds.isNotEmpty,
    futurePickDescription: _selectedFutureRounds.isNotEmpty ? futurePickDescriptions.join(", ") : null,
    futurePickValue: futurePicksValue > 0 ? futurePicksValue : null,
    forceAccept: _forceTradeEnabled,
    offeredFuturePicks: futurePicks.isNotEmpty ? futurePicks : null, // NEW: Add future picks
  );
  } else {
    // Normal trade with current year picks
    package = TradePackage(
      teamOffering: widget.userTeam,
      teamReceiving: _targetTeam,
      picksOffered: _selectedUserPicks,
      targetPick: _selectedTargetPicks.isNotEmpty 
        ? _selectedTargetPicks.first 
        : _selectedTargetFutureRounds.isNotEmpty
            ? DraftPick(
                pickNumber: 1000 + _selectedTargetFutureRounds.first,
                teamName: _targetTeam,
                round: _selectedTargetFutureRounds.first.toString(),
              )
            : DraftPick(
                pickNumber: 999,
                teamName: _targetTeam,
                round: "1",
              ),
      totalValueOffered: _totalOfferedValue,
      targetPickValue: _targetPickValue,
      additionalTargetPicks: _selectedTargetPicks.length > 1 ? 
          _selectedTargetPicks.sublist(1) : [],
      includesFuturePick: _selectedFutureRounds.isNotEmpty,
      futurePickDescription: _selectedFutureRounds.isNotEmpty ? 
          futurePickDescriptions.join(", ") : null,
      futurePickValue: futurePicksValue > 0 ? futurePicksValue : null,
      // Add this line to include the force trade flag
      forceAccept: _forceTradeEnabled,
    );
  }
  
  // Call the propose callback with the package
  widget.onPropose(package);
}

  String _getRoundText(int round) {
    if (round == 1) return "1st";
    if (round == 2) return "2nd";
    if (round == 3) return "3rd";
    return "${round}th";
  }
}