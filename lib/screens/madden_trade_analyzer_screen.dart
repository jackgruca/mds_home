// lib/screens/madden_trade_analyzer_screen.dart

import 'package:flutter/material.dart';
import '../models/nfl_trade/nfl_player.dart';
import '../models/nfl_trade/nfl_team_info.dart';
import '../models/nfl_trade/trade_asset.dart';
import '../widgets/trade/player_selection_modal.dart';
import '../services/nfl_roster_service.dart';

class MaddenTradeAnalyzerScreen extends StatefulWidget {
  const MaddenTradeAnalyzerScreen({super.key});

  @override
  State<MaddenTradeAnalyzerScreen> createState() => _MaddenTradeAnalyzerScreenState();
}

class _MaddenTradeAnalyzerScreenState extends State<MaddenTradeAnalyzerScreen> {
  NFLTeamInfo? team1;
  NFLTeamInfo? team2;
  TeamTradePackage? team1Package;
  TeamTradePackage? team2Package;
  double tradeLikelihood = 0.0;

  // Sample teams with more detailed info
  final List<NFLTeamInfo> allTeams = [
    NFLTeamInfo(
      teamName: 'Dallas Cowboys',
      abbreviation: 'DAL',
      availableCapSpace: 15.2,
      totalCapSpace: 255.4,
      projectedCapSpace2025: 28.7,
      philosophy: TeamPhilosophy.balanced,
      status: TeamStatus.competitive,
      positionNeeds: {
        'RB': 0.8,
        'S': 0.7,
        'DT': 0.6,
        'LB': 0.5,
      },
      availableDraftPicks: [24, 56, 87, 119, 151, 183, 215],
      futureFirstRounders: 1,
      tradeAggressiveness: 0.6,
    ),
    NFLTeamInfo(
      teamName: 'Buffalo Bills',
      abbreviation: 'BUF',
      availableCapSpace: 45.2,
      totalCapSpace: 255.4,
      projectedCapSpace2025: 62.1,
      philosophy: TeamPhilosophy.winNow,
      status: TeamStatus.contending,
      positionNeeds: {
        'WR': 0.9,
        'EDGE': 0.7,
        'CB': 0.6,
        'S': 0.5,
      },
      availableDraftPicks: [28, 60, 92, 124, 156, 188, 220],
      futureFirstRounders: 1,
      tradeAggressiveness: 0.8,
      willingToOverpay: true,
    ),
    NFLTeamInfo(
      teamName: 'Detroit Lions',
      abbreviation: 'DET',
      availableCapSpace: 38.7,
      totalCapSpace: 255.4,
      projectedCapSpace2025: 55.3,
      philosophy: TeamPhilosophy.aggressive,
      status: TeamStatus.contending,
      positionNeeds: {
        'EDGE': 0.8,
        'CB': 0.7,
        'S': 0.6,
        'LB': 0.5,
      },
      availableDraftPicks: [24, 56, 88, 120, 152, 184, 216],
      futureFirstRounders: 1,
      tradeAggressiveness: 0.9,
      willingToOverpay: true,
    ),
  ];

