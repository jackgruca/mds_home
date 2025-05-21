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

    final isMobile = MediaQuery.of(context).size.width < 700;

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
        body: isMobile
            ? _buildMobileDraft(context)
            : _buildDesktopDraft(context),
      ),
    );
  }

  Widget _buildMobileDraft(BuildContext context) {
    return _MobileDraftScreen(
      draftProvider: _draftProvider,
      timerKey: _timerKey,
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
      selectedTeamIndex: _selectedTeamIndex,
      onTeamChanged: (index) {
        setState(() {
          _selectedTeamIndex = index;
        });
      },
    );
  }

  Widget _buildDesktopDraft(BuildContext context) {
    return Column(
      children: [
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
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedTeamIndex = val;
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
                          : (player) {},
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
    );
  }
}

class _MobileQueueAtRiskTab extends StatefulWidget {
  final FFDraftProvider draftProvider;
  const _MobileQueueAtRiskTab({required this.draftProvider});

  @override
  State<_MobileQueueAtRiskTab> createState() => _MobileQueueAtRiskTabState();
}

class _MobileQueueAtRiskTabState extends State<_MobileQueueAtRiskTab> {
  bool showQueue = true;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => setState(() => showQueue = true),
              child: Text('Queue', style: TextStyle(fontWeight: showQueue ? FontWeight.bold : FontWeight.normal)),
            ),
            TextButton(
              onPressed: () => setState(() => showQueue = false),
              child: Text('At Risk', style: TextStyle(fontWeight: !showQueue ? FontWeight.bold : FontWeight.normal)),
            ),
          ],
        ),
        Expanded(
          child: showQueue
              ? FFDraftQueue(onPlayerSelected: widget.draftProvider.handlePlayerSelection)
              : FFRiskPlayers(onPlayerSelected: widget.draftProvider.handlePlayerSelection),
        ),
      ],
    );
  }
}

class _MobileDraftScreen extends StatefulWidget {
  final FFDraftProvider draftProvider;
  final int timerKey;
  final bool isPaused;
  final VoidCallback onPlayPause;
  final VoidCallback onUndo;
  final int selectedTeamIndex;
  final ValueChanged<int> onTeamChanged;
  const _MobileDraftScreen({
    required this.draftProvider,
    required this.timerKey,
    required this.isPaused,
    required this.onPlayPause,
    required this.onUndo,
    required this.selectedTeamIndex,
    required this.onTeamChanged,
  });

  @override
  State<_MobileDraftScreen> createState() => _MobileDraftScreenState();
}

