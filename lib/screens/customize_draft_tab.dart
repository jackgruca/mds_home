import 'package:flutter/material.dart';
import 'team_needs_editor.dart';
//import 'player_rankings_editor.dart';

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
    
    // For now we'll just use the initialTeamNeeds
    // In Phase 1, we'll only implement team needs editing
    _teamNeeds ??= widget.initialTeamNeeds ?? [];
    
    setState(() {
      _isLoading = false;
    });
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
              
              // Player Rankings Editor Tab (Placeholder for Phase 2)
              const Center(
                child: Text('Player Rankings Editor - Coming in Phase 2'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}