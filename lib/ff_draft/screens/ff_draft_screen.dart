import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';

import '../models/ff_draft_settings.dart';
import '../providers/ff_draft_provider.dart';
import '../widgets/ff_team_roster.dart';
import '../widgets/ff_player_list.dart';
import '../widgets/ff_draft_queue.dart';
import '../widgets/ff_risk_players.dart';
import '../widgets/ff_rolling_picks.dart';
import '../widgets/ff_mobile_draft_interface.dart';
import '../widgets/ff_draft_insights_panel.dart';

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
    try {
      debugPrint('Creating FFDraftProvider...');
      _draftProvider = FFDraftProvider(settings: widget.settings, userPick: widget.userPick);
      _draftProvider.onUserPick = _resetTimer;
      
      debugPrint('Initializing draft...');
      await _draftProvider.initializeDraft();
      
      debugPrint('Draft initialization complete');
      debugPrint('Teams: ${_draftProvider.teams.length}');
      debugPrint('Available players: ${_draftProvider.availablePlayers.length}');
      debugPrint('Draft picks: ${_draftProvider.draftPicks.length}');
      
      setState(() {
        _selectedTeamIndex = _draftProvider.userTeamIndex;
        _isPaused = true;
        _isInitialized = true;
      });
      
      debugPrint('Screen initialization complete');
    } catch (e) {
      debugPrint('Error initializing draft: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      
      // Still set initialized to true so user can see error state
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: CustomAppBar(
          titleWidget: Row(
            children: [
              const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Expanded(child: TopNavBarContent(currentRoute: ModalRoute.of(context)?.settings.name)),
            ],
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing draft...'),
              SizedBox(height: 8),
              Text('Loading players and setting up teams'),
            ],
          ),
        ),
      );
    }

    // Check if provider is properly initialized
    if (_draftProvider.availablePlayers.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(
          titleWidget: Row(
            children: [
              const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Expanded(child: TopNavBarContent(currentRoute: ModalRoute.of(context)?.settings.name)),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('No players loaded', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Check debug console for details'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitialized = false;
                  });
                  _initializeDraft();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 700;

    return ChangeNotifierProvider.value(
      value: _draftProvider,
      child: Scaffold(
        appBar: CustomAppBar(
          titleWidget: Row(
            children: [
              const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Expanded(child: TopNavBarContent(currentRoute: ModalRoute.of(context)?.settings.name)),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: isMobile
            ? _buildMobileDraft(context)
            : _buildDesktopDraft(context),
      ),
    );
  }

  Widget _buildMobileDraft(BuildContext context) {
    return const FFMobileDraftInterface();
  }

  Widget _buildDesktopDraft(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Rolling picks moved to top - no header section
        FFRollingPicks(
          onPickSelected: _draftProvider.handlePickSelection,
          timerKey: _timerKey,
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
        
        // Main draft area with improved layout
        Expanded(
          child: Row(
            children: [
              // Left panel - Team rosters with improved selector
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.groups,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Team Rosters',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            DropdownButton<int>(
                              value: _selectedTeamIndex,
                              underline: const SizedBox.shrink(),
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
                          ],
                        ),
                      ),
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
              ),
              
              // Center panel - Available players with new UI
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                  ),
                  child: Consumer<FFDraftProvider>(
                    builder: (context, provider, child) {
                      return FFPlayerList(
                        onPlayerSelected: provider.handlePlayerSelection,
                      );
                    },
                  ),
                ),
              ),
              
              // Right panel - Enhanced queue and insights
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            border: Border(
                              bottom: BorderSide(
                                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: const TabBar(
                            tabs: [
                              Tab(text: 'Queue', icon: Icon(Icons.queue, size: 16)),
                              Tab(text: 'At Risk', icon: Icon(Icons.warning, size: 16)),
                              Tab(text: 'Insights', icon: Icon(Icons.analytics, size: 16)),
                            ],
                            labelStyle: TextStyle(fontSize: 12),
                            unselectedLabelStyle: TextStyle(fontSize: 12),
                          ),
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
                              // Real-time draft insights panel
                              const FFDraftInsightsPanel(),
                            ],
                          ),
                        ),
                      ],
                    ),
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