class _MobileDraftScreenState extends State<_MobileDraftScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _lastPickIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    widget.draftProvider.addListener(_onDraftProviderChange);
  }

  @override
  void dispose() {
    widget.draftProvider.removeListener(_onDraftProviderChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onDraftProviderChange() {
    final currentPick = widget.draftProvider.getCurrentPick();
    if (currentPick == null) return;
    final isUserTurn = currentPick.isUserPick;
    final currentPickIndex = widget.draftProvider.draftPicks.indexOf(currentPick);
    // Auto-switch to Available tab when it's user's turn
    if (isUserTurn && _tabController.index != 1) {
      _tabController.animateTo(1);
    }
    _lastPickIndex = currentPickIndex;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          FFDraftTimer(
            key: ValueKey(widget.timerKey),
            timePerPick: widget.draftProvider.settings.timePerPick,
            onTimeExpired: widget.draftProvider.handleTimeExpired,
            isPaused: widget.isPaused,
            onPlayPause: widget.onPlayPause,
            onUndo: widget.onUndo,
          ),
          TabBar(
            controller: _tabController,
            indicator: const BoxDecoration(
              color: Colors.green,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black87,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            tabs: const [
              Tab(text: 'Draft Order'),
              Tab(text: 'Available'),
              Tab(text: 'My Roster'),
              Tab(text: 'Queue / At Risk'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Draft Order (vertical for mobile, with auto-scroll and real-time updates)
                Consumer<FFDraftProvider>(
                  builder: (context, provider, _) {
                    return _MobileDraftOrderList(
                      draftProvider: provider,
                    );
                  },
                ),
                // Available Players
                Consumer<FFDraftProvider>(
                  builder: (context, provider, child) {
                    final isUserTurn = provider.isUserTurn();
                    return FFPlayerList(
                      onPlayerSelected: isUserTurn
                          ? provider.handlePlayerSelection
                          : (player) {},
                    );
                  },
                ),
                // My Roster
                Consumer<FFDraftProvider>(
                  builder: (context, provider, _) {
                    return _MobileRosterWithDropdown(
                      teams: provider.teams,
                      selectedTeamIndex: widget.selectedTeamIndex,
                      onTeamChanged: widget.onTeamChanged,
                      onPlayerSelected: provider.handlePlayerSelection,
                    );
                  },
                ),
                // Queue / At Risk with toggle
                _MobileQueueAtRiskTab(draftProvider: widget.draftProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDraftOrderList extends StatefulWidget {
  final FFDraftProvider draftProvider;
  const _MobileDraftOrderList({required this.draftProvider});

  @override
  State<_MobileDraftOrderList> createState() => _MobileDraftOrderListState();
}

class _MobileDraftOrderListState extends State<_MobileDraftOrderList> {
  final ScrollController _scrollController = ScrollController();
  int _lastScrollToIndex = -1;

  @override
  void didUpdateWidget(covariant _MobileDraftOrderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scrollToCurrentPick();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollToCurrentPick();
  }

  void _scrollToCurrentPick() {
    final picks = widget.draftProvider.draftPicks;
    final currentPick = widget.draftProvider.getCurrentPick();
    if (currentPick == null) return;
    final currentIndex = picks.indexOf(currentPick);
    if (currentIndex != _lastScrollToIndex && currentIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          (currentIndex * 72.0).clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      _lastScrollToIndex = currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final picks = widget.draftProvider.draftPicks;
    final currentPick = widget.draftProvider.getCurrentPick();
    final numTeams = widget.draftProvider.teams.length;
    return ListView.builder(
      controller: _scrollController,
      itemCount: picks.length,
      itemBuilder: (context, index) {
        final pick = picks[index];
        final isCurrent = pick == currentPick;
        final isUserPick = pick.isUserPick;
        final pos = pick.selectedPlayer?.position;
        final posColor = _getPositionColor(pos);
        final pickNumber = pick.pickNumber;
        final round = pick.round;
        final pickInRound = pickNumber - (round - 1) * numTeams;
        final teamName = pick.team.name;
        final roundColor = _getRoundColor(round);
        final player = pick.selectedPlayer;
        return Card(
          color: isCurrent
              ? Colors.blue.withOpacity(0.15)
              : (player != null
                  ? posColor.withOpacity(0.10)
                  : Colors.grey[50]),
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: roundColor,
              child: Text(
                pickNumber.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: player != null
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPositionBadge(player.position),
                    ],
                  )
                : Text(
                    'Pick $pickNumber ($round.$pickInRound) - $teamName',
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.blue : null,
                    ),
                  ),
            subtitle: player != null
                ? Text('$round.$pickInRound $teamName')
                : null,
            trailing: isUserPick && player == null ? const Icon(Icons.person, color: Colors.blue) : null,
            onTap: isUserPick && player == null ? () => widget.draftProvider.handlePickSelection(pick) : null,
          ),
        );
      },
    );
  }

  Color _getPositionColor(String? position) {
    switch (position) {
      case 'QB':
        return Colors.blue;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.orange;
      case 'TE':
        return Colors.purple;
      case 'K':
        return Colors.red;
      case 'DEF':
      case 'D/ST':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Color _getRoundColor(int round) {
    // Cycle through a palette for rounds
    const palette = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.brown
    ];
    return palette[(round - 1) % palette.length];
  }

  Widget _buildPositionBadge(String position) {
    Color color;
    switch (position) {
      case 'QB':
        color = Colors.blue;
        break;
      case 'RB':
        color = Colors.green;
        break;
      case 'WR':
        color = Colors.orange;
        break;
      case 'TE':
        color = Colors.purple;
        break;
      case 'K':
        color = Colors.red;
        break;
      case 'DEF':
      case 'D/ST':
        color = Colors.brown;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        position,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MobileRosterWithDropdown extends StatelessWidget {
  final List<FFTeam> teams;
  final int selectedTeamIndex;
  final ValueChanged<int> onTeamChanged;
  final Function(FFPlayer) onPlayerSelected;
  const _MobileRosterWithDropdown({
    required this.teams,
    required this.selectedTeamIndex,
    required this.onTeamChanged,
    required this.onPlayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Starters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: selectedTeamIndex,
                underline: const SizedBox.shrink(),
                items: teams.asMap().entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onTeamChanged(val);
                },
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        Expanded(
          child: FFTeamRoster(
            team: teams[selectedTeamIndex],
            onPlayerSelected: onPlayerSelected,
          ),
        ),
      ],
    );
  }
} 