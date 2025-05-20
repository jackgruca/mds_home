import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_draft_settings.dart';
import '../models/ff_team.dart';
import '../models/ff_draft_pick.dart';
import '../models/ff_player.dart';
import '../models/ff_platform_ranks.dart';
import '../providers/ff_draft_provider.dart';
import '../widgets/ff_draft_board.dart';
import '../widgets/ff_team_roster.dart';
import '../widgets/ff_player_list.dart';
import '../widgets/ff_draft_timer.dart';
import '../widgets/ff_draft_queue.dart';
import '../widgets/ff_risk_players.dart';
import '../widgets/ff_rolling_picks.dart';

class FFDraftScreen extends StatefulWidget {
  final FFDraftSettings settings;
  final int? userPick;

  const FFDraftScreen({
    super.key,
    required this.settings,
    this.userPick,
  });

  @override
  State<FFDraftScreen> createState() => _FFDraftScreenState();
}

class _FFDraftScreenState extends State<FFDraftScreen> {
  late FFDraftProvider _draftProvider;
  bool _isInitialized = false;
  int _selectedTeamIndex = 0;
  bool _isPaused = true;
  int _timerKey = 0;

  void _resetTimer() {
    setState(() {
      _timerKey++;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeDraft();
  }

  Future<void> _initializeDraft() async {
    _draftProvider = FFDraftProvider(settings: widget.settings, userPick: widget.userPick);
    _draftProvider.onUserPick = _resetTimer;
    await _draftProvider.initializeDraft();
    setState(() {
      _selectedTeamIndex = _draftProvider.userTeamIndex;
      _isPaused = true;
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _draftProvider,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.settings.platform} ${widget.settings.scoringSystem} Draft'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Show draft settings dialog
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Timer and controls section
            FFDraftTimer(
              key: ValueKey(_timerKey),
              timePerPick: widget.settings.timePerPick,
              onTimeExpired: _draftProvider.handleTimeExpired,
              isPaused: _isPaused,
              onPlayPause: () {
                setState(() {
                  _isPaused = !_isPaused;
                });
                if (_isPaused) {
                  _draftProvider.pauseDraft();
                } else {
                  _draftProvider.startDraftSimulation();
                }
              },
              onUndo: _draftProvider.undoLastPick,
            ),
            FFRollingPicks(
              onPickSelected: _draftProvider.handlePickSelection,
            ),
            
            // Main draft area
            Expanded(
              child: Row(
                children: [
                  // Left panel with team selector and roster
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Team selector and player count in one row
                        Container(
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: DropdownButton<int>(
                            value: _selectedTeamIndex,
                            isExpanded: true,
                            items: _draftProvider.teams.asMap().entries.map((entry) {
                              return DropdownMenuItem<int>(
                                value: entry.key,
                                child: Text(entry.value.name),
                              );
                            }).toList(),
                            onChanged: (index) {
                              if (index != null) {
                                setState(() {
                                  _selectedTeamIndex = index;
                                });
                              }
                            },
                          ),
                        ),
                        // Team roster (real-time update)
                        Expanded(
                          child: Consumer<FFDraftProvider>(
                            builder: (context, provider, _) {
                              return FFTeamRoster(
                                team: provider.teams[_selectedTeamIndex],
                                onPlayerSelected: provider.handlePlayerSelection,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Available players
                  Expanded(
                    flex: 3,
                    child: Consumer<FFDraftProvider>(
                      builder: (context, provider, child) {
                        final isUserTurn = provider.isUserTurn();
                        return FFPlayerList(
                          onPlayerSelected: isUserTurn
                              ? provider.handlePlayerSelection
                              : (player) {}, // Disable selection if not user's turn
                        );
                      },
                    ),
                  ),
                  
                  // Right panel with queue and risk players
                  Expanded(
                    flex: 2,
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'Queue'),
                              Tab(text: 'At Risk'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                FFDraftQueue(
                                  onPlayerSelected: _draftProvider.handlePlayerSelection,
                                ),
                                FFRiskPlayers(
                                  onPlayerSelected: _draftProvider.handlePlayerSelection,
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
          ],
        ),
      ),
    );
  }
} 