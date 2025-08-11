// lib/screens/madden_trade_analyzer_screen.dart

import 'package:flutter/material.dart';
import '../models/nfl_trade/nfl_player.dart';
import '../models/nfl_trade/nfl_team_info.dart';
import '../models/nfl_trade/trade_asset.dart';
import '../widgets/trade/player_selection_modal.dart';
import '../services/trade_likelihood_service.dart';
import '../services/historical_trade_precedents.dart';
import '../services/trade_data_service.dart';
import '../services/trade_valuation_service.dart';
import '../services/trade_value_calculator.dart';
import 'dart:math';

class MaddenTradeAnalyzerScreen extends StatefulWidget {
  const MaddenTradeAnalyzerScreen({super.key});

  @override
  State<MaddenTradeAnalyzerScreen> createState() => _MaddenTradeAnalyzerScreenState();
}

// Player grading system
class PlayerGrade {
  final double overall; // 0-100
  final double positionValue; // 0-25 points
  final double playerSkill; // 0-35 points  
  final double teamNeed; // 0-25 points
  final double ageValue; // 0-15 points
  final String positionValueExplanation;
  final String playerSkillExplanation;
  final String teamNeedExplanation;
  final String ageValueExplanation;

  PlayerGrade({
    required this.overall,
    required this.positionValue,
    required this.playerSkill,
    required this.teamNeed,
    required this.ageValue,
    required this.positionValueExplanation,
    required this.playerSkillExplanation,
    required this.teamNeedExplanation,
    required this.ageValueExplanation,
  });
}

class _MaddenTradeAnalyzerScreenState extends State<MaddenTradeAnalyzerScreen> {
  NFLTeamInfo? team1;
  NFLTeamInfo? team2;
  TeamTradePackage? team1Package;
  TeamTradePackage? team2Package;
  double tradeLikelihood = 0.0;
  TradeLikelihoodResult? tradeAnalysis;
  // Track last computed trade points to build a 50/50 balance bar
  double _lastTeam1Points = 0.0;
  double _lastTeam2Points = 0.0;
  String _balanceLabel() {
    if (team1 == null || team2 == null) return '';
    final left = (tradeLikelihood * 100).round();
    final right = 100 - left;
    if (left == 50) return 'Even 50/50';
    return left > 50 ? 'Favors ${team1!.teamName} $left/$right' : 'Favors ${team2!.teamName} $right/$left';
  }
  bool isLoading = true;