  // Sample roster players
  final Map<String, List<NFLPlayer>> teamRosters = {
    'DAL': [
      NFLPlayer(
        playerId: 'micah_parsons_dal',
        name: 'Micah Parsons',
        position: 'EDGE',
        team: 'DAL',
        age: 25,
        experience: 3,
        marketValue: 45.0,
        contractStatus: 'extension',
        contractYearsRemaining: 2,
        annualSalary: 22.0,
        overallRating: 95.0,
        positionRank: 98.0,
        ageAdjustedValue: 49.5,
        positionImportance: 0.9,
        durabilityScore: 88.0,
      ),
      NFLPlayer(
        playerId: 'ceedee_lamb_dal',
        name: 'CeeDee Lamb',
        position: 'WR',
        team: 'DAL',
        age: 25,
        experience: 4,
        marketValue: 38.0,
        contractStatus: 'extension',
        contractYearsRemaining: 4,
        annualSalary: 30.0,
        overallRating: 90.0,
        positionRank: 92.0,
        ageAdjustedValue: 41.8,
        positionImportance: 0.75,
        durabilityScore: 90.0,
      ),
    ],
    'BUF': [
      NFLPlayer(
        playerId: 'josh_allen_buf',
        name: 'Josh Allen',
        position: 'QB',
        team: 'BUF',
        age: 28,
        experience: 6,
        marketValue: 55.0,
        contractStatus: 'extension',
        contractYearsRemaining: 3,
        annualSalary: 43.0,
        overallRating: 94.0,
        positionRank: 96.0,
        ageAdjustedValue: 55.0,
        positionImportance: 1.0,
        durabilityScore: 85.0,
      ),
    ],
    'DET': [
      NFLPlayer(
        playerId: 'amon_ra_det',
        name: 'Amon-Ra St. Brown',
        position: 'WR',
        team: 'DET',
        age: 25,
        experience: 3,
        marketValue: 32.0,
        contractStatus: 'extension',
        contractYearsRemaining: 3,
        annualSalary: 24.0,
        overallRating: 88.0,
        positionRank: 85.0,
        ageAdjustedValue: 35.2,
        positionImportance: 0.75,
        durabilityScore: 92.0,
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFL Trade Machine'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildTradeHeader(),
            _buildTradeLikelihoodBar(),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildTeamPanel(isTeam1: true)),
                  _buildVersusIndicator(),
                  Expanded(child: _buildTeamPanel(isTeam1: false)),
                ],
              ),
            ),
            _buildTradeActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz,
            size: 28,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Trade Machine',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeLikelihoodBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trade Likelihood',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${(tradeLikelihood * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _getLikelihoodColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: tradeLikelihood,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(_getLikelihoodColor()),
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            _getLikelihoodText(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPanel({required bool isTeam1}) {
    NFLTeamInfo? team = isTeam1 ? team1 : team2;
    TeamTradePackage? package = isTeam1 ? team1Package : team2Package;
    
    return Container(
      margin: EdgeInsets.only(
        left: isTeam1 ? 16 : 8,
        right: isTeam1 ? 8 : 16,
        top: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: team != null ? Theme.of(context).primaryColor.withValues(alpha: 0.3) : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTeamHeader(team, isTeam1),
          if (team != null) ...[
            _buildCapSpaceInfo(team),
            _buildTradeSlots(package!, team),
            _buildAssetBrowser(team),
          ] else ...[
            const Expanded(
              child: Center(
                child: Text(
                  'Select a team to start trading',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamHeader(NFLTeamInfo? team, bool isTeam1) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: team != null ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: team != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.teamName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        team.abbreviation,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Select Team',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showTeamSelector(isTeam1),
            icon: const Icon(Icons.edit, size: 16),
            label: Text(team != null ? 'Change' : 'Select'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapSpaceInfo(NFLTeamInfo team) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cap Space',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '\$${team.availableCapSpace.toStringAsFixed(1)}M',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Trade Value',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '\$${(team == team1 ? (team1Package?.totalValue ?? 0.0) : (team2Package?.totalValue ?? 0.0)).toStringAsFixed(1)}M',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeSlots(TeamTradePackage package, NFLTeamInfo team) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trade Package',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320, // Fixed height for 5 slots (60 + 8 margin each = 68 * 5 = 340, minus last margin)
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                final slot = package.slots[index];
                return _buildTradeSlot(slot, team);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeSlot(TradeSlot slot, NFLTeamInfo team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(
          color: slot.isFilled ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: slot.isFilled ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Colors.grey[50],
      ),
      child: slot.isFilled
          ? _buildFilledSlot(slot.asset!, slot.slotIndex, team)
          : _buildEmptySlot(slot.slotIndex, team),
    );
  }

  Widget _buildFilledSlot(TradeAsset asset, int slotIndex, NFLTeamInfo team) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(
          asset.type == TradeAssetType.player ? Icons.person : Icons.confirmation_number,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        asset.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        asset.description,
        style: const TextStyle(fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 16),
        onPressed: () => _removeAssetFromSlot(slotIndex, team),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildEmptySlot(int slotIndex, NFLTeamInfo team) {
    return InkWell(
      onTap: () => _showAssetSelectionDialog(team),
      borderRadius: BorderRadius.circular(8),
      child: const SizedBox(
        height: 60,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                'Add Player or Pick',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetBrowser(NFLTeamInfo team) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Assets',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Players'),
                        Tab(text: 'Picks'),
                      ],
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildPlayerList(team),
                          _buildPickList(team),
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
    );
  }

  Widget _buildPlayerList(NFLTeamInfo team) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showPlayerSelectionModal(team),
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Browse Players'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search and filter ${team.teamName} roster',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickList(NFLTeamInfo team) {
    List<DraftPickAsset> picks = _generateTeamPicks(team);
    
    return ListView.builder(
      itemCount: picks.length,
      itemBuilder: (context, index) {
        DraftPickAsset pick = picks[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.orange.withValues(alpha: 0.2),
            child: Text(
              pick.round.toString(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            pick.displayName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Value: \$${pick.marketValue.toStringAsFixed(1)}M',
            style: const TextStyle(fontSize: 10),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => _addPickAsset(pick, team),
          ),
        );
      },
    );
  }

  Widget _buildVersusIndicator() {
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.compare_arrows,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'VS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeActions() {
    bool canAnalyze = team1 != null && team2 != null && _hasAnyAssets();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: canAnalyze ? _analyzeTrade : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Analyze Trade',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton(
              onPressed: _clearTrade,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Clear Trade',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTeamSelector(bool isTeam1) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Team',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...allTeams.map((team) {
                // Don't show the other selected team
                NFLTeamInfo? otherTeam = isTeam1 ? team2 : team1;
                if (otherTeam != null && team.abbreviation == otherTeam.abbreviation) {
                  return const SizedBox.shrink();
                }
                
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(team.abbreviation),
                  ),
                  title: Text(team.teamName),
                  subtitle: Text('Cap Space: \$${team.availableCapSpace.toStringAsFixed(1)}M'),
                  onTap: () {
                    setState(() {
                      if (isTeam1) {
                        team1 = team;
                        team1Package = TeamTradePackage(teamName: team.teamName);
                      } else {
                        team2 = team;
                        team2Package = TeamTradePackage(teamName: team.teamName);
                      }
                    });
                    Navigator.pop(context);
                    _updateTradeLikelihood();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  List<DraftPickAsset> _generateTeamPicks(NFLTeamInfo team) {
    List<DraftPickAsset> picks = [];
    
    // Current year picks
    for (int pickNumber in team.availableDraftPicks) {
      int round = ((pickNumber - 1) ~/ 32) + 1;
      picks.add(DraftPickAsset(
        year: DateTime.now().year,
        round: round,
        pickNumber: pickNumber,
        originalTeam: 'Current',
      ));
    }
    
    // Future picks
    for (int i = 0; i < team.futureFirstRounders; i++) {
      picks.add(DraftPickAsset(
        year: DateTime.now().year + 1 + i,
        round: 1,
        originalTeam: 'Current',
      ));
    }
    
    return picks;
  }

  void _showPlayerSelectionModal(NFLTeamInfo team) {
    showDialog(
      context: context,
      builder: (context) {
        return PlayerSelectionModal(
          teamName: team.teamName,
          teamAbbreviation: team.abbreviation,
          onPlayerSelected: (player) {
            _addPlayerAsset(player, team);
          },
        );
      },
    );
  }

  void _addPlayerAsset(NFLPlayer player, NFLTeamInfo team) {
    TeamTradePackage? package = team == team1 ? team1Package : team2Package;
    if (package != null && package.canAddAsset()) {
      setState(() {
        package.addAsset(PlayerAsset(player));
      });
      _updateTradeLikelihood();
    }
  }

  void _addPickAsset(DraftPickAsset pick, NFLTeamInfo team) {
    TeamTradePackage? package = team == team1 ? team1Package : team2Package;
    if (package != null && package.canAddAsset()) {
      setState(() {
        package.addAsset(pick);
      });
      _updateTradeLikelihood();
    }
  }

  void _showAssetSelectionDialog(NFLTeamInfo team) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          child: Column(
            children: [
              const Text(
                'Add Asset',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showPlayerSelectionModal(team);
                      },
                      icon: const Icon(Icons.person),
                      label: const Text('Add Player'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDraftPickSelection(team);
                      },
                      icon: const Icon(Icons.confirmation_number),
                      label: const Text('Add Pick'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDraftPickSelection(NFLTeamInfo team) {
    List<DraftPickAsset> picks = _generateTeamPicks(team);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${team.teamName} Draft Picks'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: ListView.builder(
              itemCount: picks.length,
              itemBuilder: (context, index) {
                DraftPickAsset pick = picks[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    child: Text(pick.round.toString()),
                  ),
                  title: Text(pick.displayName),
                  subtitle: Text('Value: \$${pick.marketValue.toStringAsFixed(1)}M'),
                  onTap: () {
                    Navigator.pop(context);
                    _addPickAsset(pick, team);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _removeAssetFromSlot(int slotIndex, NFLTeamInfo team) {
    TeamTradePackage? package = team == team1 ? team1Package : team2Package;
    setState(() {
      package?.removeAssetFromSlot(slotIndex);
    });
    _updateTradeLikelihood();
  }

  TeamTradePackage? _getCurrentPackage() {
    // Simple logic - could be improved with better state management
    if (team1Package != null && team1Package!.filledSlots < 5) return team1Package;
    if (team2Package != null && team2Package!.filledSlots < 5) return team2Package;
    return team1Package; // fallback
  }

  bool _hasAnyAssets() {
    return (team1Package?.hasAssets ?? false) || (team2Package?.hasAssets ?? false);
  }

  void _updateTradeLikelihood() {
    if (team1 == null || team2 == null || !_hasAnyAssets()) {
      setState(() {
        tradeLikelihood = 0.0;
      });
      return;
    }

    double team1Value = team1Package?.totalValue ?? 0.0;
    double team2Value = team2Package?.totalValue ?? 0.0;
    double valueRatio = team1Value > 0 ? team2Value / team1Value : (team2Value > 0 ? 0.0 : 0.5);
    
    // Base likelihood on value fairness
    double likelihood = 0.5;
    if (valueRatio >= 0.9 && valueRatio <= 1.1) {
      likelihood = 0.9; // Very fair trade
    } else if (valueRatio >= 0.8 && valueRatio <= 1.2) {
      likelihood = 0.7; // Good trade
    } else if (valueRatio >= 0.7 && valueRatio <= 1.3) {
      likelihood = 0.5; // Okay trade
    } else {
      likelihood = 0.2; // Poor trade
    }

    setState(() {
      tradeLikelihood = likelihood.clamp(0.0, 1.0);
    });
  }

  Color _getLikelihoodColor() {
    if (tradeLikelihood >= 0.8) return Colors.green;
    if (tradeLikelihood >= 0.6) return Colors.orange;
    if (tradeLikelihood >= 0.4) return Colors.amber;
    return Colors.red;
  }

  String _getLikelihoodText() {
    if (tradeLikelihood >= 0.8) return 'Highly Likely - Fair value for both teams';
    if (tradeLikelihood >= 0.6) return 'Likely - Reasonable compensation';
    if (tradeLikelihood >= 0.4) return 'Possible - May need adjustments';
    if (tradeLikelihood >= 0.2) return 'Unlikely - Uneven value';
    return 'Very Unlikely - Poor trade proposal';
  }

  void _analyzeTrade() {
    // Show detailed analysis modal
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trade Analysis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trade Likelihood: ${(tradeLikelihood * 100).round()}%'),
              const SizedBox(height: 8),
              Text('${team1!.teamName} receives: \$${(team2Package?.totalValue ?? 0.0).toStringAsFixed(1)}M value'),
              Text('${team2!.teamName} receives: \$${(team1Package?.totalValue ?? 0.0).toStringAsFixed(1)}M value'),
              const SizedBox(height: 16),
              Text(_getLikelihoodText()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _clearTrade() {
    setState(() {
      team1Package?.clearAllAssets();
      team2Package?.clearAllAssets();
      tradeLikelihood = 0.0;
    });
  }
}