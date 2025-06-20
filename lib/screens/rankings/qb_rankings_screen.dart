import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../utils/team_logo_utils.dart';

class QBRankingsScreen extends StatefulWidget {
  const QBRankingsScreen({super.key});

  @override
  State<QBRankingsScreen> createState() => _QBRankingsScreenState();
}

class _QBRankingsScreenState extends State<QBRankingsScreen> {
  List<Map<String, dynamic>> _qbRankings = [];
  Map<String, Map<String, dynamic>> _teamQbTiers = {};
  bool _isLoading = true;
  String? _error;
  String _selectedSeason = '2024';
  String _selectedTier = 'All';
  
  final List<String> _seasons = ['2024', '2023', '2022', '2021', '2020', '2019', '2018', '2017', '2016'];
  final List<String> _tiers = ['All', '1', '2', '3', '4', '5', '6', '7', '8'];

  @override
  void initState() {
    super.initState();
    _fetchQBRankings();
  }

  Future<void> _fetchQBRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch both individual QB rankings and team QB tiers in parallel
      final results = await Future.wait([
        _fetchIndividualQBRankings(),
        _fetchTeamQBTiers(),
      ]);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = _handleFirebaseError(e, 'fetching QB rankings');
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchIndividualQBRankings() async {
    Query query = FirebaseFirestore.instance
        .collection('qbRankings')
        .where('season', isEqualTo: int.parse(_selectedSeason));

    final QuerySnapshot snapshot = await query.get();
    
    List<Map<String, dynamic>> rankings = snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();

    // Apply tier filtering in memory if needed
    if (_selectedTier != 'All') {
      final tierFilter = int.parse(_selectedTier);
      rankings = rankings.where((qb) => qb['qb_tier'] == tierFilter).toList();
    }

    // Sort by rank number in memory
    rankings.sort((a, b) {
      final rankA = a['rank_number'] as int? ?? 999;
      final rankB = b['rank_number'] as int? ?? 999;
      return rankA.compareTo(rankB);
    });
    
    setState(() {
      _qbRankings = rankings;
    });
  }

  Future<void> _fetchTeamQBTiers() async {
    Query query = FirebaseFirestore.instance
        .collection('teamQbTiers')
        .where('season', isEqualTo: int.parse(_selectedSeason));

    final QuerySnapshot snapshot = await query.get();
    
    Map<String, Map<String, dynamic>> teamTiers = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final team = data['team'] as String?;
      if (team != null) {
        teamTiers[team] = {
          'id': doc.id,
          ...data,
        };
      }
    }
    