  // Real data from CSVs
  List<NFLTeamInfo> allTeams = [];
  List<NFLPlayer> allPlayers = [];

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    await TradeDataService.initialize();
    setState(() {
      allTeams = TradeDataService.getAllTeams();
      allPlayers = TradeDataService.getAllPlayers();
      isLoading = false;
    });
  }

  // OLD Sample teams - now replaced with real data
  final List<NFLTeamInfo> _oldSampleTeams = [
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
        experience: 4,
        marketValue: 45.0,
        contractStatus: 'extension_needed',
        contractYearsRemaining: 1,
        annualSalary: 2.8, // Still on rookie deal
        overallRating: 97.0,
        positionRank: 98.0, // Elite EDGE rusher
        ageAdjustedValue: 49.5,
        positionImportance: 0.9,
        durabilityScore: 90.0,
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
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('NFL Trade Machine'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading NFL player data...'),
            ],
          ),
        ),
      );
    }

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
                'Value Balance',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(_balanceLabel(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: tradeLikelihood, // now represents team1 share 0..1
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(_getLikelihoodColor()),
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text('Left = Team 1 • Right = Team 2 • Ideal = 50/50', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
            _buildCapAndPointsInfo(team, package!, isTeam1 ? team2 : team1),
            _buildTradeSlots(package, team),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              team.teamName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Top needs display inline (resolve latest from data service to avoid stale instance)
                          if ((TradeDataService.getTeam(team.abbreviation)?.topPositionNeeds ?? team.topPositionNeeds).isNotEmpty)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.priority_high, size: 10, color: Colors.blue[700]),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        (TradeDataService.getTeam(team.abbreviation)?.topPositionNeeds ?? team.topPositionNeeds).take(3).join(', '),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
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
                : const SizedBox.shrink(),
          ),
          // Team selector dropdown remains on the right
          _buildTeamSelector(team, isTeam1),
        ],
      ),
    );
  }

  Future<double> _computePackageDisplayPoints(TeamTradePackage package, NFLTeamInfo? receivingTeam) async {
    if (receivingTeam == null) {
      // No opposite team yet: simple sum
      double sum = 0.0;
      for (final a in package.assets) {
        sum += a.marketValue;
      }
      return sum;
    }

    // Collect players and picks separately
    final List<PlayerAsset> playerAssets = [];
    double pickSum = 0.0;
    for (final slot in package.slots) {
      if (!slot.isFilled) continue;
      final asset = slot.asset!;
      if (asset is PlayerAsset) {
        playerAssets.add(asset);
      } else {
        pickSum += asset.marketValue; // picks and other assets sum linearly
      }
    }

    if (playerAssets.isEmpty) return pickSum;

    // 1) Sort players by initial blended value (using current need levels) desc
    final Map<String, double> currentNeed = {};
    double getNeed(String pos) {
      final String lp = (pos == 'DE' || pos == 'EDGE') ? 'EDGE' : pos;
      return currentNeed.putIfAbsent(lp, () => receivingTeam.getNeedLevel(lp));
    }

    final List<_PlayerEval> prelim = playerAssets.map((pa) {
      final p = pa.player;
      final need = getNeed(p.position.toUpperCase());
      final double base = _calcBlendedTradeValueWithNeed(p, receivingTeam, need);
      return _PlayerEval(player: p, baseValue: base);
    }).toList();
    prelim.sort((a, b) => b.baseValue.compareTo(a.baseValue));

    // 2) Apply multi-player decay and need saturation sequentially
    const List<double> decay = [1.00, 0.75, 0.60, 0.50, 0.40];
    final Map<String, int> positionCounts = {};
    double playersTotal = 0.0;
    int eliteCount = 0;

    for (int i = 0; i < prelim.length; i++) {
      final p = prelim[i].player;
      final String pos = p.position.toUpperCase();
      final String lp = (pos == 'DE' || pos == 'EDGE') ? 'EDGE' : pos;

      final double needNow = getNeed(pos);
      // Recalculate with current need level
      final double rawVal = _calcBlendedTradeValueWithNeed(p, receivingTeam, needNow);

      // Position duplicate penalty (2nd+ at same position)
      final int seen = (positionCounts[lp] ?? 0);
      final double dupPenalty = seen == 0 ? 1.0 : pow(0.85, seen).toDouble();
      positionCounts[lp] = seen + 1;

      // Multi-player decay weight by order
      final double orderWeight = i < decay.length ? decay[i] : decay.last;

      final double effective = (rawVal * dupPenalty * orderWeight).clamp(0.0, 100.0);
      playersTotal += effective;

      // Elite tracking: use rawVal threshold
      final bool isEliteAge = (lp == 'QB') ? p.age <= 31 : p.age <= 27;
      if (rawVal >= 92.0 && isEliteAge) eliteCount += 1;

      // Need saturation for subsequent assets at same position
      final double reduction = 0.6 * (rawVal / 100.0);
      currentNeed[lp] = (needNow - reduction).clamp(0.0, 1.0);
    }

    // 3) Elite premium on the side that includes elite players
    double factor = 1.0;
    if (eliteCount >= 1) {
      factor = 1.15 * pow(1.08, eliteCount - 1).toDouble();
    }

    return (playersTotal * factor) + pickSum;
  }

  Widget _buildCapAndPointsInfo(NFLTeamInfo team, TeamTradePackage package, NFLTeamInfo? receivingTeam) {
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
                'Trade Points',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              FutureBuilder<double>(
                future: _computePackageDisplayPoints(package, receivingTeam),
                builder: (context, snapshot) {
                  final val = snapshot.data ?? 0.0;
                  return Text(
                    val.toStringAsFixed(0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Removed - no longer needed as team needs are shown in header

  // Removed - no longer needed

  Widget _buildTradeSlots(TeamTradePackage package, NFLTeamInfo team) {
    return Expanded(
      child: Container(
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
            Expanded(
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
    // Determine receiving team (the opposite team)
    NFLTeamInfo? receivingTeam = team == team1 ? team2 : team1;
    
    if (asset is PlayerAsset && receivingTeam != null) {
      return FutureBuilder<double>(
        future: Future.value(_calcBlendedTradeValue(asset.player, receivingTeam)),
        builder: (context, snapshot) {
          double tradeValue = snapshot.hasData ? snapshot.data! : 0.0;
          int gradeValue = tradeValue.round();
          Color gradeColor = _getGradeColor(tradeValue);
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Player name and position
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        asset.player.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${asset.player.position} • ${asset.player.team}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Grade display
                InkWell(
                  onTap: snapshot.hasData 
                      ? () => _showTradeValueBreakdown(asset.player, receivingTeam, tradeValue)
                      : null,
                  child: Container(
                    width: 50,
                    height: 32,
                    decoration: BoxDecoration(
                      color: gradeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: gradeColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: snapshot.hasData
                          ? Text(
                              '$gradeValue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: gradeColor,
                              ),
                            )
                          : SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.grey[400]),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Remove button
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                  onPressed: () => _removeAssetFromSlot(slotIndex, team),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Draft pick display (add value chip same as players)
      final double pickValue = asset.marketValue.clamp(0.0, 100.0);
      final int pickValueInt = pickValue.round();
      final Color chipColor = _getGradeColor(pickValue);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.confirmation_number,
              color: Colors.orange[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    asset.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    asset.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 50,
              height: 32,
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: chipColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$pickValueInt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: chipColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.grey[600]),
              onPressed: () => _removeAssetFromSlot(slotIndex, team),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
      );
    }
  }

  // Removed - no longer needed as value display is integrated into _buildFilledSlot

  // Removed - no longer needed as it's integrated into _buildFilledSlot

  // Removed - no longer needed

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
              'Value: ${pick.marketValue.toStringAsFixed(0)}/100',
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
    NFLTeamInfo? selected;
    final NFLTeamInfo? otherTeam = isTeam1 ? team2 : team1;
    final List<NFLTeamInfo> choices = allTeams
        .where((t) => otherTeam == null || t.abbreviation != otherTeam.abbreviation)
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Team'),
              content: SizedBox(
                width: 400,
                child: DropdownButtonFormField<NFLTeamInfo>(
                  isExpanded: true,
                  hint: const Text('Choose a team'),
                  value: selected,
                  items: choices.map((t) {
                    return DropdownMenuItem<NFLTeamInfo>(
                      value: t,
                      child: Row(
                        children: [
                          CircleAvatar(radius: 10, child: Text(t.abbreviation, style: const TextStyle(fontSize: 10))),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t.teamName)),
                          const SizedBox(width: 8),
                          Text('\$${t.availableCapSpace.toStringAsFixed(1)}M', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setStateDialog(() => selected = val),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () {
                          setState(() {
                            if (isTeam1) {
                              team1 = selected;
                              team1Package = TeamTradePackage(teamName: selected!.teamName);
                            } else {
                              team2 = selected;
                              team2Package = TeamTradePackage(teamName: selected!.teamName);
                            }
                          });
                          Navigator.pop(context);
                          _updateTradeLikelihood();
                        },
                  child: const Text('Select'),
                ),
              ],
            );
          },
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
    // Determine receiving team (the opposite team)
    NFLTeamInfo? receivingTeam = team == team1 ? team2 : team1;
    
    showDialog(
      context: context,
      builder: (context) {
        return PlayerSelectionModal(
          teamName: team.teamName,
          teamAbbreviation: team.abbreviation,
          onPlayerSelected: (player) {
            _addPlayerAsset(player, team);
          },
          receivingTeam: receivingTeam,
          calculateGrade: receivingTeam != null ? (player, receivingTeam) async {
            PlayerGrade grade = await _calculatePlayerGrade(player, receivingTeam);
            return grade.overall;
          } : null,
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
                  subtitle: Text('Value: ${pick.marketValue.toStringAsFixed(0)}/100'),
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

  void _updateTradeLikelihood() async {
    // Now this function recomputes display points and sets balance value
    if (team1 == null || team2 == null) {
      setState(() {
        tradeLikelihood = 0.5;
        _lastTeam1Points = 0;
        _lastTeam2Points = 0;
      });
      return;
    }
    final t1 = await _computePackageDisplayPoints(team1Package!, team2);
    final t2 = await _computePackageDisplayPoints(team2Package!, team1);
    setState(() {
      _lastTeam1Points = t1;
      _lastTeam2Points = t2;
      _fallbackTradeLikelihood(); // set tradeLikelihood from t1/t2
    });
  }

  void _performTradeAnalysis() async {
    try {
      TradeLikelihoodResult result = await TradeLikelihoodService.analyzeTrade(
        team1: team1!,
        team2: team2!,
        team1Package: team1Package!,
        team2Package: team2Package!,
      );

      setState(() {
        tradeLikelihood = result.likelihood;
        tradeAnalysis = result;
      });
    } catch (e) {
      // Fallback to simple calculation if enhanced analysis fails
      _fallbackTradeLikelihood();
    }
  }

  void _fallbackTradeLikelihood() {
    // Recompute balance where value is team1 share [0..1]
    double t1 = _lastTeam1Points;
    double t2 = _lastTeam2Points;
    double total = (t1 + t2);
    if (total <= 0) {
      tradeLikelihood = 0.5; // neutral
      return;
    }
    tradeLikelihood = (t1 / total).clamp(0.0, 1.0);
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
    // Show enhanced analysis modal
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.analytics, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Trade Analysis'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Likelihood Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getLikelihoodColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getLikelihoodColor()),
                    ),
                    child: Row(
                      children: [
                        Icon(_getLikelihoodIcon(), color: _getLikelihoodColor()),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${(tradeLikelihood * 100).round()}% ${tradeAnalysis?.category ?? 'Likelihood'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _getLikelihoodColor(),
                                ),
                              ),
                              Text(
                                tradeAnalysis?.description ?? _getLikelihoodText(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Trade Values
                  _buildTradeValueSection(),
                  const SizedBox(height: 16),

                  // Analysis Factors
                  if (tradeAnalysis?.factors.isNotEmpty ?? false) ...[
                    _buildAnalysisSection('Key Factors', tradeAnalysis!.factors),
                    const SizedBox(height: 16),
                  ],

                  // Suggestions
                  if (tradeAnalysis?.suggestions.isNotEmpty ?? false) ...[
                    _buildAnalysisSection('Suggestions', tradeAnalysis!.suggestions),
                  ],
                ],
              ),
            ),
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

  Widget _buildTradeValueSection() {
    double team1Value = team1Package?.totalValue ?? 0.0;
    double team2Value = team2Package?.totalValue ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trade Value Exchange',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team1!.teamName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Receives: ${team2Value.toStringAsFixed(0)}/100',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      team2!.teamName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Receives: ${team1Value.toStringAsFixed(0)}/100',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  IconData _getLikelihoodIcon() {
    if (tradeLikelihood >= 0.8) return Icons.check_circle;
    if (tradeLikelihood >= 0.6) return Icons.thumb_up;
    if (tradeLikelihood >= 0.4) return Icons.help;
    if (tradeLikelihood >= 0.2) return Icons.warning;
    return Icons.cancel;
  }

  void _clearTrade() {
    setState(() {
      team1Package?.clearAllAssets();
      team2Package?.clearAllAssets();
      tradeLikelihood = 0.0;
    });
  }

  // Player grading calculation methods
  Future<PlayerGrade> _calculatePlayerGrade(NFLPlayer player, NFLTeamInfo receivingTeam) async {
    // 1. Position Value (0-25 points)
    double positionValue = _calculatePositionValue(player.position);
    String positionExplanation = _getPositionValueExplanation(player.position, positionValue);
    
    // 2. Player Skill (0-35 points) - based on rankings/rating
    double playerSkill = await _calculatePlayerSkill(player);
    String skillExplanation = _getPlayerSkillExplanation(player, playerSkill);
    
    // 3. Team Need (0-25 points)
    double teamNeed = _calculateTeamNeed(player.position, receivingTeam);
    String needExplanation = _getTeamNeedExplanation(player.position, receivingTeam, teamNeed);
    
    // 4. Age Value (0-15 points)
    double ageValue = _calculateAgeValue(player.age, player.position);
    String ageExplanation = _getAgeValueExplanation(player.age, player.position, ageValue);
    
    double overall = positionValue + playerSkill + teamNeed + ageValue;
    
    return PlayerGrade(
      overall: overall.clamp(0, 100),
      positionValue: positionValue,
      playerSkill: playerSkill,
      teamNeed: teamNeed,
      ageValue: ageValue,
      positionValueExplanation: positionExplanation,
      playerSkillExplanation: skillExplanation,
      teamNeedExplanation: needExplanation,
      ageValueExplanation: ageExplanation,
    );
  }
  
  double _calculatePositionValue(String position) {
    // Premium positions get higher base value (max 25 points)
    const Map<String, double> positionValues = {
      'QB': 25.0,   // Most important position
      'EDGE': 23.0, // Elite pass rushers
      'OT': 22.0,   // Protect the QB
      'CB': 21.0,   // Cover elite WRs
      'WR': 20.0,   // Offensive weapons
      'DE': 19.0,   // Pass rush
      'DT': 18.0,   // Interior pressure
      'S': 17.0,    // Last line of defense
      'LB': 16.0,   // Versatile defenders
      'TE': 15.0,   // Offensive flexibility
      'OG': 14.0,   // Interior protection
      'C': 13.0,    // Center the line
      'RB': 12.0,   // Replaceable position
      'K': 8.0,     // Specialist
      'P': 7.0,     // Specialist
    };
    return positionValues[position] ?? 15.0;
  }
  
  String _getPositionValueExplanation(String position, double value) {
    String tier = value >= 22 ? "Premium" : value >= 18 ? "High" : value >= 14 ? "Mid" : "Low";
    return "$position is a $tier-value position (${value.toStringAsFixed(0)}/25 points)";
  }
  
  Future<double> _calculatePlayerSkill(NFLPlayer player) async {
    // DEBUG: Print player skill calculation for Micah Parsons
    if (player.name.contains('Parsons')) {
      print('🔍 DEBUG: Player skill calculation for ${player.name}');
      print('  - Overall Rating: ${player.overallRating}');
      print('  - Position Rank: ${player.positionRank}');
      print('  - Market Value: ${player.marketValue}');
    }
    
    // Use the overall rating from our trade value system (should be 75-99 scale)
    // Convert to 35-point scale for UI consistency  
    double normalizedRating = (player.overallRating - 75.0) / (99.0 - 75.0); // Convert 75-99 to 0-1
    double skillScore = (normalizedRating * 35.0).clamp(0.0, 35.0);
    
    if (player.name.contains('Parsons')) {
      print('  - Normalized Rating: $normalizedRating');
      print('  - Final Skill Score: $skillScore/35');
    }
    
    return skillScore;
  }
  
  String _getPlayerSkillExplanation(NFLPlayer player, double value) {
    double percentile = (value / 35.0) * 100;
    String tier = percentile >= 90 ? "Elite" : percentile >= 75 ? "Pro Bowl" : percentile >= 50 ? "Starter" : "Backup";
    return "$tier player at ${percentile.toStringAsFixed(0)}th percentile (${value.toStringAsFixed(0)}/35 points)";
  }
  
  /// Calculate player trade value on 0-100 scale based on your requirements
  double calculatePlayerTradeValue(NFLPlayer player, {NFLTeamInfo? receivingTeam}) {
    if (receivingTeam == null) return player.marketValue; // fallback
    return _calcBlendedTradeValue(player, receivingTeam);
  }
  
  double _calcBlendedTradeValue(NFLPlayer player, NFLTeamInfo receivingTeam) {
    final String pos = player.position.toUpperCase();
    final String lookupPos = (pos == 'DE' || pos == 'EDGE') ? 'EDGE' : pos;
    final double need = receivingTeam.getNeedLevel(lookupPos);
    final int approxRank = (100 - player.positionRank.clamp(0, 100)).round().clamp(0, 99) + 1;
    return TradeValueCalculator.calculateTradeValue(
      position: pos,
      positionRanking: approxRank,
      tier: 3,
      age: player.age,
      teamNeed: need,
      teamStatus: 'competitive',
      positionPercentile: player.positionRank, // 0-100
    );
  }

  double _calcBlendedTradeValueWithNeed(NFLPlayer player, NFLTeamInfo receivingTeam, double needOverride) {
    final String pos = player.position.toUpperCase();
    final int approxRank = (100 - player.positionRank.clamp(0, 100)).round().clamp(0, 99) + 1;
    return TradeValueCalculator.calculateTradeValue(
      position: pos,
      positionRanking: approxRank,
      tier: 3,
      age: player.age,
      teamNeed: needOverride.clamp(0.0, 1.0),
      teamStatus: 'competitive',
      positionPercentile: player.positionRank,
    );
  }

  double _calculateAgeTradeValue(int age, String position) {
    // Age curves by position (0-20 scale)
    Map<String, Map<String, int>> ageCurves = {
      'QB': {'peak_start': 26, 'peak_end': 34},
      'RB': {'peak_start': 22, 'peak_end': 27},
      'WR': {'peak_start': 24, 'peak_end': 30},
      'TE': {'peak_start': 25, 'peak_end': 31},
      'EDGE': {'peak_start': 24, 'peak_end': 30},
      'DE': {'peak_start': 24, 'peak_end': 30},
      'DT': {'peak_start': 25, 'peak_end': 31},
      'LB': {'peak_start': 24, 'peak_end': 30},
      'CB': {'peak_start': 23, 'peak_end': 29},
      'S': {'peak_start': 24, 'peak_end': 30},
      'OT': {'peak_start': 26, 'peak_end': 33},
    };
    
    var curve = ageCurves[position.toUpperCase()] ?? ageCurves['WR']!;
    int peakStart = curve['peak_start']!;
    int peakEnd = curve['peak_end']!;
    
    if (age < 22) return 10.0; // Very young, unproven
    if (age < peakStart) return 15.0; // Rising
    if (age <= peakEnd) return 20.0; // Peak years
    if (age <= peakEnd + 3) return 15.0; // Good veteran
    if (age <= peakEnd + 6) return 10.0; // Declining
    return 5.0; // Past prime
  }
  
  double _getTeamNeedForPosition(String position, NFLTeamInfo team) {
    if (position == 'DE' || position == 'EDGE') {
      double edgeNeed = team.getNeedLevel('EDGE');
      double deNeed = team.getNeedLevel('DE');
      return edgeNeed > deNeed ? edgeNeed : deNeed;
    }
    return team.getNeedLevel(position);
  }
  
  double _calculateTeamNeed(String position, NFLTeamInfo team) {
    // Handle EDGE/DE as same position for team needs
    String lookupPosition = position;
    if (position == 'DE' || position == 'EDGE') {
      // Get both EDGE and DE needs, use the higher one
      double edgeNeed = team.getNeedLevel('EDGE');
      double deNeed = team.getNeedLevel('DE');
      double maxNeed = edgeNeed > deNeed ? edgeNeed : deNeed;
      
      // DEBUG: Print team need calculation for Bills and EDGE players
      if (team.abbreviation == 'BUF' && (position == 'DE' || position == 'EDGE')) {
        print('🔍 DEBUG: Team need calculation for ${team.teamName} - $position');
        print('  - EDGE Need: $edgeNeed');
        print('  - DE Need: $deNeed');
        print('  - Max Need Used: $maxNeed');
      }
      
      // Convert 0-1 need scale to 0-25 points
      double needPoints = (maxNeed * 25.0).clamp(0.0, 25.0);
      
      if (team.abbreviation == 'BUF' && (position == 'DE' || position == 'EDGE')) {
        print('  - Final Need Points: $needPoints/25');
      }
      
      return needPoints;
    }
    
    // For other positions, use standard lookup
    double needLevel = team.getNeedLevel(position);
    return (needLevel * 25.0).clamp(0.0, 25.0);
  }
  
  String _getTeamNeedExplanation(String position, NFLTeamInfo team, double value) {
    String level = value >= 20 ? "Desperate" : value >= 15 ? "High" : value >= 10 ? "Moderate" : "Low";
    return "${team.abbreviation} has $level need for $position (${value.toStringAsFixed(0)}/25 points)";
  }
  
  double _calculateAgeValue(int age, String position) {
    // Age-based value (max 15 points)
    double ageScore = 15.0;
    
    // Position-specific age curves
    switch (position) {
      case 'RB':
        if (age <= 24) ageScore = 15.0;
        else if (age <= 26) ageScore = 12.0;
        else if (age <= 28) ageScore = 8.0;
        else if (age <= 30) ageScore = 4.0;
        else ageScore = 2.0;
        break;
        
      case 'QB':
        if (age <= 27) ageScore = 15.0;
        else if (age <= 32) ageScore = 14.0;
        else if (age <= 35) ageScore = 10.0;
        else if (age <= 37) ageScore = 6.0;
        else ageScore = 3.0;
        break;
        
      case 'WR':
      case 'TE':
        if (age <= 26) ageScore = 15.0;
        else if (age <= 29) ageScore = 13.0;
        else if (age <= 31) ageScore = 9.0;
        else if (age <= 33) ageScore = 5.0;
        else ageScore = 2.0;
        break;
        
      default: // Most positions
        if (age <= 26) ageScore = 15.0;
        else if (age <= 29) ageScore = 12.0;
        else if (age <= 32) ageScore = 8.0;
        else if (age <= 34) ageScore = 4.0;
        else ageScore = 2.0;
    }
    
    return ageScore;
  }
  
  String _getAgeValueExplanation(int age, String position, double value) {
    String stage = value >= 13 ? "Prime" : value >= 8 ? "Good" : value >= 4 ? "Declining" : "Twilight";
    return "Age $age is $stage for $position (${value.toStringAsFixed(0)}/15 points)";
  }
  
  Color _getGradeColor(double grade) {
    if (grade >= 90) return Colors.purple; // A+
    if (grade >= 80) return Colors.green; // A
    if (grade >= 70) return Colors.blue; // B
    if (grade >= 60) return Colors.orange; // C
    if (grade >= 50) return Colors.amber; // D
    return Colors.red; // F
  }
  
  String _getGradeLetter(double grade) {
    if (grade >= 97) return 'A+';
    if (grade >= 93) return 'A';
    if (grade >= 90) return 'A-';
    if (grade >= 87) return 'B+';
    if (grade >= 83) return 'B';
    if (grade >= 80) return 'B-';
    if (grade >= 77) return 'C+';
    if (grade >= 73) return 'C';
    if (grade >= 70) return 'C-';
    if (grade >= 67) return 'D+';
    if (grade >= 63) return 'D';
    if (grade >= 60) return 'D-';
    return 'F';
  }
  
  void _showTradeValueBreakdown(NFLPlayer player, NFLTeamInfo receivingTeam, double tradeValue) {
    final String pos = player.position.toUpperCase();
    final String lookupPos = (pos == 'DE' || pos == 'EDGE') ? 'EDGE' : pos;
    final double need = receivingTeam.getNeedLevel(lookupPos);
    final int approxRank = (100 - player.positionRank.clamp(0, 100)).round().clamp(0, 99) + 1;
    final breakdown = TradeValueCalculator.getValueBreakdown(
      position: pos,
      positionRanking: approxRank,
      tier: 3,
      age: player.age,
      teamNeed: need,
      teamStatus: 'competitive',
      positionPercentile: player.positionRank,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${player.name} Trade Value'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Position: ${player.position} • Age: ${player.age}'),
            const SizedBox(height: 16),
            _buildValueRow('Rank Contribution', breakdown['rank_points'] as double, 66, 'Percentile^2 × 66'),
            _buildValueRow('Position Contribution', breakdown['position_points'] as double, 14, 'Role importance × 14'),
            _buildValueRow('Team Need Contribution', breakdown['need_points'] as double, 12, '${receivingTeam.abbreviation} need level'),
            _buildValueRow('Age Contribution', breakdown['age_points'] as double, 8, 'Age curve for ${player.position}'),
            const Divider(),
            _buildValueRow('Bonus (Top 5)', breakdown['bonus'] as double, 5, 'Elite rank bonus'),
            const Divider(),
            _buildValueRow('Final Value', breakdown['final_value'] as double, 100, 'Weighted sum + bonus', isFinal: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildValueRow(String label, double value, double maxValue, String description, {bool isMultiplier = false, bool isFinal = false}) {
    String valueText = isMultiplier ? '${value.toStringAsFixed(2)}x' : '${value.toStringAsFixed(1)}/${maxValue.toStringAsFixed(0)}';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  fontWeight: isFinal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isFinal ? 16 : 14,
                )),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(valueText, style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isFinal ? 18 : 14,
            color: isFinal ? Theme.of(context).primaryColor : null,
          )),
        ],
      ),
    );
  }

  void _showGradeBreakdown(NFLPlayer player, NFLTeamInfo receivingTeam, PlayerGrade grade) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getGradeColor(grade.overall),
                radius: 20,
                child: Text(
                  _getGradeLetter(grade.overall),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Trade Value to ${receivingTeam.teamName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Overall Grade
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getGradeColor(grade.overall).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getGradeColor(grade.overall)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Overall Grade: ',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      Text(
                        '${grade.overall.round()}/100',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getGradeColor(grade.overall),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Breakdown sections
                _buildGradeSection(
                  'Position Value',
                  grade.positionValue,
                  25,
                  grade.positionValueExplanation,
                  Icons.sports_football,
                ),
                const SizedBox(height: 8),
                _buildGradeSection(
                  'Player Skill',
                  grade.playerSkill,
                  35,
                  grade.playerSkillExplanation,
                  Icons.star,
                ),
                const SizedBox(height: 8),
                _buildGradeSection(
                  'Team Need',
                  grade.teamNeed,
                  25,
                  grade.teamNeedExplanation,
                  Icons.priority_high,
                ),
                const SizedBox(height: 8),
                _buildGradeSection(
                  'Age & Prime',
                  grade.ageValue,
                  15,
                  grade.ageValueExplanation,
                  Icons.calendar_today,
                ),
                const SizedBox(height: 16),
                
                // Historical precedent section
                _buildHistoricalPrecedentSection(player, grade),
              ],
            ),
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
  
  Widget _buildHistoricalPrecedentSection(NFLPlayer player, PlayerGrade grade) {
    String recommendation = HistoricalTradePrecedents.getTradeRecommendation(grade.overall, player.position);
    double expectedPoints = HistoricalTradePrecedents.getExpectedDraftPointsForGrade(grade.overall, player.position);
    double inflatedPoints = expectedPoints * HistoricalTradePrecedents.getMarketInflationFactor(DateTime.now().year);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 16, color: Colors.amber[700]),
              const SizedBox(width: 4),
              Text(
                'Trade Market Value',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on ${inflatedPoints.toStringAsFixed(0)} draft value points from similar trades (Khalil Mack, Bradley Chubb, etc.)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeSection(String title, double value, double maxValue, String explanation, IconData icon) {
    double percentage = (value / maxValue) * 100;
    Color barColor = percentage >= 80 ? Colors.green : percentage >= 60 ? Colors.blue : percentage >= 40 ? Colors.orange : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(0)}/${maxValue.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: barColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / maxValue,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(barColor),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text(
            explanation,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelector(NFLTeamInfo? team, bool isTeam1) {
    return SizedBox(
      width: 260,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280,
          child: DropdownButtonFormField<NFLTeamInfo>(
            isExpanded: true,
            hint: const Text('Select team'),
            value: team,
            items: allTeams.map((t) {
              // Hide the already-picked opposite team
              final other = isTeam1 ? team2 : team1;
              if (other != null && other.abbreviation == t.abbreviation) {
                return null;
              }
              return DropdownMenuItem<NFLTeamInfo>(
                value: t,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: t.logoUrl != null ? NetworkImage(t.logoUrl!) : null,
                      child: t.logoUrl == null ? Text(t.abbreviation, style: const TextStyle(fontSize: 10)) : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t.teamName, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }).whereType<DropdownMenuItem<NFLTeamInfo>>().toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                final latest = TradeDataService.getTeam(val.abbreviation) ?? val;
                if (isTeam1) {
                  team1 = latest;
                  team1Package = TeamTradePackage(teamName: val.teamName);
                } else {
                  team2 = latest;
                  team2Package = TeamTradePackage(teamName: val.teamName);
                }
              });
              _updateTradeLikelihood();
            },
          ),
        ),
      ),
    );
  }
}

class _PlayerEval {
  final NFLPlayer player;
  final double baseValue;
  _PlayerEval({required this.player, required this.baseValue});
}