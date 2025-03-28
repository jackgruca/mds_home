// lib/screens/customize_draft_tab.dart
import 'package:flutter/material.dart';
import 'team_needs_editor.dart';
import 'player_rankings_editor.dart';
import '../services/data_service.dart';

class CustomizeDraftTabView extends StatefulWidget {
  final int selectedYear;
  final Function(List<List<dynamic>>) onTeamNeedsChanged;
  final Function(List<List<dynamic>>) onPlayerRankingsChanged;
  final List<List<dynamic>>? initialTeamNeeds;
  final List<List<dynamic>>? initialPlayerRankings;

  const CustomizeDraftTabView({
    super.key,
    required this.selectedYear,
    required this.onTeamNeedsChanged,
    required this.onPlayerRankingsChanged,
    this.initialTeamNeeds,
    this.initialPlayerRankings,
  });

  @override
  State<CustomizeDraftTabView> createState() => _CustomizeDraftTabViewState();
}

class _CustomizeDraftTabViewState extends State<CustomizeDraftTabView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<List<dynamic>>? _teamNeeds;
  List<List<dynamic>>? _playerRankings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _teamNeeds = widget.initialTeamNeeds;
    _playerRankings = widget.initialPlayerRankings;
    
    if (_teamNeeds == null || _playerRankings == null) {
      _loadData();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load team needs if not provided
      if (_teamNeeds == null) {
        final teamNeeds = await DataService.loadTeamNeeds(year: widget.selectedYear);
        _teamNeeds = DataService.teamNeedsToLists(teamNeeds);
      }
      
      // Load player rankings if not provided
      if (_playerRankings == null) {
        final players = await DataService.loadAvailablePlayers(year: widget.selectedYear);
        _playerRankings = DataService.playersToLists(players);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading data for customization: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Team Needs'),
            Tab(text: 'Player Rankings'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Team Needs Editor Tab
              TeamNeedsEditor(
                teamNeeds: _teamNeeds ?? [],
                onTeamNeedsChanged: (updatedNeeds) {
                  setState(() {
                    _teamNeeds = updatedNeeds;
                  });
                  widget.onTeamNeedsChanged(updatedNeeds);
                },
              ),
              
              // Player Rankings Editor Tab
              PlayerRankingsEditor(
                playerRankings: _playerRankings ?? [],
                onPlayerRankingsChanged: (updatedRankings) {
                  setState(() {
                    _playerRankings = updatedRankings;
                  });
                  widget.onPlayerRankingsChanged(updatedRankings);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}