    setState(() {
      _teamQbTiers = teamTiers;
    });
  }

  String _handleFirebaseError(dynamic error, String operation) {
    final errorString = error.toString();
    
    if (errorString.contains('FAILED_PRECONDITION') && errorString.contains('index')) {
      final urlMatch = RegExp(r'https://console\.firebase\.google\.com[^\s]+').firstMatch(errorString);
      final indexUrl = urlMatch?.group(0) ?? '';
      
      if (indexUrl.isNotEmpty) {
        _logMissingIndex(indexUrl, operation);
      }
      
      return 'Missing Database Index Required - Check console for setup link';
    }
    
    if (errorString.contains('permission-denied')) {
      return 'Permission denied. Please sign in to access this feature.';
    }
    
    if (errorString.contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again in a moment.';
    }
    
    return 'Error $operation: ${errorString.length > 100 ? '${errorString.substring(0, 100)}...' : errorString}';
  }

  Future<void> _logMissingIndex(String indexUrl, String operation) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('logMissingIndex');
      await callable.call({
        'url': indexUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'screenName': 'QBRankingsScreen',
        'queryDetails': {
          'operation': operation,
          'season': _selectedSeason,
          'tier': _selectedTier,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'errorMessage': 'Index required for QB rankings functionality',
      });
      print('Missing index logged successfully for operation: $operation');
    } catch (e) {
      print('Failed to log missing index: $e');
    }
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return Colors.green[700]!;
      case 2:
        return Colors.green[500]!;
      case 3:
        return Colors.blue[600]!;
      case 4:
        return Colors.orange[600]!;
      case 5:
        return Colors.orange[800]!;
      case 6:
        return Colors.red[600]!;
      case 7:
        return Colors.red[800]!;
      case 8:
        return Colors.grey[600]!;
      default:
        return Colors.grey[400]!;
    }
  }

  String _getTierLabel(int tier) {
    switch (tier) {
      case 1:
        return 'Elite';
      case 2:
        return 'Very Good';
      case 3:
        return 'Good';
      case 4:
        return 'Average';
      case 5:
        return 'Below Average';
      case 6:
        return 'Poor';
      case 7:
        return 'Very Poor';
      case 8:
        return 'Backup';
      default:
        return 'Unranked';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QB Rankings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Container(
            color: Theme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TopNavBarContent(currentRoute: currentRoute, fontSize: 13.0),
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Season',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSeason,
                    items: _seasons
                        .map((season) => DropdownMenuItem(
                              value: season,
                              child: Text(season),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSeason = value;
                        });
                        _fetchQBRankings();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tier',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedTier,
                    items: _tiers
                        .map((tier) => DropdownMenuItem(
                              value: tier,
                              child: Text(tier == 'All' ? 'All Tiers' : 'Tier $tier'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTier = value;
                        });
                        _fetchQBRankings();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _fetchQBRankings,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          // Data Table Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _qbRankings.isEmpty
                        ? const Center(
                            child: Text(
                              'No QB rankings found for the selected filters.',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _buildRankingsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 12,
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          columns: const [
            DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Player', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('QB Tier', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Team Tier', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Team Rank', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Games', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Pass Att', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Total EPA', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('CPOE', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('YPG', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('TD/Game', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('INT/Game', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('3rd Down %', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _qbRankings.map((qb) {
            final tier = qb['qb_tier'] as int? ?? 0;
            final tierColor = _getTierColor(tier);
            final team = qb['team'] as String? ?? '';
            final teamTierData = _teamQbTiers[team];
            final teamTier = teamTierData?['team_qb_tier'] as int? ?? 0;
            final teamRank = teamTierData?['team_rank_number'] as int? ?? 0;
            final teamTierColor = _getTierColor(teamTier);
            
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${qb['rank_number'] ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tierColor,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    qb['player_name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TeamLogoUtils.buildNFLTeamLogo(team, size: 20),
                      const SizedBox(width: 6),
                      Text(team.isEmpty ? 'UNK' : team),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                    decoration: BoxDecoration(
                      color: tierColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'T$tier',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  teamTier > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                          decoration: BoxDecoration(
                            color: teamTierColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'T$teamTier',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const Text('-', style: TextStyle(color: Colors.grey)),
                ),
                DataCell(
                  teamRank > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                          decoration: BoxDecoration(
                            color: teamTierColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#$teamRank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: teamTierColor,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : const Text('-', style: TextStyle(color: Colors.grey)),
                ),
                DataCell(Text('${qb['games'] ?? 0}')),
                DataCell(Text('${qb['pass_attempts'] ?? 0}')),
                DataCell(
                  Text(
                    (qb['total_epa'] as num?)?.toStringAsFixed(1) ?? '0.0',
                    style: TextStyle(
                      color: (qb['total_epa'] as num? ?? 0) > 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    (qb['avg_cpoe'] as num?)?.toStringAsFixed(3) ?? '0.000',
                    style: TextStyle(
                      color: (qb['avg_cpoe'] as num? ?? 0) > 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
                DataCell(Text((qb['yards_per_game'] as num?)?.toStringAsFixed(1) ?? '0.0')),
                DataCell(Text((qb['tds_per_game'] as num?)?.toStringAsFixed(2) ?? '0.00')),
                DataCell(
                  Text(
                    (qb['ints_per_game'] as num?)?.toStringAsFixed(2) ?? '0.00',
                    style: TextStyle(
                      color: (qb['ints_per_game'] as num? ?? 0) < 1.0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${((qb['third_down_conversion_rate'] as num? ?? 0) * 100).toStringAsFixed(1)}%',
                  ),
                ),
                DataCell(
                  Text(
                    (qb['composite_rank_score'] as num?)?.toStringAsFixed(2) ?? '0.00',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
